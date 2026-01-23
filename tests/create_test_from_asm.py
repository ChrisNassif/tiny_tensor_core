import sys
import os
import random
import shutil

def sat_add(a, b):
    res = a + b
    if res > 127: return 127
    if res < -128: return -128
    return res

def mat_mul(m1_flat, m2_flat):
    m1 = [m1_flat[i:i+3] for i in range(0, 9, 3)]
    m2 = [m2_flat[i:i+3] for i in range(0, 9, 3)]
    res = []
    
    for i in range(3):
        for j in range(3):
            val = 0
            for k in range(3):
                product = m1[i][k] * m2[k][j]
                val += product
            
            if val > 127: val = 127
            if val < -128: val = -128
            res.append(val)
    return res

def mat_add(m1_flat, m2_flat):
    res = []
    for i in range(9):
        res.append(sat_add(m1_flat[i], m2_flat[i]))
    return res

def mat_relu(m_flat):
    return [x if x > 0 else 0 for x in m_flat]

def main():
    if len(sys.argv) < 3:
        print("Usage: python3 create_test_from_asm.py <asm_file> <test_name>")
        sys.exit(1)

    asm_file_path = sys.argv[1]
    test_name = sys.argv[2]
    
    # Setup directories
    test_dir = f"tests/{test_name}"
    os.makedirs(test_dir, exist_ok=True)
    
    dest_asm = f"{test_dir}/{test_name}.asm"
    dest_data = f"{test_dir}/data_in_plain_text.txt"
    dest_expected = f"{test_dir}/expected_output.txt"
    
    # Copy ASM to destination
    shutil.copy(asm_file_path, dest_asm)
    
    # Initialize State
    random.seed(42)
    # 20 matrices (0-19)
    matrices = [[random.randint(-10, 10) for _ in range(9)] for _ in range(20)]
    initial_matrices = [m[:] for m in matrices]
    
    # State tracking variables
    current_input_1 = [0]*9
    current_input_2 = [0]*9
    latched_result = [0]*9
    
    # Parse ASM
    with open(asm_file_path, 'r') as f:
        lines = f.readlines()
        
    for line in lines:
        parts = line.strip().split()
        if not parts: continue
        
        op = parts[0]
        
        if op == "burst":
            # burst write/read
            sub_op = parts[1]
            if sub_op == "write":
                idx1 = int(parts[2])
                idx2 = int(parts[3])
                current_input_1 = matrices[idx1]
                current_input_2 = matrices[idx2]
            elif sub_op == "read":
                idx_res = int(parts[2])
                # In hardware, 'read' dumps the core output to memory.
                # In our simulation, the op (add/mul) already updated 'core output'.
                # But wait, in 'create_stateless_fuzz', the op updates the matrix directly.
                # However, the ASM has instructions like:
                # burst write -> matrix_op -> burst read
                # So the op computes result, stores in internal latch.
                # burst read writes internal latch to memory.
                
                # My simple model needs to track "latched result".
                pass 
                
        elif op == "matrix_multiply":
            if current_input_1 is None or current_input_2 is None:
                print("Warning: Matrix op without initialization")
                # continue
            latched_result = mat_mul(current_input_1, current_input_2)
            
        elif op == "matrix_add":
            latched_result = mat_add(current_input_1, current_input_2)
            
        elif op == "relu":
            # Relu operates on the latched result
            latched_result = mat_relu(latched_result)
        
        elif op in ["reset", "nop"]:
            pass
            
        # Re-check burst read to assign latched result
        if op == "burst" and parts[1] == "read":
             idx_res = int(parts[2])
             matrices[idx_res] = latched_result

    # Write Data Files
    with open(dest_data, "w") as f:
        for m in initial_matrices: 
            f.write(" ".join(map(str, m)) + "\n")
        # Fill rest of memory (up to 20000 lines required? Fuzz test writes 20 + zeros)
        # Fuzz test writes initial state + 20 lines of zeros?
        # create_stateless_fuzz lines 103: for _ in range(20): f.write("0... \n")
        # It writes 40 lines total.
        for _ in range(20): f.write("0 0 0 0 0 0 0 0 0\n")

    with open(dest_expected, "w") as f:
        for m in matrices:
            f.write(" ".join(map(str, m)) + "\n")
            
    print(f"Test case '{test_name}' generated in {test_dir}")

