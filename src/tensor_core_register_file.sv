// A register file meant to supply values to a tensor core.
// This register file exposes all of the wires to each register, 
// so a tensor core can take each of the values inside the registers in a single clock cycle 
module tensor_core_register_file (
    input logic clock_in,
    input logic reset_in,

    // writing elements 2 at a time
    input logic dual_load_enable_in,
    input logic [3:0] dual_load_register_address_in,
    input logic signed [4:0] dual_load_data_in [2],
    
    output logic signed [4:0] bulk_store_data_out [18]
);

    reg signed [4:0] registers [18];


    always_comb begin
        // assign bulk store wires
        for (int n = 0; n < 18; n++) begin
            bulk_store_data_out[n] = registers[n];
        end
    end

    always_ff @(posedge clock_in) begin
        if (reset_in) begin
            for (int i = 0; i < 18; i++) begin
                registers[i] <= 5'b0;
            end
        end

        else if (dual_load_enable_in) begin
            if (dual_load_register_address_in < 9) begin
                for (int i = 0; i < 2; i++) begin
                    registers[(dual_load_register_address_in << 1) + i] <= dual_load_data_in[i];
                end
            end
        end
    end


    // make the registers visible to gtkwave
    genvar generate_index;
    generate
        for (generate_index = 0; generate_index < 18; generate_index++) begin : expose_regs
            wire [4:0] reg_wire = registers[generate_index];
            wire [4:0] bulk_store_data_out_ = bulk_store_data_out[generate_index];
        end
    endgenerate

endmodule