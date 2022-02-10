`include "defines.v"

module MiniMIPS32(
    input  	wire                  		cpu_clk_50M,
    input  	wire                  		cpu_rst_n,

    // 涓庢寚浠ゅ瓨鍌ㄥ櫒IM鐩歌繛鎺ョ殑绔彛
    output 	wire [`INST_ADDR_BUS]	    iaddr,
    output	wire                  		inst_req,
    input  	wire [`INST_BUS     ]      	inst,
    input   wire                        iaddr_ok,

    // 涓庢暟鎹瓨鍌ㄥ櫒DM鐩歌繛鎺ョ殑绔彛
    output 	wire                  		dce,
    output 	wire [`INST_ADDR_BUS] 	    daddr,
    output 	wire [`BSEL_BUS     ] 		we,
    output 	wire [`INST_BUS     ] 		din,
    input  	wire [`INST_BUS     ] 		dm,

    input   wire                        if_data_ok,
    input   wire                        mem_data_ok,

    input   wire [`CP0_INT_BUS  ]       int,//纭腑鏂俊鍙?

    output  wire [31:0]                 debug_wb_pc,
    output  wire [3 :0]                 debug_wb_rf_wen,
    output  wire [4 :0]                 debug_wb_rf_wnum,
    output  wire [31:0]                 debug_wb_rf_wdata
    );


    // 杩炴帴鍙栨寚闃舵涓庡彇鎸?/璇戠爜瀵勫瓨鍣ㄧ殑淇″彿
    wire [`WORD_BUS     ] 	    pc;
    wire [`INST_ADDR_BUS]	    pc_plus_4;
    wire [`EXC_CODE_BUS]        if_exccode_o;

    wire                        stallreq_if;


    // 杩炴帴鍙栨寚/璇戠爜瀵勫瓨鍣ㄤ笌璇戠爜闃舵鐨勪俊鍙? 
    wire [`WORD_BUS      ] 	    id_pc_i;
    wire [`WORD_BUS      ] 	    id_pc_plus_4_i; 
    wire [`EXC_CODE_BUS]        id_exccode_i;

    wire [`INST_BUS]            id_inst;


    // 杩炴帴璇戠爜闃舵涓庨?氱敤瀵勫瓨鍣ㄥ爢鐨勪俊鍙? 
    // wire 			            re1;
    wire [`REG_ADDR_BUS  ] 	    ra1;
    wire [`REG_BUS       ] 	    rd1;
    // wire 			            re2;
    wire [`REG_ADDR_BUS  ] 	    ra2;
    wire [`REG_BUS       ] 	    rd2;


    // 杩炴帴璇戠爜闃舵涓庤瘧鐮?/鎵ц瀵勫瓨鍣ㄧ殑淇″彿
    wire [`ALUOP_BUS     ] 	    id_aluop_o;
    // wire [`ALUTYPE_BUS ] 	    id_alutype_o;
    wire [`REG_BUS 	] 	        id_src1_o;
    wire [`REG_BUS 	] 	        id_src2_o;
    wire 			            id_wreg_o;
    wire [`REG_ADDR_BUS  ] 	    id_wa_o;
    wire                   		id_whilo_o;
    wire                   		id_mreg_o;
    wire [`REG_BUS 	     ] 	    id_din_o;


    //璇戠爜闃舵鎺у埗鐩稿叧澶勭悊淇″彿
    wire                        stallreq_id;
    wire [`INST_ADDR_BUS]       jump_addr_1;
    wire [`INST_ADDR_BUS]       jump_addr_2;
    wire [`INST_ADDR_BUS]       jump_addr_3;
    wire [`INST_ADDR_BUS]       ret_addr;
    wire [`JTSEL_BUS]           jtsel;


    //璇戠爜闃舵寮傚父澶勭悊鐩稿叧杈撳嚭淇″彿
    wire [`REG_ADDR_BUS]        id_cp0_addr_o;//cp0涓瘎瀛樺櫒鐨勫湴鍧?
    wire [`INST_ADDR_BUS]       id_pc_o;//澶勪簬璇戠爜闃舵鎸囦护鐨刾c鍊?
    wire                        id_in_delay_o;//澶勪簬璇戠爜闃舵鐨勬寚浠ゆ槸寤惰繜妲芥寚浠?
    wire                        id_next_delay_o;//涓嬩竴鏉¤繘鍏ヨ瘧鐮侀樁娈电殑鎸囦护鏄欢杩熸Ы鎸囦护
    wire [`EXC_CODE_BUS]        id_exccode_o;//澶勪簬璇戠爜闃舵鐨勬寚浠ょ殑寮傚父绫诲瀷


    // 杩炴帴璇戠爜/鎵ц瀵勫瓨鍣ㄤ笌鎵ц闃舵鐨勪俊鍙?
    wire [`ALUOP_BUS     ] 	    exe_aluop_i;
    // wire [`ALUTYPE_BUS ] 	    exe_alutype_i;
    wire [`REG_BUS 	] 	        exe_src1_i;
    wire [`REG_BUS 	] 	        exe_src2_i;
    wire 			            exe_wreg_i;
    wire [`REG_ADDR_BUS  ] 	    exe_wa_i;
    wire                   	    exe_whilo_i;
    wire                   	    exe_mreg_i;
    wire [`REG_BUS 	     ] 	    exe_din_i;


    //鎺у埗鐩稿叧
    wire [`REG_BUS 	     ] 	    exe_ret_addr_i;


    //璇戠爜/鎵ц瀵勫瓨鍣ㄨ緭鍑? 寮傚父澶勭悊鐩稿叧
    wire [`REG_ADDR_BUS ]       exe_cp0_addr_i;
    wire [`INST_ADDR_BUS]       exe_pc_i;
    wire                        exe_in_delay_i;
    wire                        exe_next_delay_i;
    wire [`EXC_CODE_BUS]        exe_exccode_i;


    // 杩炴帴鎵ц闃舵涓嶩ILO瀵勫瓨鍣ㄧ殑淇″彿
    wire [`REG_BUS 	     ] 	    exe_hi_i;
    wire [`REG_BUS 	     ] 	    exe_lo_i;


    // 杩炴帴鎵ц闃舵涓庢墽琛?/璁垮瓨瀵勫瓨鍣ㄧ殑淇″彿
    wire [`ALUOP_BUS     ] 	    exe_aluop_o;
    wire 			            exe_wreg_o;
    wire [`REG_ADDR_BUS  ] 	    exe_wa_o;
    wire [`REG_BUS 	     ] 	    exe_wd_o;
    wire                   		exe_mreg_o;
    wire [`REG_BUS 	     ] 	    exe_din_o;
    wire 			            exe_whilo_o;
    wire [`DOUBLE_REG_BUS] 	    exe_hilo_o;


    // 鎵ц闃舵鎺у埗鐩稿叧
    wire	                    stallreq_exe;


    // 鎵ц闃舵杈撳嚭鐨勫紓甯稿鐞嗙浉鍏充俊鍙?
    wire	                    exe_cp0_re_o;
    wire [`REG_ADDR_BUS ] 	    exe_cp0_raddr_o;
    wire	                    exe_cp0_we_o;
    wire [`REG_ADDR_BUS ] 	    exe_cp0_waddr_o;
    wire [`REG_BUS]	            exe_cp0_wdata_o;
    wire [`INST_ADDR_BUS ]      exe_pc_o;
    wire	                    exe_in_delay_o;
    wire [`EXC_CODE_BUS ]       exe_exccode_o;


    // 杩炴帴鎵ц/璁垮瓨瀵勫瓨鍣ㄤ笌璁垮瓨闃舵鐨勪俊鍙?
    wire [`ALUOP_BUS     ]	    mem_aluop_i;
    wire 			            mem_wreg_i;
    wire [`REG_ADDR_BUS  ] 	    mem_wa_i;
    wire [`REG_BUS 	     ] 	    mem_wd_i;
    wire                   		mem_mreg_i;
    wire [`REG_BUS 	     ] 	    mem_din_i;
    wire 			            mem_whilo_i;
    wire [`DOUBLE_REG_BUS] 	    mem_hilo_i;

    wire                        stallreq_mem;


    //鎵ц/璁垮瓨瀵勫瓨鍣ㄨ緭鍑虹殑寮傚父澶勭悊鐩稿叧淇″彿
    wire                        mem_cp0_we_i;
    wire [`REG_ADDR_BUS]        mem_cp0_waddr_i;
    wire [`REG_BUS 	  ]         mem_cp0_wdata_i;
    wire [`INST_ADDR_BUS]       mem_pc_i;
    wire                        mem_in_delay_i;
    wire [`EXC_CODE_BUS]        mem_exccode_i;


    // 杩炴帴璁垮瓨闃舵涓庤瀛?/鍐欏洖瀵勫瓨鍣ㄧ殑淇″彿
    wire 			            mem_wreg_o;
    wire [`REG_ADDR_BUS  ] 	    mem_wa_o;
    wire [`REG_BUS 	     ] 	    mem_dreg_o;
    wire                   		mem_mreg_o;
    wire [`BSEL_BUS      ] 	    mem_dre_o;
    wire 			            mem_whilo_o;
    wire [`DOUBLE_REG_BUS] 	    mem_hilo_o;
    wire [`ALUOP_BUS     ] 	    mem_aluop_o;


    //璁垮瓨闃舵杈撳嚭鐨勫紓甯稿鐞嗙浉鍏充俊鍙?
    wire                        mem_cp0_we_o;
    wire [`REG_ADDR_BUS  ]      mem_cp0_waddr_o;
    wire [`REG_BUS       ]      mem_cp0_wdata_o;
    wire [`INST_ADDR_BUS]       mem_cp0_pc_o;
    wire                        mem_cp0_in_delay_o;
    wire [`EXC_CODE_BUS]       	mem_cp0_exccode_o;
    wire [`INST_ADDR_BUS]       mem_cp0_badvaddr;


    // 杩炴帴璁垮瓨/鍐欏洖瀵勫瓨鍣ㄤ笌鍐欏洖闃舵鐨勪俊鍙?
    wire 			            wb_wreg_i;
    wire [`REG_ADDR_BUS  ] 	    wb_wa_i;
    wire [`REG_BUS       ] 	    wb_dreg_i;
    wire [`BSEL_BUS      ] 	    wb_dre_i;
    wire                   		wb_mreg_i;
    wire 			            wb_whilo_i;
    wire [`DOUBLE_REG_BUS] 	    wb_hilo_i;
    wire [`ALUOP_BUS     ] 	    wb_aluop_i;


    //璁垮瓨/鍐欏洖瀵勫瓨鍣ㄥ紓甯稿鐞嗙浉鍏充俊鍙?
    wire                     	wb_cp0_we_i;
    wire [`REG_ADDR_BUS  ]   	wb_cp0_waddr_i;
    wire [`REG_BUS       ]   	wb_cp0_wdata_i;


    // 杩炴帴鍐欏洖闃舵涓庨?氱敤瀵勫瓨鍣ㄥ爢鐨勪俊鍙?
    wire 			            wb_wreg_o;
    wire [`REG_ADDR_BUS  ] 	    wb_wa_o;
    wire [`REG_BUS       ] 	    wb_wd_o;



    // 杩炴帴鍐欏洖闃舵涓嶩ILO瀵勫瓨鍣ㄧ殑淇″彿
    wire 			            wb_whilo_o;
    wire [`DOUBLE_REG_BUS] 	    wb_hilo_o;
    wire [`ALUOP_BUS     ] 	    wb_aluop_o;


    // 鍐欏洖闃舵寮傚父澶勭悊杈撳嚭鐩稿叧淇″彿
    wire                     	wb_cp0_we_o;
    wire [`REG_ADDR_BUS  ]   	wb_cp0_waddr_o;
    wire [`REG_BUS       ]   	wb_cp0_wdata_o;



    /*-----------------鍓嶆帹鎺ョ嚎------------------*/
    //浠庢墽琛岄樁娈佃幏寰楃殑鍐欏洖淇″彿
    wire                        exe2id_wreg;
    wire [`REG_ADDR_BUS ]       exe2id_wa;
    wire [`INST_BUS     ]       exe2id_wd;


    //浠庢墽琛岄樁娈靛洖浼犵殑瀛樺偍鍣ㄥ埌瀵勫瓨鍣ㄤ娇鑳戒俊鍙?
    wire                        exe2id_mreg;


    //浠庤瀛橀樁娈佃幏寰楃殑鍐欏洖淇″彿
    wire                        mem2id_wreg;
    wire [`REG_ADDR_BUS ]       mem2id_wa;
    wire [`INST_BUS     ]       mem2id_wd;


    //浠庤瀛橀樁娈靛洖浼犵殑瀛樺偍鍣ㄥ埌瀵勫瓨鍣ㄤ娇鑳戒俊鍙?
    wire                        mem2id_mreg;


    //浠庤瀛橀樁娈佃幏鍙栫殑hi锛宭o淇″彿
    wire                        mem2exe_whilo;
    wire [`DOUBLE_REG_BUS]      mem2exe_hilo;


    //浠庤瀛橀樁娈靛墠鎺ㄧ殑寮傚父澶勭悊鐩稿叧淇″彿
    wire                        mem2exe_cp0_we;
    wire [`REG_ADDR_BUS ]       mem2exe_cp0_wa;
    wire [`INST_BUS     ]       mem2exe_cp0_wd;    


    //浠庡啓鍥為樁娈佃幏鍙栫殑hi锛宭o淇″彿
    wire                        wb2exe_whilo;
    wire [`DOUBLE_REG_BUS]      wb2exe_hilo;


    //浠庡啓鍥為樁娈佃幏鍙栫殑寮傚父澶勭悊鐩稿叧淇″彿
    wire                        wb2mem_cp0_we;
    wire [`REG_ADDR_BUS ]       wb2mem_cp0_wa;
    wire [`INST_BUS     ]       wb2mem_cp0_wd;
    wire                        wb2exe_cp0_we;
    wire [`REG_ADDR_BUS ]       wb2exe_cp0_wa;
    wire [`INST_BUS     ]       wb2exe_cp0_wd;
    /*-----------------------------------------*/


    //scu杈撳嚭淇″彿锛堟祦姘寸嚎鏆傚仠鎺у埗淇″彿锛?
    wire [`STALL_BUS     ]      stall;


    //cp0_reg杈撳嚭淇″彿
    wire                        cp0_flush_o;
    // wire                        cp0_flush_im_o;
    wire [`REG_BUS       ]      cp0_excaddr_o;
    wire [`REG_BUS       ]      cp0_data_o;
    wire [`REG_BUS       ]      cp0_status_o;
    wire [`REG_BUS       ]      cp0_cause_o;


    //debug
    assign debug_wb_rf_wen      = (cpu_rst_n == `RST_ENABLE) ? 4'b0 :{4{wb_wreg_o}};
    assign debug_wb_rf_wnum     = (cpu_rst_n == `RST_ENABLE) ? 5'b0 :wb_wa_o;
    assign debug_wb_rf_wdata    = (cpu_rst_n == `RST_ENABLE) ? 32'b0 :wb_wd_o;



    // 渚嬪寲scu
    scu scu0(
        .stallreq_id(stallreq_id),
        .stallreq_exe(stallreq_exe),
        .stallreq_if(stallreq_if),
        .stallreq_mem(stallreq_mem), 
        .stall(stall)
    );


    // 渚嬪寲cpu0
    cp0_reg  cp0_reg0(
        .cpu_clk_50M(cpu_clk_50M),
        .cpu_rst_n(cpu_rst_n),
        // .re(exe_cp0_re_o),
        .raddr(exe_cp0_raddr_o),
        .we(wb_cp0_we_o),
        .waddr(wb_cp0_waddr_o),
        .wdata(wb_cp0_wdata_o),
        .int_i(int),
        .pc_i(mem_cp0_pc_o),
        .in_delay_i(mem_cp0_in_delay_o),
        .exccode_i(mem_cp0_exccode_o),
        .flush(cp0_flush_o),
        // .flush_im(cp0_flush_im_o),
        .cp0_excaddr(cp0_excaddr_o),
        .data_o(cp0_data_o),
        .status_o(cp0_status_o),
        .cause_o(cp0_cause_o),
        .badvaddr_i(mem_cp0_badvaddr)
    );
            

    // 渚嬪寲鍙栨寚闃舵妯″潡
    if_stage if_stage0(
        .cpu_clk_50M(cpu_clk_50M), 
        .cpu_rst_n(cpu_rst_n),
        .iaddr_ok(iaddr_ok),
        .jtsel(jtsel),
        .jump_addr_1(jump_addr_1),
        .jump_addr_2(jump_addr_2),
        .jump_addr_3(jump_addr_3),
        .stall(stall),
        .pc(pc), 
        .inst_req(inst_req), 
        .iaddr(iaddr),
        .pc_plus_4(pc_plus_4),
        .flush(cp0_flush_o), 
        .cp0_excaddr(cp0_excaddr_o),
        .if_exccode_o(if_exccode_o),
        .stallreq_if(stallreq_if),
        .if_data_ok(if_data_ok)
    );


    // 渚嬪寲鍙栨寚/璇戠爜瀵勫瓨鍣ㄦā鍧?
    ifid_reg ifid_reg0(
        .cpu_clk_50M(cpu_clk_50M), 
        .cpu_rst_n(cpu_rst_n),
        .if_pc(pc), 
        .id_pc(id_pc_i),
        .stall(stall),
        .if_pc_plus_4(pc_plus_4),
        .id_pc_plus_4(id_pc_plus_4_i),
        .flush(cp0_flush_o),
        .if_exccode(if_exccode_o),
        .id_exccode(id_exccode_i),
        .if_inst(inst),
        .id_inst(id_inst)
    );


    // 渚嬪寲璇戠爜闃舵妯″潡
    id_stage id_stage0(
        .id_pc_i(id_pc_i),
        .pc_plus_4(id_pc_plus_4_i),
        .id_inst_i(id_inst),
        .rd1(rd1),
        .rd2(rd2),
        // .rreg1(re1), 
        // .rreg2(re2), 	  
        .ra1(ra1), 
        .ra2(ra2),
        .id_aluop_o(id_aluop_o), 
        // .id_alutype_o(id_alutype_o),
        .id_src1_o(id_src1_o), 
        .id_src2_o(id_src2_o),
        .id_wa_o(id_wa_o), 
        .id_wreg_o(id_wreg_o),
        .id_whilo_o(id_whilo_o),
        .id_mreg_o(id_mreg_o), 
        .id_din_o(id_din_o),
        
        .exe2id_wreg(exe2id_wreg), 
        .exe2id_wa(exe2id_wa), 
        .exe2id_wd(exe2id_wd),//鏁版嵁鐩稿叧
        .mem2id_wreg(mem2id_wreg), 
        .mem2id_wa(mem2id_wa), 
        .mem2id_wd(mem2id_wd),

        .exe2id_mreg(exe2id_mreg), 
        .mem2id_mreg(mem2id_mreg), 
        .stallreq_id(stallreq_id),//鎺у埗鐩稿叧
        .jump_addr_1(jump_addr_1),
        .jump_addr_2(jump_addr_2),
        .jump_addr_3(jump_addr_3),
        .ret_addr(ret_addr),
        .jtsel(jtsel),

        .id_in_delay_i(exe_next_delay_i),
        // .flush_im(cp0_flush_im_o),//寮傚父
        .cp0_addr(id_cp0_addr_o),
        .id_pc_o(id_pc_o),
        .id_in_delay_o(id_in_delay_o),
        .next_delay_o(id_next_delay_o),
        .id_exccode_i(id_exccode_i),
        .id_exccode_o(id_exccode_o)
    );


    // 渚嬪寲閫氱敤瀵勫瓨鍣ㄥ爢妯″潡
    regfile regfile0(
        .cpu_clk_50M(cpu_clk_50M), 
        .cpu_rst_n(cpu_rst_n),
        .we(wb_wreg_o), 
        .wa(wb_wa_o), 
        .wd(wb_wd_o),
        // .re1(re1), 
        .ra1(ra1), 
        .rd1(rd1),
        // .re2(re2), 
        .ra2(ra2), 
        .rd2(rd2)
    );


    // 渚嬪寲璇戠爜/鎵ц瀵勫瓨鍣ㄦā鍧?
    idexe_reg idexe_reg0(
        .cpu_clk_50M(cpu_clk_50M), .cpu_rst_n(cpu_rst_n), 
        // .id_alutype(id_alutype_o),
         .id_aluop(id_aluop_o),
        .id_src1(id_src1_o), .id_src2(id_src2_o),
        .id_wa(id_wa_o), .id_wreg(id_wreg_o), .id_whilo(id_whilo_o),
        .id_mreg(id_mreg_o), .id_din(id_din_o), 
        // .exe_alutype(exe_alutype_i),
         .exe_aluop(exe_aluop_i),
        .exe_src1(exe_src1_i), .exe_src2(exe_src2_i), 
        .exe_wa(exe_wa_i), .exe_wreg(exe_wreg_i), .exe_whilo(exe_whilo_i),
        .exe_mreg(exe_mreg_i), .exe_din(exe_din_i),

        .id_ret_addr(ret_addr),.stall(stall),
        .exe_ret_addr(exe_ret_addr_i),

        .id_cp0_addr(id_cp0_addr_o),.id_pc(id_pc_o),
        // .id_in_delay(id_in_delay_o),
        .next_delay_i(id_next_delay_o),.id_exccode(id_exccode_o),.flush(cp0_flush_o),
        .exe_cp0_addr(exe_cp0_addr_i),.exe_pc(exe_pc_i),.exe_in_delay(exe_in_delay_i),
        // .next_delay_o(exe_next_delay_i),
        .exe_exccode(exe_exccode_i)
    );


    // 渚嬪寲鎵ц闃舵妯″潡
    exe_stage exe_stage0(
        .cpu_clk_50M(cpu_clk_50M),.cpu_rst_n(cpu_rst_n),
        // .exe_alutype_i(exe_alutype_i),
         .exe_aluop_i(exe_aluop_i),
        .exe_src1_i(exe_src1_i), .exe_src2_i(exe_src2_i),
        .exe_wa_i(exe_wa_i), .exe_wreg_i(exe_wreg_i),
        .exe_mreg_i(exe_mreg_i), .exe_din_i(exe_din_i),
        .hi_i(exe_hi_i), .lo_i(exe_lo_i), .exe_whilo_i(exe_whilo_i),
        .exe_aluop_o(exe_aluop_o),
        .exe_wa_o(exe_wa_o), .exe_wreg_o(exe_wreg_o), .exe_wd_o(exe_wd_o),
        .exe_mreg_o(exe_mreg_o), .exe_din_o(exe_din_o),
        .exe_whilo_o(exe_whilo_o), .exe_hilo_o(exe_hilo_o),

        .mem2exe_whilo(mem2exe_whilo),.mem2exe_hilo(mem2exe_hilo),
        .wb2exe_whilo(wb2exe_whilo),.wb2exe_hilo(wb2exe_hilo),
        .ret_addr(exe_ret_addr_i),.stallreq_exe(stallreq_exe),

        .exe2id_wreg(exe2id_wreg),.exe2id_wa(exe2id_wa),.exe2id_wd(exe2id_wd),.exe2id_mreg(exe2id_mreg),//瀹氬悜鍓嶆帹杈撳嚭

        .cp0_addr_i(exe_cp0_addr_i),.cp0_data_i(cp0_data_o),//寮傚父鐩稿叧
        .mem2exe_cp0_we(mem2exe_cp0_we),.mem2exe_cp0_wa(mem2exe_cp0_wa),.mem2exe_cp0_wd(mem2exe_cp0_wd),
        .wb2exe_cp0_we(wb2exe_cp0_we),.wb2exe_cp0_wa(wb2exe_cp0_wa),.wb2exe_cp0_wd(wb2exe_cp0_wd),
        .exe_pc_i(exe_pc_i),.exe_in_delay_i(exe_in_delay_i),.exe_exccode_i(exe_exccode_i),
        // .cp0_re_o(exe_cp0_re_o),
        .cp0_raddr_o(exe_cp0_raddr_o),.cp0_we_o(exe_cp0_we_o),.cp0_waddr_o(exe_cp0_waddr_o),
        .cp0_wdata_o(exe_cp0_wdata_o),.exe_pc_o(exe_pc_o),.exe_in_delay_o(exe_in_delay_o),.exe_exccode_o(exe_exccode_o)
    );


    // 渚嬪寲鎵ц/璁垮瓨瀵勫瓨鍣ㄦā鍧?    
    exemem_reg exemem_reg0(
        .cpu_clk_50M(cpu_clk_50M), .cpu_rst_n(cpu_rst_n),
        .exe_aluop(exe_aluop_o),
        .exe_wa(exe_wa_o), .exe_wreg(exe_wreg_o), .exe_wd(exe_wd_o),
        .exe_mreg(exe_mreg_o), .exe_din(exe_din_o),
        .exe_whilo(exe_whilo_o), .exe_hilo(exe_hilo_o),
        .mem_aluop(mem_aluop_i),
        .mem_wa(mem_wa_i), .mem_wreg(mem_wreg_i), .mem_wd(mem_wd_i),
        .mem_mreg(mem_mreg_i), .mem_din(mem_din_i),
        .mem_whilo(mem_whilo_i), .mem_hilo(mem_hilo_i),
        .stall(stall),

        .exe_cp0_we(exe_cp0_we_o),.exe_cp0_waddr(exe_cp0_waddr_o),.exe_cp0_wdata(exe_cp0_wdata_o),.flush(cp0_flush_o),
        .exe_pc(exe_pc_o),.exe_in_delay(exe_in_delay_o),.exe_exccode(exe_exccode_o),
        .mem_cp0_we(mem_cp0_we_i),.mem_cp0_waddr(mem_cp0_waddr_i),.mem_cp0_wdata(mem_cp0_wdata_i),
        .mem_pc(mem_pc_i),.mem_in_delay(mem_in_delay_i),.mem_exccode(mem_exccode_i)
    );


    // 渚嬪寲璁垮瓨闃舵妯″潡
    mem_stage mem_stage0(
        .mem_aluop_i(mem_aluop_i),
        .mem_wa_i(mem_wa_i), .mem_wreg_i(mem_wreg_i), .mem_wd_i(mem_wd_i),
        .mem_mreg_i(mem_mreg_i), .mem_din_i(mem_din_i),
        .mem_whilo_i(mem_whilo_i), .mem_hilo_i(mem_hilo_i),
        .mem_wa_o(mem_wa_o), .mem_wreg_o(mem_wreg_o), .mem_dreg_o(mem_dreg_o),
        .mem_mreg_o(mem_mreg_o), .dre(mem_dre_o),
        .mem_whilo_o(mem_whilo_o), .mem_hilo_o(mem_hilo_o),
        .dce(dce), .daddr(daddr), .we(we), .din(din),
        .mem_aluop_o(mem_aluop_o),

        .mem2id_wreg(mem2id_wreg), .mem2id_wa(mem2id_wa), .mem2id_wd(mem2id_wd),//瀹氬悜鍓嶆帹
        .mem2exe_whilo(mem2exe_whilo), .mem2exe_hilo(mem2exe_hilo),
        .mem2id_mreg(mem2id_mreg),
        .mem2exe_cp0_we(mem2exe_cp0_we),.mem2exe_cp0_wa(mem2exe_cp0_wa),.mem2exe_cp0_wd(mem2exe_cp0_wd),//瀹氬悜鍓嶆帹(寮傚父鐩稿叧)

        .cp0_we_i(mem_cp0_we_i),.cp0_waddr_i(mem_cp0_waddr_i),.cp0_wdata_i(mem_cp0_wdata_i),//寮傚父鐩稿叧
        .wb2mem_cp0_we(wb2mem_cp0_we),.wb2mem_cp0_wa(wb2mem_cp0_wa),
        .wb2mem_cp0_wd(wb2mem_cp0_wd),.mem_pc_i(mem_pc_i),.mem_in_delay_i(mem_in_delay_i),
        .mem_exccode_i(mem_exccode_i),.cp0_status(cp0_status_o),.cp0_cause(cp0_cause_o),
        .cp0_we_o(mem_cp0_we_o),.cp0_waddr_o(mem_cp0_waddr_o),.cp0_wdata_o(mem_cp0_wdata_o),
        .cp0_pc(mem_cp0_pc_o),.cp0_in_delay(mem_cp0_in_delay_o),.cp0_exccode(mem_cp0_exccode_o),

        .cp0_badvaddr(mem_cp0_badvaddr),

        .stallreq_mem(stallreq_mem),.mem_data_ok(mem_data_ok),.wb_pc_i(debug_wb_pc)
    );


    // 渚嬪寲璁垮瓨/鍐欏洖瀵勫瓨鍣ㄦā鍧?	
    memwb_reg memwb_reg0(
        .cpu_clk_50M(cpu_clk_50M), .cpu_rst_n(cpu_rst_n),
        .mem_wa(mem_wa_o), .mem_wreg(mem_wreg_o), .mem_dreg(mem_dreg_o),
        .mem_mreg(mem_mreg_o), .mem_dre(mem_dre_o),
        .mem_whilo(mem_whilo_o), .mem_hilo(mem_hilo_o),
        .wb_wa(wb_wa_i), .wb_wreg(wb_wreg_i), .wb_dreg(wb_dreg_i),
        .wb_mreg(wb_mreg_i), .wb_dre(wb_dre_i),
        .wb_whilo(wb_whilo_i), .wb_hilo(wb_hilo_i),
        .mem_aluop(mem_aluop_o),.wb_aluop(wb_aluop_i),
        .mem_pc(mem_cp0_pc_o),

        .mem_cp0_we(mem_cp0_we_o),.mem_cp0_waddr(mem_cp0_waddr_o),.mem_cp0_wdata(mem_cp0_wdata_o),.flush(cp0_flush_o),
        .wb_cp0_we(wb_cp0_we_i),.wb_cp0_waddr(wb_cp0_waddr_i),.wb_cp0_wdata(wb_cp0_wdata_i),.wb_pc(debug_wb_pc),
    

        .stall(stall)
    );


    // 渚嬪寲鍐欏洖闃舵妯″潡
    wb_stage wb_stage0(
        .wb_mreg_i(wb_mreg_i), .wb_dre_i(wb_dre_i), 
        .wb_wa_i(wb_wa_i), .wb_wreg_i(wb_wreg_i), .wb_dreg_i(wb_dreg_i), 
        .wb_whilo_i(wb_whilo_i), .wb_hilo_i(wb_hilo_i),
        .dm(dm),
        .cp0_we_i(wb_cp0_we_i),.cp0_waddr_i(wb_cp0_waddr_i),.cp0_wdata_i(wb_cp0_wdata_i),//寮傚父鐩稿叧
        .wb_wa_o(wb_wa_o), .wb_wreg_o(wb_wreg_o), .wb_wd_o(wb_wd_o), 
        .wb_whilo_o(wb_whilo_o), .wb_hilo_o(wb_hilo_o),
        .wb_aluop_i(wb_aluop_i),.wb_aluop_o(wb_aluop_o),
        .mem_operation_ok(mem_data_ok),

        .wb2exe_whilo(wb2exe_whilo), .wb2exe_hilo(wb2exe_hilo),//瀹氬悜鍓嶆帹
        .wb2mem_cp0_we(wb2mem_cp0_we),.wb2mem_cp0_wa(wb2mem_cp0_wa),.wb2mem_cp0_wd(wb2mem_cp0_wd),//瀹氬悜鍓嶆帹(寮傚父)
        .wb2exe_cp0_we(wb2exe_cp0_we),.wb2exe_cp0_wa(wb2exe_cp0_wa),.wb2exe_cp0_wd(wb2exe_cp0_wd),
        .cp0_we_o(wb_cp0_we_o),.cp0_waddr_o(wb_cp0_waddr_o),.cp0_wdata_o(wb_cp0_wdata_o)
    );


    // 渚嬪寲HILO瀵勫瓨鍣ㄦā鍧?
    hilo hilo0(
        .cpu_clk_50M(cpu_clk_50M), .cpu_rst_n(cpu_rst_n), 
        .we(wb_whilo_o),
        .hi_i(wb_hilo_o[63:32]), .lo_i(wb_hilo_o[31:0]),
        .hi_o(exe_hi_i), .lo_o(exe_lo_i),
        .hilo_aluop(wb_aluop_o)
    );


endmodule
