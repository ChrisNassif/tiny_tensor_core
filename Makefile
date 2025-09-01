test_alu:
	iverilog -g2012 -o alu_test_bench.out alu_test_bench.sv alu.sv
	vvp alu_test_bench.out
	gtkwave alu_test_bench.vcd