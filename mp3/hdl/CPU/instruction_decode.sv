import rv32i_types::*;
import alumux::*;
import cmpmux::*;

module instruction_decode
(
    input  logic clk,
    input  logic rst,
    input  rv32i_word PC,
    input  rv32i_word data_, // instruction that has been fetched from I cache
    input  IF_stall,
    input MA_stall,
    //These inputs come from the WB stage
    input  rv32i_word  rd_in,
    input  logic [4:0] rd,
    input  logic       load_regfile,

    output rv32i_control_word ctrl_out,
    output rv32i_word instruction_out,
    output rv32i_word PC_out,
    output rv32i_word ALUin_1_out,
    output rv32i_word ALUin_2_out,
    output rv32i_word CMPin_out,
    output rv32i_word rs1_out,
    output rv32i_word rs2_out
);


rv32i_word i_imm;
rv32i_word s_imm;
rv32i_word b_imm;
rv32i_word u_imm;
rv32i_word j_imm;
assign i_imm = {{21{data_[31]}}, data_[30:20]};
assign s_imm = {{21{data_[31]}}, data_[30:25], data_[11:7]};
assign b_imm = {{20{data_[31]}}, data_[7], data_[30:25], data_[11:8], 1'b0};
assign u_imm = {data_[31:12], 12'h000};
assign j_imm = {{12{data_[31]}}, data_[19:12], data_[20], data_[30:21], 1'b0};

rv32i_control_word ctrl;
alumux1_sel_t alumux1_sel;
alumux2_sel_t alumux2_sel;
cmpmux_sel_t cmpmux_sel;
rv32i_word ALUin_1;
rv32i_word ALUin_2;
rv32i_word CMPin;

rv32i_word reg_a;
rv32i_word reg_b;

//Regfile
regfile regfile(
	.clk   (clk   ),
    .rst   (rst   ),
    .load  (load_regfile  ),
    .in    (rd_in    ),
    .src_a (data_[19:15]),
    .src_b (data_[24:20]),
    .dest  (rd),
    .reg_a (reg_a ),
    .reg_b (reg_b )
);

//CW module
control_rom control_rom(.*, .data(data_));

//ALU muxes 1 and 2 and CMP muxes
always_comb
begin
    unique case (alumux1_sel)
        alumux::rs1_out: ALUin_1 = reg_a;
        alumux::pc_out: ALUin_1 = PC;
        default: ALUin_1 = PC;
    endcase

    unique case (alumux2_sel)
        alumux::i_imm: ALUin_2 = i_imm;
        alumux::u_imm: ALUin_2 = u_imm;
        alumux::b_imm: ALUin_2 = b_imm;
        alumux::s_imm: ALUin_2 = s_imm;
        alumux::j_imm: ALUin_2 = j_imm;
        alumux::rs2_out: ALUin_2 = reg_b;
        default: ALUin_2 = reg_b;
    endcase

    unique case (cmpmux_sel)
        cmpmux::rs2_out: CMPin = reg_b;
        cmpmux::i_imm: CMPin = i_imm;
        default: CMPin = i_imm;
    endcase

end

//registers ID/EXE
always_ff @(posedge clk) //posedge triggered
begin
    if(rst)
      begin
        PC_out <= 32'b0;
        instruction_out <= 32'b0;
        ctrl_out <= 0;
        ALUin_1_out <= 32'b0;
        ALUin_2_out <= 32'b0;
        CMPin_out <= 32'b0;
        rs1_out <= 32'b0;
        rs2_out <= 32'b0;
      end
    else if (!(IF_stall || MA_stall))
      begin
        PC_out <= PC;
        instruction_out <= data_;
        ctrl_out <= ctrl;
        ALUin_1_out <= ALUin_1;
        ALUin_2_out <= ALUin_2;
        CMPin_out <= CMPin;
        rs1_out <= reg_a;
        rs2_out <= reg_b;
      end
end
endmodule
