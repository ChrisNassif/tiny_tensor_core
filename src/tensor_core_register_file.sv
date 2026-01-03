`define BUS_WIDTH 7



// A register file meant to supply values to a tensor core.
// This register file exposes all of the wires to each register, so a tensor core can take each of the values inside the registers in a single clock cycle 
module tensor_core_register_file (
    input logic clock_in,
    input logic reset_in,

    // non bulk read/ write
    input logic non_bulk_write_enable_in,
    input logic [4:0] non_bulk_write_register_address_in,
    input logic signed [`BUS_WIDTH:0] non_bulk_write_data_in,

    input logic [4:0] non_bulk_read_register_address_in,
    output logic signed [`BUS_WIDTH:0] non_bulk_read_data_out,

    // writing elements 4 at a time
    input logic quad_write_enable_in,
    input logic [2:0] quad_write_register_address_in, // supports values 0 to 4
    input logic signed [`BUS_WIDTH:0] quad_write_data_in [4],

    // dual read
    input logic [3:0] dual_read_register_address_in,  // supports values 0 to 8
    output logic signed [`BUS_WIDTH:0] dual_read_data_out [2],

    // // dual write to matrix 1
    // input logic dual_write_matrix1_enable_in,
    // input logic [2:0] dual_write_matrix1_register_address_in, // supports values 0 to 4 and only supports writing to matrix 1
    // input logic signed [`BUS_WIDTH:0] dual_write_matrix1_data_in [2],

    // // triple write
    // input logic triple_write_matrix1_enable_in,
    // input logic [2:0] triple_write_matrix1_register_address_in, // supports values 0 to 6
    // input logic signed [`BUS_WIDTH:0] triple_write_matrix1_data_in [2],

    // bulk read/ write
    input logic bulk_write_enable_in,
    input logic signed [`BUS_WIDTH:0] bulk_write_data_in [2] [3] [3],

    output logic signed [`BUS_WIDTH:0] bulk_read_data_out [2] [3] [3]
);


    reg signed [7:0] registers [2] [3] [3];


    assign non_bulk_read_data_out = registers[non_bulk_read_register_address_in/9][(non_bulk_read_register_address_in%9)/3][non_bulk_read_register_address_in%3];



    always_comb begin

        // assign bulk read wires
        for (int n = 0; n < 2; n++) begin
            for (int i = 0; i < 3; i++) begin
                for (int j = 0; j < 3; j++) begin
                    bulk_read_data_out[n][i][j] = registers[n][i][j];
                end
            end
        end


        // assign dual read wires
        for (int n = 0; n < 2; n++) begin
            dual_read_data_out[n] = registers[((dual_read_register_address_in<<1)+n)/9][(((dual_read_register_address_in<<1)+n)%9)/3][((dual_read_register_address_in<<1)+n)%3];
        end

    end


    always_ff @(posedge clock_in) begin
        
        // bulk write
        if (bulk_write_enable_in && reset_in == 0) begin

            for (int i = 0; i < 2; i++) begin
                for (int j = 0; j < 3; j++) begin
                    for (int k = 0; k < 3; k++) begin
                        registers[i][j][k] <= bulk_write_data_in[i][j][k];
                    end
                end
            end
        end


        // quad write
        else if (quad_write_enable_in && reset_in == 0) begin
            for (int i = 0; i < 4; i++) begin
                registers[((quad_write_register_address_in<<2)+i)/9][(((quad_write_register_address_in<<2)+i)%9)/3][((quad_write_register_address_in<<2)+i)%3] <= quad_write_data_in[i];
            end
        end


        // dual write to matrix 1
        // else if (dual_write_matrix1_enable_in && reset_in == 0) begin
            
        //     if (dual_write_matrix1_register_address_in != 3'd4) begin
                
        //         for (int i = 0; i < 2; i++) begin
        //             registers[0][(((dual_write_matrix1_register_address_in<<1)+i)%9)/3][((dual_write_matrix1_register_address_in<<1)+i)%3] <= dual_write_matrix1_data_in[i];
        //         end
        //     end

        //     else begin
        //         registers[0][2][2] <= dual_write_matrix1_data_in[0];
        //     end

        // end


        // else if (triple_write_enable_in && reset_in == 0) begin
        //     for (int i = 0; i < 3; i++) begin
        //         registers[((triple_write_register_address_in<<2)+i)/9][(((triple_write_register_address_in<<2)+i)%9)/3][((triple_write_register_address_in<<2)+i)%3] <= triple_write_data_in[i];
        //     end
        // end


        // non bulk write
        else if (non_bulk_write_enable_in && reset_in == 0) begin
            registers[non_bulk_write_register_address_in/9][(non_bulk_write_register_address_in%9)/3][non_bulk_write_register_address_in%3] <= non_bulk_write_data_in;
        end


        // write logic
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



    // // make the registers visible to gtkwave
    // genvar i, j, k;
    // generate
    //     for (i = 0; i < 2; i++) begin : expose_regs1
    //         for (j = 0; j < 3; j++) begin : expose_regs2
    //             for (k = 0; k < 3; k++) begin : expose_regs3
    //                 wire [`BUS_WIDTH:0] reg_wire = registers[i][j][k];
    //                 wire [`BUS_WIDTH:0] bulk_read_data_out_ = bulk_read_data_out[i][j][k];
    //                 wire [`BUS_WIDTH:0] bulk_write_data_in_ = bulk_write_data_in[i][j][k];
    //             end
    //         end
    //     end
    // endgenerate


endmodule