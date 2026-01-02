`define BUS_WIDTH 7

`define BUS_MAX_SIGNED_INTEGER $signed({1'b0, {(`BUS_WIDTH){1'b1}}})
`define BUS_MAX_SIGNED_INTEGER_EXTENDED_MATRIX_MULTIPLY $signed({{(`BUS_WIDTH+3){1'b0}}, `BUS_MAX_SIGNED_INTEGER})
`define BUS_MAX_SIGNED_INTEGER_EXTENDED_MATRIX_ADD $signed({{1'b0}, `BUS_MAX_SIGNED_INTEGER})

`define BUS_MIN_SIGNED_INTEGER $signed({1'b1, {(`BUS_WIDTH){1'b0}}})
`define BUS_MIN_SIGNED_INTEGER_EXTENDED_MATRIX_MULTIPLY $signed({{(`BUS_WIDTH+3){1'b1}}, `BUS_MIN_SIGNED_INTEGER})
`define BUS_MIN_SIGNED_INTEGER_EXTENDED_MATRIX_ADD $signed({{1'b1}, `BUS_MIN_SIGNED_INTEGER})


`define MATRIX_MULTIPLICATION_BATCH_SIZE 1
`define MATRIX_ADDITION_BATCH_SIZE 9
`define RELU_BATCH_SIZE 9

`define BATCH_SIZE 1





// TODO: REFACTOR THIS TO USE WRITE DUAL OR WRITE BULK INSTEAD OF STORING 72 REGISTERS

module small_tensor_core (
    input logic tensor_core_clock,
    input logic tensor_core_register_file_write_enable,
    input logic should_start_tensor_core,
    input logic [2:0] matrix_operation_select,
    input logic reset_in,

    input logic signed [`BUS_WIDTH:0] tensor_core_input1 [3][3], 
    input logic signed [`BUS_WIDTH:0] tensor_core_input2 [3][3],

    output logic signed [`BUS_WIDTH:0] tensor_core_output [3][3]
);

    logic [4:0] counter;
    logic [2:0] matrix_operation;

    // these should get synthesized as a wire but is a logic rn for simplicity in generating a ton of them
    logic signed [`BUS_WIDTH*2 + 1:0] products_matrix_multiply [3] [`BATCH_SIZE];
    logic signed [`BUS_WIDTH*2 + 3:0] intermediate_sum_matrix_multiply [`BATCH_SIZE];

    logic signed [`BUS_WIDTH + 1:0] intermediate_sum_matrix_add [`BATCH_SIZE];




    // The combinatorial logic to layout the multipliers and adders
    always_comb begin

        // Instantiate matrix multiplication multipliers and adders
        for (int i = 0; i < `BATCH_SIZE; i++) begin
            
            // instantiate the multipliers and adders for each of the operations
            for (int k = 0; k < 3; k++) begin
                products_matrix_multiply[k][i] = tensor_core_input1[(counter+i)/3][k] * tensor_core_input2[k][(counter+i)%3];
            end

            intermediate_sum_matrix_multiply[i] = products_matrix_multiply[0][i] + products_matrix_multiply[1][i] + products_matrix_multiply[2][i];
        end


        // Instantiate matrix addition adders
        for (int i = 0; i < `BATCH_SIZE; i++) begin
            intermediate_sum_matrix_add[i] = tensor_core_input1[(counter+i)/3][(counter+i)%3] + tensor_core_input2[(counter+i)/3][(counter+i)%3];
        end

    end



    // Two copies of the state machine that controls the state of the tensor core
    always_ff @(posedge tensor_core_clock) begin

        if (tensor_core_register_file_write_enable == 1 || reset_in == 1) begin
            counter <= 5'd9;

            for (int i = 0; i < 9; i++) begin
                tensor_core_output[i/3][i%3] <= 0;
            end
        end

        else if (counter < 5'd9) begin
            counter <= counter + `BATCH_SIZE;
        end

        else if (should_start_tensor_core == 1) begin
            counter <= 0;
            matrix_operation <= matrix_operation_select;
        end




        // matrix multiply
        if (matrix_operation == 3'b000 && counter < 5'd9) begin 
            
            for (int i = 0; i < `BATCH_SIZE; i++) begin
                // clamp the value to the max signed integer or min signed integer in the case of overflow
                if (intermediate_sum_matrix_multiply[i] > `BUS_MAX_SIGNED_INTEGER_EXTENDED_MATRIX_MULTIPLY) begin
                    tensor_core_output[(counter+i)/3][(counter+i)%3] <= `BUS_MAX_SIGNED_INTEGER;
                end

                else if (intermediate_sum_matrix_multiply[i] < `BUS_MIN_SIGNED_INTEGER_EXTENDED_MATRIX_MULTIPLY) begin
                    tensor_core_output[(counter+i)/3][(counter+i)%3] <= `BUS_MIN_SIGNED_INTEGER;
                end

                else begin
                    tensor_core_output[(counter+i)/3][(counter+i)%3] <= intermediate_sum_matrix_multiply[i][`BUS_WIDTH:0];
                end
            end

        end


        // matrix addition
        else if (matrix_operation == 3'b001 && counter < 5'd9) begin

            for (int i = 0; i < `BATCH_SIZE; i++) begin

                // clamp the value to the max signed integer or min signed integer in the case of overflow
                if (intermediate_sum_matrix_add[i] > `BUS_MAX_SIGNED_INTEGER_EXTENDED_MATRIX_ADD) begin
                    tensor_core_output[(counter+i)/3][(counter+i)%3] <= `BUS_MAX_SIGNED_INTEGER;
                end

                else if (intermediate_sum_matrix_add[i] < `BUS_MIN_SIGNED_INTEGER_EXTENDED_MATRIX_ADD) begin
                    tensor_core_output[(counter+i)/3][(counter+i)%3] <= `BUS_MIN_SIGNED_INTEGER;
                end

                else begin
                    tensor_core_output[(counter+i)/3][(counter+i)%3] <= intermediate_sum_matrix_add[i][`BUS_WIDTH:0];
                end
            end

        end



        // relu operation
        // checks the sign bit and if its 1 then set the output to 0
        else if (matrix_operation == 3'b010 && counter < 5'd9) begin
            
            for (int i = 0; i < `BATCH_SIZE; i++) begin
                tensor_core_output[(counter+i)/3][(counter+i)%3] <= (tensor_core_input1[(counter+i)/3][(counter+i)%3][`BUS_WIDTH] == 1'b0) ? tensor_core_input1[(counter+i)/3][(counter+i)%3]: 0;
            end
        end
    end









    // Expose the internals of this module to gtkwave
    genvar k, l;
    generate
        for (l = 0; l < `BATCH_SIZE; l++) begin: expose_tensor_core
            for (k = 0; k < 3; k++) begin : expose_tensor_core2
                wire signed [7:0] products_matrix_multiply_wire = products_matrix_multiply[k][l];
            end

            wire signed [7:0] intermediate_sum_matrix_multiply_ = intermediate_sum_matrix_multiply[l];
            wire signed [7:0] intermediate_sum_matrix_add_ = intermediate_sum_matrix_add[l];
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