import rv32i_types::*;
import pcmux::*;
module mp3
(
    input clk,
    input rst,

    input pmem_resp,
    input [63:0] pmem_rdata,
    output logic pmem_read,
    output logic pmem_write,
    output rv32i_word pmem_address,
    output [63:0] pmem_wdata

);

/******************CPU <-> L1Caches******************/
logic inst_read;
logic [31:0] inst_addr;
logic inst_resp;
logic [31:0] inst_rdata;

logic data_read;
logic data_write;
logic [3:0] data_mbe;
logic [31:0] data_addr;
logic [31:0] data_wdata;
logic data_resp;
logic [31:0] data_rdata;


/******************L1Caches <-> Arbiter******************/
logic inst_r;
logic data_w;
logic data_r;

logic [255:0] data_line_i;
logic [255:0] data_line_o;
logic [255:0] inst_line_o;

logic data_resp_arbiter;
logic inst_resp_arbiter;
logic [31:0] data_address;
logic [31:0] inst_address;

/******************Arbiter <-> L2Cache******************/
logic [26:0] address_arbiter_to_l2;
logic read_arbiter_to_l2;
logic write_arbiter_to_l2;
logic mem_resp;
logic [255:0] data_L2_to_arbiter;
logic [255:0] data_arbiter_to_l2;

/******************L2Cache <-> CachelineAdaptor******************/
logic [255:0] data_cacheline_to_L2;
logic [255:0] data_L2_to_cacheline;
logic [31:0]  address_L2_to_cacheline;
logic read_L2_to_cacheline;
logic write_L2_to_cacheline;
logic resp_cacheline_to_L2;



cpu cpu(.*);



datacache datacache(
	.clk                (clk),
    .rst                (rst),
    .mem_address        (data_addr ),
    .mem_wdata          (data_wdata),
    .mem_write          (data_write ),
    .mem_read           (data_read),
    .mem_byte_enable    (data_mbe),
    .pmem_resp          (data_resp_arbiter),
    .pmem_rdata         (data_line_o),
    .mem_rdata          (data_rdata ),
    .pmem_wdata         (data_line_i),
    .pmem_address       (data_address),
    .pmem_write         (data_w),
    .pmem_read          (data_r),
    .mem_resp           (data_resp)
);


instcache instcache(
	.clk            (clk),
    .rst            (rst),
    .mem_address    (inst_addr),
    .mem_read       (inst_read),
    .pmem_resp      (inst_resp_arbiter),
    .pmem_rdata     (inst_line_o),
    .mem_rdata      (inst_rdata),
    .pmem_address   (inst_address),
    .pmem_read      (inst_r),
    .mem_resp       (inst_resp)
);



arbiter arbiter(
	.clk               (clk               ),
    .rst               (rst               ),
    .mem_resp          (mem_resp),
    .data_L2_to_arbiter(data_L2_to_arbiter),
    .inst_tag          (inst_address[31:5]          ),
    .inst_r            (inst_r            ),
    .data_tag          (data_address[31:5]          ),
    .data_w            (data_w            ),
    .data_r            (data_r            ),
    .data_line_i       (data_line_i       ),
    .data_line_o       (data_line_o       ),
    .inst_line_o       (inst_line_o       ),
    .data_resp_arbiter (data_resp_arbiter ),
    .inst_resp_arbiter (inst_resp_arbiter ),
    .data_arbiter_to_l2(data_arbiter_to_l2),
    .read_arbiter_to_l2(read_arbiter_to_l2),
    .write_arbiter_to_l2(write_arbiter_to_l2),
    .address_arbiter_to_l2(address_arbiter_to_l2)
);


L2Cache L2Cache(
	.clk                    (clk                    ),
    .rst                    (rst                    ),
    .mem_address            ({address_arbiter_to_l2,5'b0}),
    .mem_wdata              (data_arbiter_to_l2 ),
    .mem_write              (write_arbiter_to_l2 ),
    .mem_read               (read_arbiter_to_l2  ),
    .pmem_resp              (resp_cacheline_to_L2  ),
    .pmem_rdata             (data_cacheline_to_L2 ),
    .mem_rdata              (data_L2_to_arbiter ),
    .pmem_wdata             ( data_L2_to_cacheline),
    .pmem_address           (address_L2_to_cacheline),
    .pmem_write             (write_L2_to_cacheline ),
    .pmem_read              (read_L2_to_cacheline),
    .mem_resp               (mem_resp)
);



cacheline_adaptor cacheline_adaptor(
	.clk       (clk       ),
    .reset_n   (rst   ),

    .line_i    (data_L2_to_cacheline),
    .line_o    (data_cacheline_to_L2),
    .address_i (address_L2_to_cacheline),
    .read_i    (read_L2_to_cacheline),
    .write_i   (write_L2_to_cacheline),
    .resp_o    (resp_cacheline_to_L2),

    .burst_i   (pmem_rdata   ),
    .burst_o   (pmem_wdata   ),
    .address_o (pmem_address ),
    .read_o    (pmem_read    ),
    .write_o   (pmem_write   ),
    .resp_i    (pmem_resp    )
);






endmodule : mp3
