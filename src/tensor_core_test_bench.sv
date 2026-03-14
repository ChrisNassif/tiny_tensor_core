`timescale 1ns / 1ps
`default_nettype wire


module tensor_core_test_bench();

    // Core signals
    logic generated_clock;
    logic clock;
    logic tensor_core_controller_reset_signal;
    logic memory_controller_reset_signal;

    
    logic [63:0] machine_code [0:400000];
    logic [9:0] current_instruction;
    logic signed [11:0] out;

    integer i;
    integer empty_instruction_count;
    integer done;
    
    int current_instruction_index;
    longint current_memory_controller_instruction;
    


    tensor_core_controller main_tensor_core_controller(
        .clock_in(clock), 
        .reset_in(tensor_core_controller_reset_signal),

        .current_instruction(current_instruction), 
        .tensor_core_controller_output(out)
    );


    tensor_core_memory_controller main_tensor_core_memory_controller(
        .clock_in(generated_clock),
        .reset_in(memory_controller_reset_signal),
        .tensor_core_controller_output(out),

        .clock_out(clock),
        .reset_out(tensor_core_controller_reset_signal),
        .current_tensor_core_instruction(current_instruction)
    );


    // Clock generation
    always begin
        #10 generated_clock = !generated_clock;
    end

    
    initial begin
        // VCD dumping disabled for speed during verification
        $dumpfile("build/tensor_core_test_bench.vcd");
        $dumpvars(0, tensor_core_test_bench);

        memory_controller_reset_signal = 1;
        generated_clock = 0;
        #20;
        memory_controller_reset_signal = 0;
        #20;

        #11;
        

        // Execute original program from machine_code file
        empty_instruction_count = 0;
        done = 0;

        for (i = 0; i < 500000 && done == 0; i = i + 1) begin
            
            current_instruction_index = main_tensor_core_memory_controller.current_machine_code_instruction_index;
            current_memory_controller_instruction = main_tensor_core_memory_controller.machine_code[current_instruction_index];

            if (current_memory_controller_instruction === 64'b0 || current_memory_controller_instruction === 64'bx) begin
                empty_instruction_count = empty_instruction_count + 1;

                if (empty_instruction_count > 20) begin
                    done = 1;
                end
            end 
            else begin
                empty_instruction_count = 0;
            end

            #20; // wait to execute the current instruction
        end

        #50;
        $finish;
    
    end


endmodule