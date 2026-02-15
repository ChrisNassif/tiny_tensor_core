
import random
import os
import subprocess
import shutil

TEST_NAME = "test_nn_quantization"
NUM_OPS = 100

def wrap16(val):
    return ((val + 32768) % 65536) - 32768

def mat_mul_check_wrap(m1_flat, m2_flat):
    m1 = [m1_flat[i:i+3] for i in range(0, 9, 3)]
    m2 = [m2_flat[i:i+3] for i in range(0, 9, 3)]
    res = []
    
    wrap_count = 0
    max_sum = 0
    min_sum = 0
    
    for i in range(3):
        for j in range(3):
            val = 0
            for k in range(3):
                product = m1[i][k] * m2[k][j]
                val += product
            
            if val > max_sum: max_sum = val
            if val < min_sum: min_sum = val
            
            if val > 32767 or val < -32768:
                wrap_count += 1
            
            val = wrap16(val)
            res.append(val)
            
    return res, wrap_count, max_sum, min_sum


def trunc8(m_flat):
    return [((v + 128) % 256) - 128 for v in m_flat]

def generate_nn_stress_test():
    random.seed(42)
    
    os.makedirs(f"tests/{TEST_NAME}", exist_ok=True)
    asm_file = f"tests/{TEST_NAME}/{TEST_NAME}.asm"
    data_file = f"tests/{TEST_NAME}/data_in_plain_text.txt"
    
    # 20 matrices
    # Indices 0-9: STRICT 7-bit inputs [-64, 63]
    # Indices 10-19: Result buffers (ignore their values for input)
    matrices = []
    
    # 0-9: Valid 7-bit inputs
    for _ in range(6):
        matrices.append([random.randint(-64, 63) for _ in range(9)])
    
    # Corner cases in 0-9
    matrices.append([63] * 9)       # index 6: Max Pos
    matrices.append([-64] * 9)      # index 7: Max Neg
    matrices.append([63, -64, 63, -64, 63, -64, 63, -64, 63]) # index 8: Mixed
    matrices.append([0] * 9)        # index 9: Zero
    
    # 10-19: Padding (will be overwritten)
    for _ in range(10):
        matrices.append([0] * 9)
        
    input_matrices_snapshot = [m[:] for m in matrices]
    
    total_wraps = 0
    overall_max = 0
    overall_min = 0
    
    # Simulator State (Hardware Memory)
    # Simulator truncates to 8-bit on Load? Or Controller truncates on Read?
    # Python model must track the memory state as 16-bit (what is written).
    # But USE trunc8 when reading as Input.
    
    with open(asm_file, "w") as f:
        f.write("reset\n")
        f.write("nop\n")
        

        # Load initial inputs
        idxA = 6 # Max Pos (63)
        idxB = 6 # Max Pos (63)
        f.write(f"burst write {idxA} {idxB}\n")
        
        for i in range(NUM_OPS):
            if random.random() < 0.1: f.write("nop\n")

            f.write("matrix_multiply\n")
            
            # Predict check
            m1 = trunc8(matrices[idxA])
            m2 = trunc8(matrices[idxB])
            
            res, wraps, mx, mn = mat_mul_check_wrap(m1, m2)
            
            total_wraps += wraps
            if mx > overall_max: overall_max = mx
            if mn < overall_min: overall_min = mn
            
            idxRes = random.randint(10, 19)
            matrices[idxRes] = res 
            
            # Deterministic sequence for first few ops to cover corners
            if i == 0:
                next_idxA = 7 # Max Neg (-64)
                next_idxB = 7
            elif i == 1:
                next_idxA = 8 # Mixed
                next_idxB = 8
            elif i == 2:
                next_idxA = 6 # Max Pos
                next_idxB = 7 # Max Neg
            else:
                next_idxA = random.randint(0, 9)
                next_idxB = random.randint(0, 9)

                
            f.write(f"burst read {idxRes}\n")
            if i < NUM_OPS - 1:
                idxA = next_idxA
                idxB = next_idxB
                f.write(f"burst write {idxA} {idxB}\n")



    # Write data
    with open(data_file, "w") as f:
        for m in input_matrices_snapshot:
            f.write(" ".join(map(str, m)) + "\n")
        # Fill rest to 40 lines (assuming 20 matrices + 20 padding lines = 40 lines total written by original script)
        # Actually, hardware memory is 256 bytes? No, just use enough padding.
        # Original create_fuzz used 40 lines.
        for _ in range(40 - len(matrices)):
             f.write("0 0 0 0 0 0 0 0 0\n")
             
    # Write EXPECTED output (for make test verification)
    expected_file = f"tests/{TEST_NAME}/expected_output.txt"
    with open(expected_file, "w") as f:
        for m in matrices:
            f.write(" ".join(map(str, m)) + "\n")
        for _ in range(40 - len(matrices)):
             f.write("0 0 0 0 0 0 0 0 0\n")

    print(f"Generated {NUM_OPS} NN Stress Ops.")
    print(f"Predicted Overflow Wraps: {total_wraps}")

    print(f"Max Sum Observed: {overall_max}")
    print(f"Min Sum Observed: {overall_min}")
    
    if total_wraps > 0:
        print("WARNING: 7-bit quantization caused OVERFLOW in 16-bit accumulator during prediction.")
    else:
        print("SUCCESS: No overflow predicted with these 7-bit inputs.")
        
    print("Running hardware simulation to confirm match...")
    
    # Run Simulation
    try:
        subprocess.run(["./tests/run_test.sh", TEST_NAME], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    except subprocess.CalledProcessError as e:
        print(f"Error running simulation: {e}")
        print(e.stdout.decode())
        print(e.stderr.decode())
        raise

    # Verify
    sim_output_file = "data_out_plain_text.txt"
    if not os.path.exists(sim_output_file):
        print("Error: Sim did not produce output.")
        return
        
    # Read Sim Output
    # compare with `matrices` final state?
    # `matrices` holds the python-calculated final state (wrapped).
    # We should match exactly.
    
    sim_data = []
    with open(sim_output_file) as f:
        lines = f.readlines()
        for line in lines:
            line = line.split('#')[0].strip()
            if not line: continue
            try:
                nums = [int(x) for x in line.split()]
                sim_data.append(nums)
            except: pass
            
    # Check
    mismatch = False
    for i, m in enumerate(matrices):
        if i >= len(sim_data):
            print(f"Sim output too short! Expected {len(matrices)} rows.")
            mismatch = True
            break
        if m != sim_data[i]:
            print(f"MISMATCH at row {i}")
            print(f"Expected: {m}")
            print(f"Got:      {sim_data[i]}")
            mismatch = True
            
    if not mismatch:
        print("VERIFICATION PASSED: Hardware matches Python model (including wrapping behavior).")
    else:
        print("VERIFICATION FAILED: Hardware deviation detected.")

if __name__ == "__main__":
    generate_nn_stress_test()
