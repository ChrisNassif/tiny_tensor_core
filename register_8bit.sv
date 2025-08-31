`timescale 1ns / 1ps
`default_nettype none
`default_nettype wire


module register_8bit (    
        input clock,
        input write_or_read,
        input enable, 
        input [7:0] write_data,
        output [7:0] read_data
    );

	reg [7:0] register;

	always @ (posedge clock) begin
        if (enable & write_or_read)
            register <= write_data;
        else 
            register <= register;
	end

	assign read_data = (enable & ~write_or_read) ? register : 0;
endmodule