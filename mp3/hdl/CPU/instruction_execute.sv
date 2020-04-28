import rv32i_types::*;
import pcmux::*;

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
  input logic IF_stall,
  input logic MA_stall,
  input rv32i_control_word mem_wb, // Forwarding, ctrl_word_out
  input rv32i_word mem_wb_data,    // Forwarding, alu_output_out

  output rv32i_control_word ctrl_word_out,
  output rv32i_word instruction_out,
  output rv32i_word PC_out,
  output rv32i_word alu_out,
  output rv32i_word alu_out_to_PC,
  output pcmux_sel_t pcmux_sel,
  output rv32i_word rs2_out,
  output logic br_en_out,
  output logic [3:0] mem_byte_enable_out,
  output logic br_taken,
  output logic [1:0] addr_offset,

  output rv32i_word alu_input_1_o,  //outputs for rvfi monitor
  output rv32i_word alu_input_2_o
);

rv32i_word alu_o;
logic [3:0] mem_byte_enable;
logic br_en;
logic [1:0] fwd_alu [1:0];
logic [1:0] fwd_cmp [1:0];
logic [1:0] fwd_rs2;
rv32i_word alu_input_1, alu_input_2;
rv32i_word cmp_input_1, cmp_input_2;
// rv32i_word alu_o_pc_tmp;
rv32i_word rs2_fwd;
logic [1:0] addr_offset_next;

alu alu (
  .aluop (ctrl_word_in.aluop),
  .a (alu_input_1),
  .b (alu_input_2),
  .f (alu_o),
  .alu_out_to_PC (alu_out_to_PC)
);

cmp cmp (
  .*,
  .opcode (ctrl_word_in.opcode),
  .cmpop (ctrl_word_in.cmpop)
);

ex_forward_unit EFU (
  .instr       (instruction_in),
  .id_ex       (ctrl_word_in),
  .ex_mem      (ctrl_word_out),
  .mem_wb      (mem_wb),
  .fwd_alu     (fwd_alu),
  .fwd_cmp     (fwd_cmp),
  .fwd_rs2     (fwd_rs2)
);



always_comb begin
  // Forwarding Muxes
  unique case (fwd_alu[0])
    default : alu_input_1 = alu_in_1;
    2'b01   : alu_input_1 = mem_wb_data;
    2'b10   : alu_input_1 = alu_out; 
  endcase

  unique case (fwd_alu[1])
    default : alu_input_2 = alu_in_2;
    2'b01   : alu_input_2 = mem_wb_data;
    2'b10   : alu_input_2 = alu_out;
  endcase

  unique case (fwd_cmp[0])
    default : cmp_input_1 = rs1_out;
    2'b01   : cmp_input_1 = mem_wb_data;
    2'b10   : cmp_input_1 = alu_out; 
  endcase

  unique case (fwd_cmp[1])
    default : cmp_input_2 = cmp_in;
    2'b01   : cmp_input_2 = mem_wb_data;
    2'b10   : cmp_input_2 = alu_out; 
  endcase 

  unique case (fwd_rs2)
    default : rs2_fwd = rs2; 
    2'b01   : rs2_fwd = mem_wb_data;
    2'b10   : rs2_fwd = alu_out;
  endcase 

  //PCMUX_sel
  if(br_en || ctrl_word_in.opcode == op_jal || ctrl_word_in.opcode == op_jalr) begin
    pcmux_sel = ctrl_word_in.pcmux_sel;
    br_taken = 1'b1;
  end
  else begin
    br_taken = 1'b0;
    pcmux_sel = pcmux::pc_plus4;
  end

<<<<<<< HEAD
mem_byte_enable = 0;

if (ctrl_word_in.opcode == op_store || ctrl_word_in.opcode == op_load) begin
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
=======
  mem_byte_enable = 4'b0000;
  addr_offset_next = alu_o[1:0];
  if (ctrl_word_in.opcode == op_store || ctrl_word_in.opcode == op_load)
  begin
    case (load_funct3_t'(instruction_in[14:12]))
      lw    : mem_byte_enable = 4'b1111 << addr_offset_next;
      lh,lhu: mem_byte_enable = 4'b0011 << addr_offset_next;
      lb,lbu: mem_byte_enable = 4'b0001 << addr_offset_next;
    endcase
  end
>>>>>>> master
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
    alu_input_1_o <= 0;
    alu_input_2_o <= 0;
    addr_offset <= 0;
  end
  else if (!MA_stall) begin
    ctrl_word_out <= ctrl_word_in;
    instruction_out <= instruction_in;
    PC_out <= PC_in;
    alu_out <= alu_o;
    rs2_out <= rs2_fwd;
    br_en_out <= br_en;
    mem_byte_enable_out <= mem_byte_enable;
    alu_input_1_o <= alu_input_1;
    alu_input_2_o <= alu_input_2;
    addr_offset <= addr_offset_next;
  end
end
endmodule
