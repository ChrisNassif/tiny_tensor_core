module alu (
	clock_in,
	reset_in,
	enable_in,
	opcode_in,
	alu_input1,
	alu_input2,
	alu_output
);
	reg _sv2v_0;
	input wire clock_in;
	input wire reset_in;
	input wire enable_in;
	input wire [7:0] opcode_in;
	input wire signed [7:0] alu_input1;
	input wire signed [7:0] alu_input2;
	output reg signed [7:0] alu_output;
	localparam ADD = 8'b00000000;
	localparam SUBTRACT = 8'b00000001;
	localparam MULTIPLY = 8'b00000010;
	localparam EQUALS = 8'b00000011;
	localparam GREATER_THAN = 8'b00000100;
	always @(*) begin
		if (_sv2v_0)
			;
		if (reset_in)
			alu_output = 8'b00000000;
		else if (enable_in)
			case (opcode_in)
				ADD: alu_output = alu_input1 + alu_input2;
				SUBTRACT: alu_output = alu_input1 - alu_input2;
				MULTIPLY: alu_output = alu_input1 * alu_input2;
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
				default: alu_output = 0;
			endcase
		else
			alu_output = 0;
	end
	initial _sv2v_0 = 0;
endmodule
