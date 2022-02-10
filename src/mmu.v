`include "defines.v"

module mmu(
    input   wire [`INST_ADDR_BUS]   inst_addr_in,
    input   wire [`INST_ADDR_BUS]   data_addr_in,
    output  wire [`INST_ADDR_BUS]   inst_addr_out,
    output  wire [`INST_ADDR_BUS]   data_addr_out,
    output  wire                    inst_uncached,
    output  wire                    data_uncached
    );
    //固定地址映射
    assign inst_addr_out = inst_addr_in[31:28] >= 4'h8 && inst_addr_in[31:28] <= 4'hb ? {3'b000,inst_addr_in[28:0]} : inst_addr_in;
    assign data_addr_out = data_addr_in[31:28] >= 4'h8 && data_addr_in[31:28] <= 4'hb ? {3'b000,data_addr_in[28:0]} : data_addr_in;
    assign inst_uncached = inst_addr_in[31:28] >= 4'ha && inst_addr_in[31:28] <= 4'hb;
    assign data_uncached = data_addr_in[31:28] >= 4'ha && data_addr_in[31:28] <= 4'hb;

endmodule
