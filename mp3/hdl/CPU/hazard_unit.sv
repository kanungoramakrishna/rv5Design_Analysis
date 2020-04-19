import rv32i_types::*;

module hazard_unit
(
	input  rv32i_word instr, 
	input  rv32i_control_word ctrl,
	output logic stall //when asserted, generate NOPS and stall ID/IF
);

rv32i_reg rs1;
rv32i_reg rs2;


always_comb
begin
	rs1 = 0;
	rs2 = 0;
	stall = 0;

	case (ctrl.opcode)
		op_lui,op_auipc,op_jal,op_jal:
		begin
			rs1 = 0;
			rs2 = 0;
		end

		op_jalr,op_load,op_imm:
		begin
			rs1 = instr[19:15];
			rs2 = 0;
		end

		default:
		begin
			rs1 = instr[19:15];
			rs2 = instr[24:20];
		end
	endcase

	if (ctrl.opcode == op_load && ctrl.rd != 0)
	begin
		if (ctrl.rd == rs1 || ctrl.rd == rs2)
		begin
			stall == 1;
		end
	end
end
endmodule