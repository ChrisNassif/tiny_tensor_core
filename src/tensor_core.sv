`define BUS_WIDTH 3

module small_tensor_core (
    input logic clock_in,
    input logic tensor_core_register_file_write_enable,
    input logic signed [`BUS_WIDTH:0] tensor_core_input1 [4][4], 
    input logic signed [`BUS_WIDTH:0] tensor_core_input2 [4][4],
    output logic signed [`BUS_WIDTH:0] tensor_core_output [4][4],
    output logic is_done_with_calculation
);
    logic [4:0] counter;
    logic signed [`BUS_WIDTH:0] products [4];

    always_comb begin
        for (int k = 0; k < 4; k++) begin
            products[k] = tensor_core_input1[counter/4][k] * tensor_core_input2[k][counter%4];
        end 
        // tensor_core_output[counter/4][counter%4] = tensor_core_input1[counter/4][counter%4] + products[0] + products[1] + products[2] + products[3];
        tensor_core_output[counter/4][counter%4] = products[0] + products[1] + products[2] + products[3];
    end

    always @(negedge clock_in) begin

        if (tensor_core_register_file_write_enable == 1) begin
            counter = 0;
            is_done_with_calculation = 0;
        end

        if (is_done_with_calculation == 0 && tensor_core_register_file_write_enable == 0) begin
            counter++;
        end

        if (counter == 5'b10000) begin
            is_done_with_calculation = 1;
        end
    end

    always @(posedge clock_in) begin
        if (tensor_core_register_file_write_enable == 1) begin
            counter = 0;
            is_done_with_calculation = 0;
        end

        if (is_done_with_calculation == 0 && tensor_core_register_file_write_enable == 0) begin
            counter++;
        end

        if (counter == 5'b10000) begin
            is_done_with_calculation = 1;
        end
    end


    // Expose the internals of this module to gtkwave
    genvar i, j;
    generate
        for (i = 0; i < 4; i++) begin : expose_tensor_core
            for (j = 0; j < 4; j++) begin: expose_tensor_core2
                wire [7:0] tensor_core_input1_wire = tensor_core_input1[i][j];
                wire [7:0] tensor_core_input2_wire = tensor_core_input2[i][j];
                wire [7:0] tensor_core_output_wire = tensor_core_output[i][j];
            end
        end
    endgenerate
endmodule


// module tensor_core (
//     input logic [7:0] tensor_core_input1 [4][4], 
//     input logic [7:0] tensor_core_input2 [4][4],
//     output logic [7:0] tensor_core_output [4][4]
// );
//     always_comb begin
        
//         for (int i = 0; i < 4; i++) begin
//             for (int j = 0; j < 4; j++) begin

//                 tensor_core_output[i][j] = 0;
//                 for (int k = 0; k < 4; k++) begin
//                     tensor_core_output[i][j] = tensor_core_output[i][j] + (tensor_core_input1[i][k] * tensor_core_input2[k][j]);
//                 end
//             end
//         end
//     end


//     // Expose the internals of this module to gtkwave
//     genvar i, j;
//     generate
//         for (i = 0; i < 4; i++) begin : expose_tensor_core
//             for (j = 0; j < 4; j++) begin: expose_tensor_core2
//                 wire [7:0] tensor_core_input1_wire = tensor_core_input1[i][j];
//                 wire [7:0] tensor_core_input2_wire = tensor_core_input2[i][j];
//                 wire [7:0] tensor_core_output_wire = tensor_core_output[i][j];
//             end
//         end
//     endgenerate
// endmodule



// module tensor_core_mma (
//     input logic [7:0] tensor_core_input1 [4][4], 
//     input logic [7:0] tensor_core_input2 [4][4],
//     output logic [7:0] tensor_core_output [4][4]
// );
//     always_comb begin
        
//         for (int i = 0; i < 4; i++) begin
//             for (int j = 0; j < 4; j++) begin

//                 tensor_core_output[i][j] = tensor_core_input1[i][j];
//                 for (int k = 0; k < 4; k++) begin
//                     tensor_core_output[i][j] = tensor_core_output[i][j] + (tensor_core_input1[i][k] * tensor_core_input2[k][j]);
//                 end
//             end
//         end
//     end


//     // Expose the internals of this module to gtkwave
//     genvar i, j;
//     generate
//         for (i = 0; i < 4; i++) begin : expose_tensor_core
//             for (j = 0; j < 4; j++) begin: expose_tensor_core2
//                 wire [7:0] tensor_core_input1_wire = tensor_core_input1[i][j];
//                 wire [7:0] tensor_core_input2_wire = tensor_core_input2[i][j];
//                 wire [7:0] tensor_core_output_wire = tensor_core_output[i][j];
//             end
//         end
//     endgenerate
// endmodule


// module small_tensor_core (
//     input logic clock_in,
//     input logic tensor_core_register_file_write_enable,
//     input logic [7:0] tensor_core_input1 [4][4], 
//     input logic [7:0] tensor_core_input2 [4][4],
//     output logic [7:0] tensor_core_output [4][4],
//     output logic is_done_with_calculation
// );
//     logic [4:0] counter, counter2;

//     // multiply_accumulate ma(
//     //     .a(tensor_core_output[counter/4][counter%4]), .b(tensor_core_input1[counter/4][3:0]), 
//     //     .c(tensor_core_input2[3:0][counter%4]), .clock_in(clock_in), .is_done_with_calculation(is_done_with_calculation),
//     //     .counter(counter)
//     // );

//     always @(posedge clock_in) begin

//         if (tensor_core_register_file_write_enable == 1) begin
//             counter = 0;
//             counter2 = 0;
//             is_done_with_calculation = 0;
//         end

//         if (is_done_with_calculation == 0) begin
//             if (counter2 == 0) begin
//                 tensor_core_output[counter/4][counter%4] = 0;
//             end
//             // tensor_core_output[counter/4][counter%4] = tensor_core_input1[i][j];
//             tensor_core_output[counter/4][counter%4] = tensor_core_output[counter/4][counter%4] + (tensor_core_input1[counter/4][counter2] * tensor_core_input2[counter2][counter%4]);

//             if (counter2 == 3) begin
//                 counter++;
//                 counter2 = 0;
//             end
//             else begin
//                 counter2++;
//             end
//         end

//         if (counter == 5'b10000) begin
//             is_done_with_calculation = 1;
//         end
//     end


//     // Expose the internals of this module to gtkwave
//     genvar i, j;
//     generate
//         for (i = 0; i < 4; i++) begin : expose_tensor_core
//             for (j = 0; j < 4; j++) begin: expose_tensor_core2
//                 wire [7:0] tensor_core_input1_wire = tensor_core_input1[i][j];
//                 wire [7:0] tensor_core_input2_wire = tensor_core_input2[i][j];
//                 wire [7:0] tensor_core_output_wire = tensor_core_output[i][j];
//             end
//         end
//     endgenerate
// endmodule


// module small_tensor_core (
//     input  logic clock_in,
//     input  logic tensor_core_register_file_write_enable,
//     input  logic [7:0] tensor_core_input1 [4][4], 
//     input  logic [7:0] tensor_core_input2 [4][4],
//     output logic [7:0] tensor_core_output [4][4],
//     output logic is_done_with_calculation
// );

//     logic [1:0] row, col;           // which output we are working on
//     logic [15:0] sum;               // wider accumulator
//     logic running;

//     // parallel multiply signals
//     logic [15:0] products [4];

//     always_comb begin
//         for (int k = 0; k < 4; k++) begin
//             products[k] = tensor_core_input1[row][k] * tensor_core_input2[k][col];
//         end
//     end

//     always_ff @(posedge clock_in) begin
//         if (tensor_core_register_file_write_enable) begin
//             row <= 0;
//             col <= 0;
//             is_done_with_calculation <= 0;
//             running <= 1;
//         end else if (running) begin
//             // perform dot product in one cycle (4 multipliers + adder tree)
//             sum = products[0] + products[1] + products[2] + products[3];
//             tensor_core_output[row][col] <= sum[7:0]; // truncate

//             // advance to next element
//             if (col == 3) begin
//                 col <= 0;
//                 if (row == 3) begin
//                     row <= 0;
//                     running <= 0;
//                     is_done_with_calculation <= 1;
//                 end else begin
//                     row <= row + 1;
//                 end
//             end else begin
//                 col <= col + 1;
//             end
//         end
//     end

// endmodule



// module multiply_accumulate(
//     output logic [7:0] a,
//     input logic [7:0] b [4], 
//     input logic [7:0] c [4], 
//     input logic clock_in, 
//     input logic is_done_with_calculation,
//     input logic [4:0] counter
// );

//     always @(posedge clock_in) begin

//         if (is_done_with_calculation == 0) begin
//             a = 0;
//             // tensor_core_output[counter/4][counter%4] = tensor_core_input1[i][j];
//             for (int k = 0; k < 4; k++) begin
//                 a = a + (b[k] * c[k]);
//             end
//             counter++;
//         end
//     end
// endmodule


// module multiply_accumulate2(
//     output logic [7:0] a [4],
//     input logic [7:0] b [4], 
//     input logic [7:0] c [4], 
//     input logic clock_in, 
//     input logic is_done_with_calculation,
//     input logic [5:0] counter
// );
//     if (is_done_with_calculation == 0) begin
//         always @(posedge clock_in) begin
//             for (int k = 0; k < 4; k++) begin
//                 a = a + (b[k] * c[k]);
//             end
//         end
//         counter++
//     end
// endmodule


