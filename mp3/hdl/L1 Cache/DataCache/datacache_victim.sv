module datacache_datapath
(
    input clk,
    input rst,
    input logic [31:0] mem_address,
    input logic [31:0] write_address,

    output logic [31:0] pmem_address,
    output logic [31:0] pmem_data,
    
)