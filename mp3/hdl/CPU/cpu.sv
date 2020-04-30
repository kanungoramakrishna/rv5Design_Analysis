import rv32i_types::*;
import pcmux::*;
module cpu
(
    input clk,
    input rst,

    output logic inst_read,
    output logic [31:0] inst_addr,
    input logic inst_resp,
    input logic [31:0] inst_rdata,

    output data_read,
    output data_write,
    output logic [3:0] data_mbe,
    output logic [31:0] data_addr,
    output logic [31:0] data_wdata,
    input logic data_resp,
    input logic [31:0] data_rdata

);

/******************* Signals Needed for RVFI Monitor *************************/

rv32i_opcode opcode;
logic [2:0] funct3;
logic [6:0] funct7;
logic br_en;
rv32i_word rs1_out;
rv32i_word rs2_out;

rv32i_reg rs1;
rv32i_reg rs2;

logic [1:0] mask_out;

rv32i_word alu_input_1_EX_MA;
rv32i_word alu_input_1_MA_WB;

rv32i_word alu_input_2_EX_MA;
rv32i_word alu_input_2_MA_WB;

/*****************************************************************************/

/**************************** Control Signals ********************************/

//Signals between fetch and decode
//connected to registered outputs of fetch
rv32i_word instruction_IF_DE;
rv32i_word PC_IF_DE;
logic bubble;   // Forwarding
logic false_NOP;

//Signals between decode and execute
//connected to registered outputs of decode
rv32i_control_word ctrl_ID_EXE;
rv32i_word instruction_ID_EXE;
rv32i_word PC_ID_EXE;
rv32i_word ALUin_1_ID_EXE;
rv32i_word ALUin_2_ID_EXE;
rv32i_word CMPin_ID_EXE;
rv32i_word rs1_ID_EXE;
rv32i_word rs2_ID_EXE;

//Signals between execute and memory access
//connected to Registered outputs puts of execute
rv32i_control_word ctrl_EXE_MA;
rv32i_word instruction_EXE_MA;
rv32i_word PC_EXE_MA;
rv32i_word alu_EXE_MA;
logic [3:0] mask_EXE_MA;
logic br_EXE_MA;
rv32i_word rs2_EXE_MA;

pcmux_sel_t pcmux_sel;
rv32i_word alu_out_to_PC;
logic br_taken;
logic [1:0] addr_offset;


//Signals between memory access and write back
//connected to registered outputs registered outputs of memory access
rv32i_control_word ctrl_MA_WB;
rv32i_word instruction_MA_WB;
rv32i_word PC_MA_WB;
rv32i_word PC_plus4_MA_WB;
logic [3:0] mask_MA_WB;
rv32i_word r_data_MA_WB;
rv32i_word w_data_MA_WB;
rv32i_word br_MA_WB;
rv32i_word alu_MA_WB;
rv32i_word data_addr_MA_WB;


//Other signals
//WB to DE to write to register file
logic load_regfile;
logic [31:0] rd_in;
logic [4:0] rd;

//stall, these are .*
logic IF_stall;
logic MA_stall;
logic leap;
rv32i_word alu_frog;
rv32i_control_word ctrl_word_frog;
rv32i_word instruction_frog;
rv32i_word pc_frog;
rv32i_word pc_plus4_frog;
logic br_en_frog;

/*****************************************************************************/

instruction_fetch IF(
    .*,
	.clk        (clk ),
    .rst        (rst ),
    .pcmux_sel  (pcmux_sel ),
    .alu_out    (alu_out_to_PC),
    .br_taken   (br_taken),
    .bubble     (bubble),    // Forwarding

    .inst_resp  (inst_resp),
    .inst_rdata (inst_rdata ),
    .inst_read  (inst_read ),
    .inst_addr  (inst_addr  ),

    //Registered outputs
    .pc_ff      (PC_IF_DE ),
    .instr_ff   (instruction_IF_DE )

);

instruction_decode ID(
    .*,
	.clk (clk ),
    .rst (rst ),
    .PC  (PC_IF_DE ),
    .data_  (instruction_IF_DE ),

    .rd_in  (rd_in ),
    .rd     (rd  ),
    .load_regfile   (load_regfile  ),
    .br_taken       (br_taken),

    //Registered outputs
    .ctrl_out       (ctrl_ID_EXE),
    .instruction_out (instruction_ID_EXE ),
    .PC_out         (PC_ID_EXE),
    .ALUin_1_out    (ALUin_1_ID_EXE),
    .ALUin_2_out    (ALUin_2_ID_EXE),
    .CMPin_out      (CMPin_ID_EXE  ),
    .rs1_out        (rs1_ID_EXE    ),
    .rs2_out        (rs2_ID_EXE    ),

    .bubble         (bubble)    // Forwarding
);


