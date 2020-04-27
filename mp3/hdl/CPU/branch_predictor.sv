import rv32i_types::*;

module branch_predictor # (
	parameter bht_size = 4
)
(
	input logic clk, rst, 
	input rv32i_word instr,
	input rv32i_word pc,
	output rv32i_word addr, 
);

logic [1:0] branch_history_table [bht_size];
logic [1:0] cur; 

always_ff @(posedge clk)
begin
	if (rst)
	begin
		for (int i=0; i<bht_size; i++) begin
			branch_history_table[i] <= 0;
		end
	end
	else if (/*TODO*/)
	begin
		// Access table
	end
end

always_comb
begin
	cur = branch_history_table[]

end

endmodule