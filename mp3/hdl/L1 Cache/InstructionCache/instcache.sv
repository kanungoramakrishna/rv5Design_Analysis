import rv32i_types::*;

module instcache #(
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
    input rv32i_word mem_address,
    input logic mem_read,
    input logic pmem_resp,
    input logic [255:0] pmem_rdata,
    output rv32i_word mem_rdata,
    output rv32i_word pmem_address,
    output logic pmem_read,
    output logic mem_resp
);

logic HIT;
logic way_hit;
logic [1:0] valid_out;

logic lru_data;
logic valid_in;
logic lru_in_value;

logic LD_LRU_in;
logic [1:0] LD_TAG;

logic [1:0] LD_VALID;
logic [2:0] W_CACHE_STATUS;
rv32i_word mem_address_copy;


logic [255:0] mem_rdata256;
logic [31:0] mem_byte_enable256;

logic [31:0] cacheline_addr_in;

assign mem_address_copy = mem_address;

// Victim cache signals
logic [255:0] data_from_cache;
logic [255:0] data_to_cache;
logic [255:0] victim_data;

assign pmem_address = cacheline_addr_in;
assign data_to_cache = pmem_resp ? pmem_rdata : victim_data;



logic valid_in_victim;
logic dirty_in_victim;
logic lru_in_victim;
logic [1:0] LD_DIRTY_victim;
logic [1:0] LD_VALID_victim;
logic [1:0] LD_TAG_victim;
logic [1:0] LD_DATA_victim;

logic LD_LRU_victim;

logic [1:0] valid_out_victim;
logic [1:0] dirty_out_victim;
logic lru_data_victim;

logic HIT_victim;
logic way_hit_victim;

instruction_victim inst_victim(
  .*,
  .mem_address      (mem_address      ),
  .evict_address    (cacheline_addr_in),
  .data_to_cache    (victim_data    ),
  .valid_in_victim  (valid_in_victim  ),
  .lru_in_victim    (lru_in_victim    ),
  .data_arr_in      (data_from_cache  ),
  .LD_VALID_victim  (LD_VALID_victim  ),
  .LD_TAG_victim    (LD_TAG_victim    ),
  .LD_DATA_victim   (LD_DATA_victim   ),
  .LD_LRU_victim    (LD_LRU_victim    ),
  .valid_out_victim (valid_out_victim ),
  .lru_data_victim  (lru_data_victim  ),
  .HIT_victim       (HIT_victim       ),
  .way_hit_victim   (way_hit_victim   )
);


instcache_control control (
  .*,
  .mem_read_cpu (mem_read),
  .mem_resp_cpu (mem_resp),
  .cacheline_read (pmem_read)
);

instcache_datapath datapath (
  .*,
  .mem_address (mem_address_copy),
  .cacheline_addr_in (cacheline_addr_in),
  .cacheline_out (data_to_cache),
  .cacheline_in(data_from_cache)
);

instcache_bus_adapter bus_adapter (
  .*,
  .address (mem_address_copy)
);

endmodule : instcache
