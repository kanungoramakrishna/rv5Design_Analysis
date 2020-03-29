import rv32i_types::*;
import pcmux::*;
module instruction_fetch
(
	// Pileline IO
	input  logic       clk,
	input  logic       rst,
	input  pcmux_sel_t pcmux_sel, 	// From WB
	input  rv32i_word alu_out,		// From WB
	output rv32i_word pc_ff,
	output rv32i_word instr_ff,

	// Cache IO
	input  logic       inst_resp,
	input  rv32i_word inst_rdata,
	output logic       inst_read,
	output rv32i_word inst_addr
);

logic pc_load;
rv32i_word pc_in;
rv32i_word pc_out;

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
always_ff @(negedge clk) begin
	// PC
	if (rst) begin
		pc_ff <= 32'b0;
	end else begin
		pc_ff <= pc_out;
	end

	// Instruction Data
	if (rst) begin
		instr_ff <= 32'b0;
	end else begin
		instr_ff <= inst_rdata;
	end
end

always_comb begin
	pc_load = 1'b1;			// Always increment (?)
	inst_read = 1'b1;		// Always read (?)
	inst_addr = pc_out;

	unique case (pcmux_sel)
		pcmux::pc_plus4: pc_in = pc_out + 4;
		pcmux::alu_out  : pc_in = alu_out;
		default  : pc_in = 32'hFFFFFFFF;	// Break on bad sel
	endcase
end
endmodule
