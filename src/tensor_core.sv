`define BUS_WIDTH 4


module tensor_core (
    input logic clock_in,
    input logic should_start_tensor_core,
    input logic reset_in,

    input logic signed [`BUS_WIDTH:0] tensor_core_input1 [3][3], 
    input logic signed [`BUS_WIDTH:0] tensor_core_input2 [3][3],

    output logic signed [`BUS_WIDTH*2+3:0] tensor_core_output [3][3]
);


    logic [3:0] counter;


    // these should get synthesized as a wire but is a logic rn for simplicity in generating a ton of them
    logic signed [`BUS_WIDTH*2 + 1:0] products_matrix_multiply [3];
    logic signed [`BUS_WIDTH*2 + 3:0] intermediate_sum_matrix_multiply;


    // The combinatorial logic to layout the multipliers and adders
    always_comb begin

        // Instantiate matrix multiplication multipliers and adders
        for (int k = 0; k < 3; k++) begin
            products_matrix_multiply[k] = tensor_core_input1[counter/3][k] * tensor_core_input2[k][counter%3];
        end

        intermediate_sum_matrix_multiply = products_matrix_multiply[0] + products_matrix_multiply[1] + products_matrix_multiply[2];
        
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
        

        else if (should_start_tensor_core == 1) begin
            counter <= 0;
        end

        else if (counter < 5'd9) begin
            counter <= counter + 1;
        end


        else begin
            counter <= counter;
        end



        // matrix multiply
        if (counter < 5'd9) begin 
            tensor_core_output[counter/3][counter%3] <= intermediate_sum_matrix_multiply;
        end
    end






    // Expose the internals of this module to gtkwave
    genvar k, l;
    generate
        for (k = 0; k < 3; k++) begin : expose_tensor_core2
            wire signed [16:0] products_matrix_multiply_wire = products_matrix_multiply[k];
        end

        wire signed [16:0] intermediate_sum_matrix_multiply_ = intermediate_sum_matrix_multiply;
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
            wire [16:0] tensor_core_output_wire = tensor_core_output[a/3][a%3];
        end
    endgenerate
endmodule