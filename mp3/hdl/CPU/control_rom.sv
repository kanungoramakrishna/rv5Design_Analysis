import rv32i_types::*;
import alumux::*;
import cmpmux::*;

module control_rom
(
    input rv32i_word data,
    input [31:0] u_imm,

    output rv32i_control_word ctrl,
    output alumux1_sel_t alumux1_sel,
    output alumux2_sel_t alumux2_sel,
    output cmpmux_sel_t cmpmux_sel
);
logic [2:0] funct3;
logic [6:0] funct7;

assign funct3 = data[14:12];
assign funct7 = data[31:25];

function void set_defaults();
    /* Default assignments */
    ctrl.opcode = rv32i_opcode'(data[6:0]);
    ctrl.load_regfile = 1'b0;
    ctrl.rd = data[11:7];
    ctrl.cmpop = branch_funct3_t'(funct3);
    ctrl.aluop = alu_add;
    ctrl.read = 1'b0;
    ctrl.write = 1'b0;
    ctrl.u_imm = u_imm;
    ctrl.regfilemux_sel = regfilemux::alu_out;
    ctrl.pcmux_sel = pcmux::pc_plus4;
    cmpmux_sel = cmpmux::rs2_out;
    alumux1_sel = alumux::rs1_out;
    alumux2_sel = alumux::i_imm;
endfunction

/*signals being set to load regfile*/
function void loadRegfile(regfilemux::regfilemux_sel_t sel);
    ctrl.load_regfile = 1'b1;
    ctrl.regfilemux_sel = sel;
endfunction

/*signals being set for ALU*/
function void setALU(alumux::alumux1_sel_t sel1,
                alumux::alumux2_sel_t sel2,
                logic setop = 1'b0, alu_ops op = alu_add);

    alumux1_sel = sel1;
    alumux2_sel = sel2;
    if (setop)
        ctrl.aluop = op;

endfunction

/*signals being set for CMP to function*/
function automatic void setCMP(cmpmux::cmpmux_sel_t sel, branch_funct3_t op);
    cmpmux_sel = sel;
    ctrl.cmpop = op;

endfunction


always_comb
begin
    set_defaults();
    /* Assign control signals based on opcode */
    case (ctrl.opcode)
        op_lui :
            loadRegfile(regfilemux::u_imm);
        op_auipc :
        begin
            loadRegfile(regfilemux::alu_out);
            setALU(alumux::pc_out,alumux::u_imm,1'b1,alu_add);
        end
        op_jal :
        begin
            loadRegfile(regfilemux::pc_plus4);
            setALU(alumux::pc_out, alumux::j_imm,1'b1, alu_add); 
            ctrl.pcmux_sel = pcmux::alu_out; 
        end
        op_jalr :
        begin
            loadRegfile(regfilemux::pc_plus4);
            setALU(alumux::rs1_out, alumux::i_imm,1'b1, alu_add);
            ctrl.pcmux_sel = pcmux::alu_mod2; 
        end

        
        op_br :
        begin
            setALU(alumux::pc_out,alumux::b_imm,1'b1,alu_add);
            setCMP(cmpmux::rs2_out,branch_funct3_t'(funct3));
            ctrl.pcmux_sel = pcmux::alu_out;
        end
        op_load :
        begin
            setALU(alumux::rs1_out,alumux::i_imm,1'b1, alu_add);
            ctrl.read = 1'b1;
             unique case(load_funct3_t'(funct3))
                lb:
                    loadRegfile(regfilemux::lb);
                lh:
                    loadRegfile(regfilemux::lh);
                lw:
                    loadRegfile(regfilemux::lw);
                lbu:
                    loadRegfile(regfilemux::lbu);
                lhu:
                    loadRegfile(regfilemux::lhu);
                default:;
            endcase
        end
        op_store :
        begin
            setALU(alumux::rs1_out,alumux::s_imm,1'b1, alu_add);
            ctrl.write = 1'b1;
        end
        op_imm :
        begin
            unique case(arith_funct3_t'(funct3))
                slt:
                begin
                    loadRegfile(regfilemux::br_en);
                    setCMP(cmpmux::i_imm, blt);
                end
                sltu:
                begin
                    loadRegfile(regfilemux::br_en);
                    setCMP(cmpmux::i_imm, bltu);
                end
                sr:
                begin
                    loadRegfile(regfilemux::alu_out);
                    if(funct7[5]) setALU(alumux::rs1_out,alumux::i_imm,1'b1,alu_sra);
                    else setALU(alumux::rs1_out,alumux::i_imm,1'b1,alu_srl);

                end
                default:
                begin
                    loadRegfile(regfilemux::alu_out);
                    setALU(alumux::rs1_out,alumux::i_imm,1'b1,alu_ops'(funct3));
                end
			endcase
        end
        op_reg :
        begin
            unique case(arith_funct3_t'(funct3))
                slt:
                begin
                    loadRegfile(regfilemux::br_en);
                    setCMP(cmpmux::rs2_out, blt);
                end
                sltu:
                begin
                    loadRegfile(regfilemux::br_en);
                    setCMP(cmpmux::rs2_out, bltu);
                end
                sr:
                begin
                    loadRegfile(regfilemux::alu_out);
                    if(funct7[5]) setALU(alumux::rs1_out,alumux::rs2_out,1'b1,alu_sra);
                    else setALU(alumux::rs1_out,alumux::rs2_out,1'b1,alu_srl);
                end
                add:
                begin
                    loadRegfile(regfilemux::alu_out);
                    if(funct7[5]) setALU(alumux::rs1_out,alumux::rs2_out,1'b1,alu_sub);
                    else setALU(alumux::rs1_out,alumux::rs2_out,1'b1,alu_add);
                end
                default:
                begin
                    loadRegfile(regfilemux::alu_out);
                    setALU(alumux::rs1_out,alumux::rs2_out,1'b1,alu_ops'(funct3));
                end
			endcase
        end
        default: begin
            ctrl = 0;   /* Unknown opcode, set control word to zero */
        end
    endcase
end
endmodule : control_rom
