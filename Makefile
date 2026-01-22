# Tiny Tensor Core Makefile

.PHONY: run verify test fuzz clean help

# Default target
help:
	@echo "Tiny Tensor Core Build System"
	@echo "-----------------------------"
	@echo "make run      : Run simulation with current assembly_code.asm (Opens GTKWave)"
	@echo "make verify   : Run full parallel verification suite"
	@echo "make test     : Alias for verify"
	@echo "make fuzz     : Regenerate fuzz test cases"
	@echo "make clean    : Remove generated files"

# 1. Run Single Simulation (Current Workspace)
# This uses the root-level assembly_code.asm and data_in_plain_text.txt
run:
	@python3 assembler.py assembly_code.asm
	@python3 convert_data_from_data_in_plain_text_to_data_in.py
	@mkdir -p build
	@iverilog -g2012 -o build/tensor_core_test_bench.out src/tensor_core_test_bench.sv src/tensor_core_memory_controller.sv src/tensor_core_controller.sv src/tensor_core.sv src/tensor_core_register_file.sv
	@vvp build/tensor_core_test_bench.out
	@python3 convert_data_from_data_out_to_data_out_plain_text.py
	@if [ -f build/tensor_core_test_bench.vcd ]; then gtkwave build/tensor_core_test_bench.vcd; fi

# 2. Run Verification Suite (Parallel)
verify:
	@python3 tests/run_verified_tests_parallel.py

test: verify

# 3. Regenerate Fuzz Tests
fuzz:
	@python3 tests/create_stateless_fuzz.py
	@echo "Fuzz tests regenerated."

# 4. Clean Artifacts
clean:
	@rm -rf build/
	@rm -f data_in data_out machine_code
	@rm -f data_out_plain_text.txt
	@echo "Cleaned."
