always_comb begin
  set_defaults();
  unique case (state)
    START: begin
    end
    CACHE_R: begin
      LD_LRU = HIT;

      mem_resp_cpu = HIT;
      unique case (way_hit)
        1'b1:
          lru_in = 1'b0;
        1'b0:
          lru_in = 1'b1;
      endcase
    end
    CACHE_W: begin
      W_CACHE_STATUS[2] = mem_write_cpu & HIT;
      mem_resp_cpu = HIT;
      LD_LRU = HIT;
      lru_in = ~way_hit;
      unique case ({HIT, way_hit})
        default:;
        2'b10: begin
          LD_DIRTY[1:0] = 2'b01;
          dirty_in = 1'b1;
        end
        2'b11: begin
          LD_DIRTY[1:0] = 2'b10;
          dirty_in = 1'b1;
        end
      endcase
    end
    CACHE_EVICT: begin
      W_CACHE_STATUS[0] = 1'b1;
    end
    FILL_CACHE: begin
      //let adaptor start writing to cache
      W_CACHE_STATUS = 3'b011;
      cacheline_read = 1'b1;
      LD_TAG[lru_data] = 1'b1;
      valid_in = 1'b1;
      unique case (lru_data)
        1'b1:
          LD_VALID[1:0] = 2'b10;
        1'b0:
          LD_VALID[1:0] = 2'b01;
      endcase
      LD_DIRTY[lru_data] = 1'b1;
      dirty_in = 1'b0;
    end
    WRITE_BACK1: begin
      W_CACHE_STATUS[0] = 1'b1;
    end
    WRITE_BACK2: begin
      LD_DIRTY[lru_data] = 1'b1;
      dirty_in = 1'b0;
    end
    FINAL: begin
      //allow CPU to write if applicable
      W_CACHE_STATUS[2] = mem_write_cpu;

      if (mem_write_cpu) begin
        LD_DIRTY[lru_data] = 1'b1;
        dirty_in = 1'b1;
      end
      //send mem_response
      mem_resp_cpu = 1'b1;

      LD_LRU = 1'b1;
      lru_in = ~lru_data;

    end
  endcase
end