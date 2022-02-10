`include "defines.v"

module iaddr_arbi(
    input  wire                     cpu_clk_50M,
    input  wire                     ice,
    input  wire [`INST_ADDR_BUS]    iaddr,
    input  wire [`INST_BUS]         btl_dout,
    input  wire [`INST_BUS]         if_rdata,
    input  wire                     if_hit,
    output wire                     btl_ce,
    output wire [`INST_ADDR_BUS]    btl_addr,
    output wire [`INST_ADDR_BUS]    if_iaddr,
    output wire [`INST_BUS]         inst,
    output wire                     if_data_ok
        
    );
    
    reg ice_t;
    always @(posedge cpu_clk_50M) begin
        ice_t <= ice;
    end

    // 仲裁指令来自bootloader还是内存
    assign btl_ce     = (ice == 1'b1 && iaddr[31:20] == 12'h1fc) ? 1 : 0;
    assign btl_addr   = iaddr[13:2];
    
    assign if_iaddr   = iaddr[31:0];
    assign inst       = (iaddr[31:20] == 12'h1fc) ? btl_dout : if_rdata;
    assign if_data_ok = (iaddr[31:20] == 12'h1fc) ? ice_t : if_hit;

endmodule
