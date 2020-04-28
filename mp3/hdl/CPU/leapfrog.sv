import rv32i_types::*;

module leapfrog (
  input rv32i_word instr,
  input rv32i_control_word ctrl_word_EX,
  input rv32i_control_word ctrl_word_MA,
  input logic miss,

  output logic leap
);

logic [4:0] rs1_addr, rs2_addr;

always_comb begin
  leap = 0;
  rs1_addr = 0;
  rs2_addr = 0;

  if (ctrl_word_MA.opcode == op_store || ctrl_word_MA.opcode == op_load
      && ctrl_word_EX.opcode != op_store && ctrl_word_EX.opcode != op_load
      && ctrl_word_EX.opcode != op_auipc && instr != 32'h0000013 && miss) begin
    unique case (ctrl_word_EX.opcode)
        op_lui, op_auipc, op_jal:
        begin
            rs1_addr = 0;
            rs2_addr = 0;
        end

        op_jalr, op_load, op_imm:
        begin
            rs1_addr = instr[19:15];
            rs2_addr = 0;
        end

        default:
        begin
            rs1_addr = instr[19:15];
            rs2_addr = instr[24:20];
        end
    endcase

    leap = rs1_addr == ctrl_word_MA.rd || rs2_addr == ctrl_word_MA.rd ? 1'b0 : 1'b1;

  end
end
endmodule
