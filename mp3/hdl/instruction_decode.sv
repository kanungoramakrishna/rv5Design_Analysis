module instruction_decode
(   
    input clk,
    input rst,
    input [31:0] PC,
    input [31:0] data, // instruction that has been fetched from I cache
    input [31:0] rd_in,
    input [4:0] rd,
    input logic load_regfile,

    output [31:0] PC_out,
    output [31:0] instruction_out,
    output rv32i_control_word ctrl_out,
    output rv32i_word ALUin_1_out,
    output rv32i_word ALUin_2_out,
    output rv32i_word CMPin_out,
    output rv32i_word rs1_out,
    output rv32i_word rs2_out
);


logic [31:0] i_imm;
logic [31:0] s_imm;
logic [31:0] b_imm;
logic [31:0] u_imm;
logic [31:0] j_imm;
assign i_imm = {{21{data[31]}}, data[30:20]};
assign s_imm = {{21{data[31]}}, data[30:25], data[11:7]};
assign b_imm = {{20{data[31]}}, data[7], data[30:25], data[11:8], 1'b0};
assign u_imm = {data[31:12], 12'h000};
assign j_imm = {{12{data[31]}}, data[19:12], data[20], data[30:21], 1'b0};

rv32i_control_word ctrl;
alumux1_sel_t alumux1_sel;
alumux2_sel_t alumux2_sel;
cmpmux_sel_t cmpmux_sel;
rv32i_word ALUin_1;
rv32i_word ALUin_2;
rv32i_word CMPin;

rv32i_word reg_a;
rv32i_word reg_b;

regfile regfile(
	.clk   (clk   ),
    .rst   (rst   ),
    .load  (load_regfile  ),
    .in    (rd_in    ),
    .src_a (data[19:15]),
    .src_b (data[24:20]),
    .dest  (rd),
    .reg_a (reg_a ),
    .reg_b (reg_b )
);

control_rom control_rom(.*);
