module alu (
	clock_in,
	reset_in,
	enable_in,
	opcode_in,
	alu_input1,
	alu_input2,
	alu_output,
	overflow_flag,
	carry_flag,
	zero_flag,
	sign_flag,
	parity_flag
);
	reg _sv2v_0;
	input wire clock_in;
	input wire reset_in;
	input wire enable_in;
	input wire [7:0] opcode_in;
	input wire [7:0] alu_input1;
	input wire [7:0] alu_input2;
	output reg [7:0] alu_output;
	output reg overflow_flag;
	output reg carry_flag;
	output reg zero_flag;
	output reg sign_flag;
	output reg parity_flag;
	localparam ADD = 8'b00000000;
	localparam SUBTRACT = 8'b00000001;
	localparam MULTIPLY = 8'b00000010;
	localparam EQUALS = 8'b00000011;
	localparam GREATER_THAN = 8'b00000100;
	localparam ADD_IMMEDIATE = 8'b00001001;
	localparam SUBTRACT_IMMEDIATE = 8'b00001010;
	reg [8:0] extended_result;
	reg [15:0] mult_result;
	initial begin
		overflow_flag = 1'b0;
		carry_flag = 1'b0;
		zero_flag = 1'b0;
		sign_flag = 1'b0;
		extended_result = 9'b000000000;
		mult_result = 16'b0000000000000000;
		parity_flag = 1'b0;
	end
	always @(*) begin
		if (_sv2v_0)
			;
		if (reset_in) begin
			alu_output = 8'b00000000;
			zero_flag = 1'b1;
		end
		else if (enable_in)
			case (opcode_in)
				ADD: begin
					extended_result = {1'b0, alu_input1} + {1'b0, alu_input2};
					alu_output = extended_result[7:0];
					carry_flag = extended_result[8];
					overflow_flag = ((~alu_input1[7] & ~alu_input2[7]) & alu_output[7]) | ((alu_input1[7] & alu_input2[7]) & ~alu_output[7]);
					zero_flag = alu_output == 8'b00000000;
					sign_flag = alu_output[7];
					parity_flag = ^alu_output;
				end
				ADD_IMMEDIATE: begin
					extended_result = {1'b0, alu_input1} + {1'b0, alu_input2};
					alu_output = extended_result[7:0];
					carry_flag = extended_result[8];
					overflow_flag = ((~alu_input1[7] & ~alu_input2[7]) & alu_output[7]) | ((alu_input1[7] & alu_input2[7]) & ~alu_output[7]);
					zero_flag = alu_output == 8'b00000000;
					sign_flag = alu_output[7];
					parity_flag = ^alu_output;
				end
				SUBTRACT: begin
					extended_result = {1'b0, alu_input1} - {1'b0, alu_input2};
					alu_output = extended_result[7:0];
					carry_flag = extended_result[8];
					overflow_flag = ((~alu_input1[7] & alu_input2[7]) & alu_output[7]) | ((alu_input1[7] & ~alu_input2[7]) & ~alu_output[7]);
					zero_flag = alu_output == 8'b00000000;
					sign_flag = alu_output[7];
					parity_flag = ^alu_output;
				end
				SUBTRACT_IMMEDIATE: begin
					extended_result = {1'b0, alu_input1} - {1'b0, alu_input2};
					alu_output = extended_result[7:0];
					carry_flag = extended_result[8];
					overflow_flag = ((~alu_input1[7] & alu_input2[7]) & alu_output[7]) | ((alu_input1[7] & ~alu_input2[7]) & ~alu_output[7]);
					zero_flag = alu_output == 8'b00000000;
					sign_flag = alu_output[7];
					parity_flag = ^alu_output;
				end
				EQUALS: begin
					if (alu_input1 == alu_input2)
						alu_output = 1;
					else
						alu_output = 0;
					zero_flag = alu_output == 8'b00000000;
					sign_flag = alu_output[7];
				end
				GREATER_THAN: begin
					if (alu_input1 > alu_input2)
						alu_output = 1;
					else
						alu_output = 0;
					zero_flag = alu_output == 8'b00000000;
					sign_flag = alu_output[7];
				end
				default: alu_output = 0;
			endcase
		else
			alu_output = 0;
	end
	initial _sv2v_0 = 0;
endmodule
