module tensor_core (
	tensor_core_input1,
	tensor_core_input2,
	tensor_core_output
);
	reg _sv2v_0;
	input wire [127:0] tensor_core_input1;
	input wire [127:0] tensor_core_input2;
	output reg [127:0] tensor_core_output;
	always @(*) begin
		if (_sv2v_0)
			;
		begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < 4; i = i + 1)
				begin : sv2v_autoblock_2
					reg signed [31:0] j;
					for (j = 0; j < 4; j = j + 1)
						begin
							tensor_core_output[(((3 - i) * 4) + (3 - j)) * 8+:8] = 0;
							begin : sv2v_autoblock_3
								reg signed [31:0] k;
								for (k = 0; k < 4; k = k + 1)
									tensor_core_output[(((3 - i) * 4) + (3 - j)) * 8+:8] = tensor_core_output[(((3 - i) * 4) + (3 - j)) * 8+:8] + (tensor_core_input1[(((3 - i) * 4) + (3 - k)) * 8+:8] * tensor_core_input2[(((3 - k) * 4) + (3 - j)) * 8+:8]);
							end
						end
				end
		end
	end
	genvar _gv_i_1;
	genvar _gv_j_1;
	generate
		for (_gv_i_1 = 0; _gv_i_1 < 4; _gv_i_1 = _gv_i_1 + 1) begin : expose_tensor_core
			localparam i = _gv_i_1;
			for (_gv_j_1 = 0; _gv_j_1 < 4; _gv_j_1 = _gv_j_1 + 1) begin : expose_tensor_core2
				localparam j = _gv_j_1;
				wire [7:0] tensor_core_input1_wire = tensor_core_input1[(((3 - i) * 4) + (3 - j)) * 8+:8];
				wire [7:0] tensor_core_input2_wire = tensor_core_input2[(((3 - i) * 4) + (3 - j)) * 8+:8];
				wire [7:0] tensor_core_output_wire = tensor_core_output[(((3 - i) * 4) + (3 - j)) * 8+:8];
			end
		end
	endgenerate
	initial _sv2v_0 = 0;
endmodule
