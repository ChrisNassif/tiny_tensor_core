module cpu (
	clock_in,
	shifted_clock_in,
	current_instruction,
	cpu_output,
	tensor_core_result
);
	reg _sv2v_0;
	input wire clock_in;
	input wire shifted_clock_in;
	input wire [31:0] current_instruction;
	output wire signed [3:0] cpu_output;
	output wire signed [63:0] tensor_core_result;
	wire signed [3:0] alu_input1;
	wire signed [3:0] alu_input2;
	wire signed [3:0] alu_output;
	wire [7:0] alu_opcode;
	wire is_immediate_instruction;
	wire [2:0] cpu_register_file_read_register_address1;
	wire [2:0] cpu_register_file_read_register_address2;
	wire signed [3:0] cpu_register_file_read_data1;
	wire signed [3:0] cpu_register_file_read_data2;
	wire [2:0] cpu_register_file_write_register_address;
	wire signed [3:0] cpu_register_file_write_data;
	wire cpu_register_file_write_enable;
	wire tensor_core_clock;
	wire tensor_core_register_file_non_bulk_write_enable;
	wire signed [3:0] tensor_core_register_file_non_bulk_write_data;
	wire [4:0] tensor_core_register_file_non_bulk_write_register_address;
	wire tensor_core_register_file_bulk_write_enable;
	reg signed [127:0] tensor_core_register_file_bulk_write_data;
	wire signed [127:0] tensor_core_register_file_bulk_read_data;
	wire [4:0] tensor_core_register_file_non_bulk_read_register_address;
	wire signed [3:0] tensor_core_register_file_non_bulk_read_data;
	wire signed [63:0] tensor_core_output;
	wire is_tensor_core_done_with_calculation;
	reg signed [63:0] tensor_core_input1;
	reg signed [63:0] tensor_core_input2;
	wire alu_overflow_flag;
	wire alu_carry_flag;
	wire alu_zero_flag;
	wire alu_sign_flag;
	wire alu_parity_flag;
	reg [4:0] status_register;
	alu main_alu(
		.reset_in(alu_opcode == 8'b00001101),
		.enable_in(1'b1),
		.opcode_in(alu_opcode),
		.alu_input1(alu_input1),
		.alu_input2(alu_input2),
		.alu_output(alu_output),
		.overflow_flag(alu_overflow_flag),
		.carry_flag(alu_carry_flag),
		.zero_flag(alu_zero_flag),
		.sign_flag(alu_sign_flag),
		.parity_flag(alu_parity_flag)
	);
	cpu_register_file main_cpu_register_file(
		.clock_in(clock_in),
		.write_enable_in(cpu_register_file_write_enable),
		.reset_in(alu_opcode == 8'b00001101),
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
	assign is_immediate_instruction = (alu_opcode == 8'b00001001) || (alu_opcode == 8'b00001010);
	assign cpu_register_file_write_enable = (((((((((alu_opcode == 8'b00000000) || (alu_opcode == 8'b00000001)) || (alu_opcode == 8'b00000010)) || (alu_opcode == 8'b00000011)) || (alu_opcode == 8'b00000100)) || (alu_opcode == 8'b00001001)) || (alu_opcode == 8'b00001010)) || (alu_opcode == 8'b00001011)) || (alu_opcode == 8'b00001110) ? 1'b1 : 1'b0);
	assign cpu_register_file_write_data = (alu_opcode == 8'b00001110 ? tensor_core_register_file_non_bulk_read_data : alu_output);
	assign alu_input1 = cpu_register_file_read_data1;
	assign alu_input2 = (is_immediate_instruction ? current_instruction[15:8] : cpu_register_file_read_data2);
	assign cpu_output = (alu_opcode == 8'b00001111 ? cpu_register_file_read_data1 : (alu_opcode == 8'b00010000 ? tensor_core_register_file_non_bulk_read_data : alu_output));
	always @(posedge clock_in)
		if (cpu_register_file_write_enable) begin
			status_register[4] <= alu_parity_flag;
			status_register[3] <= alu_overflow_flag;
			status_register[2] <= alu_carry_flag;
			status_register[1] <= alu_zero_flag;
			status_register[0] <= alu_sign_flag;
		end
	tensor_core_register_file main_tensor_core_register_file(
		.clock_in(clock_in),
		.reset_in(alu_opcode == 8'b00001101),
		.non_bulk_write_enable_in(tensor_core_register_file_non_bulk_write_enable),
		.non_bulk_write_register_address_in(tensor_core_register_file_non_bulk_write_register_address),
		.non_bulk_write_data_in(tensor_core_register_file_non_bulk_write_data),
		.bulk_write_enable_in(tensor_core_register_file_bulk_write_enable | is_tensor_core_done_with_calculation),
		.bulk_write_data_in(tensor_core_register_file_bulk_write_data),
		.non_bulk_read_register_address_in(tensor_core_register_file_non_bulk_read_register_address),
		.non_bulk_read_data_out(tensor_core_register_file_non_bulk_read_data),
		.bulk_read_data_out(tensor_core_register_file_bulk_read_data)
	);
	small_tensor_core main_tensor_core(
		.clock_in(tensor_core_clock),
		.tensor_core_register_file_write_enable(tensor_core_register_file_bulk_write_enable | tensor_core_register_file_non_bulk_write_enable),
		.tensor_core_input1(tensor_core_input1),
		.tensor_core_input2(tensor_core_input2),
		.tensor_core_output(tensor_core_output),
		.is_done_with_calculation(is_tensor_core_done_with_calculation)
	);
	assign tensor_core_clock = shifted_clock_in ^ clock_in;
	assign tensor_core_register_file_bulk_write_enable = 1'b0;
	assign tensor_core_register_file_non_bulk_read_register_address = current_instruction[20:16];
	assign tensor_core_register_file_non_bulk_write_enable = (alu_opcode == 8'b00000110 ? 1 : (alu_opcode == 8'b00000111 ? 1 : (alu_opcode == 8'b00001100 ? 1 : 0)));
	assign tensor_core_register_file_non_bulk_write_register_address = (alu_opcode == 8'b00000110 ? current_instruction[28:24] : (alu_opcode == 8'b00000111 ? current_instruction[28:24] : (alu_opcode == 8'b00001100 ? current_instruction[28:24] : 0)));
	assign tensor_core_register_file_non_bulk_write_data = (alu_opcode == 8'b00000110 ? current_instruction[23:16] : (alu_opcode == 8'b00000111 ? cpu_register_file_read_data1 : (alu_opcode == 8'b00001100 ? tensor_core_register_file_non_bulk_read_data : 0)));
	initial begin : sv2v_autoblock_1
		reg signed [31:0] i;
		for (i = 0; i < 4; i = i + 1)
			begin : sv2v_autoblock_2
				reg signed [31:0] j;
				for (j = 0; j < 4; j = j + 1)
					begin
						tensor_core_register_file_bulk_write_data[(((4 + (3 - i)) * 4) + (3 - j)) * 4+:4] = 0;
						tensor_core_register_file_bulk_write_data[(((0 + (3 - i)) * 4) + (3 - j)) * 4+:4] = 0;
						tensor_core_input1[(((3 - i) * 4) + (3 - j)) * 4+:4] = 0;
						tensor_core_input2[(((3 - i) * 4) + (3 - j)) * 4+:4] = 0;
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
							tensor_core_register_file_bulk_write_data[(((4 + (3 - i)) * 4) + (3 - j)) * 4+:4] = tensor_core_output[(((3 - i) * 4) + (3 - j)) * 4+:4];
							tensor_core_register_file_bulk_write_data[(((0 + (3 - i)) * 4) + (3 - j)) * 4+:4] = tensor_core_register_file_bulk_read_data[(((0 + (3 - i)) * 4) + (3 - j)) * 4+:4];
							tensor_core_input1[(((3 - i) * 4) + (3 - j)) * 4+:4] = tensor_core_register_file_bulk_read_data[(((4 + (3 - i)) * 4) + (3 - j)) * 4+:4];
							tensor_core_input2[(((3 - i) * 4) + (3 - j)) * 4+:4] = tensor_core_register_file_bulk_read_data[(((0 + (3 - i)) * 4) + (3 - j)) * 4+:4];
						end
				end
		end
	end
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
					wire [7:0] tensor_core_register_file_bulk_read_data_ = tensor_core_register_file_bulk_read_data[(((((1 - n) * 4) + (3 - i)) * 4) + (3 - j)) * 4+:4];
					wire [7:0] tensor_core_output_ = tensor_core_output[(((3 - i) * 4) + (3 - j)) * 4+:4];
				end
			end
		end
	endgenerate
	initial _sv2v_0 = 0;
endmodule
