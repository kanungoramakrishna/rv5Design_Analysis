module write_back
(
    input rv32i_word PC_in,
    input rv32i_word instruction_in,
    input rv32i_control_word ctrl_word_in,
    input [3:0] mem_byte_enable_in,
    input rv32i_word rs2_out,
    input rv32i_word alu_in,
    input rv32i_word br_en_in,

    output logic load_regfile,
    output logic [31:0] rd_in,
    output logic [4:0] rd
);

logic [31:0] regfilemux_out;
assign load_regfile = ctrl_word_in.load_regfile;
assign rd_in = regfilemux_out;
assign rd = ctrl_word_in.rd;
always_comb
begin
    unique case (ctrl_word_in.regfilemux_sel)
        regfilemux::alu_out  : regfilemux_out =  alu_in;
        regfilemux::br_en    : regfilemux_out = br_en_in;
        regfilemux::u_imm    : regfilemux_out =  ctrl_word_in.u_imm;
        regfilemux::lw       : regfilemux_out = rs2_out;
        regfilemux::pc_plus4 : regfilemux_out = PC_in +4;
        regfilemux::lb       : 
            begin
                unique case (mem_byte_enable_in)
                2'b00: regfilemux_out = {{24{rs2_out[7]}},rs2_out[7:0]};
                2'b01: regfilemux_out = {{24{rs2_out[15]}},rs2_out[15:8]};
                2'b10: regfilemux_out = {{24{rs2_out[23]}},rs2_out[23:16]};
                2'b11: regfilemux_out = {{24{rs2_out[31]}},rs2_out[31:24]};
                endcase
            end
        regfilemux::lbu      : 
            begin
                unique case (mem_byte_enable_in)
                2'b00: regfilemux_out = {{24{1'b0}},rs2_out[7:0]};
                2'b01: regfilemux_out = {{24{1'b0}},rs2_out[15:8]};
                2'b10: regfilemux_out = {{24{1'b0}},rs2_out[23:16]};
                2'b11: regfilemux_out = {{24{1'b0}},rs2_out[31:24]};
                endcase
            end
        regfilemux::lh       : 
            begin
                unique case (mem_byte_enable_in)
                2'b00: regfilemux_out = {{16{rs2_out[15]}},rs2_out[15:0]};
                2'b01: regfilemux_out = {{16{rs2_out[23]}},rs2_out[23:8]};
                2'b10: regfilemux_out = {{16{rs2_out[31]}},rs2_out[31:16]};
                2'b11: regfilemux_out = {{24{1'b0}},rs2_out[31:24]};
                endcase
            end
        regfilemux::lhu      : 
            begin
                unique case (mem_byte_enable_in)
                2'b00: regfilemux_out = {{16{1'b0}},rs2_out[15:0]};
                2'b01: regfilemux_out = {{16{1'b0}},rs2_out[23:8]};
                2'b10: regfilemux_out = {{16{1'b0}},rs2_out[31:16]};
                2'b11: regfilemux_out = {{24{1'b0}},rs2_out[31:24]};
                endcase
            end        
        default: `BAD_MUX_SEL;
    endcase


end