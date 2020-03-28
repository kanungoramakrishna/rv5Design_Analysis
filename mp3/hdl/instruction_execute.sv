import rv32i_types::*;

module instruction_execute
(
  input clk,
  input rst,
  input rv32i_word PC_in,
  input rv32i_word instruction_in,
  input rv32i_word alu_in_1,
  input rv32i_word alu_in_2,
  input rv32i_word rs1_out,
  input rv32i_word rs2_o,
  input rv32i_word cmp_in,
  input rv32i_control_word ctrl_word_in,

  output rv32i_control_word ctrl_word_out,
  output rv32i_word instruction_out,
  output rv32i_word PC_out,
  output rv32i_word alu_out,
  output rv32i_word rs2_out,
  output br_en_out
);

rv32i_word alu_o;
logic br_en;

alu alu (
  .aluops (ctrl_word_in.aluop),
  .a (alu_in_1),
  .b (alu_in_2),
  .f (alu_o)
);

cmp cmp (
  .*,
  .cmpop (ctrl_word_in.cmpop)
);

always_ff @(negedge clk) begin
  if (rst) begin
    ctrl_word_out <= 0;
    instruction_out <= 0;
    PC_out <= 0;
    alu_out <= 0;
    rs2_out <= 0;
    br_en_out <= 0;
  end
  else begin
    ctrl_word_out <= ctrl_word_in;
    instruction_out <= instruction_in;
    PC_out <= PC;
    alu_out <= alu_o;
    rs2_out <= rs2_o;
    br_en_out <= br_en;
  end
end
endmodule
