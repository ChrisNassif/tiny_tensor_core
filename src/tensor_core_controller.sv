`define NOP_OPCODE 2'b00
`define TENSOR_CORE_OPERATE_OPCODE 2'b01
`define BURST_OPCODE 2'b10

`define BURST_READ_SELECT 2'b00
`define BURST_WRITE_SELECT 2'b01
`define BURST_READ_AND_WRITE_SELECT 2'b10
`define BURST_MATRIX1_WRITE_SELECT 2'b11


`define BUS_WIDTH 7



// TODO: OUTPUT IS ONLY 33 MHz
// TODO: Potential optimization: make it so that we can read while doing a tensor core operation 
//       and then have a write operation that only writes to matrix1
//       so that 1 operation is approximately on average 1 half write + 1 tensor core operation
module tensor_core_controller (
    input logic clock_in, 
    input logic reset_in,
    input logic [15:0] current_instruction, 
    output logic signed [`BUS_WIDTH:0] tensor_core_controller_output
);



    // DECLARATIONS
    logic tensor_core_register_file_bulk_write_enable;
    logic signed [`BUS_WIDTH:0] tensor_core_register_file_bulk_write_data [2] [3] [3];
    
    wire signed [`BUS_WIDTH:0] tensor_core_register_file_bulk_read_data [2] [3] [3];
    wire signed [`BUS_WIDTH:0] tensor_core_output [3] [3];
    logic signed [`BUS_WIDTH:0] tensor_core_input1 [3] [3];
    logic signed [`BUS_WIDTH:0] tensor_core_input2 [3] [3];


    // used for the burst instruction state machine
    logic is_burst_write_active;
    logic is_burst_read_active;
    logic [3:0] burst_current_index; // stores the current index that the burst opcode is looking at either for reading or writing
    logic [`BUS_WIDTH:0] burst_write_negative_storage [2];
    // logic should_restrict_quad_write_to_matrix1;

    wire [1:0] burst_read_write_select;

    wire signed [`BUS_WIDTH:0] burst_current_dual_read_data [2];
    wire signed [`BUS_WIDTH:0] burst_current_quad_write_data [4];
    
    wire [2:0] burst_quad_write_address;
    wire [`BUS_WIDTH:0] burst_quad_write_data [4];

    wire [3:0] burst_dual_read_address; 




    wire [1:0] opcode;
    wire [1:0] generic_opselect;
    wire [2:0] operate_opselect;

    assign opcode = current_instruction[1:0];
    assign generic_opselect = current_instruction[3:2];
    assign operate_opselect = current_instruction[4:2];
    assign burst_read_write_select = current_instruction[3:2];

    assign burst_current_quad_write_data[0] = burst_write_negative_storage[0];
    assign burst_current_quad_write_data[1] = burst_write_negative_storage[1];
    assign burst_current_quad_write_data[2] = current_instruction[15:8];
    assign burst_current_quad_write_data[3] = current_instruction[7:0];


    assign burst_current_dual_read_data[0] = tensor_core_output[(((burst_current_index<<1))%9)/3][((burst_current_index<<1))%3];
    assign burst_current_dual_read_data[1] = tensor_core_output[(((burst_current_index<<1)+1)%9)/3][((burst_current_index<<1)+1)%3];

    assign tensor_core_controller_output = (is_burst_read_active ? burst_current_dual_read_data[~clock_in]: 8'b0);


    // manage the state machine for the burst read and write
    // this state machine will manage the burst reads and writes and ensures that it happens for the correct amount of time
    always_ff @(posedge clock_in) begin

        if (reset_in) begin
            burst_current_index <= 5;
            is_burst_read_active <= 0;
            is_burst_write_active <= 0;
            // should_restrict_quad_write_to_matrix1 <= 0;
        end

        else if (opcode == `BURST_OPCODE && burst_read_write_select == `BURST_READ_SELECT && burst_current_index == 5) begin
            burst_current_index <= 0;
            is_burst_read_active <= 1;
        end

        else if (opcode == `BURST_OPCODE && burst_read_write_select == `BURST_WRITE_SELECT && burst_current_index == 5) begin
            burst_current_index <= 0;
            is_burst_write_active <= 1;
            // should_restrict_quad_write_to_matrix1 <= 0;
        end


        else if (opcode == `BURST_OPCODE && burst_read_write_select == `BURST_READ_AND_WRITE_SELECT && burst_current_index == 5) begin
            is_burst_write_active <= 1;
            is_burst_read_active <= 1;
            burst_current_index <= 0;
            // should_restrict_quad_write_to_matrix1 <= 0;
        end

        // else if (opcode == `BURST_OPCODE && burst_read_write_select == `BURST_READ_MATRIX1_SELECT && burst_current_index == 5) begin
        //     is_burst_write_active <= 1;
        //     is_burst_read_active <= 1;
        //     burst_current_index <= 0;
        //     should_restrict_quad_write_to_matrix1 <= 1;
        // end

        // else if ((is_burst_write_active && should_restrict_quad_write_to_matrix1) && burst_current_index < 4) begin
        //     burst_current_index <= 5;
        //     is_burst_read_active <= 0;
        //     is_burst_write_active <= 0;
        // end

        // else if ((is_burst_write_active && should_restrict_quad_write_to_matrix1) && burst_current_index < 4) begin
        //     burst_current_index <= 5;
        //     is_burst_read_active <= 0;
        //     is_burst_write_active <= 0;
        // end

        else if ((is_burst_read_active || is_burst_write_active) && burst_current_index < 4) begin
            burst_current_index <= burst_current_index + 1;
        end

        else if ((is_burst_read_active || is_burst_write_active) && burst_current_index == 4) begin
            burst_current_index <= burst_current_index + 1;
            is_burst_read_active <= 0;
            is_burst_write_active <= 0;
        end
    end



    always_ff @(negedge clock_in) begin
        burst_write_negative_storage[0] <= current_instruction[15:8];
        burst_write_negative_storage[1] <= current_instruction[7:0];
    end
 


    tensor_core_register_file main_tensor_core_register_file (
        .clock_in(clock_in), .reset_in(reset_in),

        .quad_write_enable_in(is_burst_write_active),
        .quad_write_register_address_in(burst_current_index[2:0]),
        .quad_write_data_in(burst_current_quad_write_data),
        // .should_restrict_quad_write_to_matrix1(should_restrict_quad_write_to_matrix1),

        .bulk_read_data_out(tensor_core_register_file_bulk_read_data)
    );


    small_tensor_core main_tensor_core (
        .clock_in(clock_in),
        .reset_in(reset_in),

        .should_start_tensor_core(opcode == `TENSOR_CORE_OPERATE_OPCODE && is_burst_write_active == 1'b0),
        .matrix_operation_select(current_instruction[3:2]),

        .tensor_core_input1(tensor_core_input1), .tensor_core_input2(tensor_core_input2),
        .tensor_core_output(tensor_core_output)
    );


    always_comb begin
        for (int i = 0; i < 3; i++) begin
            for (int j = 0; j < 3; j++) begin
                tensor_core_input1[i][j] = tensor_core_register_file_bulk_read_data[0][i][j];
                tensor_core_input2[i][j] = tensor_core_register_file_bulk_read_data[1][i][j];
            end
        end
    end















    // Expose the internals of this module to gtkwave
    genvar i, j, n, a, b;
    generate
        for (n = 0; n < 2; n++) begin: expose_matrix_index
            for (i = 0; i < 3; i++) begin : expose_tensor_core
                for (j = 0; j < 3; j++) begin: expose_tensor_core2
                    wire [`BUS_WIDTH:0] tensor_core_register_file_bulk_read_data_ = tensor_core_register_file_bulk_read_data[n][i][j];
                    // wire [`BUS_WIDTH:0] tensor_core_output_ = tensor_core_output[i][j];
                end
            end
        end

        for (a = 0; a < 2; a++) begin: hi
            wire signed [`BUS_WIDTH:0] burst_current_dual_read_data_ = burst_current_dual_read_data[a];
        end

        for (b = 0; b < 4; b++) begin: h2
            wire signed [`BUS_WIDTH:0] burst_current_quad_write_data_ = burst_current_quad_write_data[b];
        end
    endgenerate



endmodule

