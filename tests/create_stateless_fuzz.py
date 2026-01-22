
import random
import os

def sat_add(a, b):
    res = a + b
    if res > 127: return 127
    if res < -128: return -128
    return res

def sat_mul(a, b):
    res = a * b
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

def generate_stateless_fuzz_improved(test_name, num_ops=20):
    os.makedirs(f"tests/{test_name}", exist_ok=True)
    asm_file = f"tests/{test_name}/{test_name}.asm"
    data_file = f"tests/{test_name}/data_in_plain_text.txt"
    expected_file = f"tests/{test_name}/expected_output.txt"
    
    ops = ["matrix_multiply", "matrix_add", "relu"]
    
    # 100 Matrices
    matrices = [[random.randint(-10, 10) for _ in range(9)] for _ in range(100)]
    
    input_matrices_snapshot = [m[:] for m in matrices] # Copy
    
    with open(asm_file, "w") as f:
        f.write("reset\n")
        f.write("nop\n")
        
        for i in range(num_ops):
            # Randomly insert NOPs and RESETs to test control flow robustness
            if random.random() < 0.3:
                f.write("nop\n")
                
            if random.random() < 0.05:
                f.write("reset\n")
                # Reset clears registers/output. 
                # But since we do `burst write` immediately after (loading fresh data),
                # this shouldn't affect the result IF reset works correctly (clears state, ready for new input).
            
            op = random.choice(ops)
            
            idxA = random.randint(0, 49) # using first 50 as input
            idxB = random.randint(0, 49)
            idxRes = 50 + i # Output to unique slot
            
            m1 = matrices[idxA]
            m2 = matrices[idxB]
            
            if op == "matrix_multiply":
                res = mat_mul(m1, m2)
            elif op == "matrix_add":
                res = mat_add(m1, m2)
            elif op == "relu":
                sum_res = mat_add(m1, m2)
                res = mat_relu(sum_res)
                op = "matrix_add_relu"
            
            matrices[idxRes] = res
            
            f.write(f"burst write {idxA} {idxB}\n")
            
            # Maybe NOP between load and op?
            if random.random() < 0.2: f.write("nop\n")
                
            if op == "matrix_add_relu":
                f.write("matrix_add\n")
                f.write("relu\n")
            else:
                f.write(f"{op}\n")
                
            f.write(f"burst read {idxRes}\n")
    
    # Write data files
    with open(data_file, "w") as f:
        for m in input_matrices_snapshot: # Write INITIAL state
            f.write(" ".join(map(str, m)) + "\n")
        for _ in range(100): f.write("0 0 0 0 0 0 0 0 0\n")
            
    with open(expected_file, "w") as f:
        for m in matrices: # Write FINAL state
            f.write(" ".join(map(str, m)) + "\n")
    
generate_stateless_fuzz_improved("test_fuzz_stateless", 50)
