`timescale 1ns / 1ps
`default_nettype wire


module alu (
    input logic clock_in,
    input logic reset_in,
    input logic enable_in,
    input logic [2:0] opcode_in,
    input logic signed [7:0] alu_input1,
    input logic signed [7:0] alu_input2,
    output logic signed [7:0] alu_output
);
    localparam ADD = 3'b000, SUBTRACT = 3'b001, MULTIPLY = 3'b010, 
        EQUALS = 3'b011, GREATER_THAN = 3'b100;

    always @(posedge clock_in) begin 
        if (reset_in) begin 
            alu_output <= 8'b0;
        end 
        
        else if (enable_in) begin
            case (opcode_in)
                ADD: begin 
                    alu_output <= alu_input1 + alu_input2;
                end

                SUBTRACT: begin 
                    alu_output <= alu_input1 - alu_input2;
                end

                MULTIPLY: begin 
                    alu_output <= alu_input1 * alu_input2;
                end

                EQUALS: begin
                    if (alu_input1 == alu_input2) begin
                        alu_output <= 1;
                    end

                    else begin
                        alu_output <= 0;
                    end
                end

                GREATER_THAN: begin
                    if (alu_input1 > alu_input2) begin
                        alu_output <= 1;
                    end

                    else begin
                        alu_output <= 0;
                    end
                end

            endcase
        end
    end
endmodule