import os
import shutil
import subprocess
import tempfile
import multiprocessing
import sys

PROJECT_ROOT = os.getcwd()

def run_single_test(test_name):
    # Setup temp dir
    with tempfile.TemporaryDirectory() as tmpdir:
        # Copy files manually to avoid copying massive build artifacts or recursion
        # We need: src/, *.py, *.sh, *.sv, and tests/
        
        # Explicit copy list for root files
        for f in os.listdir(PROJECT_ROOT):
            src = os.path.join(PROJECT_ROOT, f)
            # Skip build dir, git, hidden files, and artifacts
            if f in ['build', '.git', 'brain', '__pycache__', '.gemini', '.agent']: continue
            
            dst = os.path.join(tmpdir, f)
            try:
                if os.path.isdir(src):
                    shutil.copytree(src, dst)
                else:
                    shutil.copy2(src, dst)
            except Exception as e:
                # Ignore copy errors for locks/permissions
                pass
        
        os.makedirs(os.path.join(tmpdir, "build"), exist_ok=True)

        # Run test
        try:
            # 1. Run simulation using existing shell script
            cmd = ["tests/run_test.sh", test_name]
            result = subprocess.run(cmd, cwd=tmpdir, capture_output=True, text=True)
            
            if result.returncode != 0:
                # Simulation failed to compile or run
                return (test_name, False, "Simulation Error (Compile/Run Failed)")
            
            # 2. Verify Output
            expected_file = os.path.join(tmpdir, "tests", test_name, "expected_output.txt")
            output_file = os.path.join(tmpdir, "data_out_plain_text.txt")
            
            if not os.path.exists(expected_file):
                # Check if it was supposed to fail? No, assuming pass.
                # But lacking verify means "Soft".
                # We mark as "Passthrough" or "Soft Pass".
                return (test_name, True, "Soft Pass (No Expected Output)")
            
            # Parse helper
            def read_data(fpath):
                data = []
                if not os.path.exists(fpath): return []
                with open(fpath) as f:
                    for line in f:
                        # Remove comments
                        code = line.split('#')[0].strip()
                        if code:
                            try:
                                nums = [int(x) for x in code.split()]
                                data.append(nums)
                            except ValueError:
                                pass # Ignore non-integer lines
                return data
            
            expected_data = read_data(expected_file)
            actual_data = read_data(output_file)
            
            if not expected_data:
                 return (test_name, False, "Setup Error (Empty Expected Data)")

            if len(actual_data) < len(expected_data):
                 return (test_name, False, f"Mismatch: Output too short ({len(actual_data)} < {len(expected_data)})")
            
            for i, exp_row in enumerate(expected_data):
                if actual_data[i] != exp_row:
                    return (test_name, False, f"Mismatch at row {i}: expected {exp_row}, got {actual_data[i]}")
                    
            return (test_name, True, "Verified Pass")
                
        except Exception as e:
            return (test_name, False, f"Runner Exception: {e}")

def main():
    # Discovery
    test_root = os.path.join(PROJECT_ROOT, "tests")
    if not os.path.exists(test_root):
        print("No tests directory found.")
        sys.exit(1)
        
    test_dirs = [d for d in os.listdir(test_root) if os.path.isdir(os.path.join(test_root, d)) and d != "__pycache__"]
    test_dirs.sort()
    
    # Use quarter of available CPUs to avoid freezing the system
    num_cpus = max(1, multiprocessing.cpu_count() // 4)
    print(f"Discovered {len(test_dirs)} tests. Running in parallel on {num_cpus} processes...")
    
    pool = multiprocessing.Pool(processes=num_cpus)
    results = pool.map(run_single_test, test_dirs)
    pool.close()
    pool.join()
    
    # Report
    print("\n" + "="*60)
    print(f"{'TEST NAME':<30} | {'STATUS':<10} | MESSAGE")
    print("-" * 60)
    
    passed = 0
    failed = 0
    soft = 0
    
    for name, success, msg in results:
        status = "PASS" if success else "FAIL"
        if "Soft" in msg: 
            status = "SOFT"
            soft += 1
        
        if success: passed += 1
        else: failed += 1
            
        print(f"{name:<30} | {status:<10} | {msg}")
    
    print("="*60)
    print(f"TOTAL: {len(results)}. VERIFIED: {passed-soft}. SOFT: {soft}. FAILED: {failed}.")
    
    if failed > 0: sys.exit(1)

if __name__ == "__main__":
    main()
