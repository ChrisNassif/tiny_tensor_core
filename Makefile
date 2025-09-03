test_alu:
	iverilog -g2012 -o build/alu_test_bench.out src/alu_test_bench.sv src/alu.sv
	vvp build/alu_test_bench.out
	gtkwave build/alu_test_bench.vcd

transistor_count_alu:
	yosys -p "read_verilog -sv src/alu.sv; synth; stat -tech cmos"




test_cpu:
	iverilog -g2012 -o build/cpu_test_bench.out src/cpu_test_bench.sv src/cpu.sv src/alu.sv src/cpu_register_file.sv src/tensor_core.sv src/tensor_core_register_file.sv
	vvp build/cpu_test_bench.out
	gtkwave build/cpu_test_bench.vcd

transistor_count_cpu:
	yosys -p "read_verilog -sv src/cpu.sv src/alu.sv src/cpu_register_file.sv src/tensor_core.sv src/tensor_core_register_file.sv; synth; stat -tech cmos"

show_cpu_synthesis:
	yosys -p "read_verilog -sv src/cpu.sv src/alu.sv src/cpu_register_file.sv src/tensor_core.sv src/tensor_core_register_file.sv; synth -top cpu; stat -tech cmos; show cpu"


transistor_count_cpu_v:
	yosys -p "read_verilog src_v/cpu.v src_v/alu.v src_v/cpu_register_file.v src_v/tensor_core.v src_v/tensor_core_register_file.v; synth; stat -tech cmos"

show_cpu_synthesis_v:
	yosys -p "read_verilog src_v/cpu.v src_v/alu.v src_v/cpu_register_file.v src_v/tensor_core.v src_v/tensor_core_register_file.v; synth -top cpu; stat -tech cmos; show cpu"
