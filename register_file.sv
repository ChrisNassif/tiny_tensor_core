`timescale 1ns / 1ps
`default_nettype none
`default_nettype wire


module register_file #(
    parameter NUMBER_OF_REGISTERS = 8
)(
    input clock,
    input enable,
    input write_enable,
    input [$clog2(NUMBER_OF_REGISTERS)-1:0] register_address,
    input [7:0] write_data,
    output [7:0] read_data
);

    logic [7:0] registers [NUMBER_OF_REGISTERS];

    always_ff @(posedge clock) begin
        if (write_enable) begin
            registers[register_address] <= write_data;
        end
    end

    assign read_data = registers[register_address];

endmodule