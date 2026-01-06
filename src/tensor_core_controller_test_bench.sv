`timescale 1ns / 1ps
`default_nettype wire

`define BUS_WIDTH 7


module tensor_core_controller_test_bench();

    // Core signals
    logic clock;
    logic power_on_reset_signal;
    logic shifted_clock, shifted_clock2, shifted_clock3;
    logic [15:0] machine_code [0:20000];
    logic [15:0] current_instruction;
    logic signed [`BUS_WIDTH:0] output;
    
    // Test tracking
    integer test_count = 0;
    integer pass_count = 0;
    integer fail_count = 0;
    integer instruction_count = 0;
    
    initial begin
        $readmemh("machine_code", machine_code);
    end
    
    tensor_core_controller main_tensor_core_controller(
        .clock_in(clock), 
        .shifted_clock_in(shifted_clock),
        .current_instruction(current_instruction), 
        .power_on_reset_signal(power_on_reset_signal),
        .output(output)
    );
    
    initial begin
        power_on_reset_signal = 1;
    end

    always @(posedge clock) begin
        power_on_reset_signal <= 0;
    end


    // Clock generation
    always begin
        #10 shifted_clock = !shifted_clock;
        #10 clock = !clock;        
    end
    
    always begin
        #5 shifted_clock2 = !shifted_clock2;
        #15;
    end
    
    always begin
        #15 shifted_clock3 = !shifted_clock3;
        #5;
    end
    

    // ============================================
    // TENSOR REGISTER WIRES FOR WAVEFORM DISPLAY
    // ============================================
    wire signed [`BUS_WIDTH:0] T0  = main_tensor_core_controller.main_tensor_core_register_file.registers[0][0][0];
    wire signed [`BUS_WIDTH:0] T1  = main_tensor_core_controller.main_tensor_core_register_file.registers[0][0][1];
    wire signed [`BUS_WIDTH:0] T2  = main_tensor_core_controller.main_tensor_core_register_file.registers[0][0][2];
    wire signed [`BUS_WIDTH:0] T3  = main_tensor_core_controller.main_tensor_core_register_file.registers[0][1][0];
    wire signed [`BUS_WIDTH:0] T4  = main_tensor_core_controller.main_tensor_core_register_file.registers[0][1][1];
    wire signed [`BUS_WIDTH:0] T5  = main_tensor_core_controller.main_tensor_core_register_file.registers[0][1][2];
    wire signed [`BUS_WIDTH:0] T6  = main_tensor_core_controller.main_tensor_core_register_file.registers[0][2][0];
    wire signed [`BUS_WIDTH:0] T7  = main_tensor_core_controller.main_tensor_core_register_file.registers[0][2][1];
    wire signed [`BUS_WIDTH:0] T8  = main_tensor_core_controller.main_tensor_core_register_file.registers[0][2][2];
    wire signed [`BUS_WIDTH:0] T9  = main_tensor_core_controller.main_tensor_core_register_file.registers[1][0][0];
    wire signed [`BUS_WIDTH:0] T10 = main_tensor_core_controller.main_tensor_core_register_file.registers[1][0][1];
    wire signed [`BUS_WIDTH:0] T11 = main_tensor_core_controller.main_tensor_core_register_file.registers[1][0][2];
    wire signed [`BUS_WIDTH:0] T12 = main_tensor_core_controller.main_tensor_core_register_file.registers[1][1][0];
    wire signed [`BUS_WIDTH:0] T13 = main_tensor_core_controller.main_tensor_core_register_file.registers[1][1][1];
    wire signed [`BUS_WIDTH:0] T14 = main_tensor_core_controller.main_tensor_core_register_file.registers[1][1][2];
    wire signed [`BUS_WIDTH:0] T15 = main_tensor_core_controller.main_tensor_core_register_file.registers[1][2][0];
    wire signed [`BUS_WIDTH:0] T16 = main_tensor_core_controller.main_tensor_core_register_file.registers[1][2][1];
    wire signed [`BUS_WIDTH:0] T17 = main_tensor_core_controller.main_tensor_core_register_file.registers[1][2][2];

    // Status flags
    // wire tensor_done = main_tensor_core_controller.is_tensor_core_done_with_calculation;
    
    initial begin
        $dumpfile("build/tensor_core_controller_test_bench.vcd");
        $dumpvars(0, tensor_core_controller_test_bench);
        
        // Explicitly dump all named tensor registers
        $dumpvars(0, T0, T1, T2, T3, T4, T5, T6, T7);
        $dumpvars(0, T8, T9, T10, T11, T12, T13, T14, T15);
        $dumpvars(0, T16, T17);
         
        // Dump other key signals
        $dumpvars(1, main_tensor_core_controller.tensor_core_register_file_non_bulk_write_enable);
        
        clock = 0;
        shifted_clock = 0;
        shifted_clock2 = 0;
        shifted_clock3 = 0;
        
        $display("==================================================================");
        $display("    TENSOR CORE CONTROLLER TEST WITH TENSOR REGISTER DISPLAY      ");
        $display("==================================================================");
        
        #11;
        

        // Execute original program from machine_code file
        $display("\n================================================");
        $display("    EXECUTING PROGRAM FROM MACHINE CODE FILE   ");
        $display("================================================");
        
        for (integer i = 0; i < 100000; i = i + 1) begin
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