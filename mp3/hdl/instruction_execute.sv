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
  input rv32i_word rs2,
  input rv32i_word cmp_in,
  input rv32i_control_word ctrl_word_in,

  output rv32i_control_word ctrl_word_out,
  output rv32i_word instruction_out,
  output rv32i_word PC_out,
  output rv32i_word alu_out,
  output rv32i_word rs2_out,
  output logic br_en_out,
  output logic [3:0] mem_byte_enable_out
);

rv32i_word alu_o;
logic [3:0] mem_byte_enable;
logic br_en;

alu alu (
  .aluop (ctrl_word_in.aluop),
  .a (alu_in_1),
  .b (alu_in_2),
  .f (alu_o)
);

cmp cmp (
  .*,
  .cmpop (ctrl_word_in.cmpop)
);

always_comb begin
  //set byte enable
  //note that rs2 (write data) must be masked using byte enable,
  //done in mem_access stage to reduce logic in this stage
  //note that sw has same encoding as lw, etc. so we can account for both cases
  unique case (load_funct3_t'(instruction_in[14:12]))
    default:
      mem_byte_enable = 4'b1111;
    lh, lhu: begin
      unique case (alu_o[1:0])
        2'b00:
          mem_byte_enable = 4'b0011;
        2'b01:
          mem_byte_enable = 4'b0110;
        2'b10:
          mem_byte_enable = 4'b1100;
        2'b11:
          mem_byte_enable = 4'b1000;
      endcase
    end
    lw: begin
      unique case (alu_o[1:0])
        2'b00:
          mem_byte_enable = 4'b1111;
        2'b01:
          mem_byte_enable = 4'b1110;
        2'b10:
          mem_byte_enable = 4'b1100;
        2'b11:
          mem_byte_enable = 4'b1000;
      endcase
    end
    lb, lbu: begin
      unique case (alu_o[1:0])
        2'b00:
          mem_byte_enable = 4'b0001;
        2'b01:
          mem_byte_enable = 4'b0010;
        2'b10:
          mem_byte_enable = 4'b0100;
        2'b11:
          mem_byte_enable = 4'b1000;
      endcase
    end
  endcase
end

always_ff @(posedge clk) begin
  if (rst) begin
    ctrl_word_out <= 0;
    instruction_out <= 0;
    PC_out <= 0;
    alu_out <= 0;
    rs2_out <= 0;
    br_en_out <= 0;
    mem_byte_enable_out <= 0;
  end
  else begin
    ctrl_word_out <= ctrl_word_in;
    instruction_out <= instruction_in;
    PC_out <= PC_in;
    alu_out <= alu_o;
    rs2_out <= rs2;
    br_en_out <= br_en;
    mem_byte_enable_out <= mem_byte_enable;
  end
end
endmodule
