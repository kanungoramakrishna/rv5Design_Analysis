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
          .rvfi_insn (dut.cpu.IF.instr_ff),
          .rvfi_trap(1'b0),
          .rvfi_halt(rvfi.halt),
          .rvfi_intr(1'b0),
          .rvfi_mode(2'b00),
          .rvfi_rs1_addr(dut.cpu.ID.regfile.src_a),
          .rvfi_rs2_addr(dut.cpu.ID.regfile.src_b),
          .rvfi_rs1_rdata(monitor.rvfi_rs1_addr ? dut.cpu.ID.rs1_out : 0),
          .rvfi_rs2_rdata(monitor.rvfi_rs2_addr ? dut.cpu.ID.rs2_out : 0),
          .rvfi_rd_addr(dut.cpu.ID.load_regfile ? dut.cpu.ID.rd : 5'h0),
          .rvfi_rd_wdata(monitor.rvfi_rd_addr ? dut.cpu.ID.rd_in : 0),
          .rvfi_pc_rdata(dut.cpu.IF.pc_ff),
          .rvfi_pc_wdata(dut.cpu.IF.pc_in),
          .rvfi_mem_addr(itf.data_addr),
          .rvfi_mem_rmask(dut.cpu.data_mbe),
          .rvfi_mem_wmask(dut.cpu.data_mbe),
          .rvfi_mem_rdata(dut.cpu.data_rdata),
          .rvfi_mem_wdata(dut.cpu.data_wdata),
          .rvfi_mem_extamo(1'b0),
          .errcode(rvfi.errcode)
        );
    end
endgenerate

endmodule

`endif
