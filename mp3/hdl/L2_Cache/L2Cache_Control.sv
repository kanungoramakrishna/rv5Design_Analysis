module L2Cache_Control (
  input logic clk,
  input logic rst,
  input logic HIT,
  input logic [1:0] way_hit,
  input logic mem_write_cpu,
  input logic mem_read_cpu,
  input logic [3:0] dirty_out,
  input logic pmem_resp,
  input logic [1:0]lru_data,
  output logic cacheline_read,
  output logic valid_in,
  output logic [2:0]lru_in_value,
  output logic dirty_in_value,
  output logic LD_LRU,
  output logic [3:0] LD_TAG,
  output logic [3:0] LD_DIRTY,
  output logic [3:0] LD_VALID,
  output logic [2:0] W_CACHE_STATUS,
  output logic mem_resp_cpu
);

//use state machine for control logic with 2 always form

enum logic [3:0] {
IDLE, CHECK, BUFFER, WRITE_TO_MEM, READ_FROM_MEM
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
        if (!HIT)
            next_state = BUFFER;
        else 
            next_state = IDLE; 
        end
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
            next_state = READ_FROM_MEM;
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
                2'b00:
                    lru_in_value = {1'b1,lru_data[1],1'b1};
                2'b01:
                    lru_in_value = {1'b1,lru_data[1],1'b0};
                2'b10:
                    lru_in_value = {1'b0,1'b1,lru_data[0]};
                2'b11:
                    lru_in_value = {1'b0,1'b0,lru_data[0]};
                endcase
            end
            if(mem_write_cpu & HIT)
            begin
                W_CACHE_STATUS[2] = 1'b1;
                unique case (way_hit)
                2'b00: begin
                    lru_in_value = {1'b1,lru_data[1],1'b1};
                    LD_DIRTY[3:0] = 4'b0001;
                    dirty_in_value = 1'b1;
                end
                2'b01: begin
                    lru_in_value = {1'b1,lru_data[1],1'b0};
                    LD_DIRTY[3:0] = 4'b0010;
                    dirty_in_value = 1'b1;
                end
                2'b10: begin
                    lru_in_value = {1'b0,1'b1,lru_data[0]};
                    LD_DIRTY[3:0] = 4'b0100;
                    dirty_in_value = 1'b1;
                end
                2'b11: begin
                    lru_in_value = {1'b0,1'b0,lru_data[0]};
                    LD_DIRTY[3:0] = 4'b1000;
                    dirty_in_value = 1'b1;
                end
                endcase
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
            LD_VALID[lru_data] = 1'b1;
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
endfunction

endmodule : L2Cache_Control