instruction_execute EXE(
    .*,
	.clk                   (clk),
    .rst                   (rst),

    .PC_in                 (PC_ID_EXE),
    .instruction_in        (instruction_ID_EXE),
    .alu_in_1              (ALUin_1_ID_EXE),
    .alu_in_2              (ALUin_2_ID_EXE),
    .rs1_out               (rs1_ID_EXE),
    .rs2                   (rs2_ID_EXE),
    .cmp_in                (CMPin_ID_EXE),
    .ctrl_word_in          (ctrl_ID_EXE  ),
    .mem_wb                (leap ? ctrl_word_frog : ctrl_MA_WB),
    .mem_wb_data           (rd_in),

    //Registered outputs
    .ctrl_word_out         (ctrl_EXE_MA ),
    .instruction_out       (instruction_EXE_MA),
    .PC_out                (PC_EXE_MA),
    .alu_out               (alu_EXE_MA),
    .rs2_out               (rs2_EXE_MA),
    .br_en_out             (br_EXE_MA ),
    .mem_byte_enable_out   (mask_EXE_MA),
    .alu_out_to_PC         (alu_out_to_PC),
    .pcmux_sel             (pcmux_sel),
    .br_taken              (br_taken),
    .alu_input_1_o         (alu_input_1_EX_MA),
    .alu_input_2_o         (alu_input_2_EX_MA),
    .addr_offset           (addr_offset)
);

memory_access MA(
    .*,
	.clk                        (clk),
    .rst                        (rst),

    .PC_in                      (PC_EXE_MA),
    .instruction_in             (instruction_EXE_MA),
    .ctrl_word_in               (ctrl_EXE_MA),
    .mem_byte_enable_in         (mask_EXE_MA),
    .rs2_out                    (rs2_EXE_MA),
    .alu_output_in              (alu_EXE_MA),
    .br_en_in                   (br_EXE_MA),

    .data_rdata_in              (data_rdata),
    .data_resp                  (data_resp),
    .data_addr                  (data_addr),
    .data_wdata                 (data_wdata),
    .data_mbe                   (data_mbe),
    .data_read                  (data_read),
    .data_write                 (data_write),
    .alu_input_1_rvfi_in        (alu_input_1_EX_MA),
    .alu_input_2_rvfi_in        (alu_input_2_EX_MA),
    .addr_offset                (addr_offset),

    //Registered Outputs
    .ctrl_word_out              (ctrl_MA_WB ),
    .instruction_out            (instruction_MA_WB),
    .mem_byte_enable_out        (mask_MA_WB),
    .r_data_out                 (r_data_MA_WB),
    .w_data_out                 (w_data_MA_WB),
    .br_en_out                  (br_MA_WB),
    .PC_out                     (PC_MA_WB),
    .PC_plus4_out               (PC_plus4_MA_WB),
    .alu_output_out             (alu_MA_WB),
    .data_addr_MA_WB            (data_addr_MA_WB),
    .alu_input_1_rvfi_o         (alu_input_1_MA_WB),
    .alu_input_2_rvfi_o         (alu_input_2_MA_WB)
);

write_back WB(
    .clk                    (clk),
    .leap                   (leap),
	  .PC_in                  (leap ? pc_frog : PC_MA_WB),
    .PC_plus4_in            (leap ? pc_plus4_frog : PC_plus4_MA_WB),
    .instruction_in         (instruction_MA_WB),
    .instruction_frog       (instruction_frog),
    .ctrl_word_in           (leap ? ctrl_word_frog : ctrl_MA_WB ),
    .mem_byte_enable_in     (mask_MA_WB),
    .w_data_in              (w_data_MA_WB),
    .r_data_in              (r_data_MA_WB),
    .alu_in                 (leap ? alu_frog : alu_MA_WB),
    .br_en_in               (leap ? br_en_frog : br_MA_WB),
    .data_addr_in           (data_addr_MA_WB),


    .load_regfile           (load_regfile),
    .rd_in                  (rd_in),
    .rd                     (rd)
);


endmodule : cpu
