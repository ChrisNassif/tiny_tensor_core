`define ADD_OPCODE 8'b00000000
`define SUB_OPCODE 8'b00000001
`define MUL_OPCODE 8'b00000010
`define EQL_OPCODE 8'b00000011
`define GRT_OPCODE 8'b00000100

`define TENSOR_CORE_OPERATE_OPCODE 8'b00000101
`define TENSOR_CORE_LOAD_OPCODE 8'b00000110
`define CPU_TO_TENSOR_CORE_OPCODE 8'b00000111
`define TENSOR_CORE_TO_CPU_OPCODE 8'b00001101
`define NOP_OPCODE 8'b00001000

`define ADD_IMM_OPCODE 8'b00001001
`define SUB_IMM_OPCODE 8'b00001010

`define MOV_OPCODE 8'b00001011
`define RESET_OPCODE 8'b00001100

`define BUS_WIDTH 7



module cpu (
    input logic clock_in, 
    input logic shifted_clock_in,
    input logic [31:0] current_instruction, 
    output logic signed [`BUS_WIDTH:0] cpu_output,
    output logic signed [`BUS_WIDTH:0] tensor_core_result [4] [4]
);
    // TODO, there is a bug if you try to write to a tensor core register when small_tensor_core_mma is done with the matrix???

    
    // DECLARATIONS
    logic signed [`BUS_WIDTH:0] alu_input1, alu_input2, alu_output;
    logic [7:0] alu_opcode;
    logic is_add_immediate;
    logic is_sub_immediate; 

    logic [7:0] cpu_register_file_read_register_address1, cpu_register_file_read_register_address2;
    logic signed [`BUS_WIDTH:0] cpu_register_file_read_data1, cpu_register_file_read_data2;
    logic [7:0] cpu_register_file_write_register_address;
    logic signed [`BUS_WIDTH:0] cpu_register_file_write_data;
    logic cpu_register_file_write_enable;


    logic tensor_core_clock;
    logic tensor_core_register_file_non_bulk_write_enable;
    logic signed [`BUS_WIDTH:0] tensor_core_register_file_non_bulk_write_data;
    logic [4:0] tensor_core_register_file_non_bulk_write_register_address;

    logic tensor_core_register_file_bulk_write_enable;
    logic signed [`BUS_WIDTH:0] tensor_core_register_file_bulk_write_data [2] [4] [4];
    wire signed [`BUS_WIDTH:0] tensor_core_register_file_read_data [2] [4] [4];
    wire signed [`BUS_WIDTH:0] tensor_core_output [4] [4];
    wire is_tensor_core_done_with_calculation;
    
    logic signed [`BUS_WIDTH:0] tensor_core_input1 [4] [4];
    logic signed [`BUS_WIDTH:0] tensor_core_input2 [4] [4];

    logic alu_overflow_flag, alu_carry_flag, alu_zero_flag, alu_sign_flag;
    logic alu_parity_flag;
    
    
    // Status register to store flags  
    logic [3:0] status_register;  // [3] overflow, [2] carry, [1] zero, [0] sign




    alu main_alu(
        .reset_in(alu_opcode == `RESET_OPCODE), .enable_in(1'b1), 
        .opcode_in(alu_opcode), .alu_input1(alu_input1), .alu_input2(alu_input2), 
        .alu_output(alu_output), 
        .overflow_flag(alu_overflow_flag),   
        .carry_flag(alu_carry_flag),
        .zero_flag(alu_zero_flag),
        .sign_flag(alu_sign_flag),
        .parity_flag(alu_parity_flag)
    );


    cpu_register_file main_cpu_register_file (
        .clock_in(clock_in), .write_enable_in(cpu_register_file_write_enable), .reset_in(alu_opcode == `RESET_OPCODE),
        .read_register_address1_in(cpu_register_file_read_register_address1), .read_register_address2_in(cpu_register_file_read_register_address2),
        .write_register_address_in(cpu_register_file_write_register_address), .write_data_in(cpu_register_file_write_data), 
        .read_data1_out(cpu_register_file_read_data1), .read_data2_out(cpu_register_file_read_data2)
    );


    assign cpu_register_file_write_register_address = current_instruction[31:24];
    assign cpu_register_file_read_register_address1 = current_instruction[23:16];
    assign cpu_register_file_read_register_address2 = current_instruction[15:8];
    assign alu_opcode = current_instruction[7:0];


    // Check if this is an add immediate instruction (opcode 9)
    assign is_add_immediate = (alu_opcode == `ADD_IMM_OPCODE);
    assign is_sub_immediate = (alu_opcode == `SUB_IMM_OPCODE);
    
    // Write enable logic - only write for CPU instructions, not tensor core operations
    assign cpu_register_file_write_enable = (
        (alu_opcode == `ADD_OPCODE) ||             // add
        (alu_opcode == `SUB_OPCODE) ||             // sub  
        (alu_opcode == `MUL_OPCODE) ||             // mul
        (alu_opcode == `EQL_OPCODE) ||             // eql
        (alu_opcode == `GRT_OPCODE) ||             // grt
        (alu_opcode == `ADD_IMM_OPCODE) ||         // add_imm
        (alu_opcode == `SUB_IMM_OPCODE) ||         // sub_imm
        (alu_opcode == `MOV_OPCODE) ||             // mov
        (alu_opcode == `TENSOR_CORE_TO_CPU_OPCODE) // tensor_core_to_cpu
    ) ? 1'b1 : 1'b0;


    // assign cpu_register_file_write_data = (alu_opcode == `TENSOR_CORE_TO_CPU_OPCODE) ? : alu_output;
    assign cpu_register_file_write_data = alu_output;

    
    assign alu_input1 = cpu_register_file_read_data1;      // TODO CHANGE THIS BACK TO register_file_read_data1 ONCE ADD IMMEDIATE IS ADDED
    assign alu_input2 = (is_add_immediate | is_sub_immediate) ? current_instruction[15:8] : cpu_register_file_read_data2;
    assign cpu_output = alu_output;

    always_ff @(posedge clock_in) begin
        if (cpu_register_file_write_enable) begin
            status_register[4] <= alu_parity_flag;
            status_register[3] <= alu_overflow_flag;
            status_register[2] <= alu_carry_flag;
            status_register[1] <= alu_zero_flag;
            status_register[0] <= alu_sign_flag;
        end
    end






    // ALL OF THE STUFF FOR A TENSOR CORE ARE FOUND BELOW:

    tensor_core_register_file main_tensor_core_register_file (
        .clock_in(clock_in), .reset_in(alu_opcode == `RESET_OPCODE),
        .non_bulk_write_enable_in(tensor_core_register_file_non_bulk_write_enable),
        .non_bulk_write_register_address_in(tensor_core_register_file_non_bulk_write_register_address),
        .non_bulk_write_data_in(tensor_core_register_file_non_bulk_write_data),

        .bulk_write_enable_in(tensor_core_register_file_bulk_write_enable | is_tensor_core_done_with_calculation), .bulk_write_data_in(tensor_core_register_file_bulk_write_data),
        .read_data_out(tensor_core_register_file_read_data)
    );


    small_tensor_core main_tensor_core (
        .clock_in(tensor_core_clock), 
        .tensor_core_register_file_write_enable(tensor_core_register_file_bulk_write_enable | tensor_core_register_file_non_bulk_write_enable),
        .tensor_core_input1(tensor_core_input1), .tensor_core_input2(tensor_core_input2),
        .tensor_core_output(tensor_core_output), .is_done_with_calculation(is_tensor_core_done_with_calculation)
    );

    assign tensor_core_clock = shifted_clock_in ^ clock_in;
    // assign tensor_core_clock = clock_in;

    // For the opcode of operating on the contents in the tensor core register file
    assign tensor_core_register_file_bulk_write_enable = 1'b0;



    // for the opcode of load immediate and move from cpu registers to the tensor core register file   
    assign tensor_core_register_file_non_bulk_write_enable = (
        (alu_opcode == `TENSOR_CORE_LOAD_OPCODE) ? 1'b1: // tensor core load immediate
        (alu_opcode == `CPU_TO_TENSOR_CORE_OPCODE) ? 1'b1: // move from cpu to tensor core
        1'b0
    );

    assign tensor_core_register_file_non_bulk_write_register_address = (
        (alu_opcode == `TENSOR_CORE_LOAD_OPCODE) ? current_instruction[28:24]: // tensor core load immediate
        (alu_opcode == `CPU_TO_TENSOR_CORE_OPCODE) ? current_instruction[28:24]: // move from cpu to tensor core
        5'b0
    );

    assign tensor_core_register_file_non_bulk_write_data = (
        (alu_opcode == `TENSOR_CORE_LOAD_OPCODE) ? current_instruction[23:16]: // tensor core load immediate
        (alu_opcode == `CPU_TO_TENSOR_CORE_OPCODE) ? cpu_register_file_read_data1: // move from cpu to tensor core
        8'b0
    );


    // wire up the tensor_core_register_file_bulk_write_data and tensor core inputs correctly
    initial begin
        for (int i = 0; i < 4; i++) begin
            for (int j = 0; j < 4; j++) begin
                tensor_core_register_file_bulk_write_data[0][i][j] = 8'b0;
                tensor_core_register_file_bulk_write_data[1][i][j] = 8'b0;

                tensor_core_input1[i][j] = 8'b0;
                tensor_core_input2[i][j] = 8'b0;
            end
        end
    end
    always_comb begin
        for (int i = 0; i < 4; i++) begin
            for (int j = 0; j < 4; j++) begin
                tensor_core_register_file_bulk_write_data[0][i][j] = tensor_core_output[i][j];
                tensor_core_register_file_bulk_write_data[1][i][j] = tensor_core_register_file_read_data[1][i][j];

                tensor_core_input1[i][j] = tensor_core_register_file_read_data[0][i][j];
                tensor_core_input2[i][j] = tensor_core_register_file_read_data[1][i][j];
            end
        end
    

    end












    // Expose the internals of this module to gtkwave
    genvar i, j, n;
    generate
        for (n = 0; n < 2; n++) begin: hi
            for (i = 0; i < 4; i++) begin : expose_tensor_core
                for (j = 0; j < 4; j++) begin: expose_tensor_core2
                    wire [7:0] tensor_core_register_file_read_data_ = tensor_core_register_file_read_data[n][i][j];
                    wire [7:0] tensor_core_output_ = tensor_core_output[i][j];
                end
            end
        end
    endgenerate



endmodule

