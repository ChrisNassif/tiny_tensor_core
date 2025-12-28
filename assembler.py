import numpy as np
import sys
    
    
NUMBER_OF_NOPS_AFTER_MATRIX_OPERATION = 9
NUMBER_OF_NOPS_AFTER_BURST_OPERATION = 9

operation_name_to_opcode = {
    "generic": "00",
    "load_immediate": "01",
    "operate": "10",
    "burst": "11"
}

generic_opselects = {
    "read": "00",
    "move": "01",
    "nop": "10",
    "reset": "11"
}

operate_opselects = {
    "matrix_multiply": "000",
    "matrix_add": "001",
    "relu": "010",
    "addition_summation": "011",
    "dot_product": "100"
}


burst_read_write_selects = {
    "read": "0",
    "write": "1"
}


burst_matrix_selects = {
    "matrix1": "0",
    "matrix2": "1"
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
    
    
    for line_index, assembly_code_line in enumerate(assembly_code_lines):
        line_index += 1 # this is to make the index start from 1 and not start from 0
        
        
        assembly_code_tokens = assembly_code_line.strip().split(" ")
        
        operation_name = assembly_code_tokens[0]
        # opcode = operation_name_to_opcode[operation_name]

        should_have_matrix_operation_nops_after = False
        should_have_burst_operation_nops_after = False
        
        
        current_machine_code_line = ""



        # PARSE THE DIFFERENT INSTRUCTION FORMATS
        
        if (operation_name in ["nop", "reset"]):
            current_machine_code_line += "0"*12
            current_machine_code_line += generic_opselects[operation_name]
            current_machine_code_line += operation_name_to_opcode["generic"]
            
        
        elif (operation_name in ["read",]):
            read_register_address = assembly_code_tokens[1]
            
            if (int(read_register_address) > 17 or int(read_register_address) < 0): 
                raise Exception(f"Improper arguments for read instruction in line {line_index}")

            current_machine_code_line += "0"*5
            current_machine_code_line += number_into_unsigned_kbit_binary(read_register_address, k=5)
            current_machine_code_line += "0"*2
            current_machine_code_line += generic_opselects[operation_name]
            current_machine_code_line += operation_name_to_opcode["generic"]
            
            
        elif (operation_name in ["move",]):
            write_register_address = assembly_code_tokens[1]
            read_register_address = assembly_code_tokens[2]
            
            
            if (int(write_register_address) > 17 or int(write_register_address) < 0): 
                raise Exception(f"Improper arguments for move instruction in line {line_index}")
            
            if (int(read_register_address) > 17 or int(read_register_address) < 0): 
                raise Exception(f"Improper arguments for move instruction in line {line_index}")
            
            
            current_machine_code_line += number_into_unsigned_kbit_binary(write_register_address, k=5)
            current_machine_code_line += number_into_unsigned_kbit_binary(read_register_address, k=5)
            current_machine_code_line += "0"*2
            current_machine_code_line += generic_opselects[operation_name]
            current_machine_code_line += operation_name_to_opcode["generic"]
            
            
            
        elif (operation_name in ["load_immediate",]):
            
            write_register_address = assembly_code_tokens[1]
            immediate_operand = assembly_code_tokens[2]
            
            if (int(write_register_address) > 17 or int(write_register_address) < 0): 
                raise Exception(f"Improper arguments for load_immediate instruction in line {line_index}")
            

            current_machine_code_line += number_into_unsigned_kbit_binary(write_register_address, k=5)
            current_machine_code_line += number_into_signed_kbit_binary(immediate_operand, k=8)
            current_machine_code_line += "0"
            current_machine_code_line += operation_name_to_opcode["load_immediate"]
            
            
            
        elif (operation_name in ["matrix_multiply", "matrix_add", "relu", "matrix_summation", "dot_product"]):
            
            current_machine_code_line += "0"*11
            current_machine_code_line += operate_opselects[operation_name]
            current_machine_code_line += operation_name_to_opcode["operate"]
            
            should_have_matrix_operation_nops_after = True
        
        
        elif (operation_name in ["burst",]):
            
            read_or_write = assembly_code_tokens[1]
            matrix_name = assembly_code_tokens[2]
            
            if read_or_write == "write":
                write_byte = number_into_signed_kbit_binary(assembly_code_tokens[2], k=8)
                current_machine_code_line += write_byte
            else:
                current_machine_code_line += "0"*8
                
            current_machine_code_line += "0"*4
            
            current_machine_code_line += burst_matrix_selects[matrix_name]
            current_machine_code_line += burst_read_write_selects[read_or_write]

            should_have_burst_operation_nops_after = True
        
        else:
            raise Exception(f"operation name {operation_name} on line {line_index} is not supported")
                
                
                
        print(current_machine_code_line)
        
        
        # Format the machine code line       
        if line_index < len(assembly_code_lines):
            current_machine_code_line = format(int(current_machine_code_line, 2), "04X") +'\n'
        else:
            current_machine_code_line = format(int(current_machine_code_line, 2), "04X")
        
        
        machine_code.append(current_machine_code_line)
        
        
        if should_have_matrix_operation_nops_after:
            if line_index < len(assembly_code_lines):
                for i in range(NUMBER_OF_NOPS_AFTER_MATRIX_OPERATION):
                    machine_code.append(format(int("0"*16, 2), "04X") + '\n')
            else:
                for i in range(NUMBER_OF_NOPS_AFTER_MATRIX_OPERATION):
                    machine_code.append('\n' + format(int("0"*16, 2), "04X"))
                    
                    
        if should_have_burst_operation_nops_after:
            if line_index < len(assembly_code_lines):
                for i in range(NUMBER_OF_NOPS_AFTER_BURST_OPERATION):
                    machine_code.append(format(int("0"*16, 2), "04X") + '\n')
            else:
                for i in range(NUMBER_OF_NOPS_AFTER_BURST_OPERATION):
                    machine_code.append('\n' + format(int("0"*16, 2), "04X"))
    

    
    with open("machine_code", 'w+') as f:
        f.writelines(machine_code)

if __name__ == "__main__":
    main()
