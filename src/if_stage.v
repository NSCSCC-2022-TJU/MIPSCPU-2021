`include "defines.v"

module if_stage (
    input 	wire 					cpu_clk_50M,
    input 	wire 					cpu_rst_n,
    input   wire [`JTSEL_BUS]       jtsel,
    input 	wire [`INST_ADDR_BUS]	jump_addr_1,
    input 	wire [`INST_ADDR_BUS]	jump_addr_2,
    input 	wire [`INST_ADDR_BUS]	jump_addr_3,
    input   wire [`STALL_BUS]       stall,
    // new
    output  wire                    stallreq_if,
    input   wire                    if_data_ok,
    // new
    input   wire                    flush,
    input 	wire [`INST_ADDR_BUS]	cp0_excaddr,

    output  wire                    inst_req, //inst_req
    output 	reg  [`INST_ADDR_BUS] 	pc,
    output 	wire [`INST_ADDR_BUS]	iaddr,
    input   wire                    iaddr_ok,
    output 	wire [`INST_ADDR_BUS]	pc_plus_4,
    output  wire [`EXC_CODE_BUS]    if_exccode_o//处于译码阶段的指令的异常类型

    );
    
    
    // assign pc_plus_4=(cpu_rst_n==`RST_ENABLE) ? `PC_INIT : pc+4;
    assign pc_plus_4 = pc + 4;

    wire [`INST_ADDR_BUS] pc_next;
    assign pc_next = (jtsel==2'b00)?pc_plus_4:
                     (jtsel==2'b01)?jump_addr_1:            //j,jal
                     (jtsel==2'b10)?jump_addr_3:            //jr
                     (jtsel==2'b11)?jump_addr_2:`PC_INIT;   //beq,bne
                     

    reg ce;
    // assign ice = (stall[1]==`TRUE_V||flush)? 0: ce;
    // 根据处理器是否复位确定ice信号
    always @(posedge cpu_clk_50M) begin
		if (cpu_rst_n == `RST_ENABLE) begin
			ce <= `CHIP_DISABLE;		      
		end else begin
			ce <= `CHIP_ENABLE; 		      
		end
	end
    
    // new
    // assign iaddr = flush ? cp0_excaddr : pc; //cp0处理异常期间，防止取指阶段的无效pc产生miss，进而造成下一阶段miss取回的数据保存在excaddr的cache块中
    //assign iaddr = (flush  ) ? cp0_excaddr : pc;
                //    (flush_t) ? excaddr_t : pc;
    reg                     flush_t;

    assign iaddr =  ce == `CHIP_DISABLE ? `PC_INIT :
                    flush ? cp0_excaddr :
                    flush_t == `TRUE_V ? pc : pc_next;

    assign inst_req = flush_t == `TRUE_V && iaddr_ok? 1 :
                    stall[0] == `STOP ? 0 : 1;

    wire word_aligned = pc[1:0] == 2'b00;
    // assign ice = (if_data_ok == 1'b1 || !word_aligned) ? 0 : ce;
    assign stallreq_if = flush_t || !(iaddr_ok && if_data_ok);



    always @(posedge cpu_clk_50M) begin
        if(cpu_rst_n == `RST_ENABLE) begin
            flush_t <= `FALSE_V;
        end
        else if(flush == `TRUE_V && stall[0] == `STOP) begin
            flush_t <= `TRUE_V;
        end
        else if(iaddr_ok) begin
            flush_t <= `FALSE_V;
        end
    end


    // 判断ice信号是否有效
    always @(posedge cpu_clk_50M) begin
        if (ce == `CHIP_DISABLE)
            pc <= `PC_INIT;
        else begin
            if(flush==`TRUE_V) 
                pc <= cp0_excaddr;
            else if(flush_t == `TRUE_V)
                pc <= pc;
            else if(stall[0]==`NOSTOP) begin
                pc <= pc_next;                 	
            end
        end                   

    end
    
    // assign iaddr = (ice == `CHIP_DISABLE) ? `PC_INIT : pc;


    //取指地址错误异常
    assign if_exccode_o = (!word_aligned) ? `EXC_ADEL : `EXC_NONE;


endmodule