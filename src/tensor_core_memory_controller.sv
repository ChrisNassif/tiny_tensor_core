`define NOP_OPCODE 3'b000
`define TENSOR_CORE_OPERATE_OPCODE 3'b001
`define BURST_OPCODE 3'b010
`define RESET_OPCODE 3'b011
`define MATRIX_ADD_OPCODE 3'b100
`define MATRIX_SCALE_OPCODE 3'b101
`define MATRIX_RELU_OPCODE 3'b110

`define BUS_WIDTH 4



module tensor_core_memory_controller(
    input logic clock_in,
    input logic reset_in,  // can be connected to ground
    input logic signed [7:0] tensor_core_controller_output,
    output logic clock_out,
    output logic reset_out,
    output logic [15:0] current_tensor_core_instruction
);

    logic [63:0] machine_code [0:4000];
    logic [31:0] data [0:4000];
    logic [19:0] current_machine_code_instruction_index_positive_edge;
    logic [19:0] current_machine_code_instruction_index_negative_edge;
    wire [19:0] current_machine_code_instruction_index;


    // logic power_on_reset_signal = 1;
    logic has_positive_clock_edge_been_called;
    wire [2:0] current_opcode;

    assign reset_out = (current_opcode == `RESET_OPCODE) || reset_in;
    // assign reset_out = (current_opcode == `RESET_OPCODE) || reset_in || power_on_reset_signal;
    assign clock_out = clock_in;




    logic [63:0] raw_current_instruction;
    wire [7:0] scale_factor; 
    wire [7:0] negative_scale_factor;


    assign raw_current_instruction = machine_code[current_machine_code_instruction_index];
    assign current_opcode = raw_current_instruction[2:0];
    assign scale_factor = raw_current_instruction[10:3];
    assign negative_scale_factor = ~scale_factor+1;


    wire is_burst_load_active;
    wire is_burst_store_active;
    
    assign is_burst_load_active = (current_opcode == `BURST_OPCODE && raw_current_instruction[15] == 1'b1);
    assign is_burst_store_active = (current_opcode == `BURST_OPCODE && raw_current_instruction[14] == 1'b1);




    wire [15:0] data_load_address1;
    wire [15:0] data_load_address2;

    assign data_load_address1 = raw_current_instruction[31:16];
    assign data_load_address2 = raw_current_instruction[47:32];



    wire data_store_enable;
    wire [15:0] data_store_address;
    wire signed [7:0] data_store_data;
    
    assign data_store_enable = is_burst_store_active;
    assign data_store_address = machine_code[current_machine_code_instruction_index][63:48];
    assign data_store_data = tensor_core_controller_output;




    initial begin
        
        for (int i = 0; i < 400000; i++) begin
            machine_code[i] = 0;
        end
        for (int i = 0; i < 65535; i++) begin
            data[i] = 0;
        end
        
        $readmemh("machine_code", machine_code);
        $readmemh("data_in", data);
    end


    final begin
        $writememh("data_out", data);
    end
    
    always_comb begin

        if (reset_out) begin
            current_tensor_core_instruction = 0;
        end
        else if (is_burst_load_active) begin
            current_tensor_core_instruction = {8'(data[data_load_address1][7:0]), 8'(data[data_load_address2][7:0])};
            
        end

        else if (is_burst_store_active) begin
            current_tensor_core_instruction = 0;
        end

        else begin
            current_tensor_core_instruction = raw_current_instruction[15:0];
        end

    end



    // handle writing data that is being stored into main memory from the tensor core
    // also handle any relevant memory controller opcodes
    always_ff @(posedge clock_in) begin
        if (data_store_enable) begin
            data[data_store_address][7:0] <= data_store_data;
        end

        else if (current_opcode == `MATRIX_ADD_OPCODE) begin
            for (int i = 0; i < 9; i++) begin
                data[data_store_address + i] <= data[data_load_address1 + i] + data[data_load_address2 + i];
            end
        end

        else if (current_opcode == `MATRIX_SCALE_OPCODE) begin
            for (int i = 0; i < 9; i++) begin
                if (scale_factor[7] == 1) begin
                    data[data_load_address1 + i] <= ($signed(data[data_load_address1 + i]) >>> negative_scale_factor);
                end
                
                else begin
                    data[data_load_address1 + i] <= (data[data_load_address1 + i] << scale_factor); 
                end

            end
        end

        else if (current_opcode == `MATRIX_RELU_OPCODE) begin
            for (int i = 0; i < 9; i++) begin
                if (data[data_load_address1 + i][31] == 1) begin
                    data[data_load_address1 + i] <= 0;
                end
            end
        end
    end

    always_ff @(negedge clock_in) begin
        if (data_store_enable) begin
            data[data_store_address][11:8] <= data_store_data[3:0];

            // sign extend
            if (data_store_data[3] == 1) begin
                data[data_store_address][31:12] <= 20'hFFFFF;
            end else begin
                data[data_store_address][31:12] <= 20'h00000;
            end
        end
    end



    // Hardware for managing the instruction counter
    always_ff @(posedge clock_in or posedge reset_in) begin
        if (reset_in) begin
            current_machine_code_instruction_index_positive_edge <= 0;
            has_positive_clock_edge_been_called <= 0;
        end 
        else begin
            has_positive_clock_edge_been_called <= 1;
            current_machine_code_instruction_index_positive_edge <= current_machine_code_instruction_index_positive_edge + 1;
        end
    end

    always_ff @(negedge clock_in or posedge reset_in) begin
        if (reset_in) begin
            current_machine_code_instruction_index_negative_edge <= 0;
        end 
        else begin
            if (has_positive_clock_edge_been_called == 1) begin
                current_machine_code_instruction_index_negative_edge <= current_machine_code_instruction_index_negative_edge + 1;
            end
        end
    end

    assign current_machine_code_instruction_index = current_machine_code_instruction_index_positive_edge + current_machine_code_instruction_index_negative_edge;

    

endmodule