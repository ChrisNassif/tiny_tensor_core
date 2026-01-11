# Tensor Core GPU

A SystemVerilog implementation of a tensor core for GPU-accelerated matrix operations, featuring a custom assembler, memory controller, and comprehensive testbench.

## Overview

This project implements a small-scale tensor core capable of performing fundamental neural network operations:

- **Matrix Multiplication** - 3x3 matrix multiply with saturation arithmetic
- **Matrix Addition** - Element-wise matrix addition with overflow clamping  
- **ReLU Activation** - Rectified Linear Unit activation function

The tensor core uses 8-bit signed integers with automatic overflow handling to prevent arithmetic wraparound.

## Architecture

The system is split into two physical components designed for different hardware targets:

| Component                  | Target Hardware  | Purpose                                  |
|----------------------------|------------------|------------------------------------------|
| **Memory Controller**      | FPGA             | Handles memory I/O and instruction fetch |
| **Tensor Core Controller** | Taped-out ASIC   | Performs matrix computations             |

```
╔══════════════════════════════════════════════════════════════════════════╗
║                                 FPGA                                     ║
║  ┌────────────────────────────────────────────────────────────────────┐  ║
║  │                      Memory Controller                             │  ║
║  │                                                                    │  ║
║  │    ┌──────────────────┐          ┌────────────────────────┐        │  ║
║  │    │   Machine Code   │          │      Data Memory       │        │  ║
║  │    │     [20000]      │          │       (Matrices)       │        │  ║
║  │    └────────┬─────────┘          └───────────┬────────────┘        │  ║
║  │             │                                │                     │  ║
║  │             ▼                                ▼                     │  ║
║  │    ┌──────────────────┐          ┌────────────────────────┐        │  ║
║  │    │   Instruction    │          │  Burst Read/Write      │        │  ║
║  │    │      Fetch       │─────────▶│  Control Logic         │        │  ║
║  │    └──────────────────┘          └────────────────────────┘        │  ║
║  └────────────────────────────────────────────────────────────────────┘  ║
╚═══════════════════════╤══════════════════════╤═══════════════════════════╝
                        │                      ▲
                        │  clock, reset,       │  output data
                        │  instruction         │  (8-bit)
                        ▼                      │
╔═══════════════════════╧══════════════════════╧═══════════════════════════╗
║                          ASIC (Taped Out)                                ║
║  ┌────────────────────────────────────────────────────────────────────┐  ║
║  │                    Tensor Core Controller                          │  ║
║  │                                                                    │  ║
║  │                 ┌────────────────────────┐                         │  ║
║  │                 │   Instruction Decode   │                         │  ║
║  │                 │    (Opcode Parser)     │                         │  ║
║  │                 └───┬────────┬───────┬───┘                         │  ║
║  │                     │        │       │                             │  ║
║  │         ┌───────────┘        │       └───────────┐                 │  ║
║  │         ▼                    ▼                   ▼                 │  ║
║  │    ┌────────────────┐   ┌─────────────┐   ┌────────────────────┐   │  ║
║  │    │ Burst          │   │  Register   │   │   Tensor Core      │   │  ║
║  │    │ Read/Write     │   │    File     │   │      (ALU)         │   │  ║
║  │    │ State Machine  │   │             │   │                    │   │  ║
║  │    └───────┬────────┘   │ ┌─────────┐ │   │ • Matrix Multiply  │   │  ║
║  │            │            │ │ M1 │ M2 │─┼──▶│ • Matrix Add       │   │  ║
║  │            │ load data  │ │3×3│ 3×3 │ │   │ • ReLU Activation  │   │  ║
║  │            └───────────▶│ └─────────┘ │   │                    │   │  ║
║  │                         └─────────────┘   └────────────────────┘   │  ║
║  │                                                                    │  ║
║  └────────────────────────────────────────────────────────────────────┘  ║
╚══════════════════════════════════════════════════════════════════════════╝
```

**Module Descriptions:**
| Module | File | Target | Description |
|--------|------|--------|-------------|
| Memory Controller | `tensor_core_memory_controller.sv` | FPGA | Instruction fetch, matrix data I/O, burst read/write |
| Tensor Core Controller | `tensor_core_controller.sv` | ASIC | Instruction decode, register file & tensor core orchestration |
| Register File | `tensor_core_register_file.sv` | ASIC | Two 3×3 matrices (18 × 8-bit signed), quad-write burst loading |
| Tensor Core | `tensor_core.sv` | ASIC | Matrix multiply, add, ReLU with saturation arithmetic |



### Quick Install (Ubuntu/Debian)

```bash
# Install system packages
sudo apt update
sudo apt install python3 python3-pip iverilog gtkwave

# Install Python dependencies
pip3 install numpy
```

### Verify Installation

```bash
python3 --version      # Should show Python 3.x
iverilog -V            # Should show Icarus Verilog version
vvp --version          # Should show VVP version  
gtkwave --version      # Should show GTKWave version
```


## Usage

### Tutorial

In order to write a program and compile it into binary machine-understandable code, you can use the provided assembler.

```bash
python3 assembler.py assembly_code.asm
```

This will generate a binary file `machine_code` that can be loaded into the tensor core.


You can also edit the input data which the machine code will use. The input data is stored in the `data_in_plain_text.txt` file. This is a human readable format, where each line contains 9 space-separated signed integers representing a 3x3 matrix in row-major order. For instance, the following line:

```
5 -8 2 10 -4 0 7 -1 9
```

represents the matrix:
```
[  5  -8   2 ]
[ 10  -4   0 ]
[  7  -1   9 ]
```


Then, the only thing you need to do is use the Makefile to run your assembly code:

```bash
make test_tensor_core
```

That's it! This command will:
1. Convert plain text input data to binary format
2. Compile all SystemVerilog source files using Icarus Verilog
3. Run the simulation with VVP
4. Convert binary output to human-readable format
5. Launch GTKWave to view the waveforms

Afterwards you can find the output of the tensor core program in the `data_out_plain_text.txt` file.



## Assembly Language Reference

The tensor core uses a custom instruction set for matrix operations:

| Instruction            | Format                                                                     | Description                              |
|------------------------|----------------------------------------------------------------------------|------------------------------------------|
| `nop`                  | `nop`                                                                      | No operation                             |
| `reset`                | `reset`                                                                    | Reset all registers and state            |
| `matrix_multiply`      | `matrix_multiply`                                                          | Multiply matrices in input registers     |
| `matrix_add`           | `matrix_add`                                                               | Add loaded matrices element-wise         |
| `relu`                 | `relu`                                                                     | Apply ReLU activation to output          |
| `burst read`           | `burst read <address>`                                                     | Burst read from memory address           |
| `burst write`          | `burst write <address1> <address2>`                                        | Burst write to two matrix addresses      |
| `burst read_and_write` | `burst read_and_write <read_address> <write_address1> <write_address2>`    | Combined read and write for better speed |


## Input/Output Data Format

### Input Data (`data_in_plain_text.txt`)

Each line contains 9 space-separated signed integers representing a 3x3 matrix in row-major order:

```
5 -8 2 10 -4 0 7 -1 9
```

This represents the matrix:
```
[  5  -8   2 ]
[ 10  -4   0 ]
[  7  -1   9 ]
```

### Output Data (`data_out_plain_text.txt`)

Contains the results of matrix operations, also in 3x3 row-major format.

