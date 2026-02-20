`define NOP_OPCODE 2'b00
`define TENSOR_CORE_OPERATE_OPCODE 2'b01
`define BURST_OPCODE 2'b10
`define RESET_OPCODE 2'b11

`define BURST_STORE_SELECT 2'b00
`define BURST_LOAD_SELECT 2'b01
`define BURST_STORE_AND_LOAD_SELECT 2'b10


`define BUS_WIDTH 7


module tensor_core_memory_controller(
    input logic clock_in,
    input logic reset_in,  // can be connected to ground
    input logic signed [7:0] tensor_core_controller_output,

    output logic clock_out,
    output logic reset_out,
    output logic [15:0] current_tensor_core_instruction
);

    logic [63:0] machine_code [0:20000];
    logic [15:0] data [0:20000];
    logic [15:0] current_machine_code_instruction_index_positive_edge;
    logic [15:0] current_machine_code_instruction_index_negative_edge;
    wire [15:0] current_machine_code_instruction_index;



    assign clock_out = clock_in;


    logic power_on_reset_signal = 1;
    logic positive_edge_reset_called;

    assign reset_out = (current_opcode == `RESET_OPCODE) || reset_in || power_on_reset_signal;



    logic [63:0] raw_current_instruction;
    wire [1:0] current_opcode;
    wire [1:0] burst_store_load_select;

    assign raw_current_instruction = machine_code[current_machine_code_instruction_index];
    assign current_opcode = raw_current_instruction[1:0];
    assign burst_store_load_select = raw_current_instruction[3:2];



    wire is_burst_load_active;
    wire is_burst_store_active;
    
    assign is_burst_load_active = ((burst_store_load_select == `BURST_STORE_AND_LOAD_SELECT || burst_store_load_select == `BURST_LOAD_SELECT) && current_opcode == `BURST_OPCODE && raw_current_instruction[15] == 1'b1);
    assign is_burst_store_active = ((burst_store_load_select == `BURST_STORE_AND_LOAD_SELECT || burst_store_load_select == `BURST_STORE_SELECT) && current_opcode == `BURST_OPCODE && raw_current_instruction[14] == 1'b1);




    wire [15:0] data_store_address1;
    wire [15:0] data_store_address2;

    assign data_store_address1 = raw_current_instruction[31:16];
    assign data_store_address2 = raw_current_instruction[47:32];



    wire data_load_enable;
    wire [15:0] data_load_address;
    wire [`BUS_WIDTH:0] data_load_data;
    
    assign data_load_enable = is_burst_store_active;
    assign data_load_address = machine_code[current_machine_code_instruction_index][63:48];
    assign data_load_data = tensor_core_controller_output;


    initial begin
        
        for (int i = 0; i < 20000; i++) begin
            machine_code[i] = 0;
            data[i] = 0;
        end
        
        $readmemh("machine_code", machine_code);
        $readmemh("data_in", data);
    end


    final begin
        $writememh("data_out", data);
    end
    
    always_comb begin

        // Process the current instruction word if it is some kind of load or reset instructions
        if (reset_out) begin
            current_tensor_core_instruction = 0;
        end
        else if (is_burst_load_active) begin
            current_tensor_core_instruction = {data[data_store_address1][`BUS_WIDTH:0], data[data_store_address2][`BUS_WIDTH:0]};
        end

        else if (is_burst_store_active) begin
            current_tensor_core_instruction = 0;
        end

        else begin
            current_tensor_core_instruction = raw_current_instruction[15:0];
        end

    end



    // handle writing data that is store from the tensor core
    always_ff @(posedge clock_in) begin
        if (data_load_enable) begin
            data[data_load_address][7:0] <= data_load_data;
        end
    end

    always_ff @(negedge clock_in) begin
        if (data_load_enable) begin
            data[data_load_address][15:8] <= data_load_data;
        end
    end


    
    assign current_machine_code_instruction_index = current_machine_code_instruction_index_positive_edge + current_machine_code_instruction_index_negative_edge;

    always_ff @(posedge clock_in) begin

        if (power_on_reset_signal || reset_in) begin
            current_machine_code_instruction_index_positive_edge <= 0;
            current_machine_code_instruction_index_negative_edge <= 0;
            power_on_reset_signal <= 0;
            positive_edge_reset_called <= 1;
        end

        else begin
            current_machine_code_instruction_index_positive_edge <= current_machine_code_instruction_index_positive_edge + 1;
        end
    end


    always_ff @(negedge clock_in) begin
        if (positive_edge_reset_called == 0) begin
            current_machine_code_instruction_index_negative_edge <= current_machine_code_instruction_index_negative_edge + 1;
        end

        positive_edge_reset_called <= 0;
    end




    genvar i, j;
    generate
        for (i = 0; i < 20; i++) begin : i_
            for (j = 0; j < 9; j++) begin : j_
                wire [`BUS_WIDTH:0] data_ = data[i*9+j];
            end
        end
    endgenerate
endmodule