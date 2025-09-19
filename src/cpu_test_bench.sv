`timescale 1ns / 1ps
`default_nettype wire
`define BUS_WIDTH 7

module cpu_test_bench();
    // Core signals
    logic clock;
    logic shifted_clock, shifted_clock2, shifted_clock3;
    logic [31:0] machine_code [0:1023];
    logic [31:0] current_instruction;
    logic signed [`BUS_WIDTH:0] cpu_output;
    
    // Test tracking
    integer test_count = 0;
    integer pass_count = 0;
    integer fail_count = 0;
    integer instruction_count = 0;
    
    initial begin
        $readmemh("machine_code", machine_code);
    end
    
    cpu main_cpu(
        .clock_in(clock), 
        .shifted_clock_in(shifted_clock),
        .shifted_clock2_in(shifted_clock2), 
        .shifted_clock3_in(shifted_clock3), 
        .current_instruction(current_instruction), 
        .cpu_output(cpu_output)
    );
    
    // Clock generation
    always begin
        #5 shifted_clock = !shifted_clock;
        #5 clock = !clock;        
    end
    
    always begin
        #2.5 shifted_clock2 = !shifted_clock2;
        #7.5;
    end
    
    always begin
        #7.5 shifted_clock3 = !shifted_clock3;
        #2.5;
    end
    
    // ============================================
    // TENSOR REGISTER WIRES FOR WAVEFORM DISPLAY
    // ============================================
    wire signed [`BUS_WIDTH:0] T0  = main_cpu.main_tensor_core_register_file.registers[0][0][0];
    wire signed [`BUS_WIDTH:0] T1  = main_cpu.main_tensor_core_register_file.registers[0][0][1];
    wire signed [`BUS_WIDTH:0] T2  = main_cpu.main_tensor_core_register_file.registers[0][0][2];
    wire signed [`BUS_WIDTH:0] T3  = main_cpu.main_tensor_core_register_file.registers[0][0][3];
    wire signed [`BUS_WIDTH:0] T4  = main_cpu.main_tensor_core_register_file.registers[0][1][0];
    wire signed [`BUS_WIDTH:0] T5  = main_cpu.main_tensor_core_register_file.registers[0][1][1];
    wire signed [`BUS_WIDTH:0] T6  = main_cpu.main_tensor_core_register_file.registers[0][1][2];
    wire signed [`BUS_WIDTH:0] T7  = main_cpu.main_tensor_core_register_file.registers[0][1][3];
    wire signed [`BUS_WIDTH:0] T8  = main_cpu.main_tensor_core_register_file.registers[0][2][0];
    wire signed [`BUS_WIDTH:0] T9  = main_cpu.main_tensor_core_register_file.registers[0][2][1];
    wire signed [`BUS_WIDTH:0] T10 = main_cpu.main_tensor_core_register_file.registers[0][2][2];
    wire signed [`BUS_WIDTH:0] T11 = main_cpu.main_tensor_core_register_file.registers[0][2][3];
    wire signed [`BUS_WIDTH:0] T12 = main_cpu.main_tensor_core_register_file.registers[0][3][0];
    wire signed [`BUS_WIDTH:0] T13 = main_cpu.main_tensor_core_register_file.registers[0][3][1];
    wire signed [`BUS_WIDTH:0] T14 = main_cpu.main_tensor_core_register_file.registers[0][3][2];
    wire signed [`BUS_WIDTH:0] T15 = main_cpu.main_tensor_core_register_file.registers[0][3][3];
    wire signed [`BUS_WIDTH:0] T16 = main_cpu.main_tensor_core_register_file.registers[1][0][0];
    wire signed [`BUS_WIDTH:0] T17 = main_cpu.main_tensor_core_register_file.registers[1][0][1];
    wire signed [`BUS_WIDTH:0] T18 = main_cpu.main_tensor_core_register_file.registers[1][0][2];
    wire signed [`BUS_WIDTH:0] T19 = main_cpu.main_tensor_core_register_file.registers[1][0][3];
    wire signed [`BUS_WIDTH:0] T20 = main_cpu.main_tensor_core_register_file.registers[1][1][0];
    wire signed [`BUS_WIDTH:0] T21 = main_cpu.main_tensor_core_register_file.registers[1][1][1];
    wire signed [`BUS_WIDTH:0] T22 = main_cpu.main_tensor_core_register_file.registers[1][1][2];
    wire signed [`BUS_WIDTH:0] T23 = main_cpu.main_tensor_core_register_file.registers[1][1][3];
    wire signed [`BUS_WIDTH:0] T24 = main_cpu.main_tensor_core_register_file.registers[1][2][0];
    wire signed [`BUS_WIDTH:0] T25 = main_cpu.main_tensor_core_register_file.registers[1][2][1];
    wire signed [`BUS_WIDTH:0] T26 = main_cpu.main_tensor_core_register_file.registers[1][2][2];
    wire signed [`BUS_WIDTH:0] T27 = main_cpu.main_tensor_core_register_file.registers[1][2][3];
    wire signed [`BUS_WIDTH:0] T28 = main_cpu.main_tensor_core_register_file.registers[1][3][0];
    wire signed [`BUS_WIDTH:0] T29 = main_cpu.main_tensor_core_register_file.registers[1][3][1];
    wire signed [`BUS_WIDTH:0] T30 = main_cpu.main_tensor_core_register_file.registers[1][3][2];
    wire signed [`BUS_WIDTH:0] T31 = main_cpu.main_tensor_core_register_file.registers[1][3][3];
    
    // ============================================
    // CPU REGISTER WIRES FOR WAVEFORM DISPLAY
    // ============================================
    wire signed [`BUS_WIDTH:0] R0  = main_cpu.main_cpu_register_file.registers[0];
    wire signed [`BUS_WIDTH:0] R1  = main_cpu.main_cpu_register_file.registers[1];
    wire signed [`BUS_WIDTH:0] R2  = main_cpu.main_cpu_register_file.registers[2];
    wire signed [`BUS_WIDTH:0] R3  = main_cpu.main_cpu_register_file.registers[3];
    wire signed [`BUS_WIDTH:0] R4  = main_cpu.main_cpu_register_file.registers[4];
    wire signed [`BUS_WIDTH:0] R5  = main_cpu.main_cpu_register_file.registers[5];
    wire signed [`BUS_WIDTH:0] R6  = main_cpu.main_cpu_register_file.registers[6];
    wire signed [`BUS_WIDTH:0] R7  = main_cpu.main_cpu_register_file.registers[7];
    wire signed [`BUS_WIDTH:0] R8  = main_cpu.main_cpu_register_file.registers[8];
    wire signed [`BUS_WIDTH:0] R9  = main_cpu.main_cpu_register_file.registers[9];
    wire signed [`BUS_WIDTH:0] R10 = main_cpu.main_cpu_register_file.registers[10];
    wire signed [`BUS_WIDTH:0] R11 = main_cpu.main_cpu_register_file.registers[11];
    wire signed [`BUS_WIDTH:0] R12 = main_cpu.main_cpu_register_file.registers[12];
    wire signed [`BUS_WIDTH:0] R13 = main_cpu.main_cpu_register_file.registers[13];
    wire signed [`BUS_WIDTH:0] R14 = main_cpu.main_cpu_register_file.registers[14];
    wire signed [`BUS_WIDTH:0] R15 = main_cpu.main_cpu_register_file.registers[15];
    wire signed [`BUS_WIDTH:0] R16 = main_cpu.main_cpu_register_file.registers[16];
    wire signed [`BUS_WIDTH:0] R17 = main_cpu.main_cpu_register_file.registers[17];
    wire signed [`BUS_WIDTH:0] R18 = main_cpu.main_cpu_register_file.registers[18];
    wire signed [`BUS_WIDTH:0] R19 = main_cpu.main_cpu_register_file.registers[19];
    wire signed [`BUS_WIDTH:0] R20 = main_cpu.main_cpu_register_file.registers[20];
    wire signed [`BUS_WIDTH:0] R21 = main_cpu.main_cpu_register_file.registers[21];
    
    // Status flags
    wire overflow = main_cpu.alu_overflow_flag;
    wire carry = main_cpu.alu_carry_flag;
    wire zero = main_cpu.alu_zero_flag;
    wire sign = main_cpu.alu_sign_flag;
    wire parity = main_cpu.alu_parity_flag;
    wire tensor_done = main_cpu.is_tensor_core_done_with_calculation;
    
    initial begin
        $dumpfile("build/cpu_test_bench.vcd");
        $dumpvars(0, cpu_test_bench);
        
        // Explicitly dump all named tensor registers
        $dumpvars(0, T0, T1, T2, T3, T4, T5, T6, T7);
        $dumpvars(0, T8, T9, T10, T11, T12, T13, T14, T15);
        $dumpvars(0, T16, T17, T18, T19, T20, T21, T22, T23);
        $dumpvars(0, T24, T25, T26, T27, T28, T29, T30, T31);
        
        // Dump CPU registers
        $dumpvars(0, R0, R1, R2, R3, R4, R5, R6, R7, R8, R9, R10);
        
        // Dump other key signals
        $dumpvars(1, main_cpu.alu_opcode);
        $dumpvars(1, main_cpu.cpu_register_file_write_enable);
        $dumpvars(1, main_cpu.tensor_core_register_file_non_bulk_write_enable);
        
        clock = 0;
        shifted_clock = 0;
        shifted_clock2 = 0;
        shifted_clock3 = 0;
        
        $display("================================================");
        $display("    CPU TEST WITH TENSOR REGISTER DISPLAY      ");
        $display("================================================");
        
        #11;
        
        // Execute test program
        for (integer i = 0; i < 100 && machine_code[i] != 32'h0; i = i + 1) begin
            current_instruction = machine_code[i];
            instruction_count = i;
            #20;
            
            // Monitor tensor loads
            if (i >= 22 && i <= 53) begin
                $display("[%0t] Loading Tensor[%0d] = %0d", $time, 
                         current_instruction[31:24], current_instruction[23:16]);
            end
        end
        
        // Display tensor state after loading
        $display("\n=== TENSOR STATE AFTER LOADING ===");
        $display("First Matrix (T0-T15):");
        $display("  T0-T3:   %3d %3d %3d %3d", T0, T1, T2, T3);
        $display("  T4-T7:   %3d %3d %3d %3d", T4, T5, T6, T7);
        $display("  T8-T11:  %3d %3d %3d %3d", T8, T9, T10, T11);
        $display("  T12-T15: %3d %3d %3d %3d", T12, T13, T14, T15);
        $display("Second Matrix (T16-T31):");
        $display("  T16-T19: %3d %3d %3d %3d", T16, T17, T18, T19);
        $display("  T20-T23: %3d %3d %3d %3d", T20, T21, T22, T23);
        $display("  T24-T27: %3d %3d %3d %3d", T24, T25, T26, T27);
        $display("  T28-T31: %3d %3d %3d %3d", T28, T29, T30, T31);
        
        #50;
        $finish;
    end
endmodule