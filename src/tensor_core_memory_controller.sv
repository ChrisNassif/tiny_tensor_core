`define BUS_WIDTH 7

module tensor_core_memory_controller(
    input logic doubled_clock_in,
    input logic reset_in,
    input logic cpu_output,
    output logic clock_out,
    output logic shifted_clock_out,
    output logic [15:0] current_instruction,
    output logic [1024:0] tensor_core_output
);

    logic [15:0] machine_code [0:20000];
    logic [15:0] current_machine_code_instruction_index;


    assign machine_code = current_machine_code_instruction[current_machine_code_instruction_index]

    always_ff @(posedge doubled_clock_in) begin

        if (reset_in) begin
            clock_out <= 0;
            current_machine_code_instruction_index <= 0;
            $readmemh("machine_code", machine_code);
        end

        else begin
            clock_out <= ~clock_out;
        end
    end

    always_ff @(negedge doubled_clock_in) begin

        if (reset_in) begin
            shifted_clock_out <= 0;
        end

        else begin
            shifted_clock_out <= ~shifted_clock_out;
        end
    end


    always_ff @(posedge clock_out) begin
        current_machine_code_instruction_index <= current_machine_code_instruction_index + 1;
    end





endmodule

