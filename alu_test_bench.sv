`timescale 1ns / 1ps
`default_nettype none


module alu_test_bench();

    logic clock;
    logic reset;
    logic [2:0] alu_opcode;
    logic [7:0] alu_input1, alu_input2;
    logic [7:0] alu_output;
    
    
    alu main_alu(
        .clock_in(clock), .reset_in(reset), .enable_in(1'b1), 
        .opcode_in(alu_opcode), .alu_input1(alu_input1), .alu_input2(alu_input2), 
        .alu_output(alu_output)
    );

    always begin
        #5 clock = !clock;
    end
 


    initial begin
        $dumpfile("alu_test_bench.vcd"); //file to store value change dump (vcd)
        $dumpvars(0, alu_test_bench); //store everything at the current level and below


        clock = 0;
        reset = 0;
        alu_input1 = 0;
        alu_input2 = 0;

        #10 reset = 1; // reset cycle
        #10 reset = 0;
        
        // header
        $display("  alu_input1    alu_input2   opcode       alu_output");

        // test addition opcode
        for (integer i=10; i<20; i++) begin
          for (integer j=15; j<20; j++) begin
            alu_input1 = i;
            alu_input2 = j;
            alu_opcode = 3'b0;
            
            #30;
            $display("%d           %d            %3b        %d",alu_input1, alu_input2, alu_opcode, alu_output); //print values C-style formatting

            if (alu_output !== alu_input1 + alu_input2) begin
                $error("Mismatch: Expected %h, Got %h at time %0t", alu_input1 + alu_input2, alu_output, $time);
            end

          end
        end
        





        $display("Finishing Sim"); //print nice message at end
        $finish;
    end
endmodule
`default_nettype wire
 
