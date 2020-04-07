import rv32i_types::*;

module memory_access
(
input clk,
input rst,
input rv32i_word PC_in,
input rv32i_word instruction_in,
input rv32i_control_word ctrl_word_in,
input [3:0] mem_byte_enable_in,
input rv32i_word rs2_out,
input rv32i_word alu_output_in,
input logic br_en_in,
input rv32i_word data_rdata_in, //read word from memory
input data_resp,
input logic IF_stall,

output logic [31:0] data_addr,
output logic [31:0] data_wdata,
output logic [3:0] data_mbe,
output logic data_read,
output logic data_write,
output rv32i_control_word ctrl_word_out,
output rv32i_word instruction_out,
output logic [3:0] mem_byte_enable_out,
output logic [31:0] r_data_out, //output to next stage, not output to memory
output logic [31:0] br_en_out,
output logic [31:0] PC_plus4_out,
output logic [31:0] PC_out,
output logic [31:0] alu_output_out,
output logic MA_stall
);

assign data_addr = {alu_output_in[31:2], 2'b00};
assign data_mbe = mem_byte_enable_in;
assign data_wdata = rs2_out;
assign data_read = ctrl_word_in.read;
assign data_write = ctrl_word_in.write;

always_comb 
begin
  if((ctrl_word_in.read || ctrl_word_in.write))
  begin
      if (data_resp)
        MA_stall = 1'b0;
      else
        MA_stall = 1'b1;
  end
  else
    MA_stall = 1'b0;
end
//set state register outputs
always_ff @(posedge clk) begin
  if (rst) begin
    ctrl_word_out <= 0;
    instruction_out <= 0;
    mem_byte_enable_out <= 0;
    r_data_out <= 0;
    br_en_out <= 0;
    PC_out <= 0;
    PC_plus4_out <= 0;
    alu_output_out <= 0;
  end
  else if (!MA_stall) begin
    ctrl_word_out <= ctrl_word_in;
    instruction_out <= instruction_in;
    mem_byte_enable_out <= mem_byte_enable_in;
    //rdata holds its value until resp goes high from memory, but for now we will always get once cycle hit
    r_data_out <= data_rdata_in;
    br_en_out <= {31'b0,br_en_in}; 
    PC_plus4_out <= PC_in +4;
    PC_out <= PC_in;
    alu_output_out <= alu_output_in;
  end
end
endmodule
