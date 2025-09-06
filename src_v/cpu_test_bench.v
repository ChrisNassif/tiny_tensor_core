`default_nettype wire
module cpu_test_bench;
	reg _sv2v_0;
	reg clock;
	localparam MAX_MACHINE_CODE_LENGTH = 1023;
	reg [31:0] machine_code [0:1022];
	reg [31:0] current_instruction;
	wire [7:0] cpu_output;
	integer test_count = 0;
	integer pass_count = 0;
	integer fail_count = 0;
	initial $readmemh("machine_code", machine_code);
	cpu main_cpu(
		.clock_in(clock),
		.current_instruction(current_instruction),
		.cpu_output(cpu_output)
	);
	always #(5) clock = !clock;
	wire [7:0] reg0_value = main_cpu.main_cpu_register_file.registers[0];
	wire [7:0] reg1_value = main_cpu.main_cpu_register_file.registers[1];
	wire [7:0] reg2_value = main_cpu.main_cpu_register_file.registers[2];
	wire [7:0] reg3_value = main_cpu.main_cpu_register_file.registers[3];
	wire [7:0] reg4_value = main_cpu.main_cpu_register_file.registers[4];
	wire [7:0] reg5_value = main_cpu.main_cpu_register_file.registers[5];
	wire [7:0] reg6_value = main_cpu.main_cpu_register_file.registers[6];
	wire [7:0] reg7_value = main_cpu.main_cpu_register_file.registers[7];
	wire [7:0] reg8_value = main_cpu.main_cpu_register_file.registers[8];
	wire [7:0] reg9_value = main_cpu.main_cpu_register_file.registers[9];
	wire [7:0] reg10_value = main_cpu.main_cpu_register_file.registers[10];
	wire alu_overflow = main_cpu.alu_overflow_flag;
	wire alu_carry = main_cpu.alu_carry_flag;
	wire alu_zero = main_cpu.alu_zero_flag;
	wire alu_sign = main_cpu.alu_sign_flag;
	wire alu_parity = main_cpu.alu_parity_flag;
	wire [7:0] status_reg = main_cpu.status_register;
	function [7:0] get_register_value;
		input integer reg_num;
		case (reg_num)
			0: get_register_value = reg0_value;
			1: get_register_value = reg1_value;
			2: get_register_value = reg2_value;
			3: get_register_value = reg3_value;
			4: get_register_value = reg4_value;
			5: get_register_value = reg5_value;
			6: get_register_value = reg6_value;
			7: get_register_value = reg7_value;
			8: get_register_value = reg8_value;
			9: get_register_value = reg9_value;
			10: get_register_value = reg10_value;
			default:
				if (reg_num < 256)
					get_register_value = main_cpu.main_cpu_register_file.registers[reg_num];
				else
					get_register_value = 8'hxx;
		endcase
	endfunction
	task check_register;
		input integer reg_num;
		input [7:0] expected_value;
		input string test_name;
		reg [7:0] actual_value;
		begin
			actual_value = get_register_value(reg_num);
			test_count = test_count + 1;
			if (actual_value == expected_value) begin
				$display("PASS: %s - reg%0d = %0d (expected %0d)", test_name, reg_num, actual_value, expected_value);
				pass_count = pass_count + 1;
			end
			else begin
				$display("FAIL: %s - reg%0d = %0d (expected %0d)", test_name, reg_num, actual_value, expected_value);
				fail_count = fail_count + 1;
			end
		end
	endtask
	task check_register_with_overflow;
		input integer reg_num;
		input [7:0] expected_value;
		input reg expected_overflow;
		input string test_name;
		reg [7:0] actual_value;
		begin
			actual_value = get_register_value(reg_num);
			test_count = test_count + 1;
			if ((actual_value == expected_value) && (alu_overflow == expected_overflow)) begin
				$display("PASS: %s - reg%0d=%0d (exp %0d), overflow=%b", test_name, reg_num, actual_value, expected_value, alu_overflow);
				pass_count = pass_count + 1;
			end
			else begin
				$display("FAIL: %s - reg%0d=%0d (exp %0d), overflow=%b (exp %b)", test_name, reg_num, actual_value, expected_value, alu_overflow, expected_overflow);
				fail_count = fail_count + 1;
			end
		end
	endtask
	task check_register_with_parity;
		input integer reg_num;
		input [7:0] expected_value;
		input reg expected_parity;
		input string test_name;
		reg [7:0] actual_value;
		begin
			actual_value = get_register_value(reg_num);
			test_count = test_count + 1;
			if ((actual_value == expected_value) && (alu_parity == expected_parity)) begin
				$display("PASS: %s - reg%0d=%0d, parity=%b", test_name, reg_num, actual_value, alu_parity);
				pass_count = pass_count + 1;
			end
			else begin
				$display("FAIL: %s - reg%0d=%0d (exp %0d), parity=%b (exp %b)", test_name, reg_num, actual_value, expected_value, alu_parity, expected_parity);
				fail_count = fail_count + 1;
			end
		end
	endtask
	task check_register_with_all_flags;
		input integer reg_num;
		input [7:0] expected_value;
		input reg expected_overflow;
		input reg expected_carry;
		input reg expected_zero;
		input reg expected_sign;
		input reg expected_parity;
		input string test_name;
		reg [7:0] actual_value;
		begin
			actual_value = get_register_value(reg_num);
			test_count = test_count + 1;
			if ((((((actual_value == expected_value) && (alu_overflow == expected_overflow)) && (alu_carry == expected_carry)) && (alu_zero == expected_zero)) && (alu_sign == expected_sign)) && (alu_parity == expected_parity)) begin
				$display("PASS: %s - reg%0d=%0d, flags: O=%b C=%b Z=%b S=%b P=%b", test_name, reg_num, actual_value, alu_overflow, alu_carry, alu_zero, alu_sign, alu_parity);
				pass_count = pass_count + 1;
			end
			else begin
				$display("FAIL: %s - reg%0d=%0d (exp %0d)", test_name, reg_num, actual_value, expected_value);
				$display("      actual flags: O=%b C=%b Z=%b S=%b P=%b", alu_overflow, alu_carry, alu_zero, alu_sign, alu_parity);
				$display("      expected:     O=%b C=%b Z=%b S=%b P=%b", expected_overflow, expected_carry, expected_zero, expected_sign, expected_parity);
				fail_count = fail_count + 1;
			end
		end
	endtask
	always @(posedge clock)
		if (current_instruction != 32'h00000000)
			case (current_instruction[7:0])
				8'h00: begin
					$display("Time %0t: ADD reg%0d, reg%0d, reg%0d", $time, current_instruction[31:24], current_instruction[23:16], current_instruction[15:8]);
					if (main_cpu.cpu_register_file_write_enable)
						$display("    Flags: O=%b C=%b Z=%b S=%b P=%b", alu_overflow, alu_carry, alu_zero, alu_sign, alu_parity);
				end
				8'h01: begin
					$display("Time %0t: SUB reg%0d, reg%0d, reg%0d", $time, current_instruction[31:24], current_instruction[23:16], current_instruction[15:8]);
					if (main_cpu.cpu_register_file_write_enable)
						$display("    Flags: O=%b C=%b Z=%b S=%b P=%b", alu_overflow, alu_carry, alu_zero, alu_sign, alu_parity);
				end
				8'h02: begin
					$display("Time %0t: MUL reg%0d, reg%0d, reg%0d", $time, current_instruction[31:24], current_instruction[23:16], current_instruction[15:8]);
					if (main_cpu.cpu_register_file_write_enable)
						$display("    Flags: O=%b C=%b Z=%b S=%b P=%b", alu_overflow, alu_carry, alu_zero, alu_sign, alu_parity);
				end
				8'h03: begin
					$display("Time %0t: EQL reg%0d, reg%0d, reg%0d", $time, current_instruction[31:24], current_instruction[23:16], current_instruction[15:8]);
					if (main_cpu.cpu_register_file_write_enable)
						$display("    Flags: O=%b C=%b Z=%b S=%b P=%b", alu_overflow, alu_carry, alu_zero, alu_sign, alu_parity);
				end
				8'h04: begin
					$display("Time %0t: GRT reg%0d, reg%0d, reg%0d", $time, current_instruction[31:24], current_instruction[23:16], current_instruction[15:8]);
					if (main_cpu.cpu_register_file_write_enable)
						$display("    Flags: O=%b C=%b Z=%b S=%b P=%b", alu_overflow, alu_carry, alu_zero, alu_sign, alu_parity);
				end
				8'h08:
					$display("Time %0t: NOP", $time);
				8'h09: begin
					$display("Time %0t: ADD_IMM reg%0d, reg%0d, %0d", $time, current_instruction[31:24], current_instruction[23:16], current_instruction[15:8]);
					if (main_cpu.cpu_register_file_write_enable)
						$display("    Flags: O=%b C=%b Z=%b S=%b P=%b", alu_overflow, alu_carry, alu_zero, alu_sign, alu_parity);
				end
				8'h0a: begin
					$display("Time %0t: SUB_IMM reg%0d, reg%0d, %0d", $time, current_instruction[31:24], current_instruction[23:16], current_instruction[15:8]);
					if (main_cpu.cpu_register_file_write_enable)
						$display("    Flags: O=%b C=%b Z=%b S=%b P=%b", alu_overflow, alu_carry, alu_zero, alu_sign, alu_parity);
				end
				8'h06:
					$display("Time %0t: TENSOR_CORE_LOAD reg%0d, %0d, %0d", $time, current_instruction[31:24], current_instruction[23:16], current_instruction[15:8]);
				8'h05:
					$display("Time %0t: TENSOR_CORE_OPERATE", $time);
				default:
					$display("Time %0t: UNKNOWN OPCODE 0x%02X", $time, current_instruction[7:0]);
			endcase
	initial begin
		$dumpfile("build/cpu_test_bench.vcd");
		$dumpvars(0, cpu_test_bench);
		clock = 0;
		$display("=== CPU TEST BENCH WITH OVERFLOW AND PARITY DETECTION ===");
		$display("Initial register state:");
		$display("reg0=%0d, reg1=%0d, reg2=%0d, reg3=%0d, reg4=%0d", reg0_value, reg1_value, reg2_value, reg3_value, reg4_value);
		#(6)
			;
		begin : sv2v_autoblock_1
			integer i;
			for (i = 0; (i < 60) && (machine_code[i] != 32'h00000000); i = i + 1)
				begin
					current_instruction = machine_code[i];
					#(10)
						;
					case (i)
						0:
							check_register(1, 8'd5, "add_imm 1,0,5");
						1:
							check_register(2, 8'd15, "add_imm 2,1,10");
						2:
							check_register(3, 8'd20, "add 3,1,2");
						3:
							check_register(4, 8'd10, "sub 4,2,1");
						4:
							check_register(5, 8'd60, "add_imm 5,4,50");
						5:
							check_register(9, 8'd35, "sub_imm 9,5,25");
						6:
							check_register(10, 8'd12, "sub_imm 10,2,3");
						7:
							check_register_with_overflow(6, 8'd176, 1'b1, "mul 6,5,3 (8-bit overflow: 1200->176)");
						8:
							check_register(7, 8'd1, "eql 7,3,3");
						9:
							check_register(8, 8'd1, "grt 8,6,2");
						10:
							check_register_with_overflow(20, 8'd127, 1'b0, "add_imm 20,0,127 (no overflow)");
						11:
							check_register_with_overflow(21, 8'd128, 1'b1, "add_imm 21,20,1 (signed overflow)");
						12:
							check_register_with_overflow(22, 8'd127, 1'b0, "add_imm 22,0,127 (no overflow)");
						13:
							check_register_with_overflow(23, 8'd254, 1'b1, "add 23,22,22 (127+127=254, signed overflow)");
						14:
							check_register_with_overflow(24, 8'd1, 1'b1, "mul 24,20,20 (127*127 overflow)");
						15:
							check_register_with_overflow(25, 8'd255, 1'b0, "sub_imm 25,0,1 (underflow to 255)");
						16:
							check_register_with_all_flags(26, 8'd0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, "add_imm 26,0,0 (zero result)");
						17:
							check_register(27, 8'd127, "add_imm 27,0,127");
						18:
							check_register_with_overflow(28, 8'd227, 1'b1, "add_imm 28,27,100 (127+100=227, signed overflow)");
						19:
							check_register_with_parity(29, 8'd3, 1'b0, "add_imm 29,0,3 (even parity: 2 ones)");
						20:
							check_register_with_parity(30, 8'd7, 1'b1, "add_imm 30,0,7 (odd parity: 3 ones)");
						21:
							check_register_with_parity(31, 8'd15, 1'b0, "add_imm 31,0,15 (even parity: 4 ones)");
						22:
							check_register_with_parity(32, 8'd31, 1'b1, "add_imm 32,0,31 (odd parity: 5 ones)");
						23:
							check_register_with_parity(33, 8'd63, 1'b0, "add_imm 33,0,63 (even parity: 6 ones)");
						24:
							check_register_with_parity(34, 8'd127, 1'b1, "add_imm 34,0,127 (odd parity: 7 ones)");
						25:
							check_register_with_parity(35, 8'd85, 1'b0, "add_imm 35,0,85 (even parity: 4 ones)");
						26: begin
							$display("=== CPU INSTRUCTION TESTING COMPLETE ===");
							$display("Final CPU register state before tensor operations:");
							$display("reg1=%0d, reg2=%0d, reg3=%0d, reg4=%0d, reg5=%0d", reg1_value, reg2_value, reg3_value, reg4_value, reg5_value);
							$display("reg6=%0d, reg7=%0d, reg8=%0d, reg9=%0d, reg10=%0d", reg6_value, reg7_value, reg8_value, reg9_value, reg10_value);
							$display("Overflow test registers:");
							$display("reg20=%0d, reg21=%0d, reg22=%0d, reg23=%0d, reg24=%0d, reg25=%0d", get_register_value(20), get_register_value(21), get_register_value(22), get_register_value(23), get_register_value(24), get_register_value(25));
							$display("Parity test registers:");
							$display("reg29=%0d, reg30=%0d, reg31=%0d, reg32=%0d, reg33=%0d, reg34=%0d, reg35=%0d", get_register_value(29), get_register_value(30), get_register_value(31), get_register_value(32), get_register_value(33), get_register_value(34), get_register_value(35));
							$display("Status register: 0x%02X (P=%b O=%b C=%b Z=%b S=%b)", status_reg, status_reg[4], status_reg[3], status_reg[2], status_reg[1], status_reg[0]);
							$display("Starting tensor core operations...");
						end
						32: begin
							$display("=== TENSOR CORE OPERATIONS COMPLETED ===");
							$display("Checking tensor core results...");
						end
					endcase
				end
		end
		$display("=== FINAL REGISTER STATE ===");
		$display("CPU registers:");
		$display("reg0=%0d, reg1=%0d, reg2=%0d, reg3=%0d, reg4=%0d", reg0_value, reg1_value, reg2_value, reg3_value, reg4_value);
		$display("reg5=%0d, reg6=%0d, reg7=%0d, reg8=%0d, reg9=%0d, reg10=%0d", reg5_value, reg6_value, reg7_value, reg8_value, reg9_value, reg10_value);
		$display("Overflow test registers:");
		$display("reg20=%0d, reg21=%0d, reg22=%0d, reg23=%0d, reg24=%0d, reg25=%0d", get_register_value(20), get_register_value(21), get_register_value(22), get_register_value(23), get_register_value(24), get_register_value(25));
		$display("reg26=%0d, reg27=%0d, reg28=%0d", get_register_value(26), get_register_value(27), get_register_value(28));
		$display("Parity test registers:");
		$display("reg29=%0d, reg30=%0d, reg31=%0d, reg32=%0d, reg33=%0d, reg34=%0d, reg35=%0d", get_register_value(29), get_register_value(30), get_register_value(31), get_register_value(32), get_register_value(33), get_register_value(34), get_register_value(35));
		$display("Final status register: 0x%02X", status_reg);
		$display("Final flags: Parity=%b, Overflow=%b, Carry=%b, Zero=%b, Sign=%b", status_reg[4], status_reg[3], status_reg[2], status_reg[1], status_reg[0]);
		$display("=== TEST SUMMARY ===");
		$display("Total Tests: %0d", test_count);
		$display("Passed: %0d", pass_count);
		$display("Failed: %0d", fail_count);
		if (fail_count == 0)
			$display("ALL TESTS PASSED!");
		else
			$display("SOME TESTS FAILED!");
		$display("Finishing Sim");
		$finish;
	end
	initial _sv2v_0 = 0;
endmodule
