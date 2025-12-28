`timescale 1ns / 1ps
`default_nettype wire



`define ADD_OPCODE 4'b0000
`define SUB_OPCODE 4'b0001
`define MUL_OPCODE 4'b0010
`define EQL_OPCODE 4'b0011
`define GRT_OPCODE 4'b0100

`define TENSOR_CORE_OPERATE_OPCODE 4'b0101
`define TENSOR_CORE_LOAD_OPCODE 4'b0110
`define CPU_TO_TENSOR_CORE_OPCODE 4'b0111
`define TENSOR_CORE_TO_CPU_OPCODE 4'b1000
`define NOP_OPCODE 4'b1001

`define ADD_IMM_OPCODE 4'b1010

`define MOVE_CPU_OPCODE 8'b1011
`define MOVE_TENSOR_CORE_OPCODE 8'b1100
`define RESET_OPCODE 4'b1101

`define READ_CPU_OPCODE 4'b1110
`define READ_TENSOR_CORE_OPCODE 4'b1111

`define BUS_WIDTH 7

module cpu_test_bench();
    // Core signals
    logic clock;
    logic shifted_clock, shifted_clock2, shifted_clock3;
    logic [15:0] machine_code [0:1023];
    logic [15:0] current_instruction;
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
    wire signed [`BUS_WIDTH:0] T3  = main_cpu.main_tensor_core_register_file.registers[0][1][0];
    wire signed [`BUS_WIDTH:0] T4  = main_cpu.main_tensor_core_register_file.registers[0][1][1];
    wire signed [`BUS_WIDTH:0] T5  = main_cpu.main_tensor_core_register_file.registers[0][1][2];
    wire signed [`BUS_WIDTH:0] T6  = main_cpu.main_tensor_core_register_file.registers[0][2][0];
    wire signed [`BUS_WIDTH:0] T7  = main_cpu.main_tensor_core_register_file.registers[0][2][1];
    wire signed [`BUS_WIDTH:0] T8  = main_cpu.main_tensor_core_register_file.registers[0][2][2];
    wire signed [`BUS_WIDTH:0] T9  = main_cpu.main_tensor_core_register_file.registers[1][0][0];
    wire signed [`BUS_WIDTH:0] T10 = main_cpu.main_tensor_core_register_file.registers[1][0][1];
    wire signed [`BUS_WIDTH:0] T11 = main_cpu.main_tensor_core_register_file.registers[1][0][2];
    wire signed [`BUS_WIDTH:0] T12 = main_cpu.main_tensor_core_register_file.registers[1][1][0];
    wire signed [`BUS_WIDTH:0] T13 = main_cpu.main_tensor_core_register_file.registers[1][1][1];
    wire signed [`BUS_WIDTH:0] T14 = main_cpu.main_tensor_core_register_file.registers[1][1][2];
    wire signed [`BUS_WIDTH:0] T15 = main_cpu.main_tensor_core_register_file.registers[1][2][0];
    wire signed [`BUS_WIDTH:0] T16 = main_cpu.main_tensor_core_register_file.registers[1][2][1];
    wire signed [`BUS_WIDTH:0] T17 = main_cpu.main_tensor_core_register_file.registers[1][2][2];


    // ============================================
    // CPU REGISTER WIRES FOR WAVEFORM DISPLAY
    // ============================================
    // wire signed [`BUS_WIDTH:0] R0  = main_cpu.main_cpu_register_file.registers[0];
    // wire signed [`BUS_WIDTH:0] R1  = main_cpu.main_cpu_register_file.registers[1];
    // wire signed [`BUS_WIDTH:0] R2  = main_cpu.main_cpu_register_file.registers[2];
    // wire signed [`BUS_WIDTH:0] R3  = main_cpu.main_cpu_register_file.registers[3];
    // wire signed [`BUS_WIDTH:0] R4  = main_cpu.main_cpu_register_file.registers[4];
    // wire signed [`BUS_WIDTH:0] R5  = main_cpu.main_cpu_register_file.registers[5];
    // wire signed [`BUS_WIDTH:0] R6  = main_cpu.main_cpu_register_file.registers[6];
    // wire signed [`BUS_WIDTH:0] R7  = main_cpu.main_cpu_register_file.registers[7];


    // Status flags
    wire tensor_done = main_cpu.is_tensor_core_done_with_calculation;
    
    initial begin
        $dumpfile("build/cpu_test_bench.vcd");
        $dumpvars(0, cpu_test_bench);
        
        // Explicitly dump all named tensor registers
        $dumpvars(0, T0, T1, T2, T3, T4, T5, T6, T7);
        $dumpvars(0, T8, T9, T10, T11, T12, T13, T14, T15);
        $dumpvars(0, T16, T17);
        
        // Dump CPU registers
        // $dumpvars(0, R0, R1, R2, R3, R4, R5, R6, R7);
        
        // Dump other key signals
        // $dumpvars(1, main_cpu.alu_opcode);
        // $dumpvars(1, main_cpu.cpu_register_file_write_enable);
        $dumpvars(1, main_cpu.tensor_core_register_file_non_bulk_write_enable);
        
        clock = 0;
        shifted_clock = 0;
        shifted_clock2 = 0;
        shifted_clock3 = 0;
        
        $display("================================================");
        $display("    CPU TEST WITH TENSOR REGISTER DISPLAY      ");
        $display("================================================");
        
        #11;
        
        // Run comprehensive tests
        // run_alu_tests();
        // run_edge_case_tests();
        // run_tensor_core_tests();
        
        // Execute original program from machine_code file
        $display("\n================================================");
        $display("    EXECUTING PROGRAM FROM MACHINE CODE FILE   ");
        $display("================================================");
        
        for (integer i = 0; machine_code[i] != 32'hFFFF; i = i + 1) begin
            current_instruction = machine_code[i];
            instruction_count = i;
            #20;
        end


        
        // Display final tensor state
        $display("\n=== FINAL TENSOR STATE ===");
        $display("First Matrix (T0-T8):");
        $display("  T0-T2:   %3d %3d %3d", T0, T1, T2);
        $display("  T3-T5:   %3d %3d %3d", T3, T4, T5);
        $display("  T6-T8:   %3d %3d %3d", T6, T7, T8);
        $display("Second Matrix (T9-T17):");
        $display("  T9-T11:  %3d %3d %3d", T9, T10, T11);
        $display("  T12-T14: %3d %3d %3d", T12, T13, T14);
        $display("  T15-T17: %3d %3d %3d", T15, T16, T17);


        
        // Display test summary
        $display("\n================================================");
        $display("              TEST SUMMARY                     ");
        $display("================================================");
        $display("Total Tests Run:    %0d", test_count);
        $display("Tests Passed:       %0d", pass_count);
        $display("Tests Failed:       %0d", fail_count);
        if (fail_count == 0) begin
            $display("STATUS: ALL TESTS PASSED!");
        end else begin
            $display("STATUS: SOME TESTS FAILED - Review output above");
        end
        $display("================================================");
        
        #50;
        $finish;
    end
endmodule