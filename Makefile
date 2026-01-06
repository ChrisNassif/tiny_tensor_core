test_alu:
	iverilog -g2012 -o build/alu_test_bench.out src/alu_test_bench.sv src/alu.sv
	vvp build/alu_test_bench.out
	gtkwave build/alu_test_bench.vcd

transistor_count_alu:
	yosys -p "read_verilog -sv src/alu.sv; synth; stat -tech cmos"




test_tensor_core_controller:
	iverilog -g2012 -o build/tensor_core_controller_test_bench.out src/tensor_core_controller_test_bench.sv src/tensor_core_controller.sv src/tensor_core.sv src/tensor_core_register_file.sv
	vvp build/tensor_core_controller_test_bench.out
	gtkwave build/tensor_core_controller_test_bench.vcd

transistor_count_tensor_core_controller:
	yosys -p "read_verilog -sv src/tensor_core_controller.sv src/alu.sv src/tensor_core.sv src/tensor_core_register_file.sv; synth; stat -tech cmos"

show_tensor_core_controller_synthesis:
	yosys -p "read_verilog -sv src/tensor_core_controller.sv src/alu.sv src/tensor_core.sv src/tensor_core_register_file.sv; synth -top tensor_core_controller; stat -tech cmos; show tensor_core_controller"


transistor_count_tensor_core_controller_v:
	yosys -p "read_verilog src_v/tensor_core_controller.v src_v/alu.v src_v/tensor_core.v src_v/tensor_core_register_file.v; synth; stat -tech cmos"

# show_tensor_core_controller_synthesis_v:
# 	yosys -p "read_verilog src_v/tensor_core_controller.v src_v/alu.v src_v/tensor_core.v src_v/tensor_core_register_file.v; synth -top tensor_core_controller; stat -tech cmos; show tensor_core_controller"

show_tensor_core_controller_synthesis_v:
	yosys -p "read_verilog src_v/tensor_core_controller.v src_v/alu.v src_v/tensor_core.v src_v/tensor_core_register_file.v; hierarchy -top tensor_core_controller; proc; flatten; opt; fsm; memory; opt; stat -tech;"
