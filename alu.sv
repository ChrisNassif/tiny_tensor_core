`timescale 1ns / 1ps
`default_nettype none
`default_nettype wire


module alu (
    input clock,
    input reset,
    input enable,
    input [2:0] opcode,
    input logic signed [7:0] alu_input1,
    input logic signed [7:0] alu_input2,
    output wire signed [7:0] alu_output
);
    localparam ADD = 2'b00, SUBTRACT = 2'b01, MULTIPLY = 2'b10;

    logic signed [7:0] alu_output_logic;
    assign alu_output = alu_output_logic;

    always @(posedge clock) begin 
        if (reset) begin 
            alu_out_reg <= 8'b0;
        end 
        
        else if (enable) begin
            case (opcode)
                ADD: begin 
                    alu_output_logic <= alu_input1 + alu_input2;
                end

                SUBTRACT: begin 
                    alu_output_logic <= alu_input1 - alu_input2;
                end

                MULTIPLY: begin 
                    alu_output_logic <= alu_input1 * alu_input2;
                end
            endcase
        end
    end
endmodule