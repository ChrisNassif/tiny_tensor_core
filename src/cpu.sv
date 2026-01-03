`define GENERIC_OPCODE 2'b00
`define LOAD_IMMEDIATE_OPCODE 2'b01
`define TENSOR_CORE_OPERATE_OPCODE 2'b10
`define BURST_OPCODE 2'b11


`define GENERIC_NOP_OPSELECT 2'b00
`define GENERIC_MOVE_OPSELECT 2'b01
`define GENERIC_READ_OPSELECT 2'b10
`define GENERIC_RESET_OPSELECT 2'b11

`define BURST_READ_SELECT 1'b0
`define BURST_WRITE_SELECT 1'b1

// these aren't used rn
`define BURST_MATRIX1_SELECT 2'b00
`define BURST_MATRIX2_SELECT 2'b01
`define BURST_BOTH_MATRICES_SELECT 2'b10


`define BUS_WIDTH 7




module cpu (
    input logic clock_in, 
    input logic shifted_clock_in,
    input logic [15:0] current_instruction, 
    output logic signed [`BUS_WIDTH:0] cpu_output
);

    
    // DECLARATIONS

    logic tensor_core_clock;

    logic tensor_core_register_file_non_bulk_write_enable;
    logic signed [`BUS_WIDTH:0] tensor_core_register_file_non_bulk_write_data;
    logic [4:0] tensor_core_register_file_non_bulk_write_register_address;

    logic [4:0] tensor_core_register_file_non_bulk_read_register_address;
    wire signed [`BUS_WIDTH:0] tensor_core_register_file_non_bulk_read_data;

    logic tensor_core_register_file_bulk_write_enable;
    logic signed [`BUS_WIDTH:0] tensor_core_register_file_bulk_write_data [2] [3] [3];  // TODO: This should probably be turned into a wire for better clarity 
    
    wire signed [`BUS_WIDTH:0] tensor_core_register_file_bulk_read_data [2] [3] [3];
    wire signed [`BUS_WIDTH:0] tensor_core_output [3] [3];
    logic signed [`BUS_WIDTH:0] tensor_core_input1 [3] [3];
    logic signed [`BUS_WIDTH:0] tensor_core_input2 [3] [3];

    // used for the state machine that waits for the tensor core to finish operating on the matrices
    logic signed [3:0] tensor_core_timer;
    logic is_tensor_core_done_with_calculation; 



    // used for the burst instruction state machine
    logic is_burst_write_active;
    logic is_burst_read_active;
    logic [3:0] burst_current_index; // stores the current index that the burst opcode is looking at either for reading or writing
    logic [`BUS_WIDTH:0] burst_write_negative_storage [2];


    // wire [1:0] burst_matrix_select;
    wire burst_read_write_select;

    wire signed [`BUS_WIDTH:0] burst_current_dual_read_data [2];
    wire signed [`BUS_WIDTH:0] burst_current_quad_write_data [4];
    
    wire [2:0] burst_quad_write_address;
    wire [`BUS_WIDTH:0] burst_quad_write_data [4];

    wire [3:0] burst_dual_read_address; 




    wire [1:0] opcode;
    wire [1:0] generic_opselect;
    wire [2:0] operate_opselect;


    assign tensor_core_clock = (shifted_clock_in ^ clock_in);


    assign opcode = current_instruction[1:0];
    assign generic_opselect = current_instruction[3:2];
    assign operate_opselect = current_instruction[4:2];
    assign burst_matrix_select = current_instruction[4:3];
    assign burst_read_write_select = current_instruction[2];

    assign burst_current_quad_write_data[0] = burst_write_negative_storage[0];
    assign burst_current_quad_write_data[1] = burst_write_negative_storage[1];
    assign burst_current_quad_write_data[2] = current_instruction[15:8];
    assign burst_current_quad_write_data[3] = current_instruction[7:0];

    assign cpu_output = (
        (opcode == `GENERIC_OPCODE && generic_opselect == `GENERIC_READ_OPSELECT) ? tensor_core_register_file_non_bulk_read_data:
        (is_burst_read_active) ? burst_current_dual_read_data[~clock_in]:
        8'b0
    );


    assign tensor_core_register_file_non_bulk_read_register_address = (
        opcode == `GENERIC_OPCODE ? current_instruction[10:6]:
        8'b0
    );


    // For the opcode of operating on the contents in the tensor core register file
    assign tensor_core_register_file_bulk_write_enable = 1'b0;


    // for the opcode of load immediate and move from cpu registers to the tensor core register file   
    assign tensor_core_register_file_non_bulk_write_enable = (
        (opcode == `LOAD_IMMEDIATE_OPCODE) ||                                                   // tensor core load immediate
        (opcode == `GENERIC_OPCODE && generic_opselect == `GENERIC_MOVE_OPSELECT) ? 1:        // move from tensor core to another tensor core register
        0
    );


    assign tensor_core_register_file_non_bulk_write_register_address = (
        (opcode == `LOAD_IMMEDIATE_OPCODE) ? current_instruction[15:11]:    // tensor core load immediate
        (opcode == `GENERIC_OPCODE) ? current_instruction[15:11]:           // generic opcodes
        0
    );


    assign tensor_core_register_file_non_bulk_write_data = (
        (opcode == `LOAD_IMMEDIATE_OPCODE) ? current_instruction[10:3]:     // tensor core load immediate
        (opcode == `GENERIC_OPCODE) ? tensor_core_register_file_non_bulk_read_data: // move from tensor core to another tensor core register
        0
    );



    
    always_comb begin
        for (int i = 0; i < 3; i++) begin
            for (int j = 0; j < 3; j++) begin
                tensor_core_register_file_bulk_write_data[0][i][j] = tensor_core_output[i][j];
                tensor_core_register_file_bulk_write_data[1][i][j] = tensor_core_register_file_bulk_read_data[1][i][j];

                tensor_core_input1[i][j] = tensor_core_register_file_bulk_read_data[0][i][j];
                tensor_core_input2[i][j] = tensor_core_register_file_bulk_read_data[1][i][j];
            end
        end
    end


    
    // manage the state machine for the burst read and write
    // this state machine will manage the burst reads and writes and ensures that it happens for the correct amount of time
    always_ff @(posedge clock_in) begin

        if (opcode == `GENERIC_OPCODE && generic_opselect == `GENERIC_RESET_OPSELECT) begin
            burst_current_index <= 9;
            is_burst_read_active <= 0;
            is_burst_write_active <= 0;
        end

        else if (opcode == `BURST_OPCODE && burst_read_write_select == `BURST_READ_SELECT && burst_current_index == 9) begin
            burst_current_index <= 0;
            is_burst_read_active <= 1;
        end

        else if (is_burst_read_active && burst_current_index < 8) begin
            burst_current_index <= burst_current_index + 1;
        end

        else if (is_burst_read_active && burst_current_index == 8) begin
            burst_current_index <= burst_current_index + 1;
            is_burst_read_active <= 0;
        end



        else if (opcode == `BURST_OPCODE && burst_read_write_select == `BURST_WRITE_SELECT && burst_current_index == 9) begin
            is_burst_write_active <= 1;
            burst_current_index <= 0;
        end

        else if (is_burst_write_active && burst_current_index < 4) begin
            burst_current_index <= burst_current_index + 1;
        end

        else if (is_burst_write_active && burst_current_index == 4) begin
            burst_current_index <= 9;
            is_burst_write_active <= 0;
        end
    end


    always_ff @(negedge clock_in) begin
        burst_write_negative_storage[0] <= current_instruction[15:8];
        burst_write_negative_storage[1] <= current_instruction[7:0];
    end





    // manage the tensor core timer state machine
    // this state machine waits for the tensor core to finish its calculation and then write the data to the tensor core register file at the correct time
    always_ff @(posedge clock_in) begin

        if ((opcode == `GENERIC_OPCODE && generic_opselect == `GENERIC_RESET_OPSELECT)) begin
            tensor_core_timer <= 0;
            is_tensor_core_done_with_calculation <= 1'b0;
        end

        else if (tensor_core_timer == 0 && opcode == `TENSOR_CORE_OPERATE_OPCODE && is_burst_write_active == 1'b0) begin
            tensor_core_timer <= tensor_core_timer + 1;
        end

        else if (tensor_core_timer == 3'd5 && opcode == `TENSOR_CORE_OPERATE_OPCODE && is_burst_write_active == 1'b0) begin
            tensor_core_timer <= 3'd1;
            is_tensor_core_done_with_calculation <= 1'b0;
        end

        else if (tensor_core_timer == 3'd5) begin
            tensor_core_timer <= 0;
            is_tensor_core_done_with_calculation <= 1'b0;
        end


        else if (tensor_core_timer == 3'd4) begin
            tensor_core_timer <= tensor_core_timer + 1;
            is_tensor_core_done_with_calculation <= 1'b1;
        end


        else if (tensor_core_timer >= 3'd1 && tensor_core_timer <= 3'd3) begin
            tensor_core_timer <= tensor_core_timer + 1;
        end
    end

 

 


    tensor_core_register_file main_tensor_core_register_file (
        .clock_in(clock_in), .reset_in((opcode == `GENERIC_OPCODE && generic_opselect == `GENERIC_RESET_OPSELECT)),

        .non_bulk_write_enable_in(tensor_core_register_file_non_bulk_write_enable && is_burst_write_active == 1'b0),
        .non_bulk_write_register_address_in(tensor_core_register_file_non_bulk_write_register_address),
        .non_bulk_write_data_in(tensor_core_register_file_non_bulk_write_data),

        .non_bulk_read_register_address_in(tensor_core_register_file_non_bulk_read_register_address),
        .non_bulk_read_data_out(tensor_core_register_file_non_bulk_read_data),

        .quad_write_enable_in(is_burst_write_active),
        .quad_write_register_address_in(burst_current_index[2:0]),
        .quad_write_data_in(burst_current_quad_write_data),

        .dual_read_register_address_in(burst_current_index),
        .dual_read_data_out(burst_current_dual_read_data),

        .bulk_write_enable_in((tensor_core_register_file_bulk_write_enable | is_tensor_core_done_with_calculation) && is_burst_write_active == 1'b0), 
        .bulk_write_data_in(tensor_core_register_file_bulk_write_data),

        .bulk_read_data_out(tensor_core_register_file_bulk_read_data)
    );


    small_tensor_core main_tensor_core (
        .clock_in(clock_in),
        .reset_in(opcode == `GENERIC_OPCODE && generic_opselect == `GENERIC_RESET_OPSELECT),

        .should_start_tensor_core(opcode == `TENSOR_CORE_OPERATE_OPCODE && is_burst_write_active == 1'b0),
        .matrix_operation_select(current_instruction[4:2]),
        // .tensor_core_register_file_write_enable(tensor_core_register_file_bulk_write_enable | is_burst_write_active | tensor_core_register_file_non_bulk_write_enable | (opcode == `GENERIC_OPCODE && generic_opselect == `GENERIC_RESET_OPSELECT)),
        
        .tensor_core_input1(tensor_core_input1), .tensor_core_input2(tensor_core_input2),
        .tensor_core_output(tensor_core_output)
    );















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

