import rv32i_types::*;
`define BAD_OP $fatal("%0t %s %0d: Illegal operation", $time, `__FILE__, `__LINE__)

module cmp
(
  input branch_funct3_t cmpop,
  input rv32i_word rs1_out,
  input rv32i_word cmp_in,
  input rv32i_opcode opcode,
  output logic br_en
);

always_comb begin
  br_en = 1'b0;
  unique case (cmpop)
    beq: begin
      if (opcode == op_br)
        br_en = rs1_out == cmp_in ? 1'b1 : 1'b0;
    end
    bne: begin
      if (opcode == op_br)
        br_en = rs1_out == cmp_in ? 1'b0 : 1'b1;
    end
    blt: begin
      if (opcode == op_br)
        br_en = $signed(rs1_out) < $signed(cmp_in) ? 1'b1 : 1'b0;
    end
    bge: begin
      if (opcode == op_br)
        br_en = $signed(rs1_out) < $signed(cmp_in) ? 1'b0 : 1'b1;
    end
    bltu: begin
      if (opcode == op_br)
        br_en = rs1_out < cmp_in ? 1'b1 : 1'b0;
    end
    bgeu: begin
      if (opcode == op_br)
        br_en = rs1_out < cmp_in ? 1'b0 : 1'b1;
    end
    default:
      if (opcode == op_br)
        br_en = rs1_out < cmp_in ? 1'b0 : 1'b1;
  endcase
end
endmodule
