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
	input  logic       br_miss,
	input  logic       bubble,      // From ID
	output rv32i_word  pc_ff,
	output rv32i_word  instr_ff,

	// Cache IO
	input  logic      inst_resp,
	input  rv32i_word inst_rdata,
	output logic      inst_read,
	output rv32i_word inst_addr,
	output logic      IF_stall,
	output logic	  false_NOP,

	// Prediction IO
	input  logic      pred,
	input  rv32i_word pred_addr
);

logic pc_load;
rv32i_word pc_in;
rv32i_word pc_out;

logic temp_branch, temp_pred;
rv32i_word temp_pc, temp_pred_pc;
rv32i_word pc_out_tmp; 

// assign pc_load = (!(IF_stall || MA_stall || bubble) || (!IF_stall && br_miss) || (!IF_stall && temp_branch) );			// Always increment (?)
assign pc_load = (!(IF_stall || MA_stall || bubble)); 
assign inst_read = 1'b1;		// Always read (?)
assign inst_addr = pc_out;

pc_register PC (
	.clk  (clk),
	.rst  (rst),
	.load (pc_load),
	.in   ((temp_branch) ? temp_pc : pc_in),
	.out  (pc_out_tmp)
);

// assign pc_out = (pred) ? pred_addr : pc_out_tmp; 


// NOTE : The ff logic is split up  in order to
//        make it easier to expand upon later

// IF/ID
always_ff @(posedge clk) begin
	// PC
	if (rst) begin
		pc_ff <= 32'b0;
	end
	else if (!(MA_stall || bubble)) begin
		pc_ff <= pc_out;
	end

	// Instruction Data
	if (rst) begin
		instr_ff <= 32'b0;
		false_NOP <= 1'b0;
	end
	else if (!(bubble))
	begin
	if ((IF_stall &&  (!(MA_stall))) || br_miss || temp_branch) begin
		instr_ff <= 32'h00000013;
		false_NOP <= 1'b1;
	end
	else if (!(MA_stall)) begin
		instr_ff <= inst_rdata;
		false_NOP <= 1'b0;
	end
end
end

always_comb begin
	IF_stall = (inst_resp) ? 1'b0 : 1'b1;

	if (pred)
		pc_out = pred_addr;
	else if (temp_pred)
		pc_out = temp_pred_pc;
	else
		pc_out = pc_out_tmp;

	unique case (pcmux_sel)
		pcmux::pc_plus4 : pc_in = pc_out + 4;
		pcmux::alu_out  : pc_in = alu_out;
		pcmux::alu_mod2 : pc_in = {alu_out[31:1], 1'b0};
		default  : pc_in = 32'hFFFFFFFF;	// Break on bad sel
	endcase
end


//Edge case where IF_stall and br_miss

always_ff @(posedge clk)
begin
	if (rst)
		temp_branch<= 1'b0;
	else if (IF_stall && br_miss)
		temp_branch <=1'b1;
	else if (temp_branch && !IF_stall)
		temp_branch <=1'b0;
	
	if (rst)
		temp_pc <= 0;
	else if (br_miss)
		temp_pc <= pc_in;
	
	if (rst)
		temp_pred <= 1'b0;
	else if (IF_stall && pred)
		temp_pred <=1'b1;
	else if (temp_pred && !IF_stall)
		temp_pred <=1'b0;
	
	if (rst)
		temp_pred_pc <= 0;
	else if (pred)
		temp_pred_pc <= pc_out;
	


end

endmodule