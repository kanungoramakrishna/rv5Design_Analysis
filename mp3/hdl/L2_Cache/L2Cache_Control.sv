module L2Cache_Control (
  input logic clk,
  input logic rst,
  input logic HIT,
  input logic way_hit,
  input logic mem_write_cpu,
  input logic mem_read_cpu,
  input logic [1:0] valid_out,
  input logic [1:0] dirty_out,
  input logic pmem_resp,
  input logic lru_data,
  output logic cacheline_read,
  output logic valid_in,
  output logic lru_in_value,
  output logic dirty_in_value,
  output logic LD_LRU,
  output logic [1:0] LD_TAG,
  output logic [1:0] LD_DIRTY,
  output logic [1:0] LD_VALID,
  output logic [2:0] W_CACHE_STATUS,
  output logic mem_resp_cpu,
  output logic write_way
);

//use state machine for control logic with 2 always form

enum logic [3:0] {
IDLE, CHECK, BUFFER, WRITE_TO_MEM, WRITE_1, READ_FROM_MEM
} state, next_state;


//update state
always_ff @(negedge clk) begin //negedge
  if (rst)
    state <= IDLE;
  else
    state <= next_state;
end


//***next state logic***//
always_comb begin
    next_state = state;
    unique case (state)
        IDLE: begin
        if(mem_read_cpu || mem_write_cpu)
            next_state = CHECK;
        end
        CHECK:  
        begin
        if(!HIT && mem_write_cpu && (!dirty_out[0] || !dirty_out[1]))
            next_state = WRITE_1;
        else if (!HIT)
            next_state = BUFFER;
        else 
            next_state = IDLE; 
        end
        WRITE_1:
            next_state = IDLE;
        BUFFER:
        begin
        unique case (dirty_out[lru_data])
            1'b0:
            next_state = READ_FROM_MEM;
            1'b1:
            next_state = WRITE_TO_MEM;
        endcase
        end
        WRITE_TO_MEM:
        begin
            if (pmem_resp)
                if(mem_read_cpu)
                    next_state = READ_FROM_MEM;
                else
                    next_state = WRITE_1;
        end
        READ_FROM_MEM:
        begin
            if (pmem_resp)
            next_state = CHECK;
        end
    endcase
end
//***next state logic***//




always_comb begin
    set_defaults();
    unique case (state)
        default:;
        CHECK:
        begin
            mem_resp_cpu = HIT;
            LD_LRU = HIT;
            if(mem_read_cpu & HIT)
            begin
                unique case (way_hit)
                1'b1:
                    lru_in_value = 1'b0;
                1'b0:
                    lru_in_value = 1'b1;
                endcase
            end
            if(mem_write_cpu & HIT)
            begin
                W_CACHE_STATUS[2] = 1'b1;
                lru_in_value = ~way_hit;
                write_way = way_hit;
                unique case (way_hit)
                1'b0: begin
                    LD_DIRTY[1:0] = 2'b01;
                    dirty_in_value = 1'b1;
                end
                1'b1: begin
                    LD_DIRTY[1:0] = 2'b10;
                    dirty_in_value = 1'b1;
                end
                endcase
            end
        end
        WRITE_1:
        begin
            if(!HIT && mem_write_cpu)
            begin
                if(!dirty_out[lru_data])
                begin
                    mem_resp_cpu = 1'b1;
                    W_CACHE_STATUS[2] = 1'b1;
                    lru_in_value = !lru_data;
                    write_way = lru_data;
                    LD_DIRTY[lru_data] = 1'b1;
                    dirty_in_value = 1'b1;
                    LD_TAG[lru_data] = 1'b1;
                    LD_LRU = 1'b1;
                    valid_in = 1'b1;
                end
                else if((!dirty_out[!lru_data]))
                begin
                    mem_resp_cpu = 1'b1;
                    W_CACHE_STATUS[2] = 1'b1;
                    write_way = !lru_data;
                    LD_DIRTY[!lru_data] = 1'b1;
                    dirty_in_value = 1'b1;
                    LD_TAG[!lru_data] = 1'b1;
                    valid_in = 1'b1;
                end
            end
        end
        WRITE_TO_MEM:
        begin
            if(!pmem_resp)
                W_CACHE_STATUS[0] = 1'b1;
            else
            begin
                LD_DIRTY[lru_data] = 1'b1;
                dirty_in_value = 1'b0;
            end
        end
        READ_FROM_MEM:
        begin
        if(pmem_resp)
        begin
            W_CACHE_STATUS = 3'b111;
            LD_TAG[lru_data] = 1'b1;
            valid_in = 1'b1;
            unique case (lru_data)
            1'b1:
                LD_VALID[1:0] = 2'b10;
            1'b0:
                LD_VALID[1:0] = 2'b01;
            endcase
            LD_DIRTY[lru_data] = 1'b1;
            dirty_in_value = 1'b0;
        end
        else
        begin
            W_CACHE_STATUS = 3'b011;
            cacheline_read = 1'b1;
        end
        end
    endcase
end




function void set_defaults();
  valid_in = 0;
  lru_in_value = 0;
  dirty_in_value = 0;
  cacheline_read = 1'b0;
  LD_TAG = 0;
  LD_DIRTY = 0;
  LD_LRU = 0;
  LD_VALID = 0;
  W_CACHE_STATUS = 0;
  mem_resp_cpu = 0;
  write_way = 0;
endfunction

endmodule : L2Cache_Control
