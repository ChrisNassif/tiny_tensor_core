
import random
import os
import subprocess
import shutil

TEST_NAME = "test_pipeline_hazards"

def generate_hazard_test():
    os.makedirs(f"tests/{TEST_NAME}", exist_ok=True)
    asm_file = f"tests/{TEST_NAME}/{TEST_NAME}.asm"
    data_file = f"tests/{TEST_NAME}/data_in_plain_text.txt"
    
    # Matrices:
    # 0: All 10s
    # 1: All 1s
    # 2: All 2s
    # 3: Result placeholder
    matrices = []
    matrices.append([10] * 9)
    matrices.append([1] * 9)
    matrices.append([2] * 9)
    for _ in range(17):
        matrices.append([0] * 9)
        
    with open(asm_file, "w") as f:
        f.write("reset\n")
        f.write("nop\n")
        
        # Load Mat 0 (10s) and Mat 1 (1s)
        f.write("burst store_and_load 19 0 1\n")
        
        # Op 1: 10 * 1 * 3 = 30.
        # Result is 30s.
        f.write("matrix_multiply\n")
        
        # Hazard Op: Load Result (30s) to Mem 0. Store Mem 0 to Reg A. Store Mem 2 (2s) to Reg B.
        f.write("burst store_and_load 19 0 2\n")
        
        # Op 2: Reg A * Reg B.
        # If Reg A got Old Mem 0 (10s): 10 * 2 * 3 = 60.
        # If Reg A got New Mem 0 (30s): 30 * 2 * 3 = 180.
        f.write("matrix_multiply\n")
        
        # Store Result to Mem 3
        f.write("burst store_and_load 3 0 0\n")

    with open(data_file, "w") as f:
        for m in matrices:
            f.write(" ".join(map(str, m)) + "\n")
        for _ in range(20): f.write("0 0 0 0 0 0 0 0 0\n")
            
    print("Running Hazard Test Simulation...")
    try:
        subprocess.run(["./tests/run_test.sh", TEST_NAME], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    except subprocess.CalledProcessError as e:
        print(f"Error: {e}")
        print(e.stdout.decode())
        print(e.stderr.decode())
        return

    # Check Output
    sim_output_file = "data_out_plain_text.txt"
    with open(sim_output_file) as f:
        lines = f.readlines()
        
    # Mem 3 is index 3.
    # Lines format: 9 numbers.
    # We look at line 3 (0-indexed).
    
    # Parse
    sim_data = []
    for line in lines:
        if not line.strip(): continue
        try: sim_data.append([int(x) for x in line.split()])
        except: pass
        
    res = sim_data[3][0] # First element of Result
    print(f"Result in Mem 3: {res}")
    
    if res == 60:
        print("CONCLUSION: STORE-BEFORE-LOAD (Old Value). No Forwarding.")
    elif res == 180:
        print("CONCLUSION: STORE-AFTER-LOAD (New Value). Forwarding.")
    else:
        print(f"CONCLUSION: UNKNOWN ({res}). Something else happened.")

if __name__ == "__main__":
    generate_hazard_test()
