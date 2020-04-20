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
	output rv32i_word  pc_ff,
	output rv32i_word  instr_ff,

	// Cache IO
	input  logic      inst_resp,
	input  rv32i_word inst_rdata,
	output logic      inst_read,
	output rv32i_word inst_addr,
	output logic      IF_stall
);

logic pc_load;
rv32i_word pc_in;
rv32i_word pc_out;

assign pc_load = (!(IF_stall || MA_stall || bubble));			// Always increment (?)
assign inst_read = 1'b1;		// Always read (?)
assign inst_addr = pc_out;

pc_register PC (
	.clk  (clk),
	.rst  (rst),
	.load (pc_load),
	.in   (pc_in),
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
	else if (!(MA_stall || bubble)) begin
		pc_ff <= pc_out;
	end

	// Instruction Data
	if (rst) begin
		instr_ff <= 32'b0;
	end
	else if ((IF_stall &&  (!(MA_stall))) || br_taken)
		instr_ff <= 32'h00000013;
	else if (!(MA_stall || bubble)) begin
		instr_ff <= inst_rdata;
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
endmodule
