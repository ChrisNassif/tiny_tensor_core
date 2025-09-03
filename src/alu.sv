module alu (
    input logic clock_in,
    input logic reset_in,
    input logic enable_in,
    input logic [7:0] opcode_in,
    input logic [7:0] alu_input1,
    input logic [7:0] alu_input2,
    output logic [7:0] alu_output
);
    localparam ADD = 8'b0, SUBTRACT = 8'b1, MULTIPLY = 8'b10, 
        EQUALS = 8'b11, GREATER_THAN = 8'b100;

    always_comb begin 
        if (reset_in) begin 
            alu_output = 8'b0;
        end 
        
        else if (enable_in) begin
            case (opcode_in)
                ADD: begin 
                    alu_output = alu_input1 + alu_input2;
                end

                SUBTRACT: begin 
                    alu_output = alu_input1 - alu_input2;
                end

                MULTIPLY: begin 
                    alu_output = alu_input1 * alu_input2;
                end

                EQUALS: begin
                    if (alu_input1 == alu_input2) begin
                        alu_output = 1;
                    end

                    else begin
                        alu_output = 0;
                    end
                end

                GREATER_THAN: begin
                    if (alu_input1 > alu_input2) begin
                        alu_output = 1;
                    end

                    else begin
                        alu_output = 0;
                    end
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