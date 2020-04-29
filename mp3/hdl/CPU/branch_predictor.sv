import rv32i_types::*;

module branch_predictor # (parameter idx_size=4)
(
	input logic clk, rst, 

	// ID I/O
	input  rv32i_word pc,
	input  rv32i_word instr,
	output logic      pred, 
	output rv32i_word pred_addr, 

	// EX I/O
	input logic pred_update,
	input logic pred_taken
);

localparam bht_size = 2**idx_size; 

logic [1:0] branch_predict_buffer [bht_size];
rv32i_word  branch_address_buffer [bht_size];
logic       branch_address_valid  [bht_size]; 
logic [idx_size-1:0] idx;

logic [1:0] prediction;
rv32i_word  target;
logic       target_val;  

// Access info during ID
always_comb
begin
	idx = pc[(idx_size+1):2];
	prediction = branch_predict_buffer[idx];
	target     = branch_address_buffer[idx];
	target_val = branch_address_valid[idx]; 
end
// Update counters during EX
always_ff @(posedge clk)
begin
	if (rst)
	begin
		for (int i=0; i<bht_size; i++) begin
			branch_predict_buffer[i] <= 0;
			branch_address_buffer[i] <= 0;
			branch_address_valid [i] <= 0;  
		end
	end
	else if (/*TODO*/)
	begin
		// Access table
	end
end


endmodule