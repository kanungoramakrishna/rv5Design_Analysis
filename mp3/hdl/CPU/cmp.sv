import rv32i_types::*;
`define BAD_OP $fatal("%0t %s %0d: Illegal operation", $time, `__FILE__, `__LINE__)

module cmp
(
  input branch_funct3_t cmpop,
  input rv32i_word cmp_input_1,
  input rv32i_word cmp_input_2,
  input rv32i_opcode opcode,
  output logic br_en
);

always_comb begin
  br_en = 1'b0;
  unique case (cmpop)
    beq: begin
        br_en = cmp_input_1 == cmp_input_2 ? 1'b1 : 1'b0;
    end
    bne: begin
        br_en = cmp_input_1 == cmp_input_2 ? 1'b0 : 1'b1;
    end
    blt: begin
        br_en = $signed(cmp_input_1) < $signed(cmp_input_2) ? 1'b1 : 1'b0;
    end
    bge: begin
        br_en = $signed(cmp_input_1) < $signed(cmp_input_2) ? 1'b0 : 1'b1;
    end
    bltu: begin
        br_en = cmp_input_1 < cmp_input_2 ? 1'b1 : 1'b0;
    end
    bgeu: begin
        br_en = cmp_input_1 < cmp_input_2 ? 1'b0 : 1'b1;
    end
    default:
        br_en = cmp_input_1 < cmp_input_2 ? 1'b0 : 1'b1;
  endcase
end
endmodule
