`define NOP_OPCODE 3'b000
`define TENSOR_CORE_OPERATE_OPCODE 3'b001
`define BURST_OPCODE 3'b010
`define RESET_OPCODE 3'b011
`define MATRIX_ADD_OPCODE 3'b100
`define MATRIX_SCALE_OPCODE 3'b101
`define MATRIX_RELU_OPCODE 3'b110
`define CURRENTLY_BURSTING_OPCODE 3'b111

`define BUS_WIDTH 4



module tensor_core_memory_controller(
    input logic clock_in,
    input logic reset_in,
    input logic signed [11:0] tensor_core_controller_output,
    output logic clock_out,
    output logic reset_out,
    output logic [9:0] current_tensor_core_instruction
);

    logic [63:0] machine_code [0:4000];
    logic [31:0] memory [0:4000];
    logic [19:0] current_machine_code_instruction_index;


    // logic power_on_reset_signal = 1;

    assign reset_out = (current_opcode == `RESET_OPCODE) || reset_in;
    // assign reset_out = (current_opcode == `RESET_OPCODE) || reset_in || power_on_reset_signal;
    assign clock_out = clock_in;




    wire [63:0] raw_current_instruction = machine_code[current_machine_code_instruction_index];
    wire [2:0] current_opcode = raw_current_instruction[2:0];
    wire [7:0] scale_factor = raw_current_instruction[10:3];
    wire [7:0] negative_scale_factor = ~scale_factor+1;


    wire is_burst_load_active = (current_opcode == `CURRENTLY_BURSTING_OPCODE && raw_current_instruction[15] == 1'b1);
    wire is_burst_store_active = (current_opcode == `CURRENTLY_BURSTING_OPCODE && raw_current_instruction[14] == 1'b1);

    wire [15:0] memory_load_address1 = raw_current_instruction[31:16];
    wire [15:0] memory_load_address2 = raw_current_instruction[47:32];


    wire [15:0] memory_store_address = machine_code[current_machine_code_instruction_index][63:48];
    wire signed [11:0] memory_store_data = tensor_core_controller_output;




    initial begin
        
        for (int i = 0; i < 400000; i++) begin
            machine_code[i] = 0;
        end
        for (int i = 0; i < 65535; i++) begin
            memory[i] = 0;
        end
        
        $readmemh("machine_code", machine_code);
        $readmemh("data_in", memory);
    end


    final begin
        $writememh("data_out", memory);
    end
    
    always_comb begin

        if (reset_out) begin
            current_tensor_core_instruction = 0;
        end
        else if (is_burst_load_active) begin
            current_tensor_core_instruction = {5'(memory[memory_load_address1][4:0]), 5'(memory[memory_load_address2][4:0])};
            
        end
        else begin
            current_tensor_core_instruction = raw_current_instruction[9:0];
        end

    end



    // handle writing data that is being stored into main memory from the tensor core
    // also handle any relevant memory controller opcodes
    always_ff @(posedge clock_in) begin

        if (is_burst_store_active) begin
            memory[memory_store_address][11:0] <= memory_store_data;

            // sign extend
            if (memory_store_data[11] == 1) begin
                memory[memory_store_address][31:12] <= 20'hFFFFF;
            end 
            else begin
                memory[memory_store_address][31:12] <= 20'h00000;
            end
        end

        else if (current_opcode == `MATRIX_ADD_OPCODE) begin
            for (int i = 0; i < 9; i++) begin
                memory[memory_store_address + i] <= memory[memory_load_address1 + i] + memory[memory_load_address2 + i];
            end
        end

        else if (current_opcode == `MATRIX_SCALE_OPCODE) begin
            for (int i = 0; i < 9; i++) begin
                if (scale_factor[6] == 1) begin
                    memory[memory_load_address1 + i] <= ($signed(memory[memory_load_address1 + i]) >>> negative_scale_factor);
                end
                
                else begin
                    memory[memory_load_address1 + i] <= (memory[memory_load_address1 + i] << scale_factor); 
                end

            end
        end

        else if (current_opcode == `MATRIX_RELU_OPCODE) begin
            for (int i = 0; i < 9; i++) begin
                if (memory[memory_load_address1 + i][31] == 1) begin
                    memory[memory_load_address1 + i] <= 0;
                end
            end
        end
    end


    // Hardware for managing the instruction counter
    always_ff @(posedge clock_in or posedge reset_in) begin
        // power_on_reset_signal <= 0;
        
        if (reset_in) begin
            current_machine_code_instruction_index <= 0;
        end 
        else begin
            current_machine_code_instruction_index <= current_machine_code_instruction_index + 1;
        end
    end
    

endmodule