import sys
import os
import random
import shutil
import math

def wrap16(val):
    return ((val + 32768) % 65536) - 32768

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
            
            val = wrap16(val)
            res.append(val)
    return res

def mat_add(m1_flat, m2_flat):
    return [wrap16(a + b) for a, b in zip(m1_flat, m2_flat)]

def mat_scale(m_flat, scale_val):
    scale_factor = int(round(math.log2(float(scale_val))))
    res = []
    for v in m_flat:
        if scale_factor < 0:
            res.append(wrap16(v >> abs(scale_factor)))
        else:
            res.append(wrap16(v << scale_factor))
    return res

def mat_relu(m_flat):
    return [0 if v < 0 else v for v in m_flat]



def trunc8(m_flat):
    """Truncate values to 8-bit signed, simulating hardware register load."""
    return [((v + 128) % 256) - 128 for v in m_flat]

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
    try:
        shutil.copy(asm_file_path, dest_asm)
    except shutil.SameFileError:
        pass
    
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
            sub_op = parts[1]
            if sub_op == "store_and_load":
                idx_res = int(parts[2])
                idx1 = int(parts[3])
                idx2 = int(parts[4])
                
                matrices[idx_res] = latched_result
                
                current_input_1 = trunc8(matrices[idx1])
                current_input_2 = trunc8(matrices[idx2])
                
        elif op == "matrix_multiply":
            if current_input_1 is None or current_input_2 is None:
                print("Warning: Matrix op without initialization")
            latched_result = mat_mul(current_input_1, current_input_2)
            
        elif op == "matrix_add":
            idx_res = int(parts[1])
            idx1 = int(parts[2])
            idx2 = int(parts[3])
            matrices[idx_res] = mat_add(matrices[idx1], matrices[idx2])
            
        elif op == "matrix_scale":
            idx_res = int(parts[1])
            scale_val = float(parts[2])
            matrices[idx_res] = mat_scale(matrices[idx_res], scale_val)
            
        elif op == "matrix_relu":
            idx_res = int(parts[1])
            matrices[idx_res] = mat_relu(matrices[idx_res])
            
        elif op in ["reset", "nop"]:
            pass

    # Write Data Files
    with open(dest_data, "w") as f:
        for m in initial_matrices: 
            f.write(" ".join(map(str, m)) + "\n")

        for _ in range(20): f.write("0 0 0 0 0 0 0 0 0\n")

    with open(dest_expected, "w") as f:
        for m in matrices:
            f.write(" ".join(map(str, m)) + "\n")
            
    print(f"Test case '{test_name}' generated in {test_dir}")

if __name__ == "__main__":
    main()

