module L2Cache_Datapath #(
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
    input logic [255:0] mem_wdata256,
    input logic [255:0] cacheline_out,
    input logic [31:0] mem_address,
    input logic [1:0] LD_DIRTY,
    input logic dirty_in_value,
    input logic LD_LRU,
    input logic lru_in_value,
    input logic [1:0] LD_VALID,
    input logic valid_in,
    input logic [1:0] LD_TAG,
    input logic [2:0] W_CACHE_STATUS,
    output logic cacheline_write,
    output logic [1:0] valid_out,
    output logic [1:0] dirty_out,
    output logic HIT,
    output logic way_hit,
    output logic lru_data,
    output logic [31:0] cacheline_addr_in,
    output logic [255:0] cacheline_in,
    output logic [255:0] mem_rdata256
);

logic [1:0][22:0] tag_out;
logic [1:0][255:0] data_arr_out;
logic [255:0] data_arr_in_value;
logic [1:0] data_arr_write_en_in;


//valid, dirty, LRU, and tag arrays for two ways//

L2_data_array valid_arr[1:0] (
    .*,
    .read (1'b1),
    .load (LD_VALID[1:0]),
    .rindex (mem_address[8:5]),
    .windex (mem_address[8:5]),
    .datain (valid_in),
    .dataout (valid_out)
);

L2_data_array dirty_arr[1:0] (
    .*,
    .read (1'b1),
    .load (LD_DIRTY[1:0]),
    .rindex (mem_address[8:5]),
    .windex (mem_address[8:5]),
    .datain (dirty_in_value),
    .dataout (dirty_out)
);

L2_data_array lru_arr (
    .*,
    .read (1'b1),
    .load (LD_LRU),
    .rindex (mem_address[8:5]),
    .windex (mem_address[8:5]),
    .datain (lru_in_value),
    .dataout (lru_data)
);

L2_data_array #(.width(23)) tag_arr [1:0] (
    .*,
    .read (1'b1),
    .load (LD_TAG[1:0]),
    .rindex (mem_address[8:5]),
    .windex (mem_address[8:5]),
    .datain (mem_address[31:9]),
    .dataout (tag_out)
);

L2_data_array  #(.width(256)) data_arr [1:0] (
    .*,
    .read (1'b1),
    .load (data_arr_write_en_in),
    .rindex (mem_address[8:5]),
    .windex (mem_address[8:5]),
    .datain (data_arr_in_value),
    .dataout (data_arr_out)
);


always_comb begin
    set_defaults();

    unique case ({mem_address[31:9] == tag_out[0] && valid_out[0],
                  mem_address[31:9] == tag_out[1] && valid_out[1]})
        default:;
        2'b10: begin
          HIT = 1'b1;
          way_hit = 1'b0;
        end
        2'b01: begin
          HIT = 1'b1;
          way_hit = 1'b1;
        end
    endcase

    mem_rdata256 = HIT ? data_arr_out[way_hit] : data_arr_out[lru_data];

    unique case (W_CACHE_STATUS)
        default:;
        //CPU write to cache, evict inactive
        3'b100: begin
          data_arr_write_en_in[0] = !(way_hit);
          data_arr_write_en_in[1] = way_hit;
          data_arr_in_value = mem_wdata256;
        end
        //if must handle miss
        3'b001, 3'b011, 3'b111: begin

            //evict and write back if line is dirty
            cacheline_write = (W_CACHE_STATUS[0]&(!W_CACHE_STATUS[1])); // Changed from dirty_out[lru_data]
            cacheline_in = lru_data ? data_arr_out[1] : data_arr_out[0];

            unique case (W_CACHE_STATUS[1]) //(Chages from case(dirty_out[lru_data])) and the cases (the 1'b1 annd 1'b0 are switched)
              1'b1:
              //bring in line if read miss
                cacheline_addr_in = {mem_address[31:5], 5'b00000};
              1'b0:
              //write-back if line is dirty
                cacheline_addr_in = lru_data ? {tag_out[1], mem_address[8:5], 5'b00000} :
                                            {tag_out[0], mem_address[8:5], 5'b00000};
            endcase

            if (W_CACHE_STATUS[2]) begin //Changed so that the data array is not constantaly being written to
              data_arr_write_en_in[0] = !(lru_data);
              data_arr_write_en_in[1] = lru_data;
              data_arr_in_value = cacheline_out;
            end
        end
    endcase
end




function void set_defaults();
  data_arr_in_value = 0;
  cacheline_write = 0;
  data_arr_write_en_in = 0;
  HIT = 0;
  way_hit = 0;
  cacheline_in = 0;
  cacheline_addr_in = 0;
endfunction


endmodule : L2Cache_Datapath
