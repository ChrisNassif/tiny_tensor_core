`define NOP_OPCODE 2'b00
`define TENSOR_CORE_OPERATE_OPCODE 2'b01
`define BURST_OPCODE 2'b10
`define RESET_OPCODE 2'b11

`define BURST_READ_SELECT 2'b00
`define BURST_WRITE_SELECT 2'b01
`define BURST_READ_AND_WRITE_SELECT 2'b10


`define BUS_WIDTH 7



module tensor_core_memory_controller(
    input logic clock_in,
    input logic reset_in,  // can be connected to ground
    input logic [7:0] tensor_core_controller_output,

    output logic clock_out,
    output logic reset_out,
    output logic [15:0] current_tensor_core_instruction,
);

    assign clock_out = clock_in;


    logic power_on_reset_signal = 1;

    assign reset_out = (current_opcode == `RESET_OPCODE) || reset_in || power_on_reset_signal;


    wire should_reset_burst_read_write_state_machine;
    
    logic is_burst_write_active;
    logic is_burst_read_active;
    logic [3:0] burst_current_index; // stores the current index that the burst opcode is looking at either for reading or writing


    logic [15:0] raw_current_instruction;
    wire [1:0] current_opcode;
    wire [1:0] burst_read_write_select;

    assign burst_read_write_select = current_instruction[3:2];




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

        // Process the current instruction word if it is some kind of write instructions
        if (is_burst_write_active) begin
            current_tensor_core_instruction = {matrix1_data[2*burst_current_index], matrix1_data[2*burst_current_index+1]};
        end

        else begin
            current_tensor_core_instruction = raw_current_instruction[15:0];
        end


        // Process the reset instruction
        if (current_opcode == `RESET_OPCODE) begin
            current_tensor_core_instruction = 0;    // insert a nop and reset
        end

    end


    always_ff @(posedge clock_in) begin

        if (reset_out) begin
            clock_out <= 0;
            current_machine_code_instruction_index <= 0;
            power_on_reset_signal <= 0;
        end

        else begin
            clock_out <= ~clock_out;
            current_machine_code_instruction_index <= current_machine_code_instruction_index + 1;
        end
    end




    // manage the state machine for the burst read and write
    // this state machine will manage the burst reads and writes and ensures that it happens for the correct amount of time
    always_ff @(posedge clock_in) begin

        if (clock_out == 0) begin
            if (reset_out) begin
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

