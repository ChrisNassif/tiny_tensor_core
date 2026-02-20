import random
import os
import subprocess
import shutil

def generate_stateless_fuzz_improved(test_name, num_ops=50):
    random.seed(42)
    os.makedirs(f"tests/{test_name}", exist_ok=True)
    asm_file = f"tests/{test_name}/{test_name}.asm"
    data_file = f"tests/{test_name}/data_in_plain_text.txt"
    expected_file = f"tests/{test_name}/expected_output.txt"
    
    ops = ["matrix_multiply"]
    matrices = [[random.randint(-10, 10) for _ in range(9)] for _ in range(20)]
    
    with open(asm_file, "w") as f:
        f.write("reset\n")
        f.write("nop\n")
        
        idxA = random.randint(0, 18)
        idxB = random.randint(0, 18)
        f.write(f"burst store_and_load 19 {idxA} {idxB}\n")
        
        for i in range(num_ops):
            if random.random() < 0.3: f.write("nop\n")
            op = random.choice(ops)
            f.write(f"{op}\n")
            
            idxRes = random.randint(0, 18)
            next_idxA = random.randint(0, 18)
            next_idxB = random.randint(0, 18)
            
            if i < num_ops - 1:
                f.write(f"burst store_and_load {idxRes} 19 19\n")
                f.write(f"burst store_and_load 19 {next_idxA} {next_idxB}\n")
                idxA = next_idxA
                idxB = next_idxB
            else:
                f.write(f"burst store_and_load {idxRes} 19 19\n")
    
    with open(data_file, "w") as f:
        for m in matrices:
            f.write(" ".join(map(str, m)) + "\n")
        for _ in range(40 - len(matrices)):
             f.write("0 0 0 0 0 0 0 0 0\n")

    print(f"Generated ASM and Data for {test_name}.")

generate_stateless_fuzz_improved("test_fuzz", 50)
