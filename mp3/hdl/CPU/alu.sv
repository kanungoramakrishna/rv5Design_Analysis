import rv32i_types::*;

module alu
(
    input alu_ops aluop,
    input rv32i_word a, b,
    output rv32i_word f,
    output rv32i_word alu_out_to_PC
);

always_comb
begin
    alu_out_to_PC = a + b;
    unique case (aluop)
        alu_add:  f = a + b;
        alu_sll:  f = a << b[4:0];
        alu_sra:  f = $signed(a) >>> b[4:0];
        alu_sub:  f = a - b;
        alu_xor:  f = a ^ b;
        alu_srl:  f = a >> b[4:0];
        alu_or:   f = a | b;
        alu_and:  f = a & b;
    endcase
end

endmodule : alu
