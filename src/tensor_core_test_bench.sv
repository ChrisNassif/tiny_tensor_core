`timescale 1ns / 1ps
`default_nettype wire

`define BUS_WIDTH 4


module tensor_core_test_bench();

    // Core signals
    logic generated_clock;
    logic clock;
    logic reset;

    
    logic [63:0] machine_code [0:400000];
    logic [15:0] current_instruction;
    logic signed [7:0] out;
    logic [1024:0] tensor_core_output;

    integer i;
    integer empty_instruction_count;
    integer done;
    
    integer instruction_count = 0;

    
    tensor_core_controller main_tensor_core_controller(
        .clock_in(clock), 
        .reset_in(reset),

        .current_instruction(current_instruction), 
        .tensor_core_controller_output(out)
    );


    tensor_core_memory_controller main_tensor_core_memory_controller(
        .clock_in(generated_clock),
        .reset_in(1'b0),  // can be connected to ground
        .tensor_core_controller_output(out),

        .clock_out(clock),
        .reset_out(reset),
        .current_tensor_core_instruction(current_instruction)
    );


    // Clock generation
    always begin
        #10 generated_clock = !generated_clock;
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


    
    initial begin
        // VCD dumping disabled for speed during verification
        // $dumpfile("build/tensor_core_test_bench.vcd");
        // $dumpvars(0, tensor_core_test_bench);
        
        // $dumpvars(0, T0, T1, T2, T3, T4, T5, T6, T7);
        // $dumpvars(0, T8, T9, T10, T11, T12, T13, T14, T15);
        // $dumpvars(0, T16, T17);
        

        generated_clock = 0;


        $display("==================================================================");
        $display("    TENSOR CORE CONTROLLER TEST WITH TENSOR REGISTER DISPLAY      ");
        $display("==================================================================");
        
        #11;
        

        // Execute original program from machine_code file
        $display("\n================================================");
        empty_instruction_count = 0;
        done = 0;
        
        for (i = 0; i < 500000 && done == 0; i = i + 1) begin
            if (machine_code[i] == 0) begin
                empty_instruction_count = empty_instruction_count + 1;
                if (empty_instruction_count > 100) begin
                    done = 1;
                end
            end else begin
                empty_instruction_count = 0;
            end
            // wait to execute all of the instructions
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

        #50;
        $finish;
    
    end


endmodule