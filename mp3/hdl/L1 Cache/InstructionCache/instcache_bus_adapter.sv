module instcache_bus_adapter
(
    input [255:0] mem_rdata256,
    output [31:0] mem_rdata,
    output logic [31:0] mem_byte_enable256,
    input [31:0] address
);

assign mem_rdata = mem_rdata256[(32*address[4:2]) +: 32];
assign mem_byte_enable256 = {28'h0, 4'b1111} << (address[4:2]*4);

endmodule : instcache_bus_adapter
