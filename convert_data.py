def convert_to_uppercase_hex_lines(input_file, output_file):
    try:
        with open(input_file, 'r') as f_in, open(output_file, 'w') as f_out:
            for line in f_in:
                numbers = line.split()
                
                for val in numbers:
                    try:
                        num = int(val)
                        hex_str = f"{num & 0xFF:02X}"
                        
                        f_out.write(hex_str + "\n")
                    except ValueError:
                        continue
                        
        print(f"Success! Uppercase hex values written to '{output_file}'")

    except FileNotFoundError:
        print(f"Error: The file '{input_file}' was not found.")

if __name__ == "__main__":
    convert_to_uppercase_hex_lines('data_plain_text.txt', 'data')