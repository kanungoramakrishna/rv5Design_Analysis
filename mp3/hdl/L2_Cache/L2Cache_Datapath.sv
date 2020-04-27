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
    input logic [3:0] LD_DIRTY,
    input logic dirty_in_value,
    input logic LD_LRU,
    input logic [2:0] lru_in_value,
    input logic [3:0] LD_VALID,
    input logic valid_in,
    input logic [3:0] LD_TAG,
    input logic [2:0] W_CACHE_STATUS,
    output logic cacheline_write,
    output logic [3:0] dirty_out,
    output logic HIT,
    output logic [1:0] way_hit,
    output logic [1:0] lru_data,
    output logic [31:0] cacheline_addr_in,
    output logic [255:0] cacheline_in,
    output logic [255:0] mem_rdata256
);

logic [3:0][23:0] tag_out;
logic [3:0][255:0] data_arr_out;
logic [255:0] data_arr_in_value;
logic [3:0] data_arr_write_en_in;
logic [2:0] lru_out;
logic [3:0] valid_out;

//valid, dirty, LRU, and tag arrays for two ways//

L2_data_array valid_arr[3:0] (
    .*,
    .read (1'b1),
    .load (LD_VALID[3:0]),
    .rindex (mem_address[7:5]),
    .windex (mem_address[7:5]),
    .datain (valid_in),
    .dataout (valid_out)
);

L2_data_array dirty_arr[3:0] (
    .*,
    .read (1'b1),
    .load (LD_DIRTY[3:0]),
    .rindex (mem_address[7:5]),
    .windex (mem_address[7:5]),
    .datain (dirty_in_value),
    .dataout (dirty_out)
);

L2_data_array #(.width(3)) lru_arr (
    .*,
    .read (1'b1),
    .load (LD_LRU),
    .rindex (mem_address[7:5]),
    .windex (mem_address[7:5]),
    .datain (lru_in_value),
    .dataout (lru_out)
);

L2_data_array #(.width(24)) tag_arr [3:0] (
    .*,
    .read (1'b1),
    .load (LD_TAG[3:0]),
    .rindex (mem_address[7:5]),
    .windex (mem_address[7:5]),
    .datain (mem_address[31:8]),
    .dataout (tag_out)
);

L2_data_array  #(.width(256)) data_arr [3:0] (
    .*,
    .read (1'b1),
    .load (data_arr_write_en_in),
    .rindex (mem_address[7:5]),
    .windex (mem_address[7:5]),
    .datain (data_arr_in_value),
    .dataout (data_arr_out)
);


always_comb begin
    set_defaults();

    unique case ({mem_address[31:8] == tag_out[0] && valid_out[0],
                  mem_address[31:8] == tag_out[1] && valid_out[1],
                  mem_address[31:8] == tag_out[2] && valid_out[2],
                  mem_address[31:8] == tag_out[3] && valid_out[3]})
        default:;
        4'b1000: begin
          HIT = 1'b1;
          way_hit = 2'b00;
        end
        4'b0100: begin
          HIT = 1'b1;
          way_hit = 2'b01;
        end
        4'b0010: begin
          HIT = 1'b1;
          way_hit = 2'b10;
        end
        4'b0001: begin
          HIT = 1'b1;
          way_hit = 2'b11;
        end
    endcase

    mem_rdata256 = HIT ? data_arr_out[way_hit] : data_arr_out[lru_data]; // Stuff needs to be doneeeeeeeeeeee

    unique case (W_CACHE_STATUS)
        default:;
        //CPU write to cache, evict inactive
        3'b100: begin
          case(way_hit)
          2'b00: data_arr_write_en_in[0] = 1'b1;
          2'b01: data_arr_write_en_in[1] = 1'b1;
          2'b10: data_arr_write_en_in[2] = 1'b1;
          2'b11: data_arr_write_en_in[3] = 1'b1;
          endcase
          data_arr_in_value = mem_wdata256;
        end
        //if must handle miss
        3'b001, 3'b011, 3'b111: begin

            //evict and write back if line is dirty
            cacheline_write = (W_CACHE_STATUS[0]&(!W_CACHE_STATUS[1])); // Changed from dirty_out[lru_data]

            cacheline_in = data_arr_out[lru_data]; // WOOOOOORRRRKKKKK

            unique case (W_CACHE_STATUS[1]) //(Chages from case(dirty_out[lru_data])) and the cases (the 1'b1 annd 1'b0 are switched)
              1'b1:
              //bring in line if read miss
                cacheline_addr_in = {mem_address[31:5], 5'b00000};
              1'b0:
              //write-back if line is dirty
              
                cacheline_addr_in = {tag_out[lru_data], mem_address[7:5], 5'b00000};
            endcase

            if (W_CACHE_STATUS[2]) begin //Changed so that the data array is not constantaly being written to
              data_arr_write_en_in[lru_data] = 1'b1;
              data_arr_in_value = cacheline_out;
            end
        end
    endcase
end

always_comb
begin
    lru_data = 2'b0;
    case(lru_out)
    3'b000,3'b010:  lru_data = 2'b00;
    3'b001,3'b011:  lru_data = 2'b01;
    3'b100,3'b101:  lru_data = 2'b10;
    3'b110,3'b111:  lru_data = 2'b11;
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
