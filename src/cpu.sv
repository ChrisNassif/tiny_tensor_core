`timescale 1ns / 1ps
`default_nettype wire

module cpu (input logic clock_in, input logic [31:0] current_instruction, output logic [7:0] cpu_output);

    // TODO add code to support immediate instructions


    logic [7:0] alu_input1, alu_input2, alu_output;
    logic [2:0] alu_opcode;

    logic [7:0] register_file_read_register_address1, register_file_read_register_address2;
    logic [7:0] register_file_read_data1, register_file_read_data2;
    logic [7:0] register_file_write_register_address;
    logic [7:0] register_file_write_data;
    logic register_file_write_enable;


    alu main_alu(
        .clock_in(clock_in), .reset_in(1'b0), .enable_in(1'b1), 
        .opcode_in(alu_opcode), .alu_input1(alu_input1), .alu_input2(alu_input2), 
        .alu_output(alu_output)
    );


    register_file main_register_file (
        .clock_in(clock_in), .write_enable_in(register_file_write_enable), 
        .read_register_address1_in(register_file_read_register_address1), .read_register_address2_in(register_file_read_register_address2),
        .write_register_address_in(register_file_write_register_address), .write_data_in(register_file_write_data), 
        .read_data1_out(register_file_read_data1), .read_data2_out(register_file_read_data2)
    );
    

    assign register_file_write_register_address = current_instruction[31:25];
    assign register_file_read_register_address1 = current_instruction[24:18];
    assign register_file_read_register_address2 = current_instruction[17:11];
    assign alu_opcode = current_instruction[2:0];

    assign register_file_write_enable = 1`b1;
    assign alu_input1 = current_instruction[31:25];     // TODO CHANGE THIS BACK TO register_file_read_data1 ONCE ADD IMMEDIATE IS ADDED
    assign alu_input2 = register_file_read_data2;
    assign register_file_write_data = alu_output;


    // always @(posedge clock_in) begin

    // end

  

endmodule