import rv32i_types::*;

module hazard_unit
(
	input  rv32i_word         instr, 
	input  rv32i_control_word id_ex,
	output logic              bubble //when asserted, generate NOPS and stall ID/IF
);

rv32i_reg rs1;
rv32i_reg rs2;
rv32i_opcode instr_op;


always_comb
begin
	rs1 = 0;
	rs2 = 0;
	stall = 0;
	instr_op = rv32i_opcode'(instr[6:0]);

	case (id_ex.opcode)
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

	if (id_ex.opcode == op_load && id_ex.rd != 0)
	begin
		if (instr_op == op_store && id_ex.rd == rs2)
		begin
			/*We don't stall in this case because the 
			memory forwarding unit will handle it*/
			stall = 0;
		end 
		else if (id_ex.rd == rs1 || id_ex.rd == rs2)
		begin
			stall = 1;
		end
	end
end
endmodule