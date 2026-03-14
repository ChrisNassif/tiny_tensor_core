"""End-to-end MNIST verification: Measure hardware accuracy % against dataset ground truth."""
import torch, numpy as np, subprocess, sys, os, math, shutil, tempfile, argparse
from multiprocessing import Pool, cpu_count
from torchvision import datasets, transforms

MODEL_PATH = "models/quantized_tensor_core_mnist_961_5bit.pt"
SV_FILES = ["src/tensor_core_test_bench.sv", "src/tensor_core_memory_controller.sv",
            "src/tensor_core_controller.sv", "src/tensor_core.sv", "src/tensor_core_register_file.sv"]
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def run_single_test(args):
    """Run one MNIST test image through the Verilator simulation."""
    test_idx, label, x_quant, base_blocks, output_blocks, input_tiles = args
    INPUT_START_BLOCK = 3

    tmpdir = tempfile.mkdtemp(prefix=f"mnist_test_{test_idx}_")
    try:
        # Copy necessary files to temp directory
        for f in os.listdir(PROJECT_ROOT):
            if f in ['build', 'obj_dir', '.git', '__pycache__', '.gemini', 'brain', 'models', 'model_compiler']: continue
            src = os.path.join(PROJECT_ROOT, f)
            dst = os.path.join(tmpdir, f)
            if os.path.isdir(src):
                shutil.copytree(src, dst)
            else:
                shutil.copy2(src, dst)

        os.makedirs(os.path.join(tmpdir, "build"), exist_ok=True)

        # Inject quantized input pixels into memory blocks
        blocks = [row[:] for row in base_blocks]
        for t in range(input_tiles):
            tile = [0] * 9
            for k in range(3):
                idx = t * 3 + k
                if idx < 784: tile[k] = int(x_quant[idx])
            blocks[INPUT_START_BLOCK + t] = tile

        # Write data and assembly
        with open(os.path.join(tmpdir, "data_in_plain_text.txt"), "w") as f:
            f.writelines(" ".join(str(v) for v in b) + "\n" for b in blocks)

        shutil.copy2(os.path.join(PROJECT_ROOT, "assembly_code.asm"), os.path.join(tmpdir, "assembly_code.asm"))

        def run(cmd):
            res = subprocess.run(cmd, capture_output=True, text=True, timeout=600, cwd=tmpdir)
            if res.returncode != 0:
                return False, f"Command '{' '.join(cmd)}' failed:\n{res.stderr}\n{res.stdout}"
            return True, "OK"

        # Assemble and convert input
        if not run([sys.executable, "assembler.py", "assembly_code.asm"])[0]: return (test_idx, label, None, False, "Assembly failed")
        if not run([sys.executable, "convert_data_from_data_in_plain_text_to_data_in.py"])[0]: return (test_idx, label, None, False, "Input conversion failed")
        
        # Copy and run the Verilator binary
        bin_name = "Vtensor_core_test_bench"
        shutil.copy2(os.path.join(PROJECT_ROOT, "build", "verilator_obj", bin_name), os.path.join(tmpdir, "build", bin_name))
        
        if not run([os.path.join(tmpdir, "build", bin_name)])[0]: return (test_idx, label, None, False, "Simulation failed")
        if not run([sys.executable, "convert_data_from_data_out_to_data_out_plain_text.py"])[0]: return (test_idx, label, None, False, "Output conversion failed")

        # Read hardware output
        with open(os.path.join(tmpdir, "data_out_plain_text.txt")) as f:
            hw_blocks = [[int(v) for v in line.split()] for line in f]

        hw_logits = [v for bid in output_blocks for v in hw_blocks[bid][:3]][:10]
        
        print()
        print(hw_logits)
        print(label)
        print()
        
        return (test_idx, label, hw_logits, True, "OK")
    except Exception as e:
        return (test_idx, label, None, False, str(e))
    finally:
        shutil.rmtree(tmpdir, ignore_errors=True)

