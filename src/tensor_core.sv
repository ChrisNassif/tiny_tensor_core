`define BUS_WIDTH 7
`define BATCH_SIZE 1


module small_tensor_core (
    input logic tensor_core_clock,
    input logic tensor_core_register_file_write_enable,
    input logic signed [`BUS_WIDTH:0] tensor_core_input1 [3][3], 
    input logic signed [`BUS_WIDTH:0] tensor_core_input2 [3][3],
    input logic should_start_tensor_core,
    input logic [2:0] operation_select,
    input logic reset_in,

    output logic signed [`BUS_WIDTH:0] tensor_core_output [3][3]
);

    logic [4:0] counter;
    logic [1:0] operation;
    logic signed [`BUS_WIDTH*2 + 1:0] products [3] [`BATCH_SIZE];



    // The combinatorial logic to layout the multipliers and adders
    always_comb begin
        for (int i = 0; i < `BATCH_SIZE; i++) begin

            for (int k = 0; k < 3; k++) begin
                products[k][i] = tensor_core_input1[(counter+i)/3][k] * tensor_core_input2[k][(counter+i)%3];
            end
            
            // matrix multiply
            if (operation == 3'b000) begin 
                // tensor_core_output[counter/4][counter%4] = tensor_core_input1[counter/4][counter%4] + products[0] + products[1] + products[2] + products[3];
                tensor_core_output[(counter+i)/3][(counter+i)%3] = products[0][i] + products[1][i] + products[2][i];
            end


            // matrix addition
            else if (operation == 3'b001) begin
                tensor_core_output[(counter+i)/3][(counter+i)%3] = tensor_core_input1[(counter+i)/3][(counter+i)%3] + tensor_core_input2[(counter+i)/3][(counter+i)%3];
            end


            // relu
            else if (operation == 3'b010) begin
                tensor_core_output[(counter+i)/3][(counter+i)%3] = (tensor_core_input1[(counter+i)/3][(counter+i)%3][`BUS_WIDTH] == 1'b0) ? tensor_core_input1[(counter+i)/3][(counter+i)%3]: 0;
            end

            // addition summation
            // else if (operation == 3'b011) begin
            // end


            // dot product 
            // else if (operation == 3'b100) begin           
            // end

        end
    end



    // Two copies of the state machine that controls the state of the tensor core
    always_ff @(posedge tensor_core_clock) begin

        if (tensor_core_register_file_write_enable == 1 || reset_in == 1) begin
            counter <= 5'd9;
        end

        else if (counter < 5'd9) begin
            counter <= counter + `BATCH_SIZE;
        end

        if (should_start_tensor_core == 1 && counter >= 5'd9) begin
            counter <= 0;
            operation <= operation_select;
        end
    end

    
    always @(negedge tensor_core_clock) begin

        if (tensor_core_register_file_write_enable == 1 || reset_in == 1) begin
            counter <= 5'd9;
        end

        else if (counter < 5'd9) begin
            counter <= counter + `BATCH_SIZE;
        end

        if (should_start_tensor_core == 1 && counter >= 5'd9) begin
            counter <= 0;
            operation <= operation_select;
        end
        
    end









    // Expose the internals of this module to gtkwave
    genvar k, l;
    generate
        for (k = 0; k < 3; k++) begin : expose_tensor_core
            for (l = 0; l < `BATCH_SIZE; l++) begin: expose_tensor_core2
                wire signed [7:0] products_wire = products[k][l];
            end
        end
    endgenerate


    genvar i, j;
    generate
        for (i = 0; i < 3; i++) begin : expose_tensor_core3
            for (j = 0; j < 3; j++) begin: expose_tensor_core4
                wire [7:0] tensor_core_input1_wire = tensor_core_input1[i][j];
                wire [7:0] tensor_core_input2_wire = tensor_core_input2[i][j];
                wire [7:0] tensor_core_output_wire = tensor_core_output[i][j];
            end
        end
    endgenerate
endmodule