module alu (
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
	input wire reset_in;
	input wire enable_in;
	input wire [7:0] opcode_in;
	input wire signed [3:0] alu_input1;
	input wire signed [3:0] alu_input2;
	output reg signed [3:0] alu_output;
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
	localparam MOV = 8'b00001011;
	reg signed [4:0] extended_result;
	reg [15:0] mult_result;
	initial begin
		overflow_flag = 0;
		carry_flag = 0;
		zero_flag = 0;
		sign_flag = 0;
		extended_result = 0;
		mult_result = 0;
		parity_flag = 0;
	end
	always @(*) begin
		if (_sv2v_0)
			;
		if (reset_in) begin
			alu_output = 0;
			zero_flag = 1;
		end
		else if (enable_in)
			case (opcode_in)
				ADD: begin
					extended_result = {1'b0, alu_input1} + {1'b0, alu_input2};
					alu_output = extended_result[3:0];
				end
				ADD_IMMEDIATE: begin
					extended_result = {1'b0, alu_input1} + {1'b0, alu_input2};
					alu_output = extended_result[3:0];
				end
				SUBTRACT: begin
					extended_result = {1'b0, alu_input1} - {1'b0, alu_input2};
					alu_output = extended_result[3:0];
				end
				SUBTRACT_IMMEDIATE: begin
					extended_result = {1'b0, alu_input1} - {1'b0, alu_input2};
					alu_output = extended_result[3:0];
				end
				EQUALS:
					if (alu_input1 == alu_input2)
						alu_output = 1;
					else
						alu_output = 0;
				GREATER_THAN:
					if (alu_input1 > alu_input2)
						alu_output = 1;
					else
						alu_output = 0;
				MOV: alu_output = alu_input1;
				default: alu_output = 0;
			endcase
		else
			alu_output = 0;
		if ((opcode_in == ADD) || (opcode_in == ADD_IMMEDIATE)) begin
			carry_flag = extended_result[4];
			overflow_flag = ((~alu_input1[3] & ~alu_input2[3]) & alu_output[3]) | ((alu_input1[3] & alu_input2[3]) & ~alu_output[3]);
		end
		if ((opcode_in == SUBTRACT) || (opcode_in == SUBTRACT_IMMEDIATE))
			overflow_flag = ((~alu_input1[3] & alu_input2[3]) & alu_output[3]) | ((alu_input1[3] & ~alu_input2[3]) & ~alu_output[3]);
		zero_flag = alu_output == 0;
		sign_flag = alu_output[3];
		parity_flag = ^alu_output;
	end
	initial _sv2v_0 = 0;
endmodule
