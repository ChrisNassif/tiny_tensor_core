`timescale 1ns / 1ps
`default_nettype none


module alu_test_bench();

    logic clock;
    logic reset;
    logic [2:0] opcode;
    logic [7:0] a_in, b_in;
    logic [7:0] c_out;
    
    
    alu main_alu(.clock_in(clock), .reset_in(reset), .opcode_in(opcode), .alu_input1(a_in), .alu_input2(b_in), .alu_output(c_out));
 
    always begin
        #5 clock = !clock;
    end
 
    //initial block...this is our test simulation
    initial begin
        $dumpfile("alu_test_bench.vcd"); //file to store value change dump (vcd)
        $dumpvars(0, alu_test_bench); //store everything at the current level and below
        $display("Starting Sim"); //print nice message at start
        clock = 0; //0 is generally a safe value to initialize with and not specify size
        reset = 0;
        a_in = 0;
        b_in = 0;

        #10 reset = 1; //always good to reset
        #10 reset = 0;
        
        $display("a_in     b_in     opcode  c_out");

        for (integer i=0; i<2; i++) begin
          for (integer j=0; j<2; j++) begin
            a_in = i;
            b_in = j;
            opcode = 3'b0;
            
            #10;
            $display("%8b %8b %3b     %8b",a_in, b_in, opcode, c_out); //print values C-style formatting
          
          end
        end
        
        $display("Finishing Sim"); //print nice message at end
        $finish;
    end
endmodule
`default_nettype wire
 
