"""End-to-end MNIST verification: compile model → inject test images → simulate in parallel → compare to PyTorch."""
import torch, numpy as np, subprocess, sys, os, math, shutil, tempfile
from multiprocessing import Pool, cpu_count
from torchvision import datasets, transforms

MODEL_PATH = "models/quantized_tensor_core_mnist_969_64_hidden_layer.pt"
SV_FILES = ["src/tensor_core_test_bench.sv", "src/tensor_core_memory_controller.sv",
            "src/tensor_core_controller.sv", "src/tensor_core.sv", "src/tensor_core_register_file.sv"]
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def compute_quantized_reference(input_float, sd):
    """PyTorch reference: quantized forward pass matching hardware behavior."""
    input_log2 = int(math.log2(sd['quant.scale'].item()))
    x = torch.clamp(torch.round(input_float * (2 ** -input_log2)).int(), -64, 63)
    for layer in ['fc1', 'fc2']:
        W_q, _ = sd[f'{layer}._packed_params._packed_params']
        total_shift = (input_log2 + int(math.log2(W_q.q_scale()))) - int(math.log2(sd[f'{layer}.scale'].item()))
        acc = torch.nn.functional.linear(x.float(), W_q.int_repr().int().float()).long()
        out = acc >> (-total_shift) if total_shift < 0 else acc << total_shift
        x = torch.clamp(out, 0, 63).int() if layer == 'fc1' else torch.clamp(out, -64, 63).int()
        input_log2 = int(math.log2(sd[f'{layer}.scale'].item()))
    return x.flatten().tolist()

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

        # Copy only what we need from model_compiler and models
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
            return subprocess.run(cmd, capture_output=True, text=True, timeout=300, cwd=tmpdir).returncode == 0

        if not run([sys.executable, "assembler.py", "assembly_code.asm"]): return (test_idx, label, None, None, False, "Assembly failed")
        if not run([sys.executable, "convert_data_from_data_in_plain_text_to_data_in.py"]): return (test_idx, label, None, None, False, "Convert input failed")
        if not run(["iverilog", "-g2012", "-o", "build/tb.out"] + SV_FILES): return (test_idx, label, None, None, False, "Compile failed")
        if not run(["vvp", "build/tb.out"]): return (test_idx, label, None, None, False, "Simulation failed")
        if not run([sys.executable, "convert_data_from_data_out_to_data_out_plain_text.py"]): return (test_idx, label, None, None, False, "Convert output failed")

        # Read hardware output
        with open(os.path.join(tmpdir, "data_out_plain_text.txt")) as f:
            hw_blocks = [[int(v) for v in line.split()] for line in f]

        hw_logits = [v for bid in output_blocks for v in hw_blocks[bid][:3]][:10]

        # Compute reference
        sd = torch.load(sd_path, map_location='cpu')
        input_float = torch.tensor(x_quant, dtype=torch.float).unsqueeze(0)
        # Re-derive input_float from x_quant is lossy; compute ref from original data instead
        # We pass ref_logits from the parent process to avoid this
        ref_logits = None  # computed by parent

        return (test_idx, label, hw_logits, ref_logits, True, "OK")
    finally:
        shutil.rmtree(tmpdir, ignore_errors=True)

def main():
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

    # Load test data
    dataset = datasets.MNIST('../data', train=False, transform=transforms.Compose(
        [transforms.ToTensor(), lambda y: y.to(torch.float)]), download=True)

    input_log2 = int(math.log2(sd['quant.scale'].item()))
    input_tiles = (784 + 2) // 3

    base_blocks = []
    with open(os.path.join(PROJECT_ROOT, "data_in_plain_text.txt")) as f:
        base_blocks = [[int(x) for x in line.split()] for line in f]

    num_tests = 5
    num_workers = min(num_tests, cpu_count())
    print(f"\nRunning {num_tests} tests in parallel on {num_workers} processes...")

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

    # Run in parallel
    with Pool(num_workers) as pool:
        results = pool.map(run_single_test, tasks)

    # Print results
    all_pass = True
    print()
    for test_idx, label, hw_logits, _, success, msg in sorted(results):
        ref_logits = ref_logits_map[test_idx]
        if not success:
            print(f"Test {test_idx+1}/5 (digit={label}): FAILED — {msg}")
            all_pass = False
            continue

        match = hw_logits == ref_logits
        hw_pred, ref_pred = np.argmax(hw_logits), np.argmax(ref_logits)
        print(f"Test {test_idx+1}/5 (digit={label}): HW={hw_pred} Ref={ref_pred} {'✓' if match else '✗'}")
        if not match:
            print(f"  HW:  {hw_logits}")
            print(f"  Ref: {ref_logits}")
            all_pass = False

    print(f"\n{'=' * 50}")
    print("ALL TESTS PASSED ✓" if all_pass else "SOME TESTS HAD DIFFERENCES")
    print("=" * 50)
    return all_pass

if __name__ == "__main__":
    sys.exit(0 if main() else 1)
