module instruction_victim
(
    input clk,
    input rst,

    input logic [31:0] mem_address,
    input logic [31:0] evict_address,
    output logic [255:0] data_to_cache,

    input logic valid_in_victim,
    input logic lru_in_victim,

    input logic [255:0] data_arr_in,


    input logic [1:0] LD_VALID_victim,
    input logic [1:0] LD_TAG_victim,
    input logic [1:0] LD_DATA_victim,

    input logic LD_LRU_victim,

    output logic [1:0] valid_out_victim,
    output logic lru_data_victim,

    output logic HIT_victim,
    output logic way_hit_victim

    
);

logic [1:0][26:0] tag_out;
logic [1:0][255:0] data_arr_out;



instruction_victim_array valid_arr[1:0] (
    .*,
    .read (1'b1),
    .load (LD_VALID_victim[1:0]),
    .datain (valid_in_victim),
    .dataout (valid_out_victim)
);



instruction_victim_array lru_arr (
    .*,
    .read (1'b1),
    .load (LD_LRU_victim),
    .datain (lru_in_victim),
    .dataout (lru_data_victim)
);

instruction_victim_array #(.width(27)) tag_arr [1:0] (
    .*,
    .read (1'b1),
    .load (LD_TAG_victim[1:0]),
    .datain (evict_address[31:5]),
    .dataout (tag_out)
);

instruction_victim_array #(.width(256)) data_arr [1:0] (
    .*,
    .read (1'b1),
    .load (LD_DATA_victim[1:0]),
    .datain (data_arr_in),
    .dataout (data_arr_out)
);



always_comb begin
    set_defaults();

    unique case ({mem_address[31:5] == tag_out[0] && valid_out_victim[0],
                  mem_address[31:5] == tag_out[1] && valid_out_victim[1]})
        default:;
        2'b10: begin
          HIT_victim = 1'b1;
          way_hit_victim = 1'b0;
        end
        2'b01: begin
          HIT_victim = 1'b1;
          way_hit_victim = 1'b1;
        end
    endcase

    
end

always_ff @(negedge clk)
begin
    if (rst)
    begin
        data_to_cache <= 0;
    end
    else if (HIT_victim)
    begin
        data_to_cache <= data_arr_out [way_hit_victim];
    end
end


function void set_defaults();

  HIT_victim = 0;
  way_hit_victim = 0;

endfunction


endmodule : instruction_victim