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
║  │    │   Instruction    │          │  Burst Store/Load      │        │  ║
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
║  │    │ Store/Load     │   │    File     │   │      (ALU)         │   │  ║
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
| Memory Controller | `tensor_core_memory_controller.sv` | FPGA | Instruction fetch, matrix data I/O, burst store/load |
| Tensor Core Controller | `tensor_core_controller.sv` | ASIC | Instruction decode, register file & tensor core orchestration |
| Register File | `tensor_core_register_file.sv` | ASIC | Two 3×3 matrices (18 × 8-bit signed), quad-load burst loading |
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

The project is managed via a `Makefile` that handles compilation, simulation, and verification.

### 1. Run Custom Simulation
To run your own assembly program interactively:
1.  Edit `assembly_code.asm` (Code)
2.  Edit `data_in_plain_text.txt` (Data)
3.  Run:
    ```bash
    make run
    ```
    This will compile the code, run the simulation, and open GTKWave to view waveforms. Results will be saved to `data_out_plain_text.txt`.

### 2. Run Verification Suite
To run the full regression suite (Unit Tests + Fuzz Tests) in parallel:
```bash
make verify
```
This validates the RTL against the reference model.

### 3. Fuzz Testing
To regenerate the randomized fuzz test cases:
```bash
make fuzz
```

### 4. Cleanup
To remove generated artifacts:
```bash
make clean
```



## Assembly Language Reference

The tensor core uses a custom instruction set for matrix operations:

| Instruction            | Format                                                                     | Description                              |
|------------------------|----------------------------------------------------------------------------|------------------------------------------|
| `nop`                  | `nop`                                                                      | No operation                             |
| `reset`                | `reset`                                                                    | Reset all registers and state            |
| `matrix_multiply`      | `matrix_multiply`                                                          | Multiply matrices in input registers     |
| `burst store_and_load` | `burst store_and_load <store_address> <load_address1> <load_address2>`    | Combined store and load for better speed |


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



