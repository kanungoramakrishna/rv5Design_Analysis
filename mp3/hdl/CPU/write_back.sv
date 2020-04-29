import rv32i_types::*;
import pcmux::*;

module write_back
(
    input clk,
    input rv32i_word PC_in,
    input rv32i_word PC_plus4_in,
    input rv32i_word instruction_in,
    input rv32i_word instruction_frog,
    input rv32i_control_word ctrl_word_in,
    input [3:0] mem_byte_enable_in,
    input rv32i_word r_data_in,
    input rv32i_word w_data_in,
    input rv32i_word alu_in,
    input rv32i_word br_en_in,
    input rv32i_word data_addr_in,
    input logic leap,

    //To regfile (ID)
    output logic load_regfile,
    output logic [31:0] rd_in,
    output logic [4:0] rd
);

logic [31:0] regfilemux_out;
rv32i_word instruction_out;

always_ff @(posedge clk) begin
  if (leap) begin
    instruction_out <= instruction_in;
  end
end

//To ID to write to registers

assign rd_in = regfilemux_out;
assign rd = ctrl_word_in.rd;

//Regfile MUX
always_comb
begin
  load_regfile = ctrl_word_in.load_regfile;
    unique case (ctrl_word_in.regfilemux_sel)
        regfilemux::alu_out  : regfilemux_out =  alu_in;
        regfilemux::br_en    : regfilemux_out = br_en_in;
        regfilemux::u_imm    : regfilemux_out =  ctrl_word_in.u_imm;
        regfilemux::lw       : regfilemux_out = r_data_in;
        regfilemux::pc_plus4 : regfilemux_out = PC_plus4_in;
        regfilemux::lb       :
            begin
                unique case (mem_byte_enable_in)
                4'b0001: regfilemux_out = {{24{r_data_in[7]}},r_data_in[7:0]};
                4'b0010: regfilemux_out = {{24{r_data_in[15]}},r_data_in[15:8]};
                4'b0100: regfilemux_out = {{24{r_data_in[23]}},r_data_in[23:16]};
                4'b1000: regfilemux_out = {{24{r_data_in[31]}},r_data_in[31:24]};
                default: regfilemux_out = {{24{r_data_in[7]}},r_data_in[7:0]};
                endcase
            end
        regfilemux::lbu      :
            begin
                unique case (mem_byte_enable_in)
                4'b0001: regfilemux_out = {{24{1'b0}},r_data_in[7:0]};
                4'b0010: regfilemux_out = {{24{1'b0}},r_data_in[15:8]};
                4'b0100: regfilemux_out = {{24{1'b0}},r_data_in[23:16]};
                4'b1000: regfilemux_out = {{24{1'b0}},r_data_in[31:24]};
                default: regfilemux_out = {{24{1'b0}},r_data_in[7:0]};
                endcase
            end
        regfilemux::lh       :
            begin
                unique case (mem_byte_enable_in)
                4'b0011: regfilemux_out = {{16{r_data_in[15]}},r_data_in[15:0]};
                4'b0110: regfilemux_out = {{16{r_data_in[23]}},r_data_in[23:8]};
                4'b1100: regfilemux_out = {{16{r_data_in[31]}},r_data_in[31:16]};
                4'b1000: regfilemux_out = {{24{r_data_in[31]}},r_data_in[31:24]};
                default: regfilemux_out = {{16{r_data_in[15]}},r_data_in[15:0]};
                endcase
            end
        regfilemux::lhu      :
            begin
                unique case (mem_byte_enable_in)
                4'b0011: regfilemux_out = {{16{1'b0}},r_data_in[15:0]};
                4'b0110: regfilemux_out = {{16{1'b0}},r_data_in[23:8]};
                4'b1100: regfilemux_out = {{16{1'b0}},r_data_in[31:16]};
                4'b1000: regfilemux_out = {{24{1'b0}},r_data_in[31:24]};
                default: regfilemux_out = {{16{1'b0}},r_data_in[15:0]};
                endcase
            end
        default:;
    endcase
    if (instruction_in == instruction_out && !leap) begin
      load_regfile = 1'b0;
    end
end

//synthesis translate_off

RVFIMonPacket packet;

always_comb begin
  packet.instruction = instruction_in;

  unique case (ctrl_word_in.opcode)
    op_lui: begin
      packet.rs1_addr = 0;
      packet.rs2_addr = 0;
      packet.rd_addr = rd;
      packet.rd_data = rd_in;
      packet.pc_rdata = PC_in;
      packet.pc_wdata = PC_plus4_in;
      packet.mem_rmask = 0;
      packet.mem_wmask = 0;
      packet.mem_rdata = 0;
      packet.mem_wdata = 0;
      packet.mem_addr = 0;
    end
    op_auipc: begin
      packet.rs1_addr = 0;
      packet.rs2_addr = 0;
      packet.rd_addr = rd;
      packet.rd_data = rd_in;
      packet.pc_rdata = PC_in;
      packet.pc_wdata = PC_plus4_in;
      packet.mem_rmask = 0;
      packet.mem_wmask = 0;
      packet.mem_rdata = 0;
      packet.mem_wdata = 0;
      packet.mem_addr = 0;
    end
    op_jal: begin
      packet.rs1_addr = 0;
      packet.rs2_addr = 0;
      packet.rd_addr = rd;
      packet.rd_data = rd_in;
      packet.pc_rdata = PC_in;
      packet.pc_wdata = alu_in;
      packet.mem_rmask = 0;
      packet.mem_wmask = 0;
      packet.mem_rdata = 0;
      packet.mem_wdata = 0;
      packet.mem_addr = 0;
    end
    op_jalr: begin
      packet.rs1_addr = instruction_in[19:15];
      packet.rs2_addr = 0;
      packet.rd_addr = rd;
      packet.rd_data = rd_in;
      packet.pc_rdata = PC_in;
      packet.pc_wdata = alu_in;
      packet.mem_rmask = 0;
      packet.mem_wmask = 0;
      packet.mem_rdata = 0;
      packet.mem_wdata = 0;
      packet.mem_addr = 0;
    end
    op_br: begin
      packet.rs1_addr = instruction_in[19:15];
      packet.rs2_addr = instruction_in[24:20];
      packet.rd_addr = 0;
      packet.rd_data = 0;
      packet.pc_rdata = PC_in;
      packet.pc_wdata = br_en_in ? alu_in : PC_plus4_in;
      packet.mem_rmask = 0;
      packet.mem_wmask = 0;
      packet.mem_rdata = 0;
      packet.mem_wdata = 0;
      packet.mem_addr = 0;
    end
    op_load: begin
      packet.rs1_addr = instruction_in[19:15];
      packet.rs2_addr = 0;
      packet.rd_addr = rd;
      packet.rd_data = rd_in;
      packet.pc_rdata = PC_in;
      packet.pc_wdata = PC_plus4_in;
      packet.mem_rmask = mem_byte_enable_in;
      packet.mem_wmask = 0;
      packet.mem_rdata = r_data_in;
      packet.mem_wdata = 0;
      packet.mem_addr = data_addr_in;
    end
    op_store: begin
      packet.rs1_addr = instruction_in[19:15];
      packet.rs2_addr = instruction_in[24:20];
      packet.rd_addr = 0;
      packet.rd_data = 0;
      packet.pc_rdata = PC_in;
      packet.pc_wdata = PC_plus4_in;
      packet.mem_rmask = 0;
      packet.mem_wmask = mem_byte_enable_in;
      packet.mem_rdata = 0;
      packet.mem_wdata = w_data_in;
      packet.mem_addr = data_addr_in;
    end
    op_imm: begin
      packet.rs1_addr = instruction_in[19:15];
      packet.rs2_addr = 0;
      packet.rd_addr = rd;
      packet.rd_data = rd_in;
      packet.pc_rdata = PC_in;
      packet.pc_wdata = PC_plus4_in;
      packet.mem_rmask = 0;
      packet.mem_wmask = 0;
      packet.mem_rdata = 0;
      packet.mem_wdata = 0;
      packet.mem_addr = 0;
    end
    op_reg: begin
      packet.rs1_addr = instruction_in[19:15];
      packet.rs2_addr = instruction_in[24:20];
      packet.rd_addr = rd;
      packet.rd_data = rd ? rd_in : 0;
      packet.pc_rdata = PC_in;
      packet.pc_wdata = PC_plus4_in;
      packet.mem_rmask = 0;
      packet.mem_wmask = 0;
      packet.mem_rdata = 0;
      packet.mem_wdata = 0;
      packet.mem_addr = 0;
    end
    default: begin
      packet = 0;
    end
  endcase
end

//synthesis translate_on





endmodule
