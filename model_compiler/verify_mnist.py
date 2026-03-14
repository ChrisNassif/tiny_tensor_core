"""End-to-end MNIST verification: compile model → inject test images → simulate in parallel → compare to PyTorch."""
import torch, numpy as np, subprocess, sys, os, math, shutil, tempfile, argparse
from multiprocessing import Pool, cpu_count
from torchvision import datasets, transforms

MODEL_PATH = "models/quantized_tensor_core_mnist_969_64_hidden_layer.pt"
SV_FILES = ["src/tensor_core_test_bench.sv", "src/tensor_core_memory_controller.sv",
            "src/tensor_core_controller.sv", "src/tensor_core.sv", "src/tensor_core_register_file.sv"]
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def hw_trunc5(val):
    """Truncate to 5-bit signed (what registers hold)."""
    v = int(val) & 0x1F
    return v - 32 if v >= 16 else v

def hw_dot12(a_vec, b_vec):
    """3-element dot product truncated to 12-bit signed (tensor core intermediate sum)."""
    s = sum(int(a_vec[k]) * int(b_vec[k]) for k in range(3))
    s = s & 0xFFF
    return s - 4096 if s >= 2048 else s

def wrap32(val):
    """32-bit signed wrap."""
    v = int(val) & 0xFFFFFFFF
    return v - 0x100000000 if v >= 0x80000000 else v

