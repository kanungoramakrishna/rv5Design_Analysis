import rv32i_types::*;

module branch_predictor # (parameter idx_size=4)
(
	input logic clk, rst, 

	// ID I/O
	input  rv32i_word   pc,
	input  rv32i_word   instr,
	input  rv32i_opcode op,
	input  rv32i_word   imm,
	output logic        pred, 
	output rv32i_word   pred_addr, 

	// EX I/O
	input  logic                pred_update,
	input  logic                pred_taken,
	input  logic [idx_size-1:0] pred_update_idx
	output logic [idx_size-1:0] pred_idx,
);

localparam bht_size = 2**idx_size; 

logic [1:0] branch_predictor_buffer [bht_size];
logic [(idx_size-1):0] global_history, global_history_next;
logic [1:0] prediction; 

assign pred_addr = pc+imm;

always_comb
begin
	pred_idx = pc[(idx_size+1):2] ^ global_history;
	if (op == op_br) begin
		case (branch_predictor_buffer[idx])
			2'b00: pred = 0; 
			2'b01: pred = 0; 
			2'b10: pred = 1; 
			2'b11: pred = 1;
		endcase 
	end else begin
		pred = 0;
	end

	global_history_next = global_history << 1; 
	global_history_next[0] = pred_taken;

end

always_ff @(posedge clk)
begin
	if (rst) begin
		for (int i=0; i<bht_size; i++) begin
			branch_predict_buffer[i] <= 0;
			branch_address_buffer[i] <= 0;
			branch_address_valid [i] <= 0;  
		end
	end else if (pred_update) begin
		global_history <= global_history_next;

		// Update predictors
		if (pred_taken) begin
			unique case (branch_predictor_buffer[pred_update_idx])
				2'b00: branch_predictor_buffer[pred_update_idx] <= 2'b01;
				2'b01: branch_predictor_buffer[pred_update_idx] <= 2'b10;
				2'b10: branch_predictor_buffer[pred_update_idx] <= 2'b11;
				2'b11: branch_predictor_buffer[pred_update_idx] <= 2'b11;
			endcase
		end else begin
			unique case (branch_predictor_buffer[pred_update_idx])
				2'b00: branch_predictor_buffer[pred_update_idx] <= 2'b00;
				2'b01: branch_predictor_buffer[pred_update_idx] <= 2'b00; 
				2'b10: branch_predictor_buffer[pred_update_idx] <= 2'b01; 
				2'b11: branch_predictor_buffer[pred_update_idx] <= 2'b10; 
			endcase
		end
	end
begin

end
endmodule