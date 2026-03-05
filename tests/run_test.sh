#!/bin/bash
# Test Runner Script for Tensor Core Tests
# Usage: ./run_test.sh <test_name>
# Example: ./run_test.sh test_basic_ops

set -e

TEST_NAME=$1

if [ -z "$TEST_NAME" ]; then
    echo "Usage: ./run_test.sh <test_name>"
    echo "Available tests:"
    ls -d tests/*/ | xargs -n1 basename
    exit 1
fi

TEST_DIR="tests/$TEST_NAME"

if [ ! -d "$TEST_DIR" ]; then
    echo "Error: Test directory '$TEST_DIR' not found"
    exit 1
fi

echo "============================================"
echo "Running test: $TEST_NAME"
echo "============================================"

# Copy test files to root
cp "$TEST_DIR"/*.asm assembly_code.asm
cp "$TEST_DIR/data_in_plain_text.txt" data_in_plain_text.txt

# Assemble
echo "Assembling..."
python3 assembler.py assembly_code.asm

# Convert input data
echo "Converting input data..."
python3 convert_data_from_data_in_plain_text_to_data_in.py

# Compile and run simulation
mkdir -p build

echo "Compiling SystemVerilog..."
iverilog -g2012 -o build/tensor_core_test_bench.out \
    src/tensor_core_test_bench.sv \
    src/tensor_core_memory_controller.sv \
    src/tensor_core_controller.sv \
    src/tensor_core.sv \
    src/tensor_core_register_file.sv

echo "Running simulation..."
timeout 120 vvp build/tensor_core_test_bench.out

# Convert output
echo "Converting output data..."
python3 convert_data_from_data_out_to_data_out_plain_text.py

echo ""
echo "============================================"
echo "Test output in: data_out_plain_text.txt"
echo "Expected output in: $TEST_DIR/expected_output.txt"
echo "============================================"
echo ""
echo "Output preview (first 10 lines):"
head -10 data_out_plain_text.txt

