module arbiter (
    input clk,
    input rst,
    input mem_resp, //l2-resp for CP3 onwards
    input [255:0] line_o,

    input [26:0] inst_tag,
    input inst_w,
    input inst_r,
    input [255:0] inst_line_i,

    input [26:0] data_tag,
    input data_w,
    input data_r,
    input [255:0] data_line_i,

    output [255:0] data_line_o,
    output [255:0] inst_line_o,
    output data_resp,
    output inst_resp,

    output [255:0] line_i, //line to L2 cache (shadow memory for now)
    output read,
    output write,
    output [26:0] tag
);

//copies of output to L2 cache
logic [255:0] l2_line_i;
logic [26:0] l2_tag;
logic l2_read;
logic l2_write;
//need to keep track of which cache is trying to access L2 cache
//in the first cycle to prevent errant resp on next cycle
logic l2_type_in;


enum logic {
 IDLE, ACTIVE
} state, next_state;

//assign state on posedge
always_ff @(posedge clk) begin
  if (rst) begin
    state <= IDLE;
  end
  else begin
    state <= next_state;
  end
end

//next_state logic
always_comb begin
  next_state = state;
  unique case (state)
    IDLE: begin
      if ({inst_r, inst_w, data_r, data_w}) begin
        next_state = ACTIVE;
      end
    end
    ACTIVE: begin
      if (mem_resp) begin
        next_state = IDLE;
      end
    end
  endcase
end

always_comb begin
  set_defaults();

  unique case (state)
    IDLE: begin
      if (inst_r | inst_w) begin
        l2_line_i = inst_line_i;
        l2_read = inst_r;
        l2_write = inst_w;
        l2_tag = inst_tag;
        l2_type_in = 1'b1;
      end
      else begin
        l2_line_i = data_line_i;
        l2_read = data_r;
        l2_write = data_w;
        l2_tag = data_tag;
        l2_type_in = 1'b0;
      end
    end
    ACTIVE: begin
      if (l2_type) begin
        inst_resp = mem_resp;
        data_resp = 0;
        inst_line_o = line_o;
        data_line_o = 0;
      else begin
        data_resp = mem_resp;
        inst_resp = 0;
        inst_line_o = 0;
        data_line_o = line_o;
      end
    end
  endcase
end

//assign registered L2 outputs
always_ff @(posedge clk) begin
  if (rst) begin
    line_i <= 0;
    tag <= 0;
    read <= 0;
    write <= 0;
    l2_type <= 0;
  end
  else begin
    line_i <= l2_line_i;
    tag <= l2_tag;
    read <= l2_read;
    write <= l2_write;
    l2_type <= l2_type_in;
  end
end

function void set_defaults();
  l2_line_i = 0;
  l2_tag = 0;
  l2_read = 0;
  l2_write = 0;
  inst_resp = 0;
  data_resp = 0;
  l2_type_in = 0;
  inst_line_o = 0;
  data_line_o = 0;
endfunction
