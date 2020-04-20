import rv32i_types::*;

module L2Cache #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(   
    input logic clk,
    input logic rst,
    input logic [31:0] mem_address,
    input logic [255:0] mem_wdata,
    input logic mem_write,
    input logic mem_read,
    input logic pmem_resp,
    input logic [255:0] pmem_rdata,
    output logic [255:0] mem_rdata,
    output logic [255:0] pmem_wdata,
    output rv32i_word pmem_address,
    output logic pmem_write,
    output logic pmem_read,
    output logic mem_resp
    /*
    input logic clk,

    input logic rst,
    input logic [26:0] address_arbiter_to_l2;
    input logic read_arbiter_to_l2;
    input logic write_arbiter_to_l2;
    input logic [255:0] data_arbiter_to_l2;

    output logic mem_resp;
    output logic [255:0] data_L2_to_arbiter,

    output logic [255:0] data_L2_to_cacheline,
    output logic [31:0]  address_L2_to_cacheline,
    */

);

logic HIT;
logic way_hit;
logic [1:0] valid_out;
logic [1:0] dirty_out;
logic lru_data;
logic valid_in;
logic lru_in_value;
logic dirty_in_value;
logic LD_LRU;
logic [1:0] LD_TAG;
logic [1:0] LD_DIRTY;
logic [1:0] LD_VALID;
logic [2:0] W_CACHE_STATUS;
logic mem_resp_cache_control;
logic cacheline_write_datapath;
logic cacheline_read_control;
rv32i_word mem_address_copy;

logic [255:0] mem_wdata256;
logic [255:0] mem_rdata256;

assign mem_address_copy = mem_address;
assign mem_wdata256 = mem_wdata;

assign mem_rdata = mem_rdata256;


L2Cache_Control control (
  .*,
  .mem_write_cpu (mem_write),
  .mem_read_cpu (mem_read),
  .mem_resp_cpu (mem_resp),
  .cacheline_read (pmem_read)
);

L2Cache_Datapath datapath (
  .*,
  .mem_address (mem_address_copy),
  .cacheline_addr_in (pmem_address),
  .cacheline_in (pmem_wdata),
  .cacheline_out (pmem_rdata),
  .cacheline_write (pmem_write)
);


endmodule : L2Cache
