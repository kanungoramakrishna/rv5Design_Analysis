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

assign rvfi.commit = 0; // Set high when a valid instruction is modifying regfile or PC
//assign rvfi.halt = 0;   // Set high when you detect an infinite loop
initial rvfi.order = 0;
always @(posedge itf.clk iff rvfi.commit) rvfi.order <= rvfi.order + 1; // Modify for OoO
/**************************** End RVFIMON signals ****************************/

/********************* Assign Shadow Memory Signals Here *********************/
// This section not required until CP2
/*********************** End Shadow Memory Assignments ***********************/



/*********************** Instantiate your design here ************************/
mp3 dut(
  .clk (itf.clk),
  .rst (itf.rst),

  .inst_read (itf.inst_read),
  .inst_addr (itf.inst_addr),
  .inst_resp (itf.inst_resp),
  .inst_rdata (itf.inst_rdata),

  .data_read (itf.data_read),
  .data_write (itf.data_write),
  .data_mbe (itf.data_mbe),
  .data_addr (itf.data_addr),
  .data_wdata (itf.data_wdata),
  .data_resp (itf.data_resp),
  .data_rdata (itf.data_rdata)
);

// Set this to the proper value
assign itf.registers = dut.ID.regfile.data;
assign rvfi.halt = (dut.ID.regfile.data[1] == 32'h600D600d); 
//assign rvfi.halt = dut.instruction_fetch.pc_load & (dut.instruction_fetch.pc_ff == dut.instruction_fetch.pc_out);
/***************************** End Instantiation *****************************/

endmodule