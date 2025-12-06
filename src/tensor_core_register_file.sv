`define BUS_WIDTH 7

// `define MATRIX_SIZE 4
// `define NUMBER_OF_REGISTERS_PER_MATRIX 3 * 3
// `define NUMBER_OF_MATRICES 2
// `define NUMBER_OF_REGISTERS 2 * 9

// A register file meant to supply values to a tensor core.
// This register file exposes all of the wires to each register, so a tensor core can take each of the values inside the registers in a single clock cycle 
module tensor_core_register_file (
    input logic clock_in,
    input logic reset_in,
    input logic non_bulk_write_enable_in,
    input logic [4:0] non_bulk_write_register_address_in,
    input logic signed [`BUS_WIDTH:0] non_bulk_write_data_in,

    input logic bulk_write_enable_in,
    input logic signed [`BUS_WIDTH:0] bulk_write_data_in [2] [3] [3],

    input logic [4:0] non_bulk_read_register_address_in,
    output logic signed [`BUS_WIDTH:0] non_bulk_read_data_out,
    output logic signed [`BUS_WIDTH:0] bulk_read_data_out [2] [3] [3]
);

    reg [7:0] registers [2] [4] [4];


    assign non_bulk_read_data_out = registers[non_bulk_read_register_address_in/9][(non_bulk_read_register_address_in%9)/3][non_bulk_read_register_address_in%3];


    always_comb begin
        for (int n = 0; n < 2; n++) begin
            for (int i = 0; i < 3; i++) begin
                for (int j = 0; j < 3; j++) begin
                    bulk_read_data_out[n][i][j] = registers[n][i][j];
                end
            end
        end
    end

    always_ff @(posedge clock_in) begin
        if (bulk_write_enable_in && reset_in == 0) begin

            for (int i = 0; i < 2; i++) begin
                for (int j = 0; j < 3; j++) begin
                    for (int k = 0; k < 3; k++) begin
                        registers[i][j][k] <= bulk_write_data_in[i][j][k];
                    end
                end
            end
        end


        else if (non_bulk_write_enable_in && reset_in == 0) begin
            registers[non_bulk_write_register_address_in/9][(non_bulk_write_register_address_in%9)/3][non_bulk_write_register_address_in%3] <= non_bulk_write_data_in;
        end

        else if (reset_in == 1) begin
            for (int i = 0; i < 2; i++) begin
                for (int j = 0; j < 3; j++) begin
                    for (int k = 0; k < 3; k++) begin
                        registers[i][j][k] <= 0;
                    end
                end
            end
        end
    end


    // make the registers visible to gtkwave
    genvar i, j, k;
    generate
        for (i = 0; i < 2; i++) begin : expose_regs1
            for (j = 0; j < 3; j++) begin : expose_regs2
                for (k = 0; k < 3; k++) begin : expose_regs3
                    wire [`BUS_WIDTH:0] reg_wire = registers[i][j][k];
                    wire [`BUS_WIDTH:0] bulk_read_data_out_ = bulk_read_data_out[i][j][k];
                    wire [`BUS_WIDTH:0] bulk_write_data_in_ = bulk_write_data_in[i][j][k];
                end
            end
        end
    endgenerate


endmodule