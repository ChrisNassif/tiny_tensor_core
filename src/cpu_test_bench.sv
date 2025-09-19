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
    
    // Key signals for waveform display
    logic signed [`BUS_WIDTH:0] R1, R2, R3, R4, R5, R6, R7, R8, R9, R10;
    logic overflow, carry, zero, sign, parity;
    logic tensor_done;
    
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
    
    // Connect internal signals for clean waveform display
    assign R1 = main_cpu.main_cpu_register_file.registers[1];
    assign R2 = main_cpu.main_cpu_register_file.registers[2];
    assign R3 = main_cpu.main_cpu_register_file.registers[3];
    assign R4 = main_cpu.main_cpu_register_file.registers[4];
    assign R5 = main_cpu.main_cpu_register_file.registers[5];
    assign R6 = main_cpu.main_cpu_register_file.registers[6];
    assign R7 = main_cpu.main_cpu_register_file.registers[7];
    assign R8 = main_cpu.main_cpu_register_file.registers[8];
    assign R9 = main_cpu.main_cpu_register_file.registers[9];
    assign R10 = main_cpu.main_cpu_register_file.registers[10];
    
    assign overflow = main_cpu.alu_overflow_flag;
    assign carry = main_cpu.alu_carry_flag;
    assign zero = main_cpu.alu_zero_flag;
    assign sign = main_cpu.alu_sign_flag;
    assign parity = main_cpu.alu_parity_flag;
    assign tensor_done = main_cpu.is_tensor_core_done_with_calculation;
    
    // Test checking tasks
    task check_register;
        input integer reg_num;
        input signed [`BUS_WIDTH:0] expected_value;
        input string test_name;
        logic signed [`BUS_WIDTH:0] actual_value;
        begin
            actual_value = main_cpu.main_cpu_register_file.registers[reg_num];
            test_count = test_count + 1;
            if (actual_value == expected_value) begin
                pass_count = pass_count + 1;
            end else begin
                fail_count = fail_count + 1;
            end
        end
    endtask
    
    initial begin
        $dumpfile("build/cpu_test_bench.vcd");
        $dumpvars(0, cpu_test_bench);
        
        // Dump specific signals for clean waveform
        $dumpvars(1, main_cpu.alu_opcode);
        $dumpvars(1, main_cpu.cpu_register_file_write_enable);
        
        clock = 0;
        shifted_clock = 0;
        shifted_clock2 = 0;
        shifted_clock3 = 0;
        
        $display("================================================");
        $display("       CPU TEST BENCH FOR REPORT               ");
        $display("================================================");
        
        #11;
        
        // Execute test program
        for (integer i = 0; i < 100 && machine_code[i] != 32'h0; i = i + 1) begin
            current_instruction = machine_code[i];
            instruction_count = i;
            #20;
            
            // Key test points for report
            case (i)
                0: check_register(1, 8'd10, "ADD_IMM R1,0,10");
                1: check_register(2, 8'd5, "ADD_IMM R2,0,5");
                2: check_register(3, 8'd15, "ADD R3,R1,R2");
                3: check_register(4, -8'd5, "SUB R4,R2,R1");
                6: check_register(7, 8'd1, "EQL R7,R5,R6");
                9: check_register(10, 8'd1, "GRT R10,R8,R9");
                11: begin
                    check_register(12, -8'd128, "OVERFLOW TEST");
                    if (overflow) $display("Overflow detected correctly");
                end
            endcase
        end
        
        #50;
        $display("================================================");
        $display("              FINAL RESULTS                    ");
        $display("================================================");
        $display("Tests Run:    %0d", test_count);
        $display("Tests Passed: %0d", pass_count);
        $display("Tests Failed: %0d", fail_count);
        $display("================================================");
        
        $finish;
    end
endmodule