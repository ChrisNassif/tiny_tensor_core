module cpu (
    input logic clock_in, 
    input logic [31:0] current_instruction, 
    output logic [7:0] cpu_output,
    output logic [7:0] tensor_core_result [4] [4]
);

    // TODO add code to support immediate instructions

    // DECLARATIONS
    logic [7:0] alu_input1, alu_input2, alu_output;
    logic [7:0] alu_opcode;

    logic [7:0] cpu_register_file_read_register_address1, cpu_register_file_read_register_address2;
    logic [7:0] cpu_register_file_read_data1, cpu_register_file_read_data2;
    logic [7:0] cpu_register_file_write_register_address;
    logic [7:0] cpu_register_file_write_data;
    logic cpu_register_file_write_enable;


    logic tensor_core_register_file_non_bulk_write_enable;
    logic [7:0] tensor_core_register_file_non_bulk_write_data;
    logic [4:0] tensor_core_register_file_non_bulk_write_register_address;

    logic tensor_core_register_file_bulk_write_enable;
    logic [7:0] tensor_core_register_file_bulk_write_data [2] [4] [4];
    wire [7:0] tensor_core_register_file_read_data [2] [4] [4];
    wire [7:0] tensor_core_output [4] [4];

    logic [7:0] tensor_core_input1 [4] [4];
    logic [7:0] tensor_core_input2 [4] [4];


    alu main_alu(
        .clock_in(clock_in), .reset_in(1'b0), .enable_in(1'b1), 
        .opcode_in(alu_opcode), .alu_input1(alu_input1), .alu_input2(alu_input2), 
        .alu_output(alu_output)
    );


    cpu_register_file main_cpu_register_file (
        .clock_in(clock_in), .write_enable_in(cpu_register_file_write_enable), 
        .read_register_address1_in(cpu_register_file_read_register_address1), .read_register_address2_in(cpu_register_file_read_register_address2),
        .write_register_address_in(cpu_register_file_write_register_address), .write_data_in(cpu_register_file_write_data), 
        .read_data1_out(cpu_register_file_read_data1), .read_data2_out(cpu_register_file_read_data2)
    );


    assign cpu_register_file_write_register_address = current_instruction[31:24];
    assign cpu_register_file_read_register_address1 = current_instruction[23:16];
    assign cpu_register_file_read_register_address2 = current_instruction[15:8];
    assign alu_opcode = current_instruction[7:0];


    assign cpu_register_file_write_enable = 1'b1;       // TODO THIS OBVIOUSLY NEEDS TO BE CHANGED LATER
    assign alu_input1 = current_instruction[23:16];     // TODO CHANGE THIS BACK TO register_file_read_data1 ONCE ADD IMMEDIATE IS ADDED
    assign alu_input2 = cpu_register_file_read_data2;
    assign cpu_register_file_write_data = alu_output;
    assign cpu_output = alu_output;






    // ALL OF THE STUFF FOR A TENSOR CORE ARE FOUND BELOW:

    tensor_core_register_file main_tensor_core_register_file (
        .clock_in(clock_in), .non_bulk_write_enable_in(tensor_core_register_file_non_bulk_write_enable),
        .non_bulk_write_register_address_in(tensor_core_register_file_non_bulk_write_register_address),
        .non_bulk_write_data_in(tensor_core_register_file_non_bulk_write_data),

        .bulk_write_enable_in(tensor_core_register_file_bulk_write_enable), .bulk_write_data_in(tensor_core_register_file_bulk_write_data),
        .read_data_out(tensor_core_register_file_read_data)
    );


    tensor_core main_tensor_core (
        .tensor_core_input1(tensor_core_input1), 
        .tensor_core_input2(tensor_core_input2),
        .tensor_core_output(tensor_core_output)
    );


    // for the opcode of operating on the contents in the tensor core register file
    assign tensor_core_register_file_bulk_write_enable = (alu_opcode == 8'b101) ? 1'b1: 1'b0;

    // for the opcode of load immediate and move from cpu registers to the tensor core register file   
    assign tensor_core_register_file_non_bulk_write_enable = (
        (alu_opcode == 8'b110) ? 1'b1:
        (alu_opcode == 8'b111) ? 1'b1: 
        1'b0
    );
    assign tensor_core_register_file_non_bulk_write_register_address = (
        (alu_opcode == 8'b110) ? current_instruction[28:24]: 
        (alu_opcode == 8'b111) ? current_instruction[28:24]:
        5'b0
    );
    assign tensor_core_register_file_non_bulk_write_data = (
        (alu_opcode == 8'b110) ? current_instruction[23:16]: 
        (alu_opcode == 8'b111) ? cpu_register_file_read_data1: 
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