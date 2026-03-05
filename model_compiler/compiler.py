import torch
import math
import sys
import numpy as np

def pad_to_multiple(n, m):
    return ((n + m - 1) // m) * m

def tile_matrix(W):
    out_features, in_features = W.shape
    out_padded = pad_to_multiple(out_features, 3)
    in_padded = pad_to_multiple(in_features, 3)
    
    W_padded = np.zeros((out_padded, in_padded), dtype=np.int32)
    W_padded[:out_features, :in_features] = W
    
    out_tiles = out_padded // 3
    in_tiles = in_padded // 3
    
    tiles = np.zeros((out_tiles, in_tiles, 3, 3), dtype=np.int32)
    for i in range(out_tiles):
        for j in range(in_tiles):
            tiles[i, j] = W_padded[i*3:i*3+3, j*3:j*3+3]
    return tiles

def main():
    model_path = sys.argv[1] if len(sys.argv) > 1 else 'models/quantized_tensor_core_mnist_961_5bit.pt'
    sd = torch.load(model_path, map_location='cpu')
    
    layer_names = ['fc1', 'fc2']
    
    unique_tiles_map = {}
    memory_blocks = []
    
    def alloc_block(vals=None):
        if vals is None:
            vals = [0]*9
        block_idx = len(memory_blocks)
        memory_blocks.append([int(x) for x in vals])
        return block_idx

    # Basic Blocks
    ZERO_ADDR = alloc_block()
    MULTI_OUT_ADDR = alloc_block()
    DUMMY_ADDR = alloc_block()
    
    input_scale = sd['quant.scale'].item()
    input_log2_scale = int(math.log2(input_scale))
    current_input_log2_scale = input_log2_scale
    
    INPUT_SIZE = 784
    input_tiles_count = pad_to_multiple(INPUT_SIZE, 3) // 3
    
    INPUT_START_ADDR = len(memory_blocks)
    for _ in range(input_tiles_count):
        alloc_block() # Fill with zeros initially, evaluate_asm will inject here
        
    asm_instructions = ["reset", "nop"]
    
    current_activation_addrs = list(range(INPUT_START_ADDR, INPUT_START_ADDR + input_tiles_count))
    
    for layer in layer_names:
        W_q, bias = sd[f'{layer}._packed_params._packed_params']
        W_int = W_q.int_repr().numpy() 
        W_T = W_int.T
        
        W_scale = W_q.q_scale()
        out_scale = sd[f'{layer}.scale'].item()
        
        W_log2_scale = int(math.log2(W_scale))
        O_log2_scale = int(math.log2(out_scale))
        
        total_shift = (current_input_log2_scale + W_log2_scale) - O_log2_scale
        scale_factor = pow(2.0, total_shift)
        
        tiles = tile_matrix(W_T)
        in_tiles, out_tiles, _, _ = tiles.shape
        
        if len(current_activation_addrs) < in_tiles:
            diff = in_tiles - len(current_activation_addrs)
            current_activation_addrs.extend([ZERO_ADDR] * diff)
        elif len(current_activation_addrs) > in_tiles:
            current_activation_addrs = current_activation_addrs[:in_tiles]
            
        new_activation_addrs = []
        
        for j in range(out_tiles):
            ACC_ADDR = alloc_block()
            
            for i in range(in_tiles):
                w_tile = tiles[i, j].flatten()
                w_tile_tuple = tuple(w_tile)
                if w_tile_tuple not in unique_tiles_map:
                    unique_tiles_map[w_tile_tuple] = alloc_block(w_tile)
                W_ADDR = unique_tiles_map[w_tile_tuple]
                
                X_ADDR = current_activation_addrs[i]
                
                # output = X @ W^T
                asm_instructions.append(f"burst store_and_load {DUMMY_ADDR} {X_ADDR} {W_ADDR}")
                asm_instructions.append("matrix_multiply")
                asm_instructions.append(f"burst store_and_load {MULTI_OUT_ADDR} {ZERO_ADDR} {ZERO_ADDR}")
                asm_instructions.append(f"matrix_add {ACC_ADDR} {ACC_ADDR} {MULTI_OUT_ADDR}")
                
            asm_instructions.append(f"matrix_scale {ACC_ADDR} {scale_factor}")
            if layer == 'fc1':
                asm_instructions.append(f"matrix_relu {ACC_ADDR}")
                
            new_activation_addrs.append(ACC_ADDR)
            
        current_input_log2_scale = O_log2_scale
        current_activation_addrs = new_activation_addrs
        
        if layer == layer_names[-1]:
            print(f"Final output blocks are stored at logic addresses: {current_activation_addrs}")
    
    with open("assembly_code.asm", "w") as f:
        f.write("\n".join(asm_instructions) + "\n")
        
    with open("data_in_plain_text.txt", "w") as f:
        for block in memory_blocks:
            line = " ".join(str(x) for x in block)
            f.write(line + "\n")
            
    print(f"Compilation successful. Total memory blocks used: {len(memory_blocks)}")

if __name__ == "__main__":
    main()
