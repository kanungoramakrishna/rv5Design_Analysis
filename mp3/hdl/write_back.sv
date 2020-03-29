module write_back
(
    input rv32i_word PC_in,
    input rv32i_word PC_plus4_in,
    input rv32i_word instruction_in,
    input rv32i_control_word ctrl_word_in,
    input [3:0] mem_byte_enable_in,
    input rv32i_word r_data_in,
    input rv32i_word alu_in,
    input rv32i_word br_en_in,

    
    //To regfile (ID)
    output logic load_regfile,
    output logic [31:0] rd_in,
    output logic [4:0] rd,

    //To PCmux (IF)
    output logic [31:0] alu_out_to_PC,
    output  pcmux_sel_t pcmux_sel

);

logic [31:0] regfilemux_out;

//To IF
assign alu_out_to_PC = alu_in;
assign pcmux_sel = ctrl_word_in.pcmux_sel;

//To ID to write to registers
assign load_regfile = ctrl_word_in.load_regfile;
assign rd_in = regfilemux_out;
assign rd = ctrl_word_in.rd;

//PCMUX_sel
always_comb
begin
    if(br_en_in[0])
        pcmux_sel = ctrl_word_in.pcmux_sel;
    end
        pcmux_sel = pcmux::pc_plus4;

end


//Regfile MUX
always_comb
begin
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
                default: regfilemux_out = {{16{r_data_in[15]}},r_data_in[15:0]};
                endcase
            end
        regfilemux::lhu      : 
            begin
                unique case (mem_byte_enable_in)
                4'b0011: regfilemux_out = {{16{1'b0}},r_data_in[15:0]};
                4'b0110: regfilemux_out = {{16{1'b0}},r_data_in[23:8]};
                4'b1100: regfilemux_out = {{16{1'b0}},r_data_in[31:16]};
                default: regfilemux_out = {{16{1'b0}},r_data_in[15:0]};
                endcase
            end        
        default: `BAD_MUX_SEL;
    endcase


end