import rv32i_types::*;
import pcmux::*;
module instruction_fetch
(
	// Pileline IO
	input  logic       clk,
	input  logic       rst,
	input  logic       MA_stall,
	input  pcmux_sel_t pcmux_sel, 	// From WB
	input  rv32i_word  alu_out,		// From WB
	input  logic       br_taken,
	input  logic       bubble,      // From ID
	input logic 			 leap,
	output rv32i_word  pc_ff,
	output rv32i_word  instr_ff,

	// Cache IO
	input  logic      inst_resp,
	input  rv32i_word inst_rdata,
	output logic      inst_read,
	output rv32i_word inst_addr,
	output logic      IF_stall,
	output logic			false_NOP
);

logic pc_load;
rv32i_word pc_in;
rv32i_word pc_out;

logic temp_branch;
rv32i_word temp_pc;

assign pc_load = (!(IF_stall || MA_stall || bubble) || (!IF_stall && br_taken) || (!IF_stall && temp_branch) || (!IF_stall && leap));
assign inst_read = 1'b1;		// Always read
assign inst_addr = pc_out;

pc_register PC (
	.clk  (clk),
	.rst  (rst),
	.load (pc_load),
	.in   ((!IF_stall && temp_branch) ? temp_pc: pc_in),
	.out  (pc_out)
);



// NOTE : The ff logic is split up  in order to
//        make it easier to expand upon later

// IF/ID
always_ff @(posedge clk) begin
	// PC
	if (rst) begin
		pc_ff <= 32'b0;
	end
	// else if (br_taken) begin
	// 	pc_ff <= pc_ff;
	// end
	else if (!(MA_stall || bubble) || leap) begin
		pc_ff <= pc_out;
	end

	// Instruction Data
	if (rst) begin
		instr_ff <= 32'b0;
		false_NOP <= 1'b0;
	end
	else if (!(bubble))
	begin
	if ((IF_stall &&  (!(MA_stall))) || br_taken || temp_branch) begin
		instr_ff <= 32'h00000013;
		false_NOP <= 1'b1;
	end
	else if (!(MA_stall) || leap) begin
		instr_ff <= inst_rdata;
		false_NOP <= 1'b0;
	end
end
end

always_comb begin
	if (inst_resp)
	begin
		IF_stall = 1'b0;
	end
	else
	begin
		IF_stall = 1'b1;
	end

	unique case (pcmux_sel)
		pcmux::pc_plus4 : pc_in = pc_out + 4;
		pcmux::alu_out  : pc_in = alu_out;
		pcmux::alu_mod2 : pc_in = {alu_out[31:1], 1'b0};
		default  : pc_in = 32'hFFFFFFFF;	// Break on bad sel
	endcase
end


//Edge case where IF_stall and br_taken

always_ff @(posedge clk)
begin
	if (rst)
		temp_branch<= 1'b0;
	else if (IF_stall && br_taken)
		temp_branch <=1'b1;
	else if (temp_branch && !IF_stall)
		temp_branch <=1'b0;

	if (rst)
		temp_pc <= 0;
	else if (br_taken)
		temp_pc <= pc_in;



end

endmodule