`define GENERIC_OPCODE 2'b00
`define LOAD_IMMEDIATE_OPCODE 2'b01
`define TENSOR_CORE_OPERATE_OPCODE 2'b10
`define BURST_OPCODE 2'b11
`define GENERIC_RESET_OPSELECT 2'b11

`define BUS_WIDTH 7



module tensor_core_memory_controller(
    input logic doubled_clock_in,
    input logic reset_in,  // can be connected to ground
    input logic [7:0] tensor_core_controller_output,
    output logic clock_out,
    output logic shifted_clock_out,
    output logic [15:0] current_tensor_core_instruction,
);

    wire power_on_reset_signal;
    logic positive_reset_called = 0;
    logic negative_reset_called = 0;
    assign power_on_reset_signal = !(positive_reset_called && negative_reset_called);

    wire should_reset_burst_read_write_state_machine;
    assign should_reset_burst_read_write_state_machine = (opcode == `GENERIC_OPCODE && current_tensor_core_instruction[3:2] == `GENERIC_RESET_OPSELECT && is_burst_write_active == 1'b0) || power_on_reset_signal
    
    logic is_burst_write_active;
    logic is_burst_read_active;
    logic [3:0] burst_current_index; // stores the current index that the burst opcode is looking at either for reading or writing


    logic [15:0] raw_current_instruction;
    wire [1:0] current_opcode;
    wire [1:0] burst_read_write_select;


    logic [31:0] machine_code [0:20000];
    logic [15:0] input_data [0:20000];
    logic [15:0] current_machine_code_instruction_index;



    logic matrix1_memory_address; 
    logic matrix1_data;

    assign matrix1_memory_address = machine_code[current_machine_code_instruction_index][31:16];


    initial begin
        $readmemh("machine_code2", machine_code);
        $readmemh("input_data", input_data);
    end

    
    always_comb begin
        
        raw_current_instruction = machine_code[current_machine_code_instruction_index];
        current_opcode = raw_current_instruction[1:0];

        if (current_opcode == `LOAD_IMMEDIATE_OPCODE) begin
            current_tensor_core_instruction = {raw_current_instruction[15:11], input_data[matrix1_memory_address], raw_current_instruction[2:0]};
        end

        else if (is_burst_write_active) begin
            current_tensor_core_instruction = {matrix1_data[2*burst_current_index], matrix1_data[2*burst_current_index+1]};
        end

        else begin
            current_tensor_core_instruction = raw_current_instruction[15:0];
        end

    end


    always_ff @(posedge doubled_clock_in) begin

        if (reset_in || power_on_reset_signal) begin
            clock_out <= 0;
            current_machine_code_instruction_index <= 0;
            positive_reset_called <= 1;
        end

        else begin
            clock_out <= ~clock_out;
            current_machine_code_instruction_index <= current_machine_code_instruction_index + 1;
        end
    end

    always_ff @(negedge doubled_clock_in) begin

        if (reset_in || power_on_reset_signal) begin
            shifted_clock_out <= 0;
            negative_reset_called <= 1;
        end

        else begin
            shifted_clock_out <= ~shifted_clock_out;
        end
    end




    // manage the state machine for the burst read and write
    // this state machine will manage the burst reads and writes and ensures that it happens for the correct amount of time
    always_ff @(posedge doubled_clock_in) begin

        if (clock_out == 0) begin
            if (should_reset_burst_read_write_state_machine) begin
                burst_current_index <= 5;
                is_burst_read_active <= 0;
                is_burst_write_active <= 0;
            end

            else if (opcode == `BURST_OPCODE && burst_read_write_select == `BURST_READ_SELECT && burst_current_index == 5) begin
                burst_current_index <= 0;
                is_burst_read_active <= 1;
            end

            else if (opcode == `BURST_OPCODE && burst_read_write_select == `BURST_WRITE_SELECT && burst_current_index == 5) begin
                is_burst_write_active <= 1;
                burst_current_index <= 0;
            end


            else if (opcode == `BURST_OPCODE && burst_read_write_select == `BURST_READ_AND_WRITE_SELECT && burst_current_index == 5) begin
                is_burst_write_active <= 1;
                is_burst_read_active <= 1;
                burst_current_index <= 0;
            end

            else if ((is_burst_read_active || is_burst_write_active) && burst_current_index < 4) begin
                burst_current_index <= burst_current_index + 1;
            end

            else if ((is_burst_read_active || is_burst_write_active) && burst_current_index == 4) begin
                burst_current_index <= burst_current_index + 1;
                is_burst_read_active <= 0;
                is_burst_write_active <= 0;
            end
        end
    end


endmodule

