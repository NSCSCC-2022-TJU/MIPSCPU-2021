`include "defines.v"

module cp0_reg(
    input  	wire                         	cpu_clk_50M,
    input  	wire                         	cpu_rst_n,
    input  	wire                         	we,
    // input  	wire                         	re,
    input  	wire [`REG_ADDR_BUS  ]       	raddr,
    input  	wire [`REG_ADDR_BUS  ]       	waddr,
    input  	wire [`REG_BUS       ]       	wdata,
    input  	wire [`CP0_INT_BUS   ]       	int_i,
    input  	wire [`INST_ADDR_BUS]       	pc_i,
    input  	wire                         	in_delay_i,
    input  	wire [`EXC_CODE_BUS]       	    exccode_i,
    input  	wire [`INST_ADDR_BUS]       	badvaddr_i,

    output 	wire                         	flush,
    //output 	reg                          	flush_im,
    output 	wire [`REG_BUS       ]       	cp0_excaddr,
    output 	wire [`REG_BUS       ]       	data_o,
    output 	wire [`REG_BUS       ]       	status_o,
    output 	wire [`REG_BUS       ]       	cause_o

    );

    reg [`REG_BUS] badvaddr;
    reg [`REG_BUS] status;
    reg [`REG_BUS] cause;
    reg [`REG_BUS] epc;
    reg [`REG_BUS] count;

    assign status_o= status;
    assign cause_o = cause;

    assign flush = 
        (exccode_i != `EXC_NONE)? `FLUSH:`NOFLUSH;

    // always @(posedge cpu_clk_50M)begin
    //     if(cpu_rst_n==`RST_ENABLE)begin
    //         flush_im <= `NOFLUSH;
    //     end
    //     else begin
    //         flush_im <= flush;
    //     end
    // end

    task do_exc;begin
        if(status[1]==0)begin
        if(in_delay_i)begin
            cause[31] <=1;
            epc       <=pc_i-4; 
        end else begin
            cause[31] <=0;
            epc       <=pc_i;            
        end 
        end
        status[1] <= 1'b1;
        cause[6:2] <= exccode_i;

        if(exccode_i == `EXC_ADEL||exccode_i == `EXC_ADES)
                badvaddr <= badvaddr_i;//debug

    end
    endtask


    assign cp0_excaddr = 
        (exccode_i == `EXC_INT)?`EXC_INT_ADDR:
        (exccode_i == `EXC_ERET && waddr ==`CP0_EPC && we==`WRITE_ENABLE)? wdata:
        (exccode_i == `EXC_ERET)? epc:
        (exccode_i != `EXC_NONE)?`EXC_ADDR:`ZERO_WORD;

    task do_eret;begin
        status[1] <= 0;    
    end
    endtask


    reg count_flag;

    always @(posedge cpu_clk_50M)begin
        if(cpu_rst_n == `RST_ENABLE) begin
            badvaddr  <=`ZERO_WORD;
            status    <= 32'h00400000;
            cause     <=`ZERO_WORD;
            epc       <=`ZERO_WORD; 
            count     <=`ZERO_WORD;
            count_flag<=0;
        end
        else begin
            cause[15:10] <= int_i;

            if(count_flag) begin
                count <= count + 1;
            end
            count_flag <= ~count_flag;

            case (exccode_i)
                `EXC_NONE:
                    if(we == `WRITE_ENABLE) begin
                    case (waddr)
                            `CP0_BADVADDR:  badvaddr <= wdata;
                            `CP0_STATUS  :  begin
                                                status[15:8] <= wdata[15:8]; 
                                                status[ 1:0] <= wdata[ 1:0]; 
                                            end
                            `CP0_CAUSE:     cause[9:8]  <= wdata[9:8];
                            `CP0_EPC:       epc     <=  wdata;
                            `CP0_COUNT:     count   <= wdata;
                    endcase 
                    end 
                `EXC_ERET:
                        do_eret();
                default:
                        do_exc();
            endcase
        end
    end
    

    assign data_o =
        // (re != `READ_ENABLE )       ? `ZERO_WORD:
        (raddr == `CP0_BADVADDR)    ? badvaddr:
        (raddr == `CP0_STATUS)      ? status:
        (raddr == `CP0_CAUSE)       ? cause:
        (raddr == `CP0_EPC)         ? epc:
        (raddr == `CP0_COUNT)       ? count:`ZERO_WORD;

endmodule
