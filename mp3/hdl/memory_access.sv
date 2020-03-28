module memory_access
(
input clk,
input rst,
input rv32i_word PC_in,
input rv32i_word instruction_in,
input rv32i_control_word ctrl_word_in,
input [3:0] mem_byte_enable_in,
input rv32i_word rs2_out,
input rv32i_word alu_out,
input rv32i_word data_rdata_in, //read word from memory
input data_resp,

output rv32i_control_word ctrl_word_out,
output rv32i_word instruction_out,
output logic [31:0] data_addr,
output logic [31:0] data_wdata,
output logic [3:0] data_mbe,
output logic [3:0] mem_byte_enable_out,
output logic [31:0] data_rdata, //output to next stage, not output to memory
);

assign data_addr = {alu_out[31:2], 2'b00};
assign data_mbe = mem_byte_enable_in;
assign data_wdata = rs2_out;

//set state register outputs
always_ff @(negedge clk) begin
  if (rst) begin
    ctrl_word_out <= 0;
    instruction_out <= 0;
    mem_byte_enable_out <= 0;
    data_rdata <= 0;
  end
  else begin
    ctrl_word_out <= ctrl_word_in;
    instruction_out <= instruction_in;
    mem_byte_enable_out <= mem_byte_enable_in;
    //rdata holds its value until resp goes high from memory, but for now we will always get once cycle hit
    data_rdata <= data_resp ? data_rdata_in : data_rdata;
  end
end
