`timescale 1ns / 1ps
`default_nettype wire

module cpu_test_bench();

    logic clock;   

    localparam MAX_MACHINE_CODE_LENGTH = 64;

    logic [31:0] machine_code [MAX_MACHINE_CODE_LENGTH-1:0];
    logic [31:0] current_instruction;
    logic [7:0] cpu_output;

    // int file_descriptor;
    // reg [256*8:1] line;
    // int file_line_index;


    // read machine code from file ()
    initial begin
        // file_descriptor = $fopen("machine_code.gpu", "rb");
        
        // if (file_descriptor == 0) begin
        //     $fatal(1, "Failed to open machine_code.gpu");
        // end
        
        // file_line_index = 0;
        // while (!$feof(file_descriptor) && file_line_index < MAX_MACHINE_CODE_LENGTH) begin
        //     void'($fgets(line, file_descriptor));
        //     if (line[8:1] != 0) begin
        //         $sscanf(line, "%b", machine_code[file_line_index]); // parse line into a 32-bit binary word
        //         $display("Instruction[%0d] = %b", file_line_index, machine_code[file_line_index]);
        //         file_line_index++;
        //     end
        // end


        // $fclose(file_descriptor);
        $readmemh("machine_code.gpu", machine_code);
    end


    cpu main_cpu(.clock_in(clock), .current_instruction(current_instruction), .cpu_output(cpu_output));

    always begin
        #5 clock = !clock;
    end
 


    initial begin
        $dumpfile("build/cpu_test_bench.vcd"); //file to store value change dump (vcd)
        $dumpvars(0, cpu_test_bench); //store everything at the current level and below

        clock = 0;

        #6;
        for (integer i = 0; i < MAX_MACHINE_CODE_LENGTH; i++) begin
            current_instruction = machine_code[i];
            #10;
        end


        $display("Finishing Sim"); //print nice message at end
        $finish;
    end
endmodule
 