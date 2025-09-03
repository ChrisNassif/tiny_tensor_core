module cpu_register_file (
	clock_in,
	write_enable_in,
	read_register_address1_in,
	read_register_address2_in,
	write_register_address_in,
	write_data_in,
	read_data1_out,
	read_data2_out
);
	parameter NUMBER_OF_REGISTERS = 256;
	input wire clock_in;
	input wire write_enable_in;
	input wire [$clog2(NUMBER_OF_REGISTERS) - 1:0] read_register_address1_in;
	input wire [$clog2(NUMBER_OF_REGISTERS) - 1:0] read_register_address2_in;
	input wire [$clog2(NUMBER_OF_REGISTERS) - 1:0] write_register_address_in;
	input wire [7:0] write_data_in;
	output wire [7:0] read_data1_out;
	output wire [7:0] read_data2_out;
	reg [7:0] registers [0:NUMBER_OF_REGISTERS - 1];
	assign read_data1_out = registers[read_register_address1_in];
	assign read_data2_out = registers[read_register_address2_in];
	initial begin : sv2v_autoblock_1
		reg signed [31:0] i;
		for (i = 0; i < NUMBER_OF_REGISTERS; i = i + 1)
			registers[i] <= 8'b00000000;
	end
	always @(posedge clock_in)
		if (write_enable_in)
			registers[write_register_address_in] <= write_data_in;
	genvar _gv_i_1;
	generate
		for (_gv_i_1 = 0; _gv_i_1 < NUMBER_OF_REGISTERS; _gv_i_1 = _gv_i_1 + 1) begin : expose_regs
			localparam i = _gv_i_1;
			wire [7:0] reg_wire = registers[i];
		end
	endgenerate
endmodule
