def number_into_signed_8bit(number: str):
    number = int(number)
    if number < -128 or number > 127:
        raise Exception("code has out of bounds number")
    
    return f'{number:08b}'


def main():
    with open("assembly_code.asm", "r") as f:
        assembly_code_lines = f.readlines()

    machine_code = ""
    
    for assembly_code_line in assembly_code_lines:
        assembly_code_tokens = assembly_code_line.split(" ")
        
        current_machine_code_line = ""
        current_machine_code_line += number_into_signed_8bit(assembly_code_tokens[1])
        current_machine_code_line += number_into_signed_8bit(assembly_code_tokens[2])
        current_machine_code_line += number_into_signed_8bit(assembly_code_tokens[3])
        current_machine_code_line += "00000" 
        
        match assembly_code_tokens[0]:
            case "add":
                current_machine_code_line += "000"
            case "sub":
                current_machine_code_line += "001"
            case "mul":
                current_machine_code_line += "010"
            case "eql":
                current_machine_code_line += "011"
            case "grt":
                current_machine_code_line += "100"
            case _:
                raise Exception("Operation not found") 
        
        machine_code += (format(int(current_machine_code_line, 2), "08X") +'\n')
        
    print(machine_code)

if __name__ == "__main__":
    main()
