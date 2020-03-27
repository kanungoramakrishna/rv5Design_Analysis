import rv32i_types::*;

module mp3
(
    input clk,
    input rst,

    output logic inst_read,
    output logic [31:0] inst_addr,
    input logic inst_resp,
    input logic [31:0] inst_rdata,

    output data_read;
    output data_write;
    output logic [3:0] data_mbe;
    output logic [31:0] data_addr;
    output logic [31:0] data_wdata;
    input logic data_resp;
    input logic [31:0] data_rdata;

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

/*****************************************************************************/

/**************************** Control Signals ********************************/

//Signals between fetch and decode
//connected to registered outputs of fetch
rv32i_word instruction_IF_DE;
rv32i_word PC_IF_DE;

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
logic [3:0] mask_EXE_MA;
rv32i_word rs2_EXE_MA;


//Signals between memory access and write back
//connected to registered outputs registered outputs of memory access
rv32i_control_word ctrl_MA_WB;
rv32i_word instruction_MA_WB;
rv32i_word PC_MA_WB;
logic [3:0] mask_MA_WB;


//Other signals
//WB to DE to write to register file
logic load_regfile;
logic [31:0] rd_in;
logic [4:0] rd;

/*****************************************************************************/

instruction_fetch IF();

instruction_decode DE();

execute EXE();

memory_access MA();

write_back WB();


endmodule : mp3
