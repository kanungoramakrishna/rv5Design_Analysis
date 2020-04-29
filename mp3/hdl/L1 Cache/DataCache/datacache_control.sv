module datacache_control (
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
    output logic LD_LRU_in,
    output logic [1:0] LD_TAG,
    output logic [1:0] LD_DIRTY_in,
    output logic [1:0] LD_VALID,
    output logic [2:0] W_CACHE_STATUS,
    output logic mem_resp_cpu,
    output logic pmem_write,



    output logic valid_in_victim,
    output logic dirty_in_victim,
    output logic lru_in_victim,
    output logic [1:0] LD_DIRTY_victim,
    output logic [1:0] LD_VALID_victim,
    output logic [1:0] LD_TAG_victim,
    output logic [1:0] LD_DATA_victim,

    output logic LD_LRU_victim,

    input logic [1:0] valid_out_victim,
    input logic [1:0] dirty_out_victim,
    input logic lru_data_victim,

    input logic dirty_buffer,
    input logic HIT_victim,
    input logic way_hit_victim
);

//use state machine for control logic with 2 always form

enum logic [3:0] {
IDLE, CHECK, CACHE_TO_VICTIM, VICTIM_TO_CACHE, BUFFER, WRITE_TO_MEM, WRITE_TO_VICTIM, READ_FROM_MEM
} state, next_state;

//Logic to keep track if the previous value was a HIT
logic HIT_temp;
always_ff @(posedge clk)
begin
    if(rst)
        HIT_temp <= 1'b0;
    else
        HIT_temp<= HIT;
end

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
        //Logic for the pipeline only
        if ((!(mem_read_cpu || mem_write_cpu)))
            next_state = IDLE;
        else if (!HIT_temp && HIT_victim)
            next_state = CACHE_TO_VICTIM;
        else if (!HIT_temp)
            next_state = BUFFER;
        else 
            next_state = CHECK; 
        end
        CACHE_TO_VICTIM:
            next_state = VICTIM_TO_CACHE;
        VICTIM_TO_CACHE:
            next_state = CHECK;


        BUFFER:
        begin
        if (!valid_out[lru_data])
            next_state = READ_FROM_MEM;
        else if (dirty_out_victim[lru_data_victim] && valid_out_victim[lru_data_victim])
            next_state = WRITE_TO_MEM;
        else 
            next_state = WRITE_TO_VICTIM;
        end

        WRITE_TO_MEM:
        begin
            if (pmem_resp)
            next_state = WRITE_TO_VICTIM;
        end
        WRITE_TO_VICTIM:
            next_state = READ_FROM_MEM;
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
            if(mem_write_cpu & HIT)
            begin
                W_CACHE_STATUS[2] = 1'b1;
                lru_in_value = ~way_hit;
                unique case (way_hit)
                1'b0: begin
                    LD_DIRTY_in[1:0] = 2'b01;
                    dirty_in_value = 1'b1;
                end
                1'b1: begin
                    LD_DIRTY_in[1:0] = 2'b10;
                    dirty_in_value = 1'b1;
                end
                endcase
            end
        end
        CACHE_TO_VICTIM:
        begin
            W_CACHE_STATUS[0] = 1'b1;
            valid_in_victim = valid_out[lru_data];
            dirty_in_victim = dirty_out[lru_data];
            lru_in_victim = !way_hit_victim;
            LD_DIRTY_victim[way_hit_victim] =1'b1 ;
            LD_VALID_victim[way_hit_victim] = 1'b1;
            LD_TAG_victim[way_hit_victim] = 1'b1;
            LD_DATA_victim[way_hit_victim]= 1'b1;
            LD_LRU_victim = 1'b1;
        end
        VICTIM_TO_CACHE:
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
            LD_DIRTY_in[lru_data] = 1'b1;
            dirty_in_value = dirty_buffer;
        end


        WRITE_TO_MEM:
        begin
        if (!pmem_resp)
            pmem_write = 1'b1;
        end
        WRITE_TO_VICTIM:
        begin
            W_CACHE_STATUS[0] = 1'b1;
            valid_in_victim = valid_out[lru_data];
            dirty_in_victim = dirty_out[lru_data];
            lru_in_victim = !lru_data_victim;
            LD_DIRTY_victim[lru_data_victim] =1'b1 ;
            LD_VALID_victim[lru_data_victim] = 1'b1;
            LD_TAG_victim[lru_data_victim] = 1'b1;
            LD_DATA_victim[lru_data_victim]= 1'b1;
            LD_LRU_victim = 1'b1;
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
            LD_DIRTY_in[lru_data] = 1'b1;
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
    LD_DIRTY_in = 0;
    LD_LRU_in = 0;
    LD_VALID = 0;
    W_CACHE_STATUS = 0;
    mem_resp_cpu = 0;
    pmem_write = 0;

    valid_in_victim = 0;
    dirty_in_victim = 0;
    lru_in_victim = 0;
    dirty_in_victim = 0;
    LD_DIRTY_victim = 0;
    LD_VALID_victim = 0;
    LD_TAG_victim = 0;
    LD_DATA_victim = 0;
    LD_LRU_victim = 0;
endfunction

endmodule : datacache_control
