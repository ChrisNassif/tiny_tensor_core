test_alu:
	iverilog -g2012 -o build/alu_test_bench.out src/alu_test_bench.sv src/alu.sv
	vvp build/alu_test_bench.out
	gtkwave build/alu_test_bench.vcd

alu_transistor_count:
	yosys -p "read_verilog -sv src/alu.sv; synth; stat -tech cmos"




test_cpu:
	iverilog -g2012 -o build/cpu_test_bench.out src/cpu_test_bench.sv src/cpu.sv src/alu.sv src/register_file.sv
	vvp build/cpu_test_bench.out
	gtkwave build/cpu_test_bench.vcd

cpu_transistor_count:
	yosys -p "read_verilog -sv src/cpu.sv; synth; stat -tech cmos"