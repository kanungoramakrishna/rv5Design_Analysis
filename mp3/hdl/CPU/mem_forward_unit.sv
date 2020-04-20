import rv32i_types::*;

module mem_forward_unit
(
	input  rv32i_control_word ex_mem,
	input  rv32i_word ex_mem_address, 
	input  rv32i_control_word mem_wb,
	input  rv32i_word mem_wb_address, 
	output logic fwd, 
);

always_comb
begin
	fwd = 0; 

	if (ex_mem.opcode == op_store && mem_wb.opcode == op_load)
	begin
		if (ex_mem_address == mem_wb_address)
		begin
			fwd = 1; 
		end
	end
end
endmodule
