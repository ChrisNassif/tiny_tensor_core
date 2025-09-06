`define BUS_WIDTH 7

module alu (
    input logic reset_in,
    input logic enable_in,
    input logic [7:0] opcode_in,
    input logic [`BUS_WIDTH:0] alu_input1,
    input logic [`BUS_WIDTH:0] alu_input2,
    output logic [`BUS_WIDTH:0] alu_output,
    output logic overflow_flag,         // Overflow detection
    output logic carry_flag,            // Carry flag for unsigned operations
    output logic zero_flag,             // Zero flag
    output logic sign_flag,             // Sign flag (MSB of result)
    output logic parity_flag 
);
    localparam ADD = 8'b0, SUBTRACT = 8'b1, MULTIPLY = 8'b10, 
        EQUALS = 8'b11, GREATER_THAN = 8'b100, ADD_IMMEDIATE = 8'b1001, SUBTRACT_IMMEDIATE = 8'b1010;

    logic [`BUS_WIDTH+1:0] extended_result;  // extra bit for carry detection
    logic [15:0] mult_result;     // 16-bit for multiplication


    // Default flag values
    initial begin 
        overflow_flag = 0;
        carry_flag = 0;
        zero_flag = 0;
        sign_flag = 0;
        extended_result = 0;
        mult_result = 0;
        parity_flag = 0;
    end


    always_comb begin 

        if (reset_in) begin 
            alu_output = 8'b0;
            zero_flag = 1'b1;
        end 
        
        else if (enable_in) begin
            case (opcode_in)
                ADD: begin 
                    extended_result = {1'b0, alu_input1} + {1'b0, alu_input2};
                    alu_output = extended_result[7:0];
                    
                    // Carry flag (unsigned overflow)
                    carry_flag = extended_result[8];
                    
                    // Signed overflow detection for addition
                    overflow_flag = (~alu_input1[7] & ~alu_input2[7] & alu_output[7]) | (alu_input1[7] & alu_input2[7] & ~alu_output[7]);
                    
                    zero_flag = (alu_output == 8'b0);
                    sign_flag = alu_output[7];
                    parity_flag = ^alu_output;
                end

                ADD_IMMEDIATE: begin 
                    extended_result = {1'b0, alu_input1} + {1'b0, alu_input2};
                    alu_output = extended_result[7:0];
                    
                    carry_flag = extended_result[8];
                    overflow_flag = (~alu_input1[7] & ~alu_input2[7] & alu_output[7]) | (alu_input1[7] & alu_input2[7] & ~alu_output[7]);
                    zero_flag = (alu_output == 8'b0);
                    sign_flag = alu_output[7];
                    parity_flag = ^alu_output;
                end

                SUBTRACT: begin 
                    extended_result = {1'b0, alu_input1} - {1'b0, alu_input2};
                    alu_output = extended_result[7:0];
                    
                    carry_flag = extended_result[8];
                    overflow_flag = (~alu_input1[7] & alu_input2[7] & alu_output[7]) | (alu_input1[7] & ~alu_input2[7] & ~alu_output[7]);
                    zero_flag = (alu_output == 8'b0);
                    sign_flag = alu_output[7];
                    parity_flag = ^alu_output;
                end

                SUBTRACT_IMMEDIATE: begin 
                    extended_result = {1'b0, alu_input1} - {1'b0, alu_input2};
                    alu_output = extended_result[7:0];
                    
                    carry_flag = extended_result[8];
                    overflow_flag = (~alu_input1[7] & alu_input2[7] & alu_output[7]) | (alu_input1[7] & ~alu_input2[7] & ~alu_output[7]);
                    zero_flag = (alu_output == 8'b0);
                    sign_flag = alu_output[7];
                    parity_flag = ^alu_output;
                end

                // MULTIPLY: begin 
                //     mult_result = alu_input1 * alu_input2;
                //     alu_output = mult_result[7:0];
                    
                //     // For multiplication, overflow occurs if result doesn't fit in 8 bits
                //     overflow_flag = (mult_result[15:8] != 8'b0);
                //     carry_flag = overflow_flag;
                    
                //     zero_flag = (alu_output == 8'b0);
                //     sign_flag = alu_output[7];
                //     parity_flag = ^alu_output;
                // end

                EQUALS: begin
                    if (alu_input1 == alu_input2) begin
                        alu_output = 1;
                        
                    end

                    else begin
                        alu_output = 0;
                    end
                    zero_flag = (alu_output == 8'b0);
                    sign_flag = alu_output[7];
                end

                GREATER_THAN: begin
                    if (alu_input1 > alu_input2) begin
                        alu_output = 1;
                    end

                    else begin
                        alu_output = 0;
                    end
                    zero_flag = (alu_output == 8'b0);
                    sign_flag = alu_output[7];
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