def main():
    parser = argparse.ArgumentParser(description="Measure hardware accuracy % against MNIST ground truth.")
    parser.add_argument("-n", "--num-tests", type=int, default=100, 
                        help="Number of MNIST images to test. Use 0 to run the entire dataset. (default: 100)")
    args = parser.parse_args()

    # Load state dict strictly to get the quantization scale
    sd_path = os.path.join(PROJECT_ROOT, MODEL_PATH)
    sd = torch.load(sd_path, map_location='cpu')

    print("=== Compiling model assembly ===")
    result = subprocess.run(
        [sys.executable, os.path.join(PROJECT_ROOT, 'model_compiler/compiler.py'), sd_path],
        capture_output=True, text=True, cwd=PROJECT_ROOT
    )
    if result.returncode != 0:
        print("Compile failed:", result.stderr); return False

    import ast
    output_blocks = []
    for line in result.stdout.splitlines():
        if "Final output blocks" in line:
            output_blocks = ast.literal_eval(line.split(":", 1)[1].strip())
    
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

    # Load MNIST dataset (Ground Truth)
    dataset = datasets.MNIST('../data', train=False, transform=transforms.Compose(
        [transforms.ToTensor(), lambda y: y.to(torch.float)]), download=True)

    input_log2 = int(math.log2(sd['quant.scale'].item()))
    input_tiles = (784 + 2) // 3

    with open(os.path.join(PROJECT_ROOT, "data_in_plain_text.txt")) as f:
        base_blocks = [[int(x) for x in line.split()] for line in f]

    total_dataset_len = len(dataset)
    num_tests = total_dataset_len if args.num_tests <= 0 else min(args.num_tests, total_dataset_len)

    print(f"\nPreparing {num_tests} testing tasks...")
    tasks = []
    for i in range(num_tests):
        data, label = dataset[i] # 'label' is the exact ground truth integer (0-9)
        input_float = data.flatten().unsqueeze(0)
        
        # Scale pixel float to hardware integer using the model's scale
        x_quant = torch.clamp(torch.round(input_float * (2 ** -input_log2)).int(), -16, 15).numpy().flatten()
        tasks.append((i, label, x_quant, base_blocks, output_blocks, input_tiles))

    num_workers = cpu_count()
    print(f"Running Verilator simulations in parallel on {num_workers} processes...")
    
    results = []
    with Pool(num_workers) as pool:
        for i, res in enumerate(pool.imap_unordered(run_single_test, tasks), 1):
            results.append(res)
            # Print progress cleanly
            if num_tests >= 500 and (i % 500 == 0 or i == num_tests):
                print(f"  Completed {i}/{num_tests} simulations...")
            elif num_tests < 500 and (i % max(1, num_tests // 10) == 0 or i == num_tests):
                print(f"  Completed {i}/{num_tests} simulations...")

    print("\n=== Final Hardware Accuracy Results ===")
    correct_predictions = 0
    failed_simulations = 0

    for test_idx, ground_truth_label, hw_logits, success, msg in results:
        if not success:
            failed_simulations += 1
            continue
        
        # The hardware's guess is the index with the highest output value
        hw_prediction = np.argmax(hw_logits)

        # Direct comparison against MNIST ground truth
        if hw_prediction == ground_truth_label:
            correct_predictions += 1

    valid_tests = num_tests - failed_simulations
    
    if valid_tests > 0:
        accuracy_percent = (correct_predictions / valid_tests) * 100
        print(f"Total MNIST Images Tested: {valid_tests}")
        print(f"Correct Hardware Predictions: {correct_predictions}")
        print(f"Overall Hardware Accuracy: {accuracy_percent:.2f}%\n")
    
    if failed_simulations > 0:
        print(f"Warning: {failed_simulations} simulations failed to execute due to errors.")

    print("=============================================")

if __name__ == "__main__":
    main()