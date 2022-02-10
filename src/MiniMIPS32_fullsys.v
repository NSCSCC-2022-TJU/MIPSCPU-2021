`include "defines.v"

module mycpu_top(
    input wire           [`CP0_INT_BUS] ext_int,
    input wire           aclk   ,
    input wire           aresetn,

    // output wire [11     :     0] btl_addr,
    // output wire                  btl_ce,
    // input  wire [`INST_BUS     ] btl_dout,

    output [3 :0]        arid         ,
    output [31:0]        araddr       ,
    output [7 :0]        arlen        ,
    output [2 :0]        arsize       ,
    output [1 :0]        arburst      ,
    output [1 :0]        arlock       ,  
    output [3 :0]        arcache      ,   
    output [2 :0]        arprot       ,   
    output               arvalid      ,
    input                arready      ,
         
    input  [3 :0]        rid          ,    //ignored
    input  [31:0]        rdata        ,
    input  [1 :0]        rresp        ,    //ignored
    input                rlast        ,
    input                rvalid       ,
    output               rready       ,
         
    output [3 :0]        awid         ,
    output [31:0]        awaddr       ,
    output [7 :0]        awlen        ,
    output [2 :0]        awsize       ,
    output [1 :0]        awburst      ,
    output [1 :0]        awlock       ,    //ignored
    output [3 :0]        awcache      ,    //ignored
    output [2 :0]        awprot       ,    //ignored
    output               awvalid      ,
    input                awready      , 
         
    output [3 :0]        wid          , 
    output [31:0]        wdata        ,
    output [3 :0]        wstrb        ,
    output               wlast        ,
    output               wvalid       ,
    input                wready       ,
         
    input  [3 :0]        bid          ,    //ignored
    input  [1 :0]        bresp        ,    //ignored
    input                bvalid       ,
    output               bready       ,

    output  wire [31:0]  debug_wb_pc,
    output  wire [3 :0]  debug_wb_rf_wen,
    output  wire [4 :0]  debug_wb_rf_wnum,
    output  wire [31:0]  debug_wb_rf_wdata
);


    wire [`INST_ADDR_BUS] viaddr;
    wire                  iaddr_ok;
    wire                  inst_req;
    wire [`INST_BUS     ] inst;
    wire                  dce;
    wire [`INST_ADDR_BUS] vdaddr;
    wire [`BSEL_BUS     ] we;
    wire [`INST_BUS     ] din;
    wire [`INST_BUS     ] dout;
    wire                  if_data_ok;
    wire                  mem_data_ok;

    wire [31:0]                                             piaddr;
    wire [31:0]                                             pdaddr;
    wire                                                    inst_uncached;
    wire                                                    data_uncached;

    wire 					                                inst_cpu_req;
    wire [`INST_ADDR_BUS	]                               inst_cpu_addr;
    wire                                                    inst_cpu_uncached;
    wire                                                    inst_cpu_addr_ok;
    wire                                                    inst_cpu_operation_ok;
    wire [`INST_BUS		]                                   inst_cpu_rdata;

    wire                 	                                data_cpu_req;
    wire [3   :   0  	]	                                data_cpu_wre;
    wire                                                    data_cpu_wr;
    wire [`DATA_ADDR_BUS	]                               data_cpu_addr;
    wire [`DATA_BUS		]                                   data_cpu_wdata;
    wire                                                    data_cpu_uncached;
    wire                                                    data_cpu_addr_ok;
    wire                                                    data_cpu_operation_ok;
    wire [`DATA_BUS		]                                   data_cpu_rdata;


    wire [3   :   0  	]	                                inst_cache_req;
    wire 				                                    inst_cache_uncached;
    wire [`INST_ADDR_BUS	]                               inst_cache_addr;
    wire 					                                inst_cache_addr_ok;
    wire						                            inst_cache_beat_ok;
    wire 					                                inst_cache_data_ok;
    wire [`INST_BUS		]                                   inst_cache_rdata;

    wire            	                                    data_cache_rreq;
    wire            	                                    data_cache_wreq;
    wire [3   :   0  	]	                                data_cache_we;
    wire 					                                data_cache_runcached;
    wire 					                                data_cache_wuncached;
    wire [`DATA_ADDR_BUS	]                               data_cache_raddr;
    wire [`DATA_ADDR_BUS	]                               data_cache_waddr;
    wire [`DATA_WIDTH * (2 ** (`OFFSET_WIDTH - 2)) - 1 : 0] data_cache_wdata;
    wire 					                                data_cache_waddr_ok;
    wire 					                                data_cache_raddr_ok;
    wire						                            data_cache_beat_ok;
    wire 					                                data_cache_data_ok;
    wire [`DATA_BUS		]                                   data_cache_rdata;

    assign inst_cpu_req = inst_req;
    assign inst_cpu_addr = piaddr;
    assign inst_cpu_uncached = inst_uncached;
    assign iaddr_ok = inst_cpu_addr_ok;
    assign if_data_ok = inst_cpu_operation_ok;
    assign inst = inst_cpu_rdata;
    assign data_cpu_req = dce;
    assign data_cpu_wre = we == 0 ? 4'b1111 : we;
    assign data_cpu_wr = we != 0;
    assign data_cpu_addr = {pdaddr[31:2],2'b0};
    assign data_cpu_wdata = din;
    assign data_cpu_uncached = data_uncached;
    // assign data_cpu_addr_ok;
    assign mem_data_ok = data_cpu_operation_ok;
    assign dout = data_cpu_rdata;

    // wire [3 :0] mem_req;
    // wire        mem_wr;
    // assign       mem_wr  = |we;
    // assign       mem_req = (dce == 1'b1) ? ((mem_wr) ? we : 4'b1111) : 4'b0000;
    // wire [31:0] mem_daddr;
    // assign       mem_daddr = pdaddr;
    // wire        data_addr_ok;
    // wire        data_beat_ok;
    // wire        data_data_ok;
    // wire [3 :0] data_en;
    // wire        data_wr;
    // wire [31:0] data_addr;
    // wire [31:0] data_wdata;
    // wire [31:0] data_rdata;
    // wire        data_uncached;
    // wire        cache_data_uncached;

    MiniMIPS32 MiniMIPS320(
        .cpu_clk_50M(aclk),
        .cpu_rst_n(aresetn),

        .iaddr(viaddr), 
        .iaddr_ok(iaddr_ok),
        .inst_req(inst_req),
        .inst(inst),
        .dce(dce),
        .daddr(vdaddr),
        .we(we),
        .din(din),
        .dm(dout),

        .if_data_ok(if_data_ok),
        .mem_data_ok(mem_data_ok),
        .int(ext_int),

        .debug_wb_pc(debug_wb_pc),
        .debug_wb_rf_wen(debug_wb_rf_wen),
        .debug_wb_rf_wnum(debug_wb_rf_wnum),
        .debug_wb_rf_wdata(debug_wb_rf_wdata)
    );

    
    
    mmu mmu0(
        .inst_addr_in(viaddr),
        .data_addr_in(vdaddr),
        .inst_addr_out(piaddr),
        .data_addr_out(pdaddr),
        .inst_uncached(inst_uncached),
        .data_uncached(data_uncached)
    );

    inst_cache inst_cache(
        // clock and reset
        .rst   (aresetn       ),
        .clk   (aclk     ),

        //涓巆pu鐩歌繛鐨勪俊鍙?
        .cpu_req            (inst_cpu_req  ),
        .cpu_addr           (inst_cpu_addr ),
        .cpu_uncached       (inst_cpu_uncached ),
        .cpu_addr_ok        (inst_cpu_addr_ok),
        .cpu_operation_ok   (inst_cpu_operation_ok ),
        .cpu_rdata          (inst_cpu_rdata  ),

        //inst_ram like
        .ram_req     (inst_cache_req  ),
        .ram_uncached(inst_cache_uncached   ),
        .ram_addr    (inst_cache_addr   ),
        .ram_addr_ok (inst_cache_addr_ok),
        .ram_beat_ok (inst_cache_beat_ok),
        .ram_data_ok (inst_cache_data_ok),
        .ram_rdata   (inst_cache_rdata   )
    );

    

    data_cache data_cache(
        // clock and reset
        .clk   (aclk     ),
        .rst   (aresetn       ),

        //涓巆pu鐩歌繛鐨勪俊鍙?
        .cpu_req         (data_cpu_req         ),
        .cpu_wre         (data_cpu_wre),
        .cpu_wr          (data_cpu_wr         ),
        .cpu_addr        (data_cpu_addr       ),
        .cpu_wdata       (data_cpu_wdata            ),
        .cpu_uncached    (data_cpu_uncached),
        .cpu_addr_ok     (data_cpu_addr_ok),
        .cpu_operation_ok(data_cpu_operation_ok        ),
        .cpu_rdata       (data_cpu_rdata           ),

        //data_ram like
        .ram_rreq     (data_cache_rreq     ),
        .ram_wreq     (data_cache_wreq     ),
        .ram_we       (data_cache_we    ),
        .ram_runcached(data_cache_runcached   ),
        .ram_wuncached(data_cache_wuncached   ),
        .ram_raddr    (data_cache_raddr     ),
        .ram_waddr    (data_cache_waddr     ),
        .ram_wdata    (data_cache_wdata    ),
        .ram_waddr_ok (data_cache_waddr_ok ),
        .ram_raddr_ok (data_cache_raddr_ok ),
        .ram_beat_ok  (data_cache_beat_ok),
        .ram_data_ok  (data_cache_data_ok),
        .ram_rdata    (data_cache_rdata    )
    );

    sram_to_axi sram_to_axi(
       .clk(aclk),
       .resetn(aresetn),
       //fetch like-sram interface
       .inst_req     (inst_cache_req        ),
       .inst_uncached(inst_cache_uncached   ),
       .inst_addr    (inst_cache_addr    ),
       .inst_addr_ok (inst_cache_addr_ok ),
       .inst_beat_ok (inst_cache_beat_ok ),
       .inst_data_ok (inst_cache_data_ok ),
       .inst_rdata   (inst_cache_rdata    ),

       //mem like-sram interface
       .data_rreq     (data_cache_rreq     ),
       .data_wreq     (data_cache_wreq     ),
       .data_we       (data_cache_we    ),
       .data_runcached(data_cache_runcached   ),
       .data_wuncached(data_cache_wuncached   ),
       .data_raddr    (data_cache_raddr     ),
       .data_waddr    (data_cache_waddr     ),
       .data_wdata    (data_cache_wdata    ),
       .data_waddr_ok (data_cache_waddr_ok ),
       .data_raddr_ok (data_cache_raddr_ok ),
       .data_beat_ok  (data_cache_beat_ok),
       .data_data_ok  (data_cache_data_ok),
       .data_rdata    (data_cache_rdata    ),

       //axi interface
       .awid         (awid         ),
       .awaddr       (awaddr       ),
       .awlen        (awlen        ),
       .awsize       (awsize       ),
       .awburst      (awburst      ),
       .awlock       (awlock       ),
       .awcache      (awcache      ),
       .awprot       (awprot       ),
       .awvalid      (awvalid      ),
       .awready      (awready      ),
       .wid          (wid          ),
       .wdata        (wdata        ),
       .wstrb        (wstrb        ),
       .wlast        (wlast        ),
       .wvalid       (wvalid       ),
       .wready       (wready       ),
       .bid          (bid          ),
       .bresp        (bresp        ),
       .bvalid       (bvalid       ),
       .bready       (bready       ),
       .arid         (arid         ),
       .araddr       (araddr       ),
       .arlen        (arlen        ),
       .arsize       (arsize       ),
       .arburst      (arburst      ),
       .arlock       (arlock       ),
       .arcache      (arcache      ),
       .arprot       (arprot       ),
       .arvalid      (arvalid      ),
       .arready      (arready      ),
       .rid          (rid          ),
       .rdata        (rdata        ),
       .rresp        (rresp        ),
       .rlast        (rlast        ),
       .rvalid       (rvalid       ),
       .rready       (rready       )

    );

endmodule