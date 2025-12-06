import numpy as np
import sys
    
    
    
    
operation_name_to_opcode = {
    "nop": "0000",
    "reset": "0001",
    "add": "0010",
    "sub": "0011",
    "eql": "0100",
    "grt": "0101",
    "cpu_load": "0110",
    "cpu_mov": "0111",
    "cpu_read": "1000",
    "tensor_core_operate": "1001",
    "tensor_core_load": "1010",
    "cpu_to_tensor_core": "1100",
    "tensor_core_to_cpu": "1101",
    "tensor_core_mov": "1110",
    "tensor_core_read": "1111"
}


def number_into_signed_kbit_binary(number: str, k):
    number = int(number)
    if number < -1 * (2**(k-1)) or number > (2**(k-1))-1:
        raise Exception("code has out of bounds number")
    
    return np.binary_repr(number, k)



def number_into_unsigned_kbit_binary(number: str, k):
    number = int(number)
    if number < 0 or number > (2**k)-1:
        raise Exception("code has out of bounds number")
    
    return np.binary_repr(number, k)


def main():
    
    if len(sys.argv) > 1:
        assembly_file = sys.argv[1]
    else:
        assembly_file = "assembly_code.asm"
        
    with open(assembly_file, "r") as f:
        assembly_code_lines = f.readlines()




    machine_code = []
    
    for index, assembly_code_line in enumerate(assembly_code_lines):
        assembly_code_tokens = assembly_code_line.strip().split(" ")
        
        operation_name = assembly_code_tokens[0]
        opcode = operation_name_to_opcode[operation_name]

        should_have_nop_after = False

        current_machine_code_line = ""



        # PARSE THE DIFFERENT INSTRUCTION FORMATS
        
        if (operation_name in ["nop", "reset"]):
            current_machine_code_line += "0"*12
            
        elif (operation_name in ["add", "sub", "grt", "eql"]):
            current_machine_code_line += number_into_unsigned_kbit_binary(assembly_code_tokens[1], k=3)
            current_machine_code_line += "0"*2
            current_machine_code_line += number_into_unsigned_kbit_binary(assembly_code_tokens[2], k=3)
            current_machine_code_line += "0"*1
            current_machine_code_line += number_into_unsigned_kbit_binary(assembly_code_tokens[3], k=3)
            
            
        elif (operation_name in ["cpu_mov",]):
            current_machine_code_line += number_into_unsigned_kbit_binary(assembly_code_tokens[1], k=3)
            current_machine_code_line += "0"*4
            current_machine_code_line += number_into_unsigned_kbit_binary(assembly_code_tokens[2], k=3)
            
            
        elif (operation_name in ["cpu_load",]):
            current_machine_code_line += number_into_unsigned_kbit_binary(assembly_code_tokens[1], k=3)
            current_machine_code_line += "0"*1
            current_machine_code_line += number_into_signed_kbit_binary(assembly_code_tokens[2], k=8)
        
        elif (operation_name in ["tensor_core_load",]):
            if (int(assembly_code_tokens[1]) > 17 and int(assembly_code_tokens[1]) < 0):
                raise Exception("Improper arguments for tensor_core_load")
            
            
            tensor_core_address = number_into_unsigned_kbit_binary(assembly_code_tokens[1], k=5)
            
            opcode = opcode[0:-1] + tensor_core_address[-1]
            
            current_machine_code_line += tensor_core_address[0:-1]
            current_machine_code_line += number_into_signed_kbit_binary(assembly_code_tokens[2], k=8)
        
        elif (operation_name in ["tensor_core_to_cpu",]):
            current_machine_code_line += number_into_unsigned_kbit_binary(assembly_code_tokens[1], k=3)
            current_machine_code_line += "0"*4
            current_machine_code_line += number_into_unsigned_kbit_binary(assembly_code_tokens[2], k=5)
        
        elif (operation_name in ["cpu_to_tensor_core",]):
            current_machine_code_line += number_into_unsigned_kbit_binary(assembly_code_tokens[1], k=5)
            current_machine_code_line += "0"*4
            current_machine_code_line += number_into_unsigned_kbit_binary(assembly_code_tokens[2], k=3)
        
        elif (operation_name in ["cpu_read",]):
            current_machine_code_line += "0"*9
            current_machine_code_line += number_into_unsigned_kbit_binary(assembly_code_tokens[1], k=3)
        
        elif (operation_name in ["tensor_core_read",]):
            current_machine_code_line += "0"*7
            current_machine_code_line += number_into_unsigned_kbit_binary(assembly_code_tokens[1], k=5)
        
        elif (operation_name in ["tensor_core_mov",]):
            current_machine_code_line += number_into_unsigned_kbit_binary(assembly_code_tokens[1], k=5)
            current_machine_code_line += "0"*2
            current_machine_code_line += number_into_unsigned_kbit_binary(assembly_code_tokens[2], k=5)
            
            
        elif (operation_name in ["tensor_core_operate",]):
            current_machine_code_line += "0"*10
            
            if (assembly_code_tokens[1] == "mul"):
                current_machine_code_line += "00"
            
            elif (assembly_code_tokens[1] == "add"):
                current_machine_code_line += "01"
                
            elif (assembly_code_tokens[1] == "relu"):
                current_machine_code_line += "10"

            should_have_nop_after = True
        
        
        
        current_machine_code_line += opcode
        
        print(current_machine_code_line)
        
        
        # Format the machine code line       
        if index < len(assembly_code_lines) - 1:
            current_machine_code_line = format(int(current_machine_code_line, 2), "04X") +'\n'
        else:
            current_machine_code_line = format(int(current_machine_code_line, 2), "04X")
        
        machine_code.append(current_machine_code_line)
        
        if should_have_nop_after:
            if index < len(assembly_code_lines) - 1:
                machine_code.append(format(int("0"*16, 2), "04X") + '\n')
                machine_code.append(format(int("0"*16, 2), "04X") + '\n')
                machine_code.append(format(int("0"*16, 2), "04X") + '\n')
            else:
                machine_code.append('\n' + format(int("0"*16, 2), "04X"))
                machine_code.append('\n' + format(int("0"*16, 2), "04X"))
                machine_code.append('\n' + format(int("0"*16, 2), "04X"))
            
        
    

    
    with open("machine_code", 'w+') as f:
        f.writelines(machine_code)

if __name__ == "__main__":
    main()
