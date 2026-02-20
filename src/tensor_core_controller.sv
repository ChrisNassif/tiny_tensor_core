`define NOP_OPCODE 3'b000
`define TENSOR_CORE_OPCODE 3'b001
`define BURST_OPCODE 3'b010

`define BUS_WIDTH 7



// TODO: OUTPUT IS ONLY 33 MHz
module tensor_core_controller (
    input logic clock_in, 
    input logic reset_in,
    input logic [15:0] current_instruction, 
    output logic signed [`BUS_WIDTH:0] tensor_core_controller_output
);



    // DECLARATIONS
    logic tensor_core_register_file_bulk_load_enable;
    logic signed [`BUS_WIDTH:0] tensor_core_register_file_bulk_load_data [2] [3] [3];
    
    wire signed [`BUS_WIDTH:0] tensor_core_register_file_bulk_store_data [2] [3] [3];
    wire signed [`BUS_WIDTH*2+1:0] tensor_core_output [3] [3];
    logic signed [`BUS_WIDTH:0] tensor_core_input1 [3] [3];
    logic signed [`BUS_WIDTH:0] tensor_core_input2 [3] [3];


    // used for the burst instruction state machine
    logic is_burst_load_active;
    logic is_burst_store_active;
    logic [3:0] burst_current_index; // stores the current index that the burst opcode is looking at either for storing or loading
    logic [`BUS_WIDTH:0] burst_load_negative_storage [2];

    wire signed [`BUS_WIDTH:0] burst_current_dual_store_data [2];
    wire signed [`BUS_WIDTH:0] burst_current_quad_load_data [4];
    
    
    wire [2:0] burst_quad_load_address;
    wire [`BUS_WIDTH:0] burst_quad_load_data [4];

    wire [3:0] burst_dual_store_address; 




    wire [1:0] opcode;

    assign opcode = current_instruction[2:0];

    assign burst_current_quad_load_data[0] = burst_load_negative_storage[0];
    assign burst_current_quad_load_data[1] = burst_load_negative_storage[1];
    assign burst_current_quad_load_data[2] = current_instruction[15:8];
    assign burst_current_quad_load_data[3] = current_instruction[7:0];


    assign burst_current_dual_store_data[0] = tensor_core_output[(burst_current_index%9)/3][(burst_current_index)%3][15:8];
    assign burst_current_dual_store_data[1] = tensor_core_output[(burst_current_index%9)/3][(burst_current_index)%3][7:0];

    assign tensor_core_controller_output = (is_burst_store_active ? burst_current_dual_store_data[~clock_in]: 8'b0);


    // manage the state machine for the burst store and load
    // this state machine will manage the burst stores and loads and ensures that it happens for the correct amount of time
    always_ff @(posedge clock_in) begin
        
        if (reset_in) begin
            burst_current_index <= 9;
            is_burst_store_active <= 0;
            is_burst_load_active <= 0;
        end

        else if (opcode == `BURST_OPCODE && (burst_current_index == 9 || burst_current_index == 8)) begin
            burst_current_index <= 0;
            is_burst_load_active <= 1;
            is_burst_store_active <= 1;
        end

        // handles burst store_load
        else if (burst_current_index == 4) begin
            burst_current_index <= burst_current_index + 1;
            is_burst_load_active <= 0;
        end

        else if (burst_current_index < 8) begin
            burst_current_index <= burst_current_index + 1;
        end

        else if (burst_current_index == 8) begin
            burst_current_index <= burst_current_index + 1;
            is_burst_store_active <= 0;
            is_burst_load_active <= 0;
        end

    end



    always_ff @(negedge clock_in) begin
        burst_load_negative_storage[0] <= current_instruction[15:8];
        burst_load_negative_storage[1] <= current_instruction[7:0];
    end
 


    tensor_core_register_file main_tensor_core_register_file (
        .clock_in(clock_in), .reset_in(reset_in),

        .quad_load_enable_in(is_burst_load_active),
        .quad_load_register_address_in(burst_current_index[2:0]),
        .quad_load_data_in(burst_current_quad_load_data),

        .bulk_store_data_out(tensor_core_register_file_bulk_store_data)
    );


    tensor_core main_tensor_core (
        .clock_in(clock_in),
        .reset_in(reset_in),

        .should_start_tensor_core(opcode == `TENSOR_CORE_OPCODE && (!is_burst_load_active || burst_current_index == 8)),

        .tensor_core_input1(tensor_core_input1), .tensor_core_input2(tensor_core_input2),
        .tensor_core_output(tensor_core_output)
    );


    always_comb begin
        for (int i = 0; i < 3; i++) begin
            for (int j = 0; j < 3; j++) begin
                tensor_core_input1[i][j] = tensor_core_register_file_bulk_store_data[0][i][j];
                tensor_core_input2[i][j] = tensor_core_register_file_bulk_store_data[1][i][j];
            end
        end
    end















    // Expose the internals of this module to gtkwave
    genvar i, j, n, a, b;
    generate
        for (n = 0; n < 2; n++) begin: expose_matrix_index
            for (i = 0; i < 3; i++) begin : expose_tensor_core
                for (j = 0; j < 3; j++) begin: expose_tensor_core2
                    wire [`BUS_WIDTH:0] tensor_core_register_file_bulk_store_data_ = tensor_core_register_file_bulk_store_data[n][i][j];
                    // wire [`BUS_WIDTH:0] tensor_core_output_ = tensor_core_output[i][j];
                end
            end
        end

        for (a = 0; a < 2; a++) begin: hi
            wire signed [`BUS_WIDTH:0] burst_current_dual_store_data_ = burst_current_dual_store_data[a];
        end

        for (b = 0; b < 4; b++) begin: h2
            wire signed [`BUS_WIDTH:0] burst_current_quad_load_data_ = burst_current_quad_load_data[b];
        end
    endgenerate



endmodule

