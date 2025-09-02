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

    initial begin
        for (int i = 0; i < NUMBER_OF_REGISTERS; i++) begin
            registers[i] <= 8'b0;
        end
    end

    always_ff @(posedge clock_in) begin
        if (write_enable_in) begin
            registers[write_register_address_in] <= write_data_in;
        end
    end

    assign read_data1_out = registers[read_register_address1_in];
    assign read_data2_out = registers[read_register_address2_in];


    genvar i;
    generate
        for (i = 0; i < NUMBER_OF_REGISTERS; i++) begin : expose_regs
            wire [7:0] reg_wire = registers[i];
        end
    endgenerate


endmodule