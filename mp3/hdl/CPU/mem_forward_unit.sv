import rv32i_types::*;

module mem_forward_unit
(
	input  rv32i_control_word ex_mem,
	input  rv32i_word         ex_mem_address,
	input  rv32i_word         ex_mem_instr,  
	input  rv32i_control_word mem_wb,
	input  rv32i_word         mem_wb_address, 
	input  rv32i_word         mem_wb_instr, 
	output logic              fwd
);

rv32i_reg ex_mem_rs2, mem_wb_rd;

always_comb
begin
	ex_mem_rs2 = ex_mem_instr[11:7 ]; 
	mem_wb_rd  = mem_wb_instr[24:20];

	fwd = 0; 

	// LD then ST same data (no stall) 
	if (ex_mem.opcode == op_store && mem_wb.opcode == op_load)
	begin
		if (ex_mem_rs2 == mem_wb_rd)
		begin
			fwd = 1; 
		end
	end

	// ST then LD into same address 


	/*
	Store r3 into 0xFF
	Load 0xFF into r2

	In this scenario I want to pass the data from store into load 
	since the data is still in the pipeline. FWD r3 -> r2

	Load r4 into 0xFF
	Store r4 into 0xEF

	In this scenario I want to pass the data from load into store
	since the data is ready (no hazard).  
	*/
end
endmodule
