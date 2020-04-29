import rv32i_types::*;

module ex_forward_unit
(
    input  rv32i_word instr,
    input  rv32i_control_word id_ex, ex_mem, mem_wb,
    output logic [1:0] fwd_alu [1:0],
    output logic [1:0] fwd_cmp [1:0],
    output logic [1:0] fwd_rs2
);

rv32i_reg id_ex_rs1, id_ex_rs2;

/*
fwd == 00   Data from ID/EX
fwd == 01   Data from MEM/WB
fwd == 10   Data from EX/MEM
fwd == 11   N/A
*/

always_comb
begin
    id_ex_rs1 = 0;
    id_ex_rs2 = 0;
    fwd_alu[0] = 2'b00;
    fwd_alu[1] = 2'b00;
    fwd_cmp[0] = 2'b00;
    fwd_cmp[1] = 2'b00;
    fwd_rs2    = 2'b00;

    case (id_ex.opcode)
        op_lui,op_auipc,op_jal,op_jal:
        begin
            id_ex_rs1 = 0;
            id_ex_rs2 = 0;
        end

        op_jalr,op_load,op_imm:
        begin
            id_ex_rs1 = instr[19:15];
            id_ex_rs2 = 0;
        end

        default:
        begin
            id_ex_rs1 = instr[19:15];
            id_ex_rs2 = instr[24:20];
        end
    endcase

    case (id_ex.opcode)
        op_lui, op_auipc, op_jal, op_csr:; // Never forward
        op_br:
        begin
            /*
            FWD ALU - nil
            FWD CMP - RS1, RS2
            FWD FF  - nil
            */
            if (mem_wb.load_regfile && mem_wb.rd != 0)
            begin
                if (mem_wb.rd == id_ex_rs1)
                begin
                    fwd_cmp[0] = 2'b01;
                end
                if (mem_wb.rd == id_ex_rs2)
                begin
                    fwd_cmp[1] = 2'b01;
                end
            end
            if (ex_mem.load_regfile && ex_mem.rd != 0)
            begin
                if (ex_mem.rd == id_ex_rs1)
                begin
                    fwd_cmp[0] = 2'b10;
                end
                if (ex_mem.rd == id_ex_rs2)
                begin
                    fwd_cmp[1] = 2'b10;
                end
            end
        end

        op_store, op_load:
        begin
            /*
            FWD ALU - RS1
            FWD CMP - nil
            FWD FF  - RS2
            */
            if (mem_wb.load_regfile && mem_wb.rd != 0)
            begin
                if (mem_wb.rd == id_ex_rs1)
                begin
                    fwd_alu[0] = 2'b01;
                end
                if (mem_wb.rd == id_ex_rs2)
                begin
                    fwd_rs2 = 2'b01;
                end
            end
            if (ex_mem.load_regfile && ex_mem.rd != 0)
            begin
                if (ex_mem.rd == id_ex_rs1)
                begin
                    fwd_alu[0] = 2'b10;
                end
                if (ex_mem.rd == id_ex_rs2)
                begin
                    fwd_rs2 = 2'b10;
                end
            end
        end

        op_reg, op_imm, op_jalr:
        begin
            /*
            FWD ALU - RS1, RS2
            FWD CMP - nil
            FWD FF  - nil
            */
            if (mem_wb.load_regfile && mem_wb.rd != 0)
            begin
                if (mem_wb.rd == id_ex_rs1)
                begin
                    fwd_alu[0] = 2'b01;
                    fwd_cmp[0] = 2'b01;
                end
                if (mem_wb.rd == id_ex_rs2)
                begin
                    fwd_alu[1] = 2'b01;
                    fwd_cmp[1] = 2'b01;
                end
            end
            if (ex_mem.load_regfile && ex_mem.rd != 0)
            begin
                if (ex_mem.rd == id_ex_rs1)
                begin
                    fwd_alu[0] = 2'b10;
                    fwd_cmp[0] = 2'b10;
                end
                if (ex_mem.rd == id_ex_rs2)
                begin
                    fwd_alu[1] = 2'b10;
                    fwd_cmp[1] = 2'b10;
                end
            end
        end
    endcase
end
endmodule
