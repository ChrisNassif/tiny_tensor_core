def number_into_signed_8bit(number: str):
    number = int(number)
    if number < -128 or number > 127:
        raise Exception("code has out of bounds number")
    
    return f'{number:08b}'


def main():
    with open("assembly_code.asm", "r") as f:
        assembly_code_lines = f.readlines()

    machine_code = []
    
    for index, assembly_code_line in enumerate(assembly_code_lines):
        assembly_code_tokens = assembly_code_line.split(" ")
        
        current_machine_code_line = ""
        current_machine_code_line += number_into_signed_8bit(assembly_code_tokens[1])
        current_machine_code_line += number_into_signed_8bit(assembly_code_tokens[2])
        current_machine_code_line += number_into_signed_8bit(assembly_code_tokens[3])
        
        match assembly_code_tokens[0]:
            case "add":
                current_machine_code_line += "00000000"
            case "sub":
                current_machine_code_line += "00000001"
            case "mul":
                current_machine_code_line += "00000010"
            case "eql":
                current_machine_code_line += "00000011"
            case "grt":
                current_machine_code_line += "00000100"
            case "tensor_core_operate":
                current_machine_code_line += "00000101"
            case "tensor_core_load":
                current_machine_code_line += "00000110"
            case "cpu_to_tensor_core":
                current_machine_code_line += "00000111"
            case "nop":
                current_machine_code_line += "00001000"
            case "add_imm":
                current_machine_code_line += "00001001" 
            case "sub_imm":
                current_machine_code_line += "00001010" 
                
            # UNIMPLEMENTED FROM HERE DOWN
            case "move_cpu":
                current_machine_code_line += "00001011"
            case "move_tensor_core":
                current_machine_code_line += "00001100"
            case "reset":
                current_machine_code_line += "00001101"
            case "tensor_core_to_cpu":
                current_machine_code_line += "00001110"
            case "read_cpu":
                current_machine_code_line += "00001111"
            case "read_tensor_core":
                current_machine_code_line += "00010000"
            case "read_tensor_core_burst":
                current_machine_code_line += "00010001"
            case "tensor_core_load_burst":
                current_machine_code_line += "00010010"
            case _:
                raise Exception("Operation not found") 
        
        if index < len(assembly_code_lines) - 1:
            machine_code.append(format(int(current_machine_code_line, 2), "08X") +'\n')
        else:
            machine_code.append(format(int(current_machine_code_line, 2), "08X"))
        
        
    with open("machine_code", 'w+') as f:
        f.writelines(machine_code)

if __name__ == "__main__":
    main()
