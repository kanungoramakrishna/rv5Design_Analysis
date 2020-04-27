module mp3_tb;
`timescale 1ns/10ps

/********************* Do not touch for proper compilation *******************/
// Instantiate Interfaces
tb_itf itf();
rvfi_itf rvfi(itf.clk, itf.rst);

// Instantiate Testbench
source_tb tb(
    .magic_mem_itf(itf),
    .mem_itf(itf),
    .sm_itf(itf),
    .tb_itf(itf),
    .rvfi(rvfi)
);
/****************************** End do not touch *****************************/

/************************ Signals necessary for monitor **********************/
// This section not required until CP3

assign rvfi.commit = dut.cpu.ID.load_regfile | (dut.cpu.WB.ctrl_word_in.opcode == 7'b1100011) | (dut.cpu.WB.ctrl_word_in.opcode == 7'b0100011) && (~dut.cpu.EXE.MA_stall); // Set high when a valid instruction is modifying regfile or PC
initial rvfi.order = 0;
always @(posedge itf.clk iff rvfi.commit) rvfi.order <= rvfi.order + 1; // Modify for OoO
/**************************** End RVFIMON signals ****************************/

/********************* Assign Shadow Memory Signals Here *********************/
// This section not required until CP2
/* I Cache Ports */
assign itf.inst_read = dut.cpu.inst_read;
assign itf.inst_addr = dut.cpu.inst_addr;
assign itf.inst_resp = dut.cpu.inst_resp;
assign itf.inst_rdata = dut.cpu.inst_rdata;

/* D Cache Ports */
assign itf.data_read = dut.cpu.data_read;
assign itf.data_write = dut.cpu.data_write;
assign itf.data_mbe =  dut.cpu.data_mbe;
assign itf.data_addr = dut.cpu.data_addr;
assign itf.data_wdata = dut.cpu.data_wdata;
assign itf.data_resp = dut.cpu.data_resp;
assign itf.data_rdata = dut.cpu.data_rdata;
/*********************** End Shadow Memory Assignments ***********************/



/*********************** Instantiate your design here ************************/
mp3 dut(
  .clk (itf.clk),
  .rst (itf.rst),

  .pmem_resp(itf.mem_resp),
  .pmem_rdata(itf.mem_rdata),
  .pmem_read(itf.mem_read),
  .pmem_write(itf.mem_write),
  .pmem_address(itf.mem_addr),
  .pmem_wdata(itf.mem_wdata)
);

// Set this to the proper value
assign itf.registers = dut.cpu.ID.regfile.data;
assign rvfi.halt = ((dut.cpu.ctrl_MA_WB.opcode == 7'b1100011) && (dut.cpu.instruction_IF_DE == dut.cpu.instruction_MA_WB) && (dut.cpu.PC_IF_DE == dut.cpu.PC_MA_WB)); 
// assign rvfi.halt = (dut.cpu.ID.regfile.data[1] == 32'h600D600D) | (dut.cpu.ID.regfile.data[1] == 32'h0000000F) | (dut.cpu.ID.regfile.data[7] == 32'h600D600D);
/***************************** End Instantiation *****************************/




endmodule
