import numpy as np
import sys


NUMBER_OF_NOPS_AFTER_MATRIX_OPERATION = 16
# NUMBER_OF_NOPS_AFTER_BURST_READ_OPERATION = 11


operation_name_to_opcode = {
    "nop": "00",
    "operate": "01",
    "burst": "10",
    "reset": "11"
}


operate_opselects = {
    "matrix_multiply": "00",
    "matrix_add": "01",
    "relu": "10",
}


burst_read_write_selects = {
    "read": "00",
    "write": "01",
    "read_and_write": "10",
    "matrix1_write": "11"
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
        should_have_burst_operation_nops_after = False
        
        burst_write_matrix1_address = None
        burst_write_matrix2_address = None
        burst_read_address = None
        
        read_or_write = None
        
        current_machine_code_line = ""
        current_machine_code_line += "0" * 48


        # PARSE THE DIFFERENT INSTRUCTION FORMATS
        if (operation_name in ["nop", "reset"]):
            current_machine_code_line += "0"*14
            current_machine_code_line += operation_name_to_opcode[operation_name]
    
            
        elif (operation_name in ["matrix_multiply", "matrix_add", "relu"]):
            
            current_machine_code_line += "0"*12
            current_machine_code_line += operate_opselects[operation_name]
            current_machine_code_line += operation_name_to_opcode["operate"]
            
            if operation_name != "relu":
                should_have_matrix_operation_nops_after = True
        
        
        elif (operation_name == "burst"):
            
            read_or_write = assembly_code_tokens[1]

            current_machine_code_line += "0"*12
            
            current_machine_code_line += burst_read_write_selects[read_or_write]
            current_machine_code_line += operation_name_to_opcode["burst"]
            
            if read_or_write == "write":
                burst_write_matrix1_address = int(assembly_code_tokens[2])
                burst_write_matrix2_address = int(assembly_code_tokens[3])
                
            elif read_or_write == "read":
                burst_read_address = int(assembly_code_tokens[2])
                should_have_burst_operation_nops_after = True
            
            elif read_or_write == "read_and_write":
                burst_read_address = int(assembly_code_tokens[2])
                burst_write_matrix1_address = int(assembly_code_tokens[3])
                burst_write_matrix2_address = int(assembly_code_tokens[4])
                
            # elif read_or_write == "matrix1_write":
            #     burst_write_matrix1_address = int(assembly_code_tokens[2])
                
            else:
                raise Exception(f"Only accepts read or write or read_and_write as acceptable arguments on line {line_index}")
            
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
                    
        # if should_have_burst_operation_nops_after:
        #     for i in range(NUMBER_OF_NOPS_AFTER_BURST_READ_OPERATION):
        #         machine_code.append(format(int("0"*64, 2), "016X") + '\n')
    
    
    

        
        if burst_write_matrix1_address is not None and burst_write_matrix2_address is not None:
            
            for index in range(9):
                current_machine_code_line = ""
                                
                if burst_read_address is not None:
                    current_machine_code_line += number_into_unsigned_kbit_binary(9*burst_read_address + index, k=16)
                else:
                    current_machine_code_line += "0"*16
                
                # print(f"index: {index}")
                # print(f"burst_write_matrix1_address: {burst_write_matrix1_address}")
                # print(f"burst_write_matrix2_address: {burst_write_matrix2_address}")
                
                if 2*index+1 < 9:
                    # print(9*burst_write_matrix1_address + 2*index+1)
                    current_machine_code_line += number_into_unsigned_kbit_binary(9*burst_write_matrix1_address + 2*index+1, k=16)
                else:
                    # print(9*burst_write_matrix2_address + 2*index+1 - 9)
                    current_machine_code_line += number_into_unsigned_kbit_binary(9*burst_write_matrix2_address + 2*index+1 - 9, k=16)
                
                
                if 2*index < 9:
                    # print(9*burst_write_matrix1_address + 2*index)
                    current_machine_code_line += number_into_unsigned_kbit_binary(9*burst_write_matrix1_address + 2*index,   k=16)
                else:
                    # print(9*burst_write_matrix2_address + 2*index - 9)
                    current_machine_code_line += number_into_unsigned_kbit_binary(9*burst_write_matrix2_address + 2*index - 9, k=16)
                
            
                current_machine_code_line += "1"
                
                if burst_read_address is not None:
                    current_machine_code_line += "1"
                else:
                    current_machine_code_line += "0"
                    
                current_machine_code_line += "0"*10
            
                current_machine_code_line += burst_read_write_selects[read_or_write]
                current_machine_code_line += operation_name_to_opcode["burst"]
                
                
                machine_code.append(format(int(current_machine_code_line, 2), "016X") + '\n')
                
            machine_code.append(format(int("0"*64, 2), "016X") + '\n')
            machine_code.append(format(int("0"*64, 2), "016X") + '\n')
            
            
    
        elif burst_read_address is not None:
            for index in range(9):
                
                current_machine_code_line = ""
                
                if burst_read_address is not None:
                    current_machine_code_line += number_into_unsigned_kbit_binary(9*burst_read_address + index, k=16)
                
                else:
                    current_machine_code_line += "0"*16
                    
                    
                current_machine_code_line += "0"*32
                
                current_machine_code_line += "0"
                current_machine_code_line += "1"
                current_machine_code_line += "0"*10
            
                current_machine_code_line += burst_read_write_selects[read_or_write]
                current_machine_code_line += operation_name_to_opcode["burst"]
                
                                
                machine_code.append(format(int(current_machine_code_line, 2), "016X") + '\n')\
                    
            machine_code.append(format(int("0"*64, 2), "016X") + '\n')
            machine_code.append(format(int("0"*64, 2), "016X") + '\n')



    
    with open("machine_code", 'w+') as f:
        f.writelines(machine_code)





if __name__ == "__main__": 
    main()