module datacache_datapath #(
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
    input logic [31:0] mem_byte_enable256,
    input logic [255:0] cacheline_out,
    input logic [31:0] mem_address,
    input logic [1:0] LD_DIRTY_in,
    input logic dirty_in_value,
    input logic LD_LRU_in,
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

logic [1:0][23:0] tag_out;
logic [1:0][255:0] data_arr_out;
logic [255:0] data_arr_in;
logic [255:0] data_arr_in_value;
logic [1:0][31:0] data_arr_write_en;
logic [1:0][31:0] data_arr_write_en_in;

logic [1:0] LD_DIRTY;
logic dirty_in;

logic LD_LRU;
logic lru_in;

logic [2:0] windex;


//valid, dirty, LRU, and tag arrays for two ways//

array valid_arr[1:0] (
    .*,
    .read (1'b1),
    .load (LD_VALID[1:0]),
    .rindex (mem_address[7:5]),
    .windex (mem_address[7:5]),
    .datain (valid_in),
    .dataout (valid_out)
);

array dirty_arr[1:0] (
    .*,
    .read (1'b1),
    .load (LD_DIRTY[1:0]),
    .rindex (mem_address[7:5]),
    .windex (windex),
    .datain (dirty_in),
    .dataout (dirty_out)
);

array lru_arr (
    .*,
    .read (1'b1),
    .load (LD_LRU),
    .rindex (mem_address[7:5]),
    .windex (windex),
    .datain (lru_in),
    .dataout (lru_data)
);

array #(.width(24)) tag_arr [1:0] (
    .*,
    .read (1'b1),
    .load (LD_TAG[1:0]),
    .rindex (mem_address[7:5]),
    .windex (mem_address[7:5]),
    .datain (mem_address[31:8]),
    .dataout (tag_out)
);

data_array data_arr [1:0] (
    .*,
    .read (1'b1),
    .write_en (data_arr_write_en),
    .rindex (mem_address[7:5]),
    .windex (windex),
    .datain (data_arr_in),
    .dataout (data_arr_out)
);


always_comb begin
    set_defaults();

    unique case ({mem_address[31:8] == tag_out[0] && valid_out[0],
                  mem_address[31:8] == tag_out[1] && valid_out[1]})
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
          data_arr_write_en_in[0] = way_hit ? 32'b0 : mem_byte_enable256;
          data_arr_write_en_in[1] = way_hit ? mem_byte_enable256 : 32'b0;
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
                cacheline_addr_in = lru_data ? {tag_out[1], mem_address[7:5], 5'b00000} :
                                            {tag_out[0], mem_address[7:5], 5'b00000};
            endcase

            if (W_CACHE_STATUS[2]) begin //Changed so that the data array is not constantaly being written to
              data_arr_write_en_in[0] = lru_data ? 32'd0 : 32'hFFFFFFFF;
              data_arr_write_en_in[1] = lru_data ? 32'hFFFFFFFF : 32'd0;
              data_arr_in_value = cacheline_out;
            end
        end
    endcase
end

always_ff @(posedge clk) // posedge
begin
  if (rst)
  begin
    data_arr_write_en[0]<= 0;
    data_arr_write_en[1]<=0;
  end
  else
  begin
    data_arr_write_en[0]<= data_arr_write_en_in[0];
    data_arr_write_en[1]<= data_arr_write_en_in[1];
  end
end

always_ff @(posedge clk) //posedge
begin
    if(rst)
    begin
        data_arr_in<= 0;
    end
    else
        data_arr_in <= data_arr_in_value;
end

always_ff @(posedge clk) // posedge
begin
  if (rst)
  begin
    LD_LRU<= 0;
    lru_in<=0;
  end
  else
  begin
    LD_LRU<= LD_LRU_in;
    lru_in<= lru_in_value;
  end
end


always_ff @(posedge clk) // posedge
begin
  if (rst)
  begin
    LD_DIRTY<= 0;
    dirty_in<=0;
  end
  else
  begin
    LD_DIRTY<= LD_DIRTY_in;
    dirty_in<= dirty_in_value;
  end
end

always_ff @(posedge clk)
begin
  if(rst)
  begin
    windex <= 0;
  end
  else
  begin
    windex <= mem_address[7:5];
  end
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


endmodule : datacache_datapath
