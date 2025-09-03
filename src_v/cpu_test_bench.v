`default_nettype wire
module cpu_test_bench;
	reg clock;
	localparam MAX_MACHINE_CODE_LENGTH = 64;
	reg [31:0] machine_code [63:0];
	reg [31:0] current_instruction;
	wire [7:0] cpu_output;
	initial $readmemh("machine_code", machine_code);
	cpu main_cpu(
		.clock_in(clock),
		.current_instruction(current_instruction),
		.cpu_output(cpu_output)
	);
	always #(5) clock = !clock;
	initial begin
		$dumpfile("build/cpu_test_bench.vcd");
		$dumpvars(0, cpu_test_bench);
		clock = 0;
		#(6)
			;
		begin : sv2v_autoblock_1
			integer i;
			for (i = 0; i < MAX_MACHINE_CODE_LENGTH; i = i + 1)
				begin
					current_instruction = machine_code[i];
					#(10)
						;
				end
		end
		$display("Finishing Sim");
		$finish;
	end
endmodule
