`define BUS_WIDTH 7

module cpu_register_file #(
    parameter NUMBER_OF_REGISTERS = 32
)(
    input logic clock_in,
    input logic reset_in,
    input logic write_enable_in,
    input logic [$clog2(NUMBER_OF_REGISTERS)-1:0] read_register_address1_in,
    input logic [$clog2(NUMBER_OF_REGISTERS)-1:0] read_register_address2_in,
    input logic [$clog2(NUMBER_OF_REGISTERS)-1:0] write_register_address_in,
    input logic signed [`BUS_WIDTH:0] write_data_in,
    output logic signed [`BUS_WIDTH:0] read_data1_out,
    output logic signed [`BUS_WIDTH:0] read_data2_out
);

    reg signed [`BUS_WIDTH:0] registers [NUMBER_OF_REGISTERS];
    assign read_data1_out = registers[read_register_address1_in];
    assign read_data2_out = registers[read_register_address2_in];


    initial begin
        for (int i = 0; i < NUMBER_OF_REGISTERS; i++) begin
            registers[i] <= 0;
        end
    end

    always_ff @(posedge clock_in) begin
        if (write_enable_in && write_register_address_in != 0 && reset_in == 0) begin
            registers[write_register_address_in] <= write_data_in;
        end

        else if (reset_in == 1) begin
            for (int i = 0; i < NUMBER_OF_REGISTERS; i++) begin
                registers[i] <= 0;
            end
        end 
    end

    always_ff @(negedge clock_in) begin
        if (write_enable_in && write_register_address_in != 0 && reset_in == 0) begin
            registers[write_register_address_in] <= write_data_in;
        end

        else if (reset_in == 1) begin
            for (int i = 0; i < NUMBER_OF_REGISTERS; i++) begin
                registers[i] <= 0;
            end
        end 
    end


    // make the registers visible to gtkwave
    genvar i;
    generate
        for (i = 0; i < NUMBER_OF_REGISTERS; i++) begin : expose_regs
            wire [7:0] reg_wire = registers[i];
        end
    endgenerate

    // make the registers visible to gtkwave

endmodule