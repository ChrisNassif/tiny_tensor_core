test_tensor_core:
	python3 convert_data_from_data_in_plain_text_to_data_in.py
	iverilog -g2012 -o build/tensor_core_test_bench.out src/tensor_core_test_bench.sv src/tensor_core_memory_controller.sv src/tensor_core_controller.sv src/tensor_core.sv src/tensor_core_register_file.sv
	vvp build/tensor_core_test_bench.out
	python3 convert_data_from_data_out_to_data_out_plain_text.py
	gtkwave build/tensor_core_test_bench.vcd
