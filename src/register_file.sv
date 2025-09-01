`timescale 1ns / 1ps
`default_nettype none
`default_nettype wire


module register_file #(
    parameter NUMBER_OF_REGISTERS = 256
)(
    input logic clock_in,
    input logic write_enable_in,
    input logic [$clog2(NUMBER_OF_REGISTERS)-1:0] read_register_address1_in,
    input logic [$clog2(NUMBER_OF_REGISTERS)-1:0] read_register_address2_in,
    input logic [$clog2(NUMBER_OF_REGISTERS)-1:0] write_register_address_in,
    input logic [7:0] write_data_in,
    output logic [7:0] read_data1_out,
    output logic [7:0] read_data2_out
);

    reg [7:0] registers [NUMBER_OF_REGISTERS];

    always_ff @(posedge clock_in) begin
        if (write_enable_in) begin
            registers[write_register_address_in] <= write_data_in;
        end
    end

    assign read_data1_out = registers[read_register_address2_in];
    assign read_data2_out = register[read_register_address2_in];

endmodule