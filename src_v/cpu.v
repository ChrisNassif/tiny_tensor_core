module cpu (
	clock_in,
	current_instruction,
	cpu_output
);
	reg _sv2v_0;
	input wire clock_in;
	input wire [31:0] current_instruction;
	output wire [7:0] cpu_output;
	wire [7:0] alu_input1;
	wire [7:0] alu_input2;
	wire [7:0] alu_output;
	wire [7:0] alu_opcode;
	wire [7:0] cpu_register_file_read_register_address1;
	wire [7:0] cpu_register_file_read_register_address2;
	wire [7:0] cpu_register_file_read_data1;
	wire [7:0] cpu_register_file_read_data2;
	wire [7:0] cpu_register_file_write_register_address;
	wire [7:0] cpu_register_file_write_data;
	wire cpu_register_file_write_enable;
	wire tensor_core_register_file_non_bulk_write_enable;
	wire [7:0] tensor_core_register_file_non_bulk_write_data;
	wire [4:0] tensor_core_register_file_non_bulk_write_register_address;
	wire tensor_core_register_file_bulk_write_enable;
	reg [255:0] tensor_core_register_file_bulk_write_data;
	wire [255:0] tensor_core_register_file_read_data;
	wire [127:0] tensor_core_output;
	reg [127:0] tensor_core_input1;
	reg [127:0] tensor_core_input2;
	alu main_alu(
		.clock_in(clock_in),
		.reset_in(1'b0),
		.enable_in(1'b1),
		.opcode_in(alu_opcode),
		.alu_input1(alu_input1),
		.alu_input2(alu_input2),
		.alu_output(alu_output)
	);
	cpu_register_file main_cpu_register_file(
		.clock_in(clock_in),
		.write_enable_in(cpu_register_file_write_enable),
		.read_register_address1_in(cpu_register_file_read_register_address1),
		.read_register_address2_in(cpu_register_file_read_register_address2),
		.write_register_address_in(cpu_register_file_write_register_address),
		.write_data_in(cpu_register_file_write_data),
		.read_data1_out(cpu_register_file_read_data1),
		.read_data2_out(cpu_register_file_read_data2)
	);
	assign cpu_register_file_write_register_address = current_instruction[31:24];
	assign cpu_register_file_read_register_address1 = current_instruction[23:16];
	assign cpu_register_file_read_register_address2 = current_instruction[15:8];
	assign alu_opcode = current_instruction[7:0];
	assign cpu_register_file_write_enable = 1'b1;
	assign alu_input1 = current_instruction[23:16];
	assign alu_input2 = cpu_register_file_read_data2;
	assign cpu_register_file_write_data = alu_output;
	assign cpu_output = alu_output;
	assign tensor_core_register_file_bulk_write_enable = (alu_opcode == 8'b00000101 ? 1'b1 : 1'b0);
	assign tensor_core_register_file_non_bulk_write_enable = (alu_opcode == 8'b00000110 ? 1'b1 : 1'b0);
	assign tensor_core_register_file_non_bulk_write_register_address = (alu_opcode == 8'b00000110 ? current_instruction[28:24] : 5'b00000);
	assign tensor_core_register_file_non_bulk_write_data = (alu_opcode == 8'b00000110 ? current_instruction[23:16] : 8'b00000000);
	initial begin : sv2v_autoblock_1
		reg signed [31:0] i;
		for (i = 0; i < 4; i = i + 1)
			begin : sv2v_autoblock_2
				reg signed [31:0] j;
				for (j = 0; j < 4; j = j + 1)
					begin
						tensor_core_register_file_bulk_write_data[(((4 + (3 - i)) * 4) + (3 - j)) * 8+:8] = 8'b00000000;
						tensor_core_register_file_bulk_write_data[(((0 + (3 - i)) * 4) + (3 - j)) * 8+:8] = 8'b00000000;
						tensor_core_input1[(((3 - i) * 4) + (3 - j)) * 8+:8] = 8'b00000000;
						tensor_core_input2[(((3 - i) * 4) + (3 - j)) * 8+:8] = 8'b00000000;
					end
			end
	end
	always @(*) begin
		if (_sv2v_0)
			;
		begin : sv2v_autoblock_3
			reg signed [31:0] i;
			for (i = 0; i < 4; i = i + 1)
				begin : sv2v_autoblock_4
					reg signed [31:0] j;
					for (j = 0; j < 4; j = j + 1)
						begin
							tensor_core_register_file_bulk_write_data[(((4 + (3 - i)) * 4) + (3 - j)) * 8+:8] = tensor_core_output[(((3 - i) * 4) + (3 - j)) * 8+:8];
							tensor_core_register_file_bulk_write_data[(((0 + (3 - i)) * 4) + (3 - j)) * 8+:8] = tensor_core_register_file_read_data[(((0 + (3 - i)) * 4) + (3 - j)) * 8+:8];
							tensor_core_input1[(((3 - i) * 4) + (3 - j)) * 8+:8] = tensor_core_register_file_read_data[(((4 + (3 - i)) * 4) + (3 - j)) * 8+:8];
							tensor_core_input2[(((3 - i) * 4) + (3 - j)) * 8+:8] = tensor_core_register_file_read_data[(((0 + (3 - i)) * 4) + (3 - j)) * 8+:8];
						end
				end
		end
	end
	better_tensor_core_register_file main_tensor_core_register_file(
		.clock_in(clock_in),
		.non_bulk_write_enable_in(tensor_core_register_file_non_bulk_write_enable),
		.non_bulk_write_register_address_in(tensor_core_register_file_non_bulk_write_register_address),
		.non_bulk_write_data_in(tensor_core_register_file_non_bulk_write_data),
		.bulk_write_enable_in(tensor_core_register_file_bulk_write_enable),
		.bulk_write_data_in(tensor_core_register_file_bulk_write_data),
		.read_data_out(tensor_core_register_file_read_data)
	);
	tensor_core main_tensor_core(
		.tensor_core_input1(tensor_core_input1),
		.tensor_core_input2(tensor_core_input2),
		.tensor_core_output(tensor_core_output)
	);
	genvar _gv_i_1;
	genvar _gv_j_1;
	genvar _gv_n_1;
	generate
		for (_gv_n_1 = 0; _gv_n_1 < 2; _gv_n_1 = _gv_n_1 + 1) begin : hi
			localparam n = _gv_n_1;
			for (_gv_i_1 = 0; _gv_i_1 < 4; _gv_i_1 = _gv_i_1 + 1) begin : expose_tensor_core
				localparam i = _gv_i_1;
				for (_gv_j_1 = 0; _gv_j_1 < 4; _gv_j_1 = _gv_j_1 + 1) begin : expose_tensor_core2
					localparam j = _gv_j_1;
					wire [7:0] tensor_core_register_file_read_data_ = tensor_core_register_file_read_data[(((((1 - n) * 4) + (3 - i)) * 4) + (3 - j)) * 8+:8];
					wire [7:0] tensor_core_output_ = tensor_core_output[(((3 - i) * 4) + (3 - j)) * 8+:8];
				end
			end
		end
	endgenerate
	initial _sv2v_0 = 0;
endmodule
