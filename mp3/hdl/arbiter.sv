module arbiter (
    input clk,
    input rst,
    input logic mem_resp, //l2-resp for CP3 onwards
    input logic [255:0] line_o,

    input logic [26:0] inst_tag,
    input logic inst_r,

    input logic [26:0] data_tag,
    input logic data_w,
    input logic data_r,
    input logic [255:0] data_line_i,

    output logic [255:0] data_line_o,
    output logic [255:0] inst_line_o,
    output logic data_resp_arbiter,
    output logic inst_resp_arbiter,

    output logic [255:0] line_i, //line to L2 cache (shadow memory for now)
    output logic read,
    output logic write,
    output logic [26:0] tag
);

//copies of output to L2 cache
logic [255:0] l2_line_i;
logic [26:0] l2_tag;
logic l2_read;
logic l2_write;
//need to keep track of which cache is trying to access L2 cache
//in the first cycle to prevent errant resp on next cycle
logic l2_type;
logic l2_type_in;

logic inst_resp_arbiter_in;
logic data_resp_arbiter_in;

assign data_line_o = line_o;
assign inst_line_o = line_o;

enum logic {
 IDLE, ACTIVE
} state, next_state;

//assign state on posedge
always_ff @(negedge clk) begin
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
      if ({inst_r, data_r, data_w}) begin
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
      if (inst_r ) begin
        l2_read = inst_r;
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
        inst_resp_arbiter_in = mem_resp;
        l2_tag = inst_tag;
        l2_type_in = 1'b1;
        if(!mem_resp)
            l2_read = inst_r;
		end
      else begin
        data_resp_arbiter_in = mem_resp;
        l2_type_in = 1'b0;
        l2_line_i = data_line_i;
        l2_tag = data_tag;
        if (!mem_resp)
        begin
          l2_read = data_r;
          l2_write = data_w;
        end
      end
    end
    default:;
  endcase
end

//assign registered L2 outputs
always_ff @(negedge clk) begin
  if (rst) begin
    line_i <= 0;
    tag <= 0;
    read <= 0;
    write <= 0;
    l2_type <= 0;
    inst_resp_arbiter <= 0;
    data_resp_arbiter <=0;
  end
  else begin
    line_i <= l2_line_i;
    tag <= l2_tag;
    read <= l2_read;
    write <= l2_write;
    l2_type <= l2_type_in;
    inst_resp_arbiter <= inst_resp_arbiter_in;
    data_resp_arbiter <= data_resp_arbiter_in;
  end
end

function void set_defaults();
  l2_line_i = 0;
  l2_tag = 0;
  l2_read = 0;
  l2_write = 0;
  inst_resp_arbiter_in = 0;
  data_resp_arbiter_in = 0;
  l2_type_in = 0;
endfunction

endmodule : arbiter