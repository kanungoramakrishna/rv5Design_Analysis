module instcache_control (
  input logic clk,
  input logic rst,
  input logic HIT,
  input logic way_hit,
  input logic mem_read_cpu,
  input logic [1:0] valid_out,
  input logic pmem_resp,
  input logic lru_data,
  output logic cacheline_read,
  output logic valid_in,
  output logic lru_in_value,
  output logic LD_LRU_in,
  output logic [1:0] LD_TAG,
  output logic [1:0] LD_VALID,
  output logic [2:0] W_CACHE_STATUS,
  output logic mem_resp_cpu
);

//use state machine for control logic with 2 always form

//Logic to keep track if the previous value was a HIT was befor the CPU brings in 
//the new instruction and the address and tag value changes
logic HIT_temp;
always_ff @(posedge clk)
begin
    if(rst)
        HIT_temp <= 1'b0;
    else
        HIT_temp<= HIT;
end



enum logic [3:0] {
IDLE, CHECK, READ_FROM_MEM
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
        if(mem_read_cpu)
            next_state = CHECK;
        end
        CHECK:  
        begin
        //Logic for the pipeline only
        if ((!(mem_read_cpu)))
            next_state = IDLE;
        else if (!HIT_temp)
            next_state = READ_FROM_MEM;
        else 
            next_state = CHECK; 
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
            LD_LRU_in = HIT;
            if(mem_read_cpu & HIT)
            begin
                unique case (way_hit)
                1'b1:
                    lru_in_value = 1'b0;
                1'b0:
                    lru_in_value = 1'b1;
                endcase
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
  cacheline_read = 1'b0;
  LD_TAG = 0;
  LD_LRU_in = 0;
  LD_VALID = 0;
  W_CACHE_STATUS = 0;
  mem_resp_cpu = 0;
endfunction

endmodule : instcache_control
