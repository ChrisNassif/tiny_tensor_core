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
`timescale 1ns / 1ps






module alu (
    input logic reset_in,
    input logic enable_in,
    input logic [3:0] opcode_in,
    input logic signed [`BUS_WIDTH:0] alu_input1,
    input logic signed [`BUS_WIDTH:0] alu_input2,
    output logic signed [`BUS_WIDTH:0] alu_output
);

    logic signed [`BUS_WIDTH+1:0] extended_result;  // extra bit for carry detection


    always_comb begin 
        
        extended_result = 0;

        if (reset_in) begin 
            alu_output = 0;
        end 
        
        else if (enable_in) begin
            case (opcode_in)
                `ADD_OPCODE: begin 
                    extended_result = {1'b0, alu_input1} + {1'b0, alu_input2};
                    alu_output = extended_result[`BUS_WIDTH:0];
                end

                `SUB_OPCODE: begin 
                    extended_result = {1'b0, alu_input1} - {1'b0, alu_input2};
                    alu_output = extended_result[`BUS_WIDTH:0];
                end

                `EQL_OPCODE: begin
                    if (alu_input1 == alu_input2) begin
                        alu_output = 1;
                    end

                    else begin
                        alu_output = 0;
                    end
                end

                `GRT_OPCODE: begin
                    if (alu_input1 > alu_input2) begin
                        alu_output = 1;
                    end

                    else begin
                        alu_output = 0;
                    end
                end

                `CPU_MOV_OPCODE: begin
                    alu_output = alu_input1;
                end


                default: begin
                    alu_output = 0;
                end

            endcase
        end

        else begin
            alu_output = 0;
        end


    end
endmodule