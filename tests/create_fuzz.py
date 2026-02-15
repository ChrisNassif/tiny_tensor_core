import random
import os
import subprocess
import shutil

def generate_stateless_fuzz_improved(test_name, num_ops=50):
    # Fixed seed for reproducibility
    random.seed(42)
    
    os.makedirs(f"tests/{test_name}", exist_ok=True)
    asm_file = f"tests/{test_name}/{test_name}.asm"
    data_file = f"tests/{test_name}/data_in_plain_text.txt"
    expected_file = f"tests/{test_name}/expected_output.txt"
    
    ops = ["matrix_multiply"]
    
    # 20 matrices available
    # We only care about initial values for input file
    matrices = [[random.randint(-10, 10) for _ in range(9)] for _ in range(20)]
    
    with open(asm_file, "w") as f:
        f.write("reset\n")
        f.write("nop\n")
        
        # Initial setup: pick inputs for first op
        idxA = random.randint(0, 19)
        idxB = random.randint(0, 19)
        
        # Load them
        f.write(f"burst write {idxA} {idxB}\n")
        
        for i in range(num_ops):
            if random.random() < 0.3: f.write("nop\n")

            # Perform operation
            op = random.choice(ops)
            f.write(f"{op}\n")
            
            # Destination for result (hardware will write here)
            idxRes = random.randint(0, 19)
            
            # Determine NEXT operation inputs
            next_idxA = random.randint(0, 19)
            next_idxB = random.randint(0, 19)
            
            # Optimize loading for next step?
            # 50% chance to use burst read_and_write
            # Only if not last op AND no hazard
            use_read_write = (random.random() < 0.5) and (i < num_ops - 1)
            
            if use_read_write:
                # Hazard check: if Result overwrites Next Input, we can't do simultaneous
                # (HW writes result to memory, but we need to load new inputs from memory?
                # Actually, read_and_write writes to memory from core, AND reads from memory to RegFile.
                # If we write to X and read from X, we might get old or new value depending on timing.
                # To be safe, avoid hazard.)
                if idxRes == next_idxA or idxRes == next_idxB:
                    use_read_write = False

            if use_read_write:
                f.write(f"burst read_and_write {idxRes} {next_idxA} {next_idxB}\n")
                idxA = next_idxA
                idxB = next_idxB
            else:
                f.write(f"burst read {idxRes}\n")
                if i < num_ops - 1:
                    idxA = next_idxA
                    idxB = next_idxB
                    f.write(f"burst write {idxA} {idxB}\n")
    
    # Write initial data
    with open(data_file, "w") as f:
        for m in matrices:
            f.write(" ".join(map(str, m)) + "\n")
        # Fill rest to 64 lines? (Hardware memory size)
        # Memory is 256 bytes? 
        # convert_data script handles padding usually?
        # create_fuzz.py originally wrote 20 lines then padding?
        # Original code: "for m in input_matrices_snapshot: write... for _ in range(20): write 0..."
        # 20 input lines + 20 zero lines = 40 lines.
        # We'll match that pattern to be safe.
        for _ in range(40 - len(matrices)):
             f.write("0 0 0 0 0 0 0 0 0\n")
            
    print(f"Generated ASM and Data for {test_name}. Running simulation to generate expected output...")

    # Run Simulation to get Expected Output
    # We use run_test.sh which handles everything (compile, run, convert output)
    # Output will be in data_out_plain_text.txt in CWD
    try:
        subprocess.run(["./tests/run_test.sh", test_name], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    except subprocess.CalledProcessError as e:
        print(f"Error running simulation: {e}")
        # print stdout for debugging
        print(e.stdout.decode())
        print(e.stderr.decode())
        raise

    # Copy output to expected_output.txt
    if os.path.exists("data_out_plain_text.txt"):
        shutil.copy("data_out_plain_text.txt", expected_file)
        print(f"Expected output captured to {expected_file}")
    else:
        print("Error: Simulation did not produce data_out_plain_text.txt")

generate_stateless_fuzz_improved("test_fuzz", 50)
