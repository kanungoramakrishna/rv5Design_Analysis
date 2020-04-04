import rv32i_types::*;
import pcmux::*;
module mp3
(
    input clk,
    input rst,

    input pmem_resp,
    input [63:0] pmem_rdata,
    output logic pmem_read,
    output logic pmem_write,
    output rv32i_word pmem_address,
    output [63:0] pmem_wdata

);

//PC Signals
logic inst_read;
logic [31:0] inst_addr;
logic inst_resp;
logic [31:0] inst_rdata;

logic data_read;
logic data_write;
logic [3:0] data_mbe;
logic [31:0] data_addr;
logic [31:0] data_wdata;
logic data_resp;
logic [31:0] data_rdata;

//Arbiter Signals


// arbiter arbiter (
//   .*,
//   .mem_resp
// );

cpu cpu(.*);


datacache datacache(
	.clk                (clk),
    .rst                (rst),
    .mem_address        (data_addr ),
    .mem_wdata          (data_wdata),
    .mem_write          (data_write ),
    .mem_read           (data_read),
    .mem_byte_enable    (data_mbe),
    .pmem_resp          (),
    .pmem_rdata         (),
    .mem_rdata          (data_rdata ),
    .pmem_wdata         (),
    .pmem_address       (),
    .pmem_write         (),
    .pmem_read          (),
    .mem_resp           (data_resp)
);

instcache instcache(
	.clk            (clk),
    .rst            (rst),
    .mem_address    (inst_addr),
    .mem_read       (inst_read),
    .pmem_resp      (),
    .pmem_rdata     (),
    .mem_rdata      (inst_rdata),
    .pmem_address   (),
    .pmem_read      (),
    .mem_resp       (inst_resp)
);




endmodule : mp3
