
import random
import os

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
    res = []
    for i in range(9):
        res.append(m1_flat[i] + m2_flat[i])
    return res

def mat_relu(m_flat):
    return [x if x > 0 else 0 for x in m_flat]

def trunc8(m_flat):
    """Truncate values to 8-bit signed, simulating hardware register load."""
    return [((v + 128) % 256) - 128 for v in m_flat]

def generate_stateless_fuzz_improved(test_name, num_ops=20):
    # Fixed seed for reproducibility
    random.seed(42)
    
    os.makedirs(f"tests/{test_name}", exist_ok=True)
    asm_file = f"tests/{test_name}/{test_name}.asm"
    data_file = f"tests/{test_name}/data_in_plain_text.txt"
    expected_file = f"tests/{test_name}/expected_output.txt"
    
    ops = ["matrix_multiply", "matrix_add", "relu"]
    
    # 10 input matrices (indices 0-9), 10 output slots (indices 10-19)
    # Actually, let's allow all 20 to be used for anything to maximize chaos
    matrices = [[random.randint(-10, 10) for _ in range(9)] for _ in range(20)]
    
    input_matrices_snapshot = [m[:] for m in matrices] # Copy
    
    with open(asm_file, "w") as f:
        f.write("reset\n")
        f.write("nop\n")
        
        # State tracking for optimization
        inputs_loaded = False
        loaded_indices = (None, None) # (A, B)

        for i in range(num_ops):
            # Control flow noise
            if random.random() < 0.3: f.write("nop\n")
            if random.random() < 0.05: 
                f.write("reset\n")
                inputs_loaded = False
            
            op = random.choice(ops)
            
            # Select inputs for THIS operation
            idxA = random.randint(0, 19)
            idxB = random.randint(0, 19)
            idxRes = random.randint(0, 19)
            
            # If we happen to have the right inputs loaded (unlikely but possible), skip write?
            # But mostly we will need to load, explicitly or via read_and_write from prev step.
            
            if not inputs_loaded:
                 f.write(f"burst write {idxA} {idxB}\n")
                 if random.random() < 0.2: f.write("nop\n")
            else:
                 # Check if the loaded inputs match what we wanted? 
                 # Actually, if inputs_loaded is True, it means the PREVIOUS step did a read_and_write
                 # which LOADED the inputs for THIS step.
                 # So we MUST use the inputs that were loaded.
                 # Wait. If I decide inputs randomly NOW, I can't force the previous step to have loaded them.
                 # So I need to decide the inputs for the NEXT step during the CURRENT step 
                 # if I want to use read_and_write.
                 pass
            
            # WAIT. The logic needs to look ahead.
            # OR, I just re-write the loop to determine the Current Op and Next Op.
            
            # Let's simplify: 
            # If inputs_loaded is True, it means `idxA` and `idxB` were already decided in previous iteration 
            # and passed to `burst read_and_write`. 
            # So I need variables `next_idxA`, `next_idxB`?
            pass

        # REWRITE LOOP
        
        # Initial setup for loop
        # We need to pick the FIRST operation inputs
        idxA = random.randint(0, 19)
        idxB = random.randint(0, 19)
        inputs_loaded = False # First time, we need to write manually
        
        # We loop num_ops times.
        # Check logic inside.
        
    with open(asm_file, "w") as f:
        f.write("reset\n")
        f.write("nop\n")
        
        # Determine inputs for the very first operation
        idxA = random.randint(0, 19)
        idxB = random.randint(0, 19)
        
        # Do we load them now? Yes.
        f.write(f"burst write {idxA} {idxB}\n")
        
        for i in range(num_ops):
            if random.random() < 0.3: f.write("nop\n")

            # Perform the operation on (idxA, idxB)
            m1 = trunc8(matrices[idxA])
            m2 = trunc8(matrices[idxB])
            
            op = random.choice(ops)
            
            if op == "matrix_multiply":
                res = mat_mul(m1, m2)
                f.write(f"{op}\n")
            elif op == "matrix_add":
                res = mat_add(m1, m2)
                f.write(f"{op}\n")
            elif op == "relu":
                # Relu is special, usually coupled with add in fuzzer
                sum_res = mat_add(m1, m2)
                res = mat_relu(sum_res)
                op = "matrix_add_relu" 
                f.write("matrix_add\n")
                f.write("relu\n")
            
            # Store result
            idxRes = random.randint(0, 19)
            matrices[idxRes] = res
            
            # Determine NEXT operation inputs
            next_idxA = random.randint(0, 19)
            next_idxB = random.randint(0, 19)
            
            # 50% chance to use burst read_and_write to optimize loading next inputs
            # Only if not last op
            # AND if no hazard (Res != NextA and Res != NextB)
            # Because HW reads old memory value while writing new one, so forwarding doesn't happen.
            use_read_write = (random.random() < 0.5) and (i < num_ops - 1)
            
            if use_read_write:
                if idxRes == next_idxA or idxRes == next_idxB:
                    use_read_write = False

            if use_read_write:
                f.write(f"burst read_and_write {idxRes} {next_idxA} {next_idxB}\n")
                # Next iter will have these loaded
                idxA = next_idxA
                idxB = next_idxB
                # Implicitly loaded for next loop
            else:
                f.write(f"burst read {idxRes}\n")
                # Next iter needs to load explicitly
                if i < num_ops - 1:
                    idxA = next_idxA
                    idxB = next_idxB
                    f.write(f"burst write {idxA} {idxB}\n")
    
    # Write data files
    with open(data_file, "w") as f:
        for m in input_matrices_snapshot: # Write INITIAL state
            f.write(" ".join(map(str, m)) + "\n")
        for _ in range(20): f.write("0 0 0 0 0 0 0 0 0\n")
            
    with open(expected_file, "w") as f:
        for m in matrices: # Write FINAL state
            f.write(" ".join(map(str, m)) + "\n")
    
generate_stateless_fuzz_improved("test_fuzz", 50)
