`define BUS_WIDTH 7

// A register file meant to supply values to a tensor core.
// This register file exposes all of the wires to each register, so a tensor core can take each of the values inside the registers in a single clock cycle 
module tensor_core_register_file #(
    parameter NUMBER_OF_REGISTERS = 32
)(
    input logic clock_in,
    input logic reset_in,
    input logic non_bulk_write_enable_in,
    input logic [$clog2(NUMBER_OF_REGISTERS)-1:0] non_bulk_write_register_address_in,
    input logic signed [`BUS_WIDTH:0] non_bulk_write_data_in,

    input logic bulk_write_enable_in,
    input logic signed [`BUS_WIDTH:0] bulk_write_data_in [(NUMBER_OF_REGISTERS-1)/16 + 1] [4] [4],

    input logic [$clog2(NUMBER_OF_REGISTERS)-1:0] non_bulk_read_register_address_in,
    output logic signed [`BUS_WIDTH:0] non_bulk_read_data_out,
    output logic signed [`BUS_WIDTH:0] bulk_read_data_out [(NUMBER_OF_REGISTERS-1)/16 + 1] [4] [4]
);

    reg [7:0] registers [(NUMBER_OF_REGISTERS-1)/16 + 1] [4] [4];

    initial begin
        for (int i = 0; i < (NUMBER_OF_REGISTERS-1)/16 + 1; i++) begin
            for (int j = 0; j < 4; j++) begin
                for (int k = 0; k < 4; k++) begin
                    registers[i][j][k] = 0;
                end
            end
        end
    end



    assign non_bulk_read_data_out = registers[non_bulk_read_register_address_in/16][(non_bulk_read_register_address_in%16)/4][non_bulk_read_register_address_in%4];


    always_comb begin
        for (int n = 0; n < 2; n++) begin
            for (int i = 0; i < 4; i++) begin
                for (int j = 0; j < 4; j++) begin
                    bulk_read_data_out[n][i][j] = registers[n][i][j];
                end
            end
        end
    end

    always_ff @(posedge clock_in) begin
        if (bulk_write_enable_in && reset_in == 0) begin
            for (int i = 0; i < (NUMBER_OF_REGISTERS-1)/16 + 1; i++) begin
                for (int j = 0; j < 4; j++) begin
                    for (int k = 0; k < 4; k++) begin
                        registers[i][j][k] <= bulk_write_data_in[i][j][k];
                    end
                end
            end
        end


        else if (non_bulk_write_enable_in && reset_in == 0) begin
            registers[non_bulk_write_register_address_in/16][(non_bulk_write_register_address_in%16)/4][non_bulk_write_register_address_in%4] <= non_bulk_write_data_in;
        end

        else if (reset_in == 1) begin
            for (int i = 0; i < (NUMBER_OF_REGISTERS-1)/16 + 1; i++) begin
                for (int j = 0; j < 4; j++) begin
                    for (int k = 0; k < 4; k++) begin
                        registers[i][j][k] <= 0;
                    end
                end
            end
        end
    end


    always_ff @(negedge clock_in) begin
        if (bulk_write_enable_in && reset_in == 0) begin
            for (int i = 0; i < (NUMBER_OF_REGISTERS-1)/16 + 1; i++) begin
                for (int j = 0; j < 4; j++) begin
                    for (int k = 0; k < 4; k++) begin
                        registers[i][j][k] <= bulk_write_data_in[i][j][k];
                    end
                end
            end
        end


        else if (non_bulk_write_enable_in && reset_in == 0) begin
            registers[non_bulk_write_register_address_in/16][(non_bulk_write_register_address_in%16)/4][non_bulk_write_register_address_in%4] <= non_bulk_write_data_in;
        end

        else if (reset_in == 1) begin
            for (int i = 0; i < (NUMBER_OF_REGISTERS-1)/16 + 1; i++) begin
                for (int j = 0; j < 4; j++) begin
                    for (int k = 0; k < 4; k++) begin
                        registers[i][j][k] <= 0;
                    end
                end
            end
        end
    end



    // make the registers visible to gtkwave
    genvar i, j, k;
    generate
        for (i = 0; i < (NUMBER_OF_REGISTERS-1)/16 + 1; i++) begin : expose_regs1
            for (j = 0; j < 4; j++) begin : expose_regs2
                for (k = 0; k < 4; k++) begin : expose_regs3
                    wire [7:0] reg_wire = registers[i][j][k];
                    wire [7:0] bulk_read_data_out_ = bulk_read_data_out[i][j][k];
                    wire [7:0] bulk_write_data_in_ = bulk_write_data_in[i][j][k];
                end
            end
        end
    endgenerate


endmodule