# Tiny Tensor Core Makefile

.PHONY: run verify test fuzz mnist mnist-verify clean help

# Default target
help:
	@echo "Tiny Tensor Core Build System"
	@echo "-----------------------------"
	@echo "make run           : Run simulation with current assembly_code.asm (Opens GTKWave)"
	@echo "make test          : Run full parallel verification suite (11 tests)"
	@echo "make fuzz          : Regenerate fuzz test cases"
	@echo "make mnist         : Compile quantized MNIST model to assembly + data"
	@echo "make mnist-verify  : End-to-end verify: compile model, simulate 5 MNIST digits, compare to PyTorch"
	@echo "make clean         : Remove generated files"

# 1.a Run Single Simulation (Current Workspace)
# This uses the root-level assembly_code.asm and data_in_plain_text.txt
run:
	@python3 assembler.py assembly_code.asm
	@python3 convert_data_from_data_in_plain_text_to_data_in.py
	@mkdir -p build
	@iverilog -g2012 -o build/tensor_core_test_bench.out src/tensor_core_test_bench.sv src/tensor_core_memory_controller.sv src/tensor_core_controller.sv src/tensor_core.sv src/tensor_core_register_file.sv
	@vvp build/tensor_core_test_bench.out
	@python3 convert_data_from_data_out_to_data_out_plain_text.py
	@if [ -f build/tensor_core_test_bench.vcd ]; then gtkwave build/tensor_core_test_bench.vcd; fi

# 1.b Run Synthesized Simulation (Current Workspace)
run_synthesized:
	@python3 assembler.py assembly_code.asm
	@python3 convert_data_from_data_in_plain_text_to_data_in.py
	@mkdir -p build
	@iverilog -g2012 -o build/tensor_core_test_bench.out src/tensor_core_test_bench.sv src/tensor_core_memory_controller.sv src/synthesized_tensor_core.v src/sky130_scl_9T.v
	@vvp build/tensor_core_test_bench.out
	@python3 convert_data_from_data_out_to_data_out_plain_text.py
	@if [ -f build/tensor_core_test_bench.vcd ]; then gtkwave build/tensor_core_test_bench.vcd; fi


# 2. Run Verification Suite (Parallel)
verify:
	@python3 tests/run_verified_tests_parallel.py

test: verify

# 3. Regenerate Fuzz Tests
fuzz:
	@python3 tests/create_fuzz.py
	@echo "Fuzz tests regenerated."

# 4. Compile MNIST Model
mnist:
	@python3 model_compiler/compiler.py models/quantized_tensor_core_mnist_961_5bit.pt

# 5. End-to-End MNIST Verification (Compile + Simulate + Compare to PyTorch)
mnist-verify:
	@python3 model_compiler/verify_mnist.py

# 6. Clean Artifacts
clean:
	@rm -rf build/ obj_dir/
	@rm -f data_in data_out machine_code a.out
	@rm -f data_out_plain_text.txt test_input.npy
	@echo "Cleaned."

