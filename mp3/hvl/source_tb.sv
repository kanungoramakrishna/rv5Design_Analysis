`ifndef SOURCE_TB
`define SOURCE_TB

`define MAGIC_MEM 0
`define PARAM_MEM 1
`define MEMORY `PARAM_MEM

// Set these to 1 to enable the feature
`define USE_SHADOW_MEMORY 1
`define USE_RVFI_MONITOR 0

module source_tb(
    tb_itf.magic_mem magic_mem_itf,
    tb_itf.mem mem_itf,
    tb_itf.sm sm_itf,
    tb_itf.tb tb_itf,
    rvfi_itf rvfi
);

initial begin
    $display("Compilation Successful");
    tb_itf.path_mb.put("memory.lst");
    tb_itf.rst = 1'b1;
    repeat (5) @(posedge tb_itf.clk);
    tb_itf.rst = 1'b0;
end

/**************************** Halting Conditions *****************************/
int timeout = 100000000;
logic [31:0] rs1_data, rs2_data;

always @(negedge tb_itf.clk) begin
  rs1_data <= dut.cpu.WB.packet.rs1_addr ? dut.cpu.ID.regfile.data[dut.cpu.WB.packet.rs1_addr] : 0;
  rs2_data <= dut.cpu.WB.packet.rs2_addr ? dut.cpu.ID.regfile.data[dut.cpu.WB.packet.rs2_addr] : 0;
end

always @(posedge tb_itf.clk) begin
    if (rvfi.halt)
        $finish;
    if (timeout == 0) begin
        $display("TOP: Timed out");
        $finish;
    end
    timeout <= timeout - 1;
end

always @(rvfi.errcode iff (rvfi.errcode != 0)) begin
    repeat(5) @(posedge itf.clk);
    $display("TOP: Errcode: %0d", rvfi.errcode);
    $finish;
end

/************************** End Halting Conditions ***************************/

generate
    if (`MEMORY == `MAGIC_MEM) begin : memory
        magic_memory_dp mem(magic_mem_itf);
    end
    else if (`MEMORY == `PARAM_MEM) begin : memory
        ParamMemory #(50, 25, 4, 256, 512) mem(mem_itf);
    end
endgenerate

generate
    if (`USE_SHADOW_MEMORY) begin
        shadow_memory sm(sm_itf);
    end

    if (`USE_RVFI_MONITOR) begin
        /* Instantiate RVFI Monitor */
        riscv_formal_monitor_rv32imc monitor (
          .clock (itf.clk),
          .reset (itf.rst),
          .rvfi_valid (rvfi.commit),
          .rvfi_order (rvfi.order),
          .rvfi_insn (dut.cpu.WB.packet.instruction),
          .rvfi_trap(1'b0),
          .rvfi_halt(rvfi.halt),
          .rvfi_intr(1'b0),
          .rvfi_mode(2'b00),
          .rvfi_rs1_addr(dut.cpu.WB.packet.rs1_addr),
          .rvfi_rs2_addr(dut.cpu.WB.packet.rs2_addr),
          .rvfi_rs1_rdata(rs1_data),
          .rvfi_rs2_rdata(rs2_data),
          .rvfi_rd_addr(dut.cpu.ID.load_regfile ? dut.cpu.WB.packet.rd_addr : 5'h0),
          .rvfi_rd_wdata(monitor.rvfi_rd_addr ? dut.cpu.WB.packet.rd_data : 0),
          .rvfi_pc_rdata(dut.cpu.WB.packet.pc_rdata),
          .rvfi_pc_wdata(dut.cpu.WB.packet.pc_wdata),
          .rvfi_mem_addr(dut.cpu.WB.packet.mem_addr),
          .rvfi_mem_rmask(dut.cpu.WB.packet.mem_rmask),
          .rvfi_mem_wmask(dut.cpu.WB.packet.mem_wmask),
          .rvfi_mem_rdata(dut.cpu.WB.packet.mem_rdata),
          .rvfi_mem_wdata(dut.cpu.WB.packet.mem_wdata),
          .rvfi_mem_extamo(1'b0),
          .errcode(rvfi.errcode)
        );
    end
endgenerate

endmodule

`endif
