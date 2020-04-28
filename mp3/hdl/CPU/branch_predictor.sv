import rv32i_types::*;

module branch_predictor # (parameter idx_size)
(
	// ID I/O
	input logic clk, rst, 
	input rv32i_word instr,
	input rv32i_word pc,
	output rv32i_word addr, 

	// EX I/O
	input 
);

localparam bht_size = 2**idx_size; 

logic [1:0] branch_history_table [bht_size];
rv32i_word  branch_target_buffer [bht_size];
logic       branch_target_valid  [bht_size]; 
logic [idx_size-1:0] idx;

logic [1:0] prediction;
rv32i_word  target;
logic       target_val;  

// Access info during ID
always_comb
begin
	idx = pc[(idx_size+1):2];
	prediction = branch_history_table[idx];
	target     = branch_target_buffer[idx];
	target_val = branch_target_valid[idx]; 
end
// Update counters during EX
always_ff @(posedge clk)
begin
	if (rst)
	begin
		for (int i=0; i<bht_size; i++) begin
			branch_history_table[i] <= 0;
			branch_target_buffer[i] <= 0;
			branch_target_valid [i] <= 0;  
		end
	end
	else if (/*TODO*/)
	begin
		// Access table
	end
end


endmodule