def compute_quantized_reference(input_float, sd):
    """Hardware-accurate reference: 5-bit regs, 12-bit dot products, 32-bit memory."""
    input_log2 = int(math.log2(sd['quant.scale'].item()))
    x_quant = torch.clamp(torch.round(input_float * (2 ** -input_log2)).int(), -64, 63).numpy().flatten()

    x_padded = np.zeros(((len(x_quant) + 2) // 3) * 3, dtype=np.int64)
    x_padded[:len(x_quant)] = x_quant

    for layer in ['fc1', 'fc2']:
        W_q, _ = sd[f'{layer}._packed_params._packed_params']
        W_int = W_q.int_repr().int().numpy()
        out_features, in_features = W_int.shape

        out_padded = ((out_features + 2) // 3) * 3
        in_padded = ((in_features + 2) // 3) * 3

        W_padded = np.zeros((out_padded, in_padded), dtype=np.int64)
        W_padded[:out_features, :in_features] = W_int

        # Register load truncation: 5-bit signed
        X_reg = np.array([hw_trunc5(v) for v in x_padded], dtype=np.int64)
        W_reg = np.array([[hw_trunc5(v) for v in row] for row in W_padded.T], dtype=np.int64)

        I = in_padded // 3
        J = out_padded // 3

        # Accumulate in 32-bit memory (matrix_add adds 12-bit dot products into 32-bit words)
        acc = np.zeros((J, 3), dtype=np.int64)
        for i in range(I):
            x_tile = X_reg[i*3:i*3+3]
            for j in range(J):
                for c in range(3):
                    dp = hw_dot12(x_tile, W_reg[i*3:i*3+3, j*3+c])
                    acc[j, c] = wrap32(acc[j, c] + dp)

        acc = acc.flatten()[:out_features]

        total_shift = (input_log2 + int(math.log2(W_q.q_scale()))) - int(math.log2(sd[f'{layer}.scale'].item()))
        if total_shift < 0:
            scaled = np.array([wrap32(int(v) >> (-total_shift)) for v in acc])
        else:
            scaled = np.array([wrap32(int(v) << total_shift) for v in acc])

        if layer == 'fc1':
            scaled = np.where(np.array([int(v) for v in scaled]) < 0, 0, scaled)

        x_padded = np.zeros(out_padded, dtype=np.int64)
        x_padded[:out_features] = scaled
        input_log2 = int(math.log2(sd[f'{layer}.scale'].item()))

    return x_padded[:10].tolist()

def run_single_test(args):
    """Run one MNIST test image in an isolated temp directory. Returns (test_idx, label, hw_logits, ref_logits, passed)."""
    test_idx, label, x_quant, base_blocks, output_blocks, input_tiles, sd_path = args
    INPUT_START_BLOCK = 3

    tmpdir = tempfile.mkdtemp(prefix=f"mnist_test_{test_idx}_")
    try:
        # Copy project files to temp dir (skip build artifacts)
        for f in os.listdir(PROJECT_ROOT):
            if f in ['build', 'obj_dir', '.git', '__pycache__', '.gemini', 'brain', 'models', 'model_compiler']: continue
            src = os.path.join(PROJECT_ROOT, f)
            dst = os.path.join(tmpdir, f)
            if os.path.isdir(src):
                shutil.copytree(src, dst)
            else:
                shutil.copy2(src, dst)

        # Create build directory in temp folder
        os.makedirs(os.path.join(tmpdir, "build"), exist_ok=True)

        # Inject quantized input into memory blocks
        blocks = [row[:] for row in base_blocks]
        for t in range(input_tiles):
            tile = [0] * 9
            for k in range(3):
                idx = t * 3 + k
                if idx < 784: tile[k] = int(x_quant[idx])
            blocks[INPUT_START_BLOCK + t] = tile

        # Write data and assembly to temp dir
        with open(os.path.join(tmpdir, "data_in_plain_text.txt"), "w") as f:
            f.writelines(" ".join(str(v) for v in b) + "\n" for b in blocks)

        asm_src = os.path.join(PROJECT_ROOT, "assembly_code.asm")
        shutil.copy2(asm_src, os.path.join(tmpdir, "assembly_code.asm"))

        def run(cmd):
            res = subprocess.run(cmd, capture_output=True, text=True, timeout=600, cwd=tmpdir)
            if res.returncode != 0:
                return False, f"Command '{' '.join(cmd)}' failed:\n{res.stderr}\n{res.stdout}"
            return True, "OK"

        success, msg = run([sys.executable, "assembler.py", "assembly_code.asm"])
        if not success: return (test_idx, label, None, None, False, msg)
        
        success, msg = run([sys.executable, "convert_data_from_data_in_plain_text_to_data_in.py"])
        if not success: return (test_idx, label, None, None, False, msg)
        
        # Copy the Verilator executable binary to the temp workspace
        bin_name = "Vtensor_core_test_bench"
        src_bin = os.path.join(PROJECT_ROOT, "build", "verilator_obj", bin_name)
        dst_bin = os.path.join(tmpdir, "build", bin_name)
        shutil.copy2(src_bin, dst_bin)
        
        # Run Verilator binary natively
        success, msg = run([dst_bin])
        if not success: return (test_idx, label, None, None, False, msg)
        
        success, msg = run([sys.executable, "convert_data_from_data_out_to_data_out_plain_text.py"])
        if not success: return (test_idx, label, None, None, False, msg)

        # Read hardware output
        with open(os.path.join(tmpdir, "data_out_plain_text.txt")) as f:
            hw_blocks = [[int(v) for v in line.split()] for line in f]

        hw_logits = [v for bid in output_blocks for v in hw_blocks[bid][:3]][:10]

        return (test_idx, label, hw_logits, None, True, "OK")
    except Exception as e:
        return (test_idx, label, None, None, False, str(e))
    finally:
        shutil.rmtree(tmpdir, ignore_errors=True)

def main():
    parser = argparse.ArgumentParser(description="End-to-end MNIST verification with Verilator")
    parser.add_argument("-n", "--num-tests", type=int, default=100, 
                        help="Number of MNIST images to test. Use 0 to run the entire dataset. (default: 100)")
    args = parser.parse_args()

    sd = torch.load(os.path.join(PROJECT_ROOT, MODEL_PATH), map_location='cpu')

    # Compile model once to get weight layout and assembly
    print("=== Compiling model ===")
    result = subprocess.run(
        [sys.executable, os.path.join(PROJECT_ROOT, 'model_compiler/compiler.py'),
         os.path.join(PROJECT_ROOT, MODEL_PATH)],
        capture_output=True, text=True, cwd=PROJECT_ROOT
    )
    if result.returncode != 0:
        print("Compile failed:", result.stderr); return False

    import ast
    output_blocks = []
    for line in result.stdout.splitlines():
        if "Final output blocks" in line:
            output_blocks = ast.literal_eval(line.split(":", 1)[1].strip())
    print(f"  Output blocks: {output_blocks}")
    print(f"  {result.stdout.strip()}")

    print("=== Compiling SystemVerilog Simulation with Verilator ===")
    verilator_build_dir = os.path.join(PROJECT_ROOT, "build", "verilator_obj")
    os.makedirs(verilator_build_dir, exist_ok=True)
    
    compile_cmd = [
        "verilator", "--binary", "-Wno-fatal", 
        "--top-module", "tensor_core_test_bench",
        "-Mdir", verilator_build_dir
    ] + [os.path.join(PROJECT_ROOT, f) for f in SV_FILES]
    
    compile_res = subprocess.run(compile_cmd, capture_output=True, text=True, cwd=PROJECT_ROOT)
    if compile_res.returncode != 0:
        print("Verilator Compile failed:\n", compile_res.stderr, "\n", compile_res.stdout) 
        return False

    # Load test data
    dataset = datasets.MNIST('../data', train=False, transform=transforms.Compose(
        [transforms.ToTensor(), lambda y: y.to(torch.float)]), download=True)

    input_log2 = int(math.log2(sd['quant.scale'].item()))
    input_tiles = (784 + 2) // 3

    base_blocks = []
    with open(os.path.join(PROJECT_ROOT, "data_in_plain_text.txt")) as f:
        base_blocks = [[int(x) for x in line.split()] for line in f]

    # Determine number of tests to run based on arguments
    total_dataset_len = len(dataset)
    if args.num_tests <= 0:
        num_tests = total_dataset_len
    else:
        num_tests = min(args.num_tests, total_dataset_len)

    num_workers = cpu_count()
    print(f"\nPreparing {num_tests} tasks...")

    # Prepare test data
    tasks = []
    ref_logits_map = {}
    for i in range(num_tests):
        data, label = dataset[i]
        input_float = data.flatten().unsqueeze(0)
        x_quant = torch.clamp(torch.round(input_float * (2 ** -input_log2)).int(), -64, 63).numpy().flatten()
        ref_logits_map[i] = compute_quantized_reference(input_float, sd)[:10]
        tasks.append((i, label, x_quant, base_blocks, output_blocks, input_tiles,
                      os.path.join(PROJECT_ROOT, MODEL_PATH)))

    print(f"Running {num_tests} tests in parallel on {num_workers} processes...")
    
    # Run in parallel with progress tracking
    results = []
    with Pool(num_workers) as pool:
        for i, res in enumerate(pool.imap_unordered(run_single_test, tasks), 1):
            results.append(res)
            if num_tests >= 500:
                if i % 500 == 0 or i == num_tests:
                    print(f"  Completed {i}/{num_tests} simulations...")
            else:
                if i % max(1, num_tests // 10) == 0 or i == num_tests:
                    print(f"  Completed {i}/{num_tests} simulations...")

    # Process and print aggregated results
    print("\n=== Final Results ===")
    correct_count = 0
    failed_tests = []
    all_pass = True

    for test_idx, label, hw_logits, _, success, msg in sorted(results, key=lambda x: x[0]):
        ref_logits = ref_logits_map[test_idx]
        if not success:
            failed_tests.append(f"Test {test_idx} (digit={label}): FAILED — {msg}")
            all_pass = False
            continue

        match = hw_logits == ref_logits
        if match:
            correct_count += 1
        else:
            hw_pred, ref_pred = np.argmax(hw_logits), np.argmax(ref_logits)
            failed_tests.append(f"Test {test_idx} (digit={label}): HW={hw_pred} Ref={ref_pred} ✗\n  HW:  {hw_logits}\n  Ref: {ref_logits}")
            all_pass = False

    match_percentage = (correct_count / num_tests) * 100
    print(f"Hardware outputs matching PyTorch reference: {correct_count}/{num_tests} ({match_percentage:.2f}%)")

    if not all_pass:
        print("\nSOME TESTS HAD DIFFERENCES OR FAILED.")
        print("Showing up to the first 15 failures:")
        for fail_msg in failed_tests[:15]:
            print(fail_msg)
        if len(failed_tests) > 15:
            print(f"... and {len(failed_tests) - 15} more failures.")
    else:
        print("ALL TESTS PASSED ✓")

    print("=" * 50)
    return all_pass

if __name__ == "__main__":
    sys.exit(0 if main() else 1)