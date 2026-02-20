import numpy as np
import sys
import math

NUMBER_OF_NOPS_AFTER_MATRIX_OPERATION = 16


operation_name_to_opcode = {
    "nop": "000",
    "tensor_core": "001",
    "burst": "010",
    "reset": "011",
    "matrix_add": "100",
    "matrix_scale": "101",
    "matrix_relu": "110"
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

        should_have_matrix_operation_nops_after = False
        
        burst_load_matrix1_address = None
        burst_load_matrix2_address = None
        burst_store_address = None
        
        store_or_load = None
        
        current_machine_code_line = ""


        # PARSE THE DIFFERENT INSTRUCTION FORMATS
        if (operation_name in ["nop", "reset"]):
            current_machine_code_line += "0" * 48
            
            current_machine_code_line += "0"*13
            current_machine_code_line += operation_name_to_opcode[operation_name]
    
        
        elif (operation_name == "burst"):
            current_machine_code_line += "0" * 48
            
            store_or_load = assembly_code_tokens[1]

            if store_or_load != "store_and_load":
                raise Exception(f"Only accepts store_and_load as an acceptable argument on line {line_index}")

            current_machine_code_line += "0"*13
            
            current_machine_code_line += operation_name_to_opcode["burst"]
            
            burst_store_address = int(assembly_code_tokens[2])
            burst_load_matrix1_address = int(assembly_code_tokens[3])
            burst_load_matrix2_address = int(assembly_code_tokens[4])
            
            if burst_store_address in [burst_load_matrix1_address, burst_load_matrix2_address]:
                raise Exception(f"Pipeline Hazard on line {line_index}: Cannot store to and load from the same matrix address ({burst_store_address}) in the same instruction.")
        
        
                    
        elif (operation_name in ["matrix_multiply"]):
            current_machine_code_line += "0" * 48
            
            current_machine_code_line += "0"*13
            current_machine_code_line += operation_name_to_opcode["tensor_core"]
            
            should_have_matrix_operation_nops_after = True

        
        elif (operation_name == "matrix_add"):
            matrix_input1_address = int(assembly_code_tokens[2])
            matrix_input2_address = int(assembly_code_tokens[3])
            matrix_output_address = int(assembly_code_tokens[4])
            
            current_machine_code_line += number_into_unsigned_kbit_binary(matrix_output_address, k=16)
            current_machine_code_line += number_into_unsigned_kbit_binary(matrix_input2_address, k=16)
            current_machine_code_line += number_into_unsigned_kbit_binary(matrix_input1_address, k=16)

            current_machine_code_line += "0"*13
            current_machine_code_line += operation_name_to_opcode["matrix_add"]
                    
        
        elif (operation_name == "matrix_scale"):
            current_machine_code_line += "0" * 32
            
            matrix_address = int(assembly_code_tokens[2])
            
            scale_factor = int(round(math.log2(assembly_code_tokens[3])))
            
            current_machine_code_line += number_into_unsigned_kbit_binary(matrix_address, k=16)
            
            current_machine_code_line += "0"*5
            current_machine_code_line += number_into_signed_kbit_binary(scale_factor, k=8)
            current_machine_code_line += operation_name_to_opcode["matrix_scale"]
            
            
        elif (operation_name == "matrix_relu"):
            current_machine_code_line += "0" * 32
            
            matrix_address = int(assembly_code_tokens[2])
            
            current_machine_code_line += number_into_unsigned_kbit_binary(matrix_address, k=16)
            current_machine_code_line += "0"*13
            current_machine_code_line += operation_name_to_opcode["matrix_relu"]
        
            
        else:
            raise Exception(f"operation name {operation_name} on line {line_index} is not supported")
                
                
        print(current_machine_code_line)
        
        
        # Format the machine code line       
        machine_code.append(format(int(current_machine_code_line, 2), "016X") +'\n')
        
        
        # add a copy of the instruction if it isn't a burst instruction
        if operation_name != "burst":
            machine_code.append(format(int(current_machine_code_line, 2), "016X") +'\n')
        
        
        if should_have_matrix_operation_nops_after:
            for i in range(NUMBER_OF_NOPS_AFTER_MATRIX_OPERATION):
                machine_code.append(format(int("0"*64, 2), "016X") + '\n')


        
        if burst_load_matrix1_address is not None and burst_load_matrix2_address is not None:
            
            for index in range(9):
                current_machine_code_line = ""
                                
                if burst_store_address is not None:
                    current_machine_code_line += number_into_unsigned_kbit_binary(9*burst_store_address + int(index/2), k=16)
                else:
                    current_machine_code_line += "0"*16

                if 2*index+1 < 9:
                    current_machine_code_line += number_into_unsigned_kbit_binary(9*burst_load_matrix1_address + 2*index+1, k=16)
                else:
                    current_machine_code_line += number_into_unsigned_kbit_binary(9*burst_load_matrix2_address + 2*index+1 - 9, k=16)
                
                if 2*index < 9:
                    current_machine_code_line += number_into_unsigned_kbit_binary(9*burst_load_matrix1_address + 2*index,   k=16)
                else:
                    current_machine_code_line += number_into_unsigned_kbit_binary(9*burst_load_matrix2_address + 2*index - 9, k=16)
                

                current_machine_code_line += "1"*2
                current_machine_code_line += "0"*11
            
                current_machine_code_line += operation_name_to_opcode["burst"]

                machine_code.append(format(int(current_machine_code_line, 2), "016X") + '\n')


            
            if burst_store_address is not None:
                for index in range(9, 18):
                    current_machine_code_line = ""

                    current_machine_code_line += number_into_unsigned_kbit_binary(9*burst_store_address + int(index/2), k=16)     
                        
                    current_machine_code_line += "0"*32
                    
                    current_machine_code_line += "0"
                    current_machine_code_line += "1"
                    current_machine_code_line += "0"*11
                
                    current_machine_code_line += operation_name_to_opcode["burst"]
                                    
                    machine_code.append(format(int(current_machine_code_line, 2), "016X") + '\n')


                machine_code.append(format(int("0"*64, 2), "016X") + '\n')
            
    




    
    with open("machine_code", 'w+') as f:
        f.writelines(machine_code)





if __name__ == "__main__": 
    main()