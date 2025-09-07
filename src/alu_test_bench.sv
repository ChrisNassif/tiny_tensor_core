`timescale 1ns / 1ps
`default_nettype wire
`define BUS_WIDTH 3

module alu_test_bench();

    logic clock;
    logic reset;
    logic signed [`BUS_WIDTH:0] alu_opcode;
    logic signed [`BUS_WIDTH:0] alu_input1, alu_input2, alu_output, alu_expected_output;
    
    
    alu main_alu(
        .reset_in(reset), .enable_in(1'b1), 
        .opcode_in(alu_opcode), .alu_input1(alu_input1), .alu_input2(alu_input2), 
        .alu_output(alu_output)
    );

    always begin
        #5 clock = !clock;
    end



    initial begin
        $dumpfile("build/alu_test_bench.vcd"); //file to store value change dump (vcd)
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
        for (integer i=0; i<256; i++) begin
        for (integer j=0; j<256; j++) begin
            alu_input1 = i;
            alu_input2 = j;
            alu_opcode = 8'b000;
            
            #30;
            // $display("%d           %d            %3b        %d",alu_input1, alu_input2, alu_opcode, alu_output);

            alu_expected_output = alu_input1 + alu_input2;
            if (alu_output != alu_expected_output) begin
                $error("Mismatch: Expected %h, Got %h at time %0t", alu_expected_output, alu_output, $time);
            end

        end
        end
        
        // test subtraction opcode
        for (integer i=0; i<256; i++) begin
        for (integer j=0; j<256; j++) begin
            alu_input1 = i;
            alu_input2 = j;
            alu_opcode = 8'b001;
            
            #30;
            // $display("%d           %d            %3b        %d",alu_input1, alu_input2, alu_opcode, alu_output);

            alu_expected_output = alu_input1 - alu_input2;
            if (alu_output != alu_expected_output) begin
                $error("Mismatch: Expected %h, Got %h at time %0t", alu_expected_output, alu_output, $time);
            end

        end
        end
        

        // test multiplication opcode
        for (integer i=0; i<256; i++) begin
        for (integer j=0; j<256; j++) begin
            alu_input1 = i;
            alu_input2 = j;
            alu_opcode = 8'b010;
            
            #30;
            // $display("%d           %d            %3b        %d",alu_input1, alu_input2, alu_opcode, alu_output);

            alu_expected_output = alu_input1 * alu_input2;
            if (alu_output != alu_expected_output) begin
                $error("Mismatch: Expected %h, Got %h at time %0t", alu_expected_output, alu_output, $time);
            end

        end
        end


        // test equals opcode
        for (integer i=0; i<256; i++) begin
        for (integer j=0; j<256; j++) begin
            alu_input1 = i;
            alu_input2 = j;
            alu_opcode = 8'b011;
            
            #30;
            // $display("%d           %d            %3b        %d",alu_input1, alu_input2, alu_opcode, alu_output);

            alu_expected_output = (alu_input1 == alu_input2);
            if (alu_output != alu_expected_output) begin
                $error("Mismatch: Expected %h, Got %h at time %0t", alu_expected_output, alu_output, $time);
            end

        end
        end


        // test greater than opcode
        for (integer i=0; i<256; i++) begin
            for (integer j=0; j<256; j++) begin
                alu_input1 = i;
                alu_input2 = j;
                alu_opcode = 8'b100;
                
                #30;
                // $display("%d           %d            %3b        %d",alu_input1, alu_input2, alu_opcode, alu_output);

                alu_expected_output = (alu_input1 > alu_input2);
                if (alu_output != alu_expected_output) begin
                    $error("Mismatch: Expected %h, Got %h at time %0t", alu_expected_output, alu_output, $time);
                end

            end
        end

        $display("Finishing Sim"); //print nice message at end
        $finish;
    end
endmodule
