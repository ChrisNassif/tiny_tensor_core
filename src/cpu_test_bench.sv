`timescale 1ns / 1ps
`default_nettype wire

module alu_test_bench();

    logic clock;   

    // read machine code from file
    reg [32*45:0] machine_code;
    integer file_descriptor;

    initial begin
    file_descriptor = $fopen("machine_code.gpu", "r");

        while (! $feof(file_descriptor)) begin

        $fgets(machine_code, file_descriptor);

        $display("%0s", machine_code);
        end
        $fclose(file_descriptor);
    end


    cpu main_cpu(.clock_in(clock));

    always begin
        #5 clock = !clock;
    end
 


    initial begin
        $dumpfile("build/cpu_test_bench.vcd"); //file to store value change dump (vcd)
        $dumpvars(0, alu_test_bench); //store everything at the current level and below


        clock = 0;
    
        $display("Finishing Sim"); //print nice message at end
        $finish;
    end
endmodule
 