module datacache_victim_array #(
    parameter s_index = 0,
    parameter width = 1
)
(
    clk,
    rst,
    read,
    load,
    datain,
    dataout
);


input clk;
input rst;
input read;
input load;
input [width-1:0] datain;
output logic [width-1:0] dataout;

logic [width-1:0] data /* synthesis ramstyle = "logic" */;
logic [width-1:0] _dataout;
assign dataout = _dataout;

always_ff @(negedge clk) //negedge
begin
    if (rst) begin
        data <= '0;
    end
    else begin
        if (read)
            _dataout <= (load) ? datain : data;

        if(load)
            data <= datain;
    end
end

endmodule : datacache_victim_array
