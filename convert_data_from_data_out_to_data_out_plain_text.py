def process_hex_data(input_file, output_file):
    decimals = []
    
    with open(input_file, 'r') as f:
        for line in f:
            clean_line = line.split('//')[0]
            parts = clean_line.split()
            
            for h in parts:
                try:
                    val = int(h, 16)
                    if val > (2**31 - 1):
                        val -= (2**32)
                    decimals.append(val)
                    
                except ValueError:
                    continue
    

    row_size = 9
    with open(output_file, 'w') as f_out:
        for i in range(0, len(decimals), row_size):
            row = decimals[i:i + row_size]
            line_str = " ".join(map(str, row))
            f_out.write(line_str + "\n")
            
    print(f"Success! Formatted data written to '{output_file}'.")



if __name__ == "__main__":
    process_hex_data('data_out', 'data_out_plain_text.txt')