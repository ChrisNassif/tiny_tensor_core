// TODO: IMPLEMENT TENSOR_CORE_OPERATE_MATADD_OPCODE
// TODO: IMPLEMENT NOP?



`define NOP_OPCODE 4'b0000
`define RESET_OPCODE 4'b0001

`define ADD_OPCODE 4'b0010
`define SUB_OPCODE 4'b0011
`define EQL_OPCODE 4'b0100
`define GRT_OPCODE 4'b0101

`define CPU_LOAD_OPCODE 4'b0110

`define CPU_MOV_OPCODE 4'b0111
`define CPU_READ_OPCODE 4'b1000

`define TENSOR_CORE_OPERATE_OPCODE 4'b1001
`define TENSOR_CORE_LOAD_MATRIX1_OPCODE 4'b1010
`define TENSOR_CORE_LOAD_MATRIX2_OPCODE 4'b1011
`define CPU_TO_TENSOR_CORE_OPCODE 4'b1100
`define TENSOR_CORE_TO_CPU_OPCODE 4'b1101

`define TENSOR_CORE_MOV_OPCODE 4'b1110
`define TENSOR_CORE_READ_OPCODE 4'b1111


`define BUS_WIDTH 7


module cpu (
    input logic clock_in, 
    input logic shifted_clock_in,
    input logic [15:0] current_instruction, 
    output logic signed [`BUS_WIDTH:0] cpu_output
);

    
    // DECLARATIONS
    logic signed [`BUS_WIDTH:0] alu_input1, alu_input2, alu_output;
    logic [3:0] alu_opcode;

    logic [2:0] cpu_register_file_read_register_address1, cpu_register_file_read_register_address2;
    logic signed [`BUS_WIDTH:0] cpu_register_file_read_data1, cpu_register_file_read_data2;
    logic [2:0] cpu_register_file_write_register_address;
    logic signed [`BUS_WIDTH:0] cpu_register_file_write_data;
    logic cpu_register_file_write_enable;


    logic tensor_core_clock;
    logic tensor_core_register_file_non_bulk_write_enable;
    logic signed [`BUS_WIDTH:0] tensor_core_register_file_non_bulk_write_data;
    logic [4:0] tensor_core_register_file_non_bulk_write_register_address;

    logic tensor_core_register_file_bulk_write_enable;
    logic signed [`BUS_WIDTH:0] tensor_core_register_file_bulk_write_data [2] [3] [3];
    wire signed [`BUS_WIDTH:0] tensor_core_register_file_bulk_read_data [2] [3] [3];

    logic [4:0] tensor_core_register_file_non_bulk_read_register_address;
    wire signed [`BUS_WIDTH:0] tensor_core_register_file_non_bulk_read_data;
    wire signed [`BUS_WIDTH:0] tensor_core_output [3] [3];
    logic is_tensor_core_done_with_calculation;
    
    logic signed [`BUS_WIDTH:0] tensor_core_input1 [3] [3];
    logic signed [`BUS_WIDTH:0] tensor_core_input2 [3] [3];

    logic [2:0] tensor_core_timer;
    





    // ---------------------------------------------------------------------
    // ALL OF THE STUFF FOR A CPU CORE ARE FOUND BELOW:
    // ---------------------------------------------------------------------


    assign cpu_register_file_write_register_address = current_instruction[15:13];
    assign cpu_register_file_read_register_address1 = current_instruction[10:8];
    assign cpu_register_file_read_register_address2 = current_instruction[6:4];
    assign alu_opcode = current_instruction[3:0];


    // Write enable logic - only write for CPU instructions, not tensor core operations
    assign cpu_register_file_write_enable = (
        (alu_opcode == `ADD_OPCODE) ||                   // add
        (alu_opcode == `SUB_OPCODE) ||                   // sub
        (alu_opcode == `EQL_OPCODE) ||                   // eql
        (alu_opcode == `GRT_OPCODE) ||                   // grt
        (alu_opcode == `CPU_LOAD_OPCODE) ||        // load_imm
        (alu_opcode == `CPU_MOV_OPCODE)  ||             // mov
        (alu_opcode == `TENSOR_CORE_TO_CPU_OPCODE)       // tensor_core_to_cpu
    ) ? 1'b1 : 1'b0;



    assign cpu_register_file_write_data = (
        (alu_opcode == `TENSOR_CORE_TO_CPU_OPCODE) ? tensor_core_register_file_non_bulk_read_data: 
        (alu_opcode == `CPU_LOAD_OPCODE) ? current_instruction[11:4]:
        alu_output
    );

    
    assign alu_input1 = cpu_register_file_read_data1;
    assign alu_input2 = cpu_register_file_read_data2;
    assign cpu_output = (
        (alu_opcode == `CPU_READ_OPCODE) ? cpu_register_file_read_data2:
        (alu_opcode == `TENSOR_CORE_READ_OPCODE) ? tensor_core_register_file_non_bulk_read_data:
        alu_output
    );


    alu main_alu(
        .reset_in(alu_opcode == `RESET_OPCODE), .enable_in(1'b1), 
        .opcode_in(alu_opcode), .alu_input1(alu_input1), .alu_input2(alu_input2), 
        .alu_output(alu_output)
    );


    cpu_register_file main_cpu_register_file (
        .clock_in(clock_in), .write_enable_in(cpu_register_file_write_enable), .reset_in(alu_opcode == `RESET_OPCODE),
        .read_register_address1_in(cpu_register_file_read_register_address1), .read_register_address2_in(cpu_register_file_read_register_address2),
        .write_register_address_in(cpu_register_file_write_register_address), .write_data_in(cpu_register_file_write_data), 
        .read_data1_out(cpu_register_file_read_data1), .read_data2_out(cpu_register_file_read_data2)
    );








    // ---------------------------------------------------------------------
    // ALL OF THE STUFF FOR A TENSOR CORE ARE FOUND BELOW:
    // ---------------------------------------------------------------------


    assign tensor_core_clock = (shifted_clock_in ^ clock_in);
    // assign tensor_core_clock = clock_in;


    // For the opcode of operating on the contents in the tensor core register file
    assign tensor_core_register_file_bulk_write_enable = 1'b0;


    // for the opcode of load immediate and move from cpu registers to the tensor core register file   
    assign tensor_core_register_file_non_bulk_write_enable = (
        alu_opcode == `TENSOR_CORE_LOAD_MATRIX1_OPCODE || // tensor core load immediate
        alu_opcode == `TENSOR_CORE_LOAD_MATRIX2_OPCODE || // tensor core load immediate
        alu_opcode == `CPU_TO_TENSOR_CORE_OPCODE ||       // move from cpu to tensor core
        alu_opcode == `TENSOR_CORE_MOV_OPCODE ? 1:        // move from tensor core to another tensor core register
        0
    );

    assign tensor_core_register_file_non_bulk_write_register_address = (
        (alu_opcode == `TENSOR_CORE_LOAD_MATRIX1_OPCODE) ? {current_instruction[15:12], 1'b0}:    // tensor core load immediate
        (alu_opcode == `TENSOR_CORE_LOAD_MATRIX2_OPCODE) ? {current_instruction[15:12], 1'b1}:    // tensor core load immediate

        alu_opcode == `CPU_TO_TENSOR_CORE_OPCODE ||                            // move from cpu to tensor core
        alu_opcode == `TENSOR_CORE_MOV_OPCODE ? current_instruction[15:11]:    // move from tensor core to another tensor core register
        0
    );
    // assign tensor_core_register_file_non_bulk_write_register_address = (
    //     (alu_opcode == `TENSOR_CORE_LOAD_MATRIX1_OPCODE) ? {1'b0, current_instruction[15:12]}:    // tensor core load immediate
    //     (alu_opcode == `TENSOR_CORE_LOAD_MATRIX2_OPCODE) ? {1'b1, current_instruction[15:12]}:    // tensor core load immediate
    //     (alu_opcode == `CPU_TO_TENSOR_CORE_OPCODE) ? current_instruction[15:11]:  // move from cpu to tensor core
    //     (alu_opcode == `TENSOR_CORE_MOV_OPCODE) ? current_instruction[15:11]:    // move from tensor core to another tensor core register
    //     0
    // );

    assign tensor_core_register_file_non_bulk_write_data = (
        (alu_opcode == `TENSOR_CORE_LOAD_MATRIX1_OPCODE) ? current_instruction[11:4]:     // tensor core load immediate
        (alu_opcode == `TENSOR_CORE_LOAD_MATRIX2_OPCODE) ? current_instruction[11:4]:     // tensor core load immediate
        (alu_opcode == `CPU_TO_TENSOR_CORE_OPCODE) ? cpu_register_file_read_data2:        // move from cpu to tensor core
        (alu_opcode == `TENSOR_CORE_MOV_OPCODE) ? tensor_core_register_file_non_bulk_read_data: // move from tensor core to another tensor core register
        0
    );


    assign tensor_core_register_file_non_bulk_read_register_address = current_instruction[8:4];


    
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



    
    always @(posedge clock_in) begin

        if ((alu_opcode == `RESET_OPCODE)) begin
            tensor_core_timer <= 0;
            is_tensor_core_done_with_calculation <= 1'b0;
        end

        else if (tensor_core_timer == 3'd3) begin
            tensor_core_timer <= 0;
            is_tensor_core_done_with_calculation <= 1'b0;
        end


        else if (tensor_core_timer == 3'd2) begin
            tensor_core_timer <= tensor_core_timer + 1;
            is_tensor_core_done_with_calculation <= 1'b1;
        end


        else if (tensor_core_timer == 3'd1) begin
            tensor_core_timer <= tensor_core_timer + 1;
        end


        else if (tensor_core_timer == 0 && (alu_opcode == `TENSOR_CORE_OPERATE_OPCODE)) begin
            tensor_core_timer <= tensor_core_timer + 1;
        end
    end



    tensor_core_register_file main_tensor_core_register_file (
        .clock_in(clock_in), .reset_in(alu_opcode == `RESET_OPCODE),

        .non_bulk_write_enable_in(tensor_core_register_file_non_bulk_write_enable),
        .non_bulk_write_register_address_in(tensor_core_register_file_non_bulk_write_register_address),
        .non_bulk_write_data_in(tensor_core_register_file_non_bulk_write_data),

        .non_bulk_read_register_address_in(tensor_core_register_file_non_bulk_read_register_address),
        .non_bulk_read_data_out(tensor_core_register_file_non_bulk_read_data),


        .bulk_write_enable_in(tensor_core_register_file_bulk_write_enable | is_tensor_core_done_with_calculation), 
        .bulk_write_data_in(tensor_core_register_file_bulk_write_data),

        .bulk_read_data_out(tensor_core_register_file_bulk_read_data)
    );


    small_tensor_core main_tensor_core (
        .tensor_core_clock(tensor_core_clock), .reset_in((alu_opcode == `RESET_OPCODE)),
        
        .should_start_tensor_core((alu_opcode == `TENSOR_CORE_OPERATE_OPCODE)),
        .operation_select(current_instruction[5:4]),
        .tensor_core_register_file_write_enable(tensor_core_register_file_bulk_write_enable | tensor_core_register_file_non_bulk_write_enable | alu_opcode == `RESET_OPCODE),
        
        .tensor_core_input1(tensor_core_input1), .tensor_core_input2(tensor_core_input2),
        .tensor_core_output(tensor_core_output)
    );












    // Expose the internals of this module to gtkwave
    genvar i, j, n;
    generate
        for (n = 0; n < 2; n++) begin: hi
            for (i = 0; i < 3; i++) begin : expose_tensor_core
                for (j = 0; j < 3; j++) begin: expose_tensor_core2
                    wire [`BUS_WIDTH:0] tensor_core_register_file_bulk_read_data_ = tensor_core_register_file_bulk_read_data[n][i][j];
                    wire [`BUS_WIDTH:0] tensor_core_output_ = tensor_core_output[i][j];
                end
            end
        end
    endgenerate



endmodule

