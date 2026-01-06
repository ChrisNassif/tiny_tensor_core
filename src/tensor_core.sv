`define BUS_WIDTH 7

`define BUS_MAX_SIGNED_INTEGER $signed({1'b0, {(`BUS_WIDTH){1'b1}}})
`define BUS_MAX_SIGNED_INTEGER_EXTENDED_MATRIX_MULTIPLY $signed({{(`BUS_WIDTH+3){1'b0}}, `BUS_MAX_SIGNED_INTEGER})
`define BUS_MAX_SIGNED_INTEGER_EXTENDED_MATRIX_ADD $signed({{1'b0}, `BUS_MAX_SIGNED_INTEGER})

`define BUS_MIN_SIGNED_INTEGER $signed({1'b1, {(`BUS_WIDTH){1'b0}}})
`define BUS_MIN_SIGNED_INTEGER_EXTENDED_MATRIX_MULTIPLY $signed({{(`BUS_WIDTH+3){1'b1}}, `BUS_MIN_SIGNED_INTEGER})
`define BUS_MIN_SIGNED_INTEGER_EXTENDED_MATRIX_ADD $signed({{1'b1}, `BUS_MIN_SIGNED_INTEGER})


// `define MATRIX_MULTIPLICATION_BATCH_SIZE 1
// `define MATRIX_ADDITION_BATCH_SIZE 9
// `define RELU_BATCH_SIZE 9

// `define BATCH_SIZE 1




module small_tensor_core (
    input logic clock_in,
    // input logic tensor_core_register_file_write_enable,
    input logic should_start_tensor_core,
    input logic [2:0] matrix_operation_select,
    input logic reset_in,

    input logic signed [`BUS_WIDTH:0] tensor_core_input1 [3][3], 
    input logic signed [`BUS_WIDTH:0] tensor_core_input2 [3][3],

    output logic signed [`BUS_WIDTH:0] tensor_core_output [3][3]
);


    logic [4:0] counter;
    logic [2:0] matrix_operation;
    // logic tensor_core_clock_phase;

    // these should get synthesized as a wire but is a logic rn for simplicity in generating a ton of them
    logic signed [`BUS_WIDTH*2 + 1:0] products_matrix_multiply [3];
    logic signed [`BUS_WIDTH*2 + 3:0] intermediate_sum_matrix_multiply;

    logic signed [`BUS_WIDTH + 1:0] intermediate_sum_matrix_add;




    // The combinatorial logic to layout the multipliers and adders
    always_comb begin

        // Instantiate matrix multiplication multipliers and adders
        for (int k = 0; k < 3; k++) begin
            products_matrix_multiply[k] = tensor_core_input1[counter/3][k] * tensor_core_input2[k][counter%3];
        end

        intermediate_sum_matrix_multiply = products_matrix_multiply[0] + products_matrix_multiply[1] + products_matrix_multiply[2];


        // Instantiate matrix addition adders
        intermediate_sum_matrix_add = tensor_core_input1[counter/3][counter%3] + tensor_core_input2[counter/3][counter%3];
        
    end




    // Two copies of the state machine that controls the state of the tensor core
    always_ff @(posedge clock_in) begin

        if (reset_in) begin

            counter <= 5'd9;

            for (int i = 0; i < 3; i = i + 1) begin
                for (int j = 0; j < 3; j = j + 1) begin
                    tensor_core_output[i][j] <= 0;
                end
            end
        end


        else if (counter < 5'd9) begin
            counter <= counter + 1;
        end

        else if (should_start_tensor_core == 1) begin
            counter <= 0;
            matrix_operation <= matrix_operation_select;
        end

        else begin
            counter <= counter;
        end



        // matrix multiply
        if (matrix_operation == 3'b000) begin 
            
            // // clamp the value to the max signed integer or min signed integer in the case of overflow
            // if (intermediate_sum_matrix_multiply > `BUS_MAX_SIGNED_INTEGER_EXTENDED_MATRIX_MULTIPLY) begin
            //     tensor_core_output[tensor_core_clock_phase] <= `BUS_MAX_SIGNED_INTEGER;
            // end

            // else if (intermediate_sum_matrix_multiply < `BUS_MIN_SIGNED_INTEGER_EXTENDED_MATRIX_MULTIPLY) begin
            //     tensor_core_output[tensor_core_clock_phase] <= `BUS_MIN_SIGNED_INTEGER;
            // end

            // else begin
            tensor_core_output[counter/3][counter%3] <= intermediate_sum_matrix_multiply[`BUS_WIDTH:0];
            // end
        end


        // matrix addition
        else if (matrix_operation == 3'b001) begin

            // // clamp the value to the max signed integer or min signed integer in the case of overflow
            // if (intermediate_sum_matrix_add > `BUS_MAX_SIGNED_INTEGER_EXTENDED_MATRIX_ADD) begin
            //     tensor_core_output[tensor_core_clock_phase] <= `BUS_MAX_SIGNED_INTEGER;
            // end

            // else if (intermediate_sum_matrix_add < `BUS_MIN_SIGNED_INTEGER_EXTENDED_MATRIX_ADD) begin
            //     tensor_core_output[tensor_core_clock_phase] <= `BUS_MIN_SIGNED_INTEGER;
            // end

            // else begin
            tensor_core_output[counter/3][counter%3] <= intermediate_sum_matrix_add[`BUS_WIDTH:0];
            // end
        end



        // relu operation
        // checks the sign bit and if its 1 then set the output to 0
        else if (matrix_operation == 3'b010) begin
            tensor_core_output[counter/3][counter%3] <= (tensor_core_input1[counter/3][counter%3][`BUS_WIDTH] == 1'b0) ? tensor_core_input1[counter/3][counter%3]: 0;
        end
    end








    // Expose the internals of this module to gtkwave
    genvar k, l;
    generate
        for (k = 0; k < 3; k++) begin : expose_tensor_core2
            wire signed [7:0] products_matrix_multiply_wire = products_matrix_multiply[k];
        end

        wire signed [7:0] intermediate_sum_matrix_multiply_ = intermediate_sum_matrix_multiply;
        wire signed [7:0] intermediate_sum_matrix_add_ = intermediate_sum_matrix_add;
    endgenerate


    genvar i, j, a;
    generate
        for (i = 0; i < 3; i++) begin : expose_tensor_core3
            for (j = 0; j < 3; j++) begin: expose_tensor_core4
                wire [7:0] tensor_core_input1_wire = tensor_core_input1[i][j];
                wire [7:0] tensor_core_input2_wire = tensor_core_input2[i][j];
            end
        end

        for (a = 0; a < 9; a++) begin: expose_tensor_core5
            wire [7:0] tensor_core_output_wire = tensor_core_output[a/3][a%3];
        end
    endgenerate
endmodule