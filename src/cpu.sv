`timescale 1ns / 1ps
`default_nettype wire

module cpu (input logic clock_in, input logic [31:0] current_instruction, output logic [7:0] cpu_output);

    logic [7:0] source_register1, source_register2, destination_register;
    logic [2:0] alu_opcode;


    alu main_alu(
        .clock_in(clock_in), .reset_in(1'b0), .enable_in(1'b1), 
        .opcode_in(alu_opcode), .alu_input1(alu_input1), .alu_input2(alu_input2), 
        .alu_output(alu_output)
    );


    
    assign source_register1 = current_instruction[31:25];
    assign source_register2 = current_instruction[24:18];
    assign destination_register = current_instruction[17:11];
    assign alu_opcode = current_instruction[2:0];



    always @(posedge clock_in) begin

    end

  

endmodule