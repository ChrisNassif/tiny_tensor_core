`define NOP_OPCODE 3'b000
`define TENSOR_CORE_OPCODE 3'b001
`define BURST_OPCODE 3'b010


module tensor_core_controller (
    input logic clock_in, 
    input logic reset_in,
    input logic [9:0] current_instruction, 
    output logic signed [11:0] tensor_core_controller_output
);
        
    wire signed [4:0] tensor_core_register_file_bulk_store_data [18];
    wire signed [11:0] tensor_core_output [9];
    logic signed [4:0] tensor_core_input1 [9];
    logic signed [4:0] tensor_core_input2 [9];

    
    // grabbing bits from the instruction
    wire [2:0] opcode = current_instruction[2:0];
    wire signed [4:0] burst_current_dual_load_data [2];
    assign burst_current_dual_load_data[0] = current_instruction[9:5];
    assign burst_current_dual_load_data[1] = current_instruction[4:0];

    
    // used for the burst instruction state machine
    logic is_burst_state_machine_active;
    wire is_burst_load_store_active = (is_burst_state_machine_active || opcode == `BURST_OPCODE);
    logic [3:0] burst_current_index; // stores the current index that the burst opcode is looking at either for storing or loading
    wire signed [11:0] burst_current_store_data = (burst_current_index < 4'd9) ? tensor_core_output[burst_current_index] : 12'b0;


    always_ff @(posedge clock_in) begin
        tensor_core_controller_output <= (is_burst_load_store_active ? burst_current_store_data: 12'b0);
    end


    // manage the state machine for the burst store and load
    // this state machine will manage the burst stores and loads and ensures that it happens for the correct amount of time
    always_ff @(posedge clock_in) begin
        if (reset_in == 1'b1) begin
            burst_current_index <= 4'd0;
            is_burst_state_machine_active <= 1'b0;
        end

        else if (opcode == `BURST_OPCODE && burst_current_index == 4'd0) begin
            burst_current_index <= 4'd1;
            is_burst_state_machine_active <= 1'b1;
        end

        else if (burst_current_index < 4'd9 && burst_current_index != 4'd0) begin
            burst_current_index <= burst_current_index + 1'b1;
        end

        else if (burst_current_index == 4'd9) begin
            burst_current_index <= 4'd0;
            is_burst_state_machine_active <= 1'b0;
        end

        else begin
            burst_current_index <= burst_current_index;
        end
    end



    tensor_core_register_file main_tensor_core_register_file (
        .clock_in(clock_in), .reset_in(reset_in),

        .dual_load_enable_in(is_burst_state_machine_active),
        .dual_load_register_address_in(burst_current_index - 4'd1),
        .dual_load_data_in(burst_current_dual_load_data),

        .bulk_store_data_out(tensor_core_register_file_bulk_store_data)
    );

    
    tensor_core main_tensor_core (
        .clock_in(clock_in),
        .reset_in(reset_in),

        .should_start_tensor_core(opcode == `TENSOR_CORE_OPCODE && !is_burst_load_store_active),

        .tensor_core_input1(tensor_core_input1), .tensor_core_input2(tensor_core_input2),
        .tensor_core_output(tensor_core_output)
    );


    genvar map_idx;
    generate
        for (map_idx = 0; map_idx < 9; map_idx++) begin : route_bulk_store_to_inputs
            assign tensor_core_input1[map_idx] = tensor_core_register_file_bulk_store_data[map_idx];
            assign tensor_core_input2[map_idx] = tensor_core_register_file_bulk_store_data[map_idx + 9];
        end
    endgenerate




    // make the registers visible to gtkwave
    genvar i, j;
    generate
        for (i = 0; i < 9; i++) begin : expose_regs
            wire [11:0] tensor_core_output_wire = tensor_core_output[i];
            wire [4:0] tensor_core_input1_wire = tensor_core_input1[i];
            wire [4:0] tensor_core_input2_wire = tensor_core_input2[i];
        end
    endgenerate

endmodule