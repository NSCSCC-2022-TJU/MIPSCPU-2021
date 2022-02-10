`include "defines.v"

module id_stage(
    // 从取指阶段获得的PC值
    input  wire [`INST_ADDR_BUS]    id_pc_i,
    input  wire [`INST_ADDR_BUS]    pc_plus_4,
    // 从指令存储器读出的指令字
    input  wire [`INST_BUS     ]    id_inst_i,
    // 从通用寄存器堆读出的数据 
    input  wire [`REG_BUS      ]    rd1,
    input  wire [`REG_BUS      ]    rd2,
    //从执行阶段获得的写回信号
    input  wire                     exe2id_wreg,
    input  wire [`REG_ADDR_BUS ]    exe2id_wa,
    input  wire [`INST_BUS     ]    exe2id_wd,
    //从访存阶段获得的写回信号
    input  wire                     mem2id_wreg,
    input  wire [`REG_ADDR_BUS ]    mem2id_wa,
    input  wire [`INST_BUS     ]    mem2id_wd,
    //从执行阶段和访存阶段回传的存储器到寄存器使能信号
    input  wire                     exe2id_mreg,
    input  wire                     mem2id_mreg,
    //异常处理添加
    input  wire                     id_in_delay_i,//处于译码阶段的指令是延迟槽指令
    //new
    // input  wire                     flush_im,//清空从指令存储器读出的指令
    //new
    input  wire [`EXC_CODE_BUS]     id_exccode_i,//取指阶段异常编码
    

    //译码阶段发出的暂停请求信号
    output wire                     stallreq_id,
    // 送至执行阶段的译码信息
    // output wire [`ALUTYPE_BUS  ]    id_alutype_o,
    output wire [`ALUOP_BUS    ]    id_aluop_o,
    output wire                     id_whilo_o,
    output wire                     id_mreg_o,
    output wire [`REG_ADDR_BUS ]    id_wa_o,
    output wire                     id_wreg_o,
    output wire [`REG_BUS]          id_din_o,
    // 送至执行阶段的源操作数
    output wire [`REG_BUS      ]    id_src1_o,
    output wire [`REG_BUS      ]    id_src2_o,
    // 送至读通用寄存器堆端口的使能和地址
    // output wire                     rreg1,
    output wire [`REG_ADDR_BUS ]    ra1,
    // output wire                     rreg2,
    output wire [`REG_ADDR_BUS ]    ra2,
    //跳转(add)
    output wire [`INST_ADDR_BUS]    jump_addr_1,
    output wire [`INST_ADDR_BUS]    jump_addr_2,
    output wire [`INST_ADDR_BUS]    jump_addr_3,
    output wire [`INST_ADDR_BUS]    ret_addr,
    output wire [`JTSEL_BUS]        jtsel,
    //异常处理添加
    output wire [`REG_ADDR_BUS]     cp0_addr,//cp0中寄存器的地址
    output wire [`INST_ADDR_BUS]    id_pc_o,//处于译码阶段指令的pc值
    output wire                     id_in_delay_o,//处于译码阶段的指令是延迟槽指令
    output wire                     next_delay_o,//下一条进入译码阶段的指令是延迟槽指令
    output wire [`EXC_CODE_BUS]     id_exccode_o//处于译码阶段的指令的异常类型

    );
    
    // 根据小端模式组织的指令字(如果清空流水线则取出空指令)
    //wire [`INST_BUS] id_inst =(flush_im==`FLUSH)?`ZERO_WORD: {id_inst_i[7:0], id_inst_i[15:8], id_inst_i[23:16], id_inst_i[31:24]};
    // wire [`INST_BUS] id_inst =(flush_im==`FLUSH)?`ZERO_WORD: id_inst_i;
    //new
    wire [`INST_BUS] id_inst = id_inst_i;
    //new

    // 提取指令字中的各个字段的信息
    wire [5 :0] op   = id_inst[31:26];
    wire [5 :0] func = id_inst[5 : 0];
    wire [4 :0] rd   = id_inst[15:11];
    wire [4 :0] rs   = id_inst[25:21];
    wire [4 :0] rt   = id_inst[20:16];
    wire [4 :0] sa   = id_inst[10: 6];
    wire [15:0] imm  = id_inst[15: 0];

    //直接送入下一阶段(add)
    assign id_pc_o=id_pc_i;
    assign id_in_delay_o=id_in_delay_i;


    /*-------------------- 第一级译码逻辑：确定当前需要译码的指令 --------------------*/
    wire inst_reg  = ~|op;
    wire inst_add  = inst_reg&  func[5]& ~func[4]& ~func[3]& ~func[2]& ~func[1]& ~func[0];
    wire inst_subu = inst_reg&  func[5]& ~func[4]& ~func[3]& ~func[2]&  func[1]&  func[0];
    wire inst_slt  = inst_reg&  func[5]& ~func[4]&  func[3]& ~func[2]&  func[1]& ~func[0];
    wire inst_and  = inst_reg&  func[5]& ~func[4]& ~func[3]&  func[2]& ~func[1]& ~func[0];
    wire inst_mult = inst_reg& ~func[5]&  func[4]&  func[3]& ~func[2]& ~func[1]& ~func[0];
    wire inst_mfhi = inst_reg& ~func[5]&  func[4]& ~func[3]& ~func[2]& ~func[1]& ~func[0];
    wire inst_mflo = inst_reg& ~func[5]&  func[4]& ~func[3]& ~func[2]&  func[1]& ~func[0];
    wire inst_sll  = inst_reg& ~func[5]& ~func[4]& ~func[3]& ~func[2]& ~func[1]& ~func[0];
    wire inst_ori  = ~op[5]& ~op[4]&  op[3]&  op[2]& ~op[1]&  op[0];
    wire inst_lui  = ~op[5]& ~op[4]&  op[3]&  op[2]&  op[1]&  op[0];
    wire inst_addiu= ~op[5]& ~op[4]&  op[3]& ~op[2]& ~op[1]&  op[0];
    wire inst_sltiu= ~op[5]& ~op[4]&  op[3]& ~op[2]&  op[1]&  op[0];
    wire inst_lb   =  op[5]& ~op[4]& ~op[3]& ~op[2]& ~op[1]& ~op[0];
    wire inst_lw   =  op[5]& ~op[4]& ~op[3]& ~op[2]&  op[1]&  op[0];
    wire inst_sb   =  op[5]& ~op[4]&  op[3]& ~op[2]& ~op[1]& ~op[0];
    wire inst_sw   =  op[5]& ~op[4]&  op[3]& ~op[2]&  op[1]&  op[0];

    //实验1 R型指令(补全)
    wire inst_addu  = inst_reg&  func[5]& ~func[4]& ~func[3]& ~func[2]& ~func[1]&  func[0];
    wire inst_sub   = inst_reg&  func[5]& ~func[4]& ~func[3]& ~func[2]&  func[1]& ~func[0];
    wire inst_sltu  = inst_reg&  func[5]& ~func[4]&  func[3]& ~func[2]&  func[1]&  func[0];
    wire inst_or    = inst_reg&  func[5]& ~func[4]& ~func[3]&  func[2]& ~func[1]&  func[0];
    wire inst_nor   = inst_reg&  func[5]& ~func[4]& ~func[3]&  func[2]&  func[1]&  func[0];
    wire inst_xor   = inst_reg&  func[5]& ~func[4]& ~func[3]&  func[2]&  func[1]& ~func[0];
    wire inst_srl   = inst_reg& ~func[5]& ~func[4]& ~func[3]& ~func[2]&  func[1]& ~func[0];
    wire inst_sra   = inst_reg& ~func[5]& ~func[4]& ~func[3]& ~func[2]&  func[1]&  func[0];
    wire inst_sllv  = inst_reg& ~func[5]& ~func[4]& ~func[3]&  func[2]& ~func[1]& ~func[0];
    wire inst_srlv  = inst_reg& ~func[5]& ~func[4]& ~func[3]&  func[2]&  func[1]& ~func[0];
    wire inst_srav  = inst_reg& ~func[5]& ~func[4]& ~func[3]&  func[2]&  func[1]&  func[0];
    wire inst_multu = inst_reg& ~func[5]&  func[4]&  func[3]& ~func[2]& ~func[1]&  func[0];
    wire inst_div   = inst_reg& ~func[5]&  func[4]&  func[3]& ~func[2]&  func[1]& ~func[0];
    wire inst_divu  = inst_reg& ~func[5]&  func[4]&  func[3]& ~func[2]&  func[1]&  func[0];
    wire inst_mthi  = inst_reg& ~func[5]&  func[4]& ~func[3]& ~func[2]& ~func[1]&  func[0];
    wire inst_mtlo  = inst_reg& ~func[5]&  func[4]& ~func[3]& ~func[2]&  func[1]&  func[0];
    //实验1 I型指令(补全)
    wire inst_addi  = ~op[5]& ~op[4]&  op[3]& ~op[2]& ~op[1]& ~op[0];
    wire inst_slti  = ~op[5]& ~op[4]&  op[3]& ~op[2]&  op[1]& ~op[0];
    wire inst_andi  = ~op[5]& ~op[4]&  op[3]&  op[2]& ~op[1]& ~op[0];
    wire inst_xori  = ~op[5]& ~op[4]&  op[3]&  op[2]&  op[1]& ~op[0];
    wire inst_lbu   =  op[5]& ~op[4]& ~op[3]&  op[2]& ~op[1]& ~op[0];
    wire inst_lh    =  op[5]& ~op[4]& ~op[3]& ~op[2]& ~op[1]&  op[0];
    wire inst_lhu   =  op[5]& ~op[4]& ~op[3]&  op[2]& ~op[1]&  op[0];
    wire inst_sh    =  op[5]& ~op[4]&  op[3]& ~op[2]& ~op[1]&  op[0];

    //实验2
    wire inst_j     = ~op[5]& ~op[4]& ~op[3]& ~op[2]&  op[1]& ~op[0];
    wire inst_jal   = ~op[5]& ~op[4]& ~op[3]& ~op[2]&  op[1]&  op[0];
    wire inst_beq   = ~op[5]& ~op[4]& ~op[3]&  op[2]& ~op[1]& ~op[0];
    wire inst_bne   = ~op[5]& ~op[4]& ~op[3]&  op[2]& ~op[1]&  op[0];
    wire inst_jr    = inst_reg& ~func[5]& ~func[4]& func[3]& ~func[2]& ~func[1]& ~func[0];
    //实验2指令(补全)
    wire inst_bgez  = ~op[5]& ~op[4]& ~op[3]& ~op[2]& ~op[1]&  op[0] & ~rt[4]& ~rt[3]& ~rt[2]& ~rt[1]&  rt[0];
    wire inst_bgtz  = ~op[5]& ~op[4]& ~op[3]&  op[2]&  op[1]&  op[0] & ~rt[4]& ~rt[3]& ~rt[2]& ~rt[1]& ~rt[0];
    wire inst_blez  = ~op[5]& ~op[4]& ~op[3]&  op[2]&  op[1]& ~op[0] & ~rt[4]& ~rt[3]& ~rt[2]& ~rt[1]& ~rt[0];
    wire inst_bltz  = ~op[5]& ~op[4]& ~op[3]& ~op[2]& ~op[1]&  op[0] & ~rt[4]& ~rt[3]& ~rt[2]& ~rt[1]& ~rt[0];
    wire inst_bgezal= ~op[5]& ~op[4]& ~op[3]& ~op[2]& ~op[1]&  op[0] &  rt[4]& ~rt[3]& ~rt[2]& ~rt[1]&  rt[0];
    wire inst_bltzal= ~op[5]& ~op[4]& ~op[3]& ~op[2]& ~op[1]&  op[0] &  rt[4]& ~rt[3]& ~rt[2]& ~rt[1]& ~rt[0];
    wire inst_jalr  = inst_reg& ~func[5]& ~func[4]& func[3]& ~func[2]& ~func[1]&  func[0];

    wire is_jump=inst_j|inst_jal|inst_beq|inst_bne|inst_jr|inst_bgez|inst_bgtz|inst_blez|inst_bltz|
        inst_bgezal|inst_bltzal|inst_jalr;

    //实验3（异常处理）
    wire inst_syscall = inst_reg& ~func[5]& ~func[4]& func[3]& func[2]& ~func[1]& ~func[0];
    wire inst_eret    = ~op[5]& op[4]& ~op[3]& ~op[2]& ~op[1]& ~op[0]& ~func[5]& func[4]& func[3]& ~func[2]& ~func[1]& ~func[0];
    wire inst_mfc0    = ~op[5]& op[4]& ~op[3]& ~op[2]& ~op[1]& ~op[0]& ~id_inst[23] &~id_inst[25];//&~id_inst[25]
    wire inst_mtc0    = ~op[5]& op[4]& ~op[3]& ~op[2]& ~op[1]& ~op[0]&  id_inst[23];
    wire inst_break   = inst_reg& ~func[5]& ~func[4]& func[3]& func[2]& ~func[1]& func[0];

    wire inst_mul     = ~op[5]& op[4]& op[3]& op[2]& ~op[1]& ~op[0]& ~func[5]& ~func[4]& ~func[3]& ~func[2]& func[1]& ~func[0];


    /*------------------------------------------------------------------------------*/

    /*-------------------- 第二级译码逻辑：生成具体的控制信号 --------------------*/
    // 操作类型alutype
    // assign id_alutype_o[2] =  
    //             (inst_sll|inst_srl|inst_sra|inst_sllv|inst_srlv|inst_srav|
    //             inst_j|inst_jal|inst_jr|inst_beq|inst_bne|inst_bgez|inst_bltz|inst_bgezal|inst_bltzal|inst_bgtz|inst_blez|inst_j|inst_jal|inst_jr|inst_jalr|
    //             inst_break|inst_syscall|inst_eret|inst_mtc0);//inst_break|
    // assign id_alutype_o[1] =
    //             (inst_and | inst_mfhi | inst_mflo | inst_ori | inst_lui|
    //             inst_or|inst_nor|inst_xor|inst_mthi|inst_mtlo|inst_andi|inst_xori|
    //             inst_break|inst_syscall|inst_eret|inst_mtc0|inst_mfc0);//inst_break|
    // assign id_alutype_o[0] = 
    //             ( inst_add | inst_subu | inst_slt | inst_mfhi | inst_mflo |
    //             inst_addiu | inst_sltiu | inst_lb | inst_lw | inst_sb | inst_sw|
    //             |inst_addu|inst_sub|inst_sltu|inst_mthi|inst_mtlo|
    //             inst_addi|inst_slti|inst_lbu|inst_lh|inst_lhu|inst_sh|
    //             inst_j|inst_jal|inst_jr|inst_beq|inst_bne|inst_bgez|inst_bltz|inst_bgezal|inst_bltzal|inst_bgtz|inst_blez|inst_jalr|
    //             inst_mfc0);
    

    // 内部操作码aluop
    // assign id_aluop_o[7]   =
    //         (inst_lb | inst_lw | inst_sb | inst_sw|
    //         inst_syscall|inst_eret|inst_mtc0|inst_mfc0);
    // assign id_aluop_o[6]   =1'b0;
    // assign id_aluop_o[5]   =
    //         (inst_slt | inst_sltiu|inst_srl|inst_sra|inst_sllv|inst_srlv|inst_srav|
    //         inst_divu|inst_mthi|inst_mtlo|inst_slti|inst_andi|inst_xori|inst_lbu|
    //         inst_lh|inst_lhu|inst_sh|
    //         is_jump|inst_break);//|inst_break
    // assign id_aluop_o[4]   =
    //         (inst_add | inst_subu | inst_and | inst_mult | inst_sll |
    //         inst_ori | inst_addiu | inst_lb | inst_lw | inst_sb | inst_sw|
    //         inst_addu|inst_sub|inst_sltu|inst_or|inst_nor|inst_xor|inst_multu|inst_div|
    //         inst_addi|inst_lbu|inst_lh|inst_lhu|inst_sh|
    //         inst_beq|inst_bne|inst_bgez|inst_bgtz|inst_blez|inst_bltz|inst_bgezal|inst_bltzal|inst_jalr);
    // assign id_aluop_o[3]	=
    //         (inst_add | inst_subu | inst_and | inst_mfhi | inst_mflo | inst_ori |
    //          inst_addiu | inst_sb | inst_sw|inst_xor|inst_multu|inst_div|inst_mthi|inst_mtlo|
    //          inst_slti|inst_andi|inst_xori|
    //          inst_j|inst_jal|inst_jr|inst_bltz|inst_blez|inst_bgezal|inst_bltzal|inst_jalr|
    //          inst_mtc0|inst_mfc0|inst_break);//|inst_break
    // assign id_aluop_o[2]	=
    //         (inst_slt | inst_and | inst_mult | inst_mfhi | inst_mflo | inst_ori | inst_lui | inst_sltiu|
    //         inst_sub|inst_sltu|inst_or|inst_srav|inst_multu|inst_div|inst_divu|inst_xori|
    //         inst_lhu|inst_sh|
    //         inst_j|inst_jal|inst_jr|inst_bgez|inst_bgtz|inst_jalr|
    //         inst_syscall|inst_eret|inst_mtc0|inst_mfc0|inst_break);//|inst_break
    // assign id_aluop_o[1]	=
    //         (inst_subu | inst_slt | inst_sltiu | inst_lw | inst_sw|
    //         inst_sltu|inst_or|inst_nor|inst_xor|inst_sllv|inst_srlv|inst_multu|inst_div|
    //         inst_addi|inst_slti|inst_andi|inst_xori|inst_lbu|inst_lh|
    //         inst_jal|inst_bgez|inst_bgtz|inst_bgezal|inst_bltzal|
    //         inst_syscall|inst_eret);
    // assign id_aluop_o[0]	= 
    //         (inst_subu | inst_mflo | inst_sll | inst_ori | inst_lui | inst_addiu | inst_sltiu|
    //         inst_sub|inst_or|inst_sra|inst_srlv|inst_div|inst_divu|inst_mtlo|inst_addi|
    //         inst_andi|inst_xori|inst_lh|inst_sh|
    //         inst_jr|inst_bne|inst_bgtz|inst_bltz|inst_bltzal|
    //         inst_eret|inst_mtc0|inst_break);//|inst_break

    assign id_aluop_o[7] = inst_sll | inst_srl | inst_sra | inst_sllv | inst_srlv | inst_srav | inst_jal | inst_bgezal | inst_bltzal | inst_jalr | inst_mul;
    assign id_aluop_o[6] = inst_and | inst_mfhi | inst_mflo | inst_or | inst_nor | inst_xor | inst_mthi | inst_mtlo | inst_ori | inst_lui | inst_andi | inst_xori | inst_mfc0 | inst_mul;
    assign id_aluop_o[5] = inst_add | inst_subu | inst_slt | inst_mfhi | inst_mflo | inst_addu | inst_sub | inst_sltu | inst_mthi | inst_mtlo | inst_addiu | inst_sltiu | 
                           inst_lb | inst_lw | inst_sb | inst_sw | inst_addi | inst_slti | inst_lbu | inst_lh | inst_lhu | inst_sh | inst_jal | inst_bgezal | inst_bltzal |
                           inst_jalr | inst_mfc0; 
    assign id_aluop_o[4] = inst_lhu | inst_sh | inst_mul;
    assign id_aluop_o[3] = inst_lb | inst_lw | inst_sb | inst_sw | inst_addi | inst_slti | inst_lbu | inst_lh | inst_bgez | inst_bgtz | inst_blez | inst_bltz | inst_mtc0 | 
                           inst_syscall | inst_eret | inst_break;
    assign id_aluop_o[2] = inst_sub | inst_sltu | inst_srlv | inst_srav | inst_addiu | inst_sltiu | inst_ori | inst_lui | inst_addi | inst_slti | inst_andi | inst_xori | 
                           inst_lbu | inst_lh | inst_j | inst_jr | inst_beq|inst_bne|inst_mfc0 | inst_mtc0 | inst_syscall | inst_eret | inst_break;
    assign id_aluop_o[1] = inst_slt | inst_addu | inst_nor | inst_xor | inst_sra | inst_sllv | inst_div | inst_divu | inst_mthi | inst_mtlo | inst_addiu | inst_sltiu | 
                           inst_sb | inst_sw | inst_andi | inst_xori | inst_lbu | inst_lh | inst_beq | inst_bne | inst_blez | inst_bltz | inst_bltzal | inst_jalr | inst_eret | 
                           inst_break;
    assign id_aluop_o[0] = inst_subu | inst_mflo | inst_addu | inst_sltu | inst_or | inst_xor | inst_srl | inst_sllv | inst_srav | inst_multu | inst_divu | inst_mtlo | inst_sltiu |
                           inst_lui | inst_lw | inst_sw | inst_slti | inst_xori | inst_lh | inst_sh | inst_jr | inst_bne | inst_bgtz | inst_bltz | inst_bgezal | inst_jalr | 
                           inst_syscall | inst_break;                      
    //生成相等使能信号(弃用)
    // wire equ =  (cpu_rst_n==`RST_ENABLE)?1'b0:
    //             (inst_bgez)     ?(id_src1_o >= 0):
    //             (inst_bgtz)     ?(id_src1_o >  0):
    //             (inst_blez)     ?(id_src1_o <= 0):
    //             (inst_bltz)     ?(id_src1_o <  0):
    //             (inst_bgezal)   ?(id_src1_o >= 0):
    //             (inst_bltzal)   ?(id_src1_o <  0):
    //             (inst_beq)      ?(id_src1_o==id_src2_o):
    //             (inst_bne)      ?(id_src1_o!=id_src2_o):1'b0;


    // 写通用寄存器使能信号
    assign id_wreg_o = 
        (inst_add | inst_subu | inst_slt | inst_and | inst_mfhi | inst_mflo | inst_sll | 
        inst_ori | inst_lui | inst_addiu | inst_sltiu | inst_lb | inst_lw|
        inst_addu|inst_sub|inst_sltu|inst_or|inst_nor|inst_xor|
        inst_srl|inst_sra|inst_sllv|inst_srlv|inst_srav|inst_addi|
        inst_slti|inst_andi|inst_xori|inst_lbu|inst_lh|inst_lhu|
        inst_jal|inst_bgezal| inst_bltzal|inst_jalr|
        inst_mfc0 | inst_mul);
    
    
    //写HILO寄存器使能信号
    assign id_whilo_o =  
    (inst_mult|inst_multu|inst_div|inst_divu|inst_mthi|inst_mtlo);
    
    
    //移位使能指令
    wire shift = inst_sll|inst_srl|inst_sra;
    
    //立即数使能信号
    wire immsel = inst_ori | inst_lui | inst_addiu | inst_sltiu | inst_lb | inst_lw | inst_sb | inst_sw|
            inst_addi|inst_slti|inst_andi|inst_xori|inst_lbu|inst_lh|inst_lhu|inst_sh
            ;
    
    //目的寄存器选择信号
    wire rtsel = inst_ori | inst_lui | inst_addiu | inst_sltiu | inst_lb | inst_lw|
            inst_addi|inst_slti|inst_andi|inst_xori|inst_lbu|inst_lh|inst_lhu
            ;
    
    //符号扩展使能信号
    wire sext = inst_addiu | inst_sltiu | inst_lb | inst_lw | inst_sb | inst_sw|
            inst_addi|inst_slti|inst_lbu|inst_lh|inst_lhu|inst_sh;
    
    //加载高半字使能信号
    wire upper = inst_lui;
    
    //存储器到寄存器使能信号
    assign id_mreg_o =  (inst_lb | inst_lw|
            inst_lbu|inst_lh|inst_lhu);

    wire rreg1;
    wire rreg2;
    
    // 读通用寄存器堆读端口1使能信号
    assign rreg1 = 
            (inst_add | inst_subu | inst_slt | inst_and | inst_mult |
            inst_ori | inst_addiu | inst_sltiu | inst_lb | inst_lw | inst_sb | inst_sw|
            inst_addu|inst_sub|inst_sltu|inst_or|inst_nor|inst_xor|inst_sllv|inst_srlv|
            inst_srav|inst_multu|inst_div|inst_divu|inst_mthi|inst_mtlo|
            inst_addi|inst_slti|inst_andi|inst_xori|inst_lbu|inst_lh|inst_lhu|inst_sh|
            inst_jr|inst_beq|inst_bne|inst_bgez|inst_bgtz|inst_blez|inst_bltz|
            inst_bgezal|inst_bltzal|inst_jalr | inst_mul);
    
    // 读通用寄存器堆读端口2使能信号
    assign rreg2 = 
            (inst_add | inst_subu | inst_slt | inst_and | inst_mult | inst_sll | inst_sb | inst_sw|
            inst_addu|inst_sub|inst_sltu|inst_or|inst_nor|inst_xor|
            inst_srl|inst_sra|inst_sllv|inst_srlv|inst_srav|
            inst_multu|inst_div|inst_divu|inst_sb|inst_sw|inst_sh|
            inst_beq|inst_bne|
            inst_mtc0 | inst_mul);

    //生成子程序调用使能信号
    wire jal=inst_jal;


    //生成译码阶段暂停请求信号，以解决加载相关
    assign stallreq_id= 
                        (((exe2id_wreg==`WRITE_ENABLE && exe2id_wa==ra1 && rreg1==`READ_ENABLE)||
                        (exe2id_wreg==`WRITE_ENABLE && exe2id_wa==ra2 && rreg2==`READ_ENABLE))&&(exe2id_mreg==`TRUE_V))?`STOP:
                        (((mem2id_wreg==`WRITE_ENABLE && mem2id_wa==ra1 && rreg1==`READ_ENABLE)||
                        (mem2id_wreg==`WRITE_ENABLE && mem2id_wa==ra2 && rreg2==`READ_ENABLE))&&(mem2id_mreg==`TRUE_V))?`STOP:`NOSTOP;
                        
    
    /*------------------------------------------------------------------------------*/

    // 读通用寄存器堆端口1的地址为rs字段，读端口2的地址为rt字段
    assign ra1   =  rs;
    assign ra2   =  rt;
    
    
    //获取指令操作需要的立即数
    wire [31:0] imm_ext = 
        (upper == `UPPER_ENABLE ) ? (imm << 16):
        (sext == `SIGNED_EXT ) ? {{16{imm[15]}}, imm}: {{16{1'b0}}, imm};
    
                                            
    // 获得待写入目的寄存器的地址
    assign id_wa_o =  
        (rtsel == `RT_ENABLE || inst_mfc0) ? rt: 
        //(jal==`TRUE_V        ) ? 5'b11111:rd;
        (inst_jal|inst_bgezal|inst_bltzal ) ? 5'b11111:rd;


    //生成转移地址选择信号
    // assign jtsel[1]=inst_jr| inst_beq & equ | (inst_bne & equ) | inst_bgez & equ |
    //          inst_bgtz & equ | inst_blez & equ | inst_bltz & equ | inst_bgezal & equ | inst_bltzal & equ | inst_jalr;
    // assign jtsel[0]=inst_j| inst_jal| inst_beq & equ | (inst_bne & equ)|
    //         | inst_bgez & equ | inst_bgtz & equ | inst_blez & equ | inst_bltz & equ | inst_bgezal & equ | inst_bltzal & equ;
    
    wire lesseq =  id_src1_o[31]|(~|id_src1_o);
    wire great  =  ~lesseq;
    assign jtsel[1] = (inst_beq&id_src1_o==id_src2_o)|(inst_bne&id_src1_o!=id_src2_o)|
                            (inst_bgez&~id_src1_o[31])|(inst_bltz&id_src1_o[31])|
                            (inst_bgezal&~id_src1_o[31])|(inst_bltzal&id_src1_o[31])|
                            (inst_blez&lesseq)|(inst_bgtz&great)|inst_jr|inst_jalr;
    assign jtsel[0] = (inst_beq&id_src1_o==id_src2_o)|(inst_bne&id_src1_o!=id_src2_o)|
                            (inst_bgez&~id_src1_o[31])|(inst_bltz&id_src1_o[31])|
                            (inst_bgezal&~id_src1_o[31])|(inst_bltzal&id_src1_o[31])|
                            (inst_blez&lesseq)|(inst_bgtz&great)|inst_j|inst_jal;    


    //生成计算转移地址所需信号
    wire [`INST_ADDR_BUS]   pc_plus_8   =pc_plus_4+4;
    wire [`JUMP_BUS]        instr_index =id_inst[25:0];
    wire [`INST_ADDR_BUS]   imm_jump    ={{14{imm[15]}},imm,2'b00};

    //获得转移地址
    assign jump_addr_1  ={pc_plus_4[31:28],instr_index,2'b00};
    assign jump_addr_2  =pc_plus_4+imm_jump;
    assign jump_addr_3  =id_src1_o;

    //生成子程序调用的返回地址
    assign ret_addr     =pc_plus_8;

    //源操作数选择信号（执行与访存阶段的定向前推）
    wire [1:0] fwrd1=
        (exe2id_wreg==`WRITE_ENABLE && exe2id_wa==ra1 && rreg1==`READ_ENABLE) ? 2'b01:
        (mem2id_wreg==`WRITE_ENABLE && mem2id_wa==ra1 && rreg1==`READ_ENABLE) ? 2'b10:
        (rreg1==`READ_ENABLE)? 2'b11: 2'b00;

    wire [1:0] fwrd2=
        (exe2id_wreg==`WRITE_ENABLE && exe2id_wa==ra2 && rreg2==`READ_ENABLE) ? 2'b01:
        (mem2id_wreg==`WRITE_ENABLE && mem2id_wa==ra2 && rreg2==`READ_ENABLE) ? 2'b10:
        (rreg2==`READ_ENABLE)? 2'b11: 2'b00;  


    // 获得访存阶段要存入数据存储器的数据（可能来自定向前推的数据）
    assign id_din_o =  
        (fwrd2 == 2'b01         ) ? exe2id_wd:
        (fwrd2 == 2'b10         ) ? mem2id_wd:
        (fwrd2 == 2'b11         ) ? rd2 : `ZERO_WORD;
    

    // 获得源操作数1，如果shift信号有效，则源操作数1为移位位数;可能是定向前推的数据;也可能为从通用寄存器堆端口1获得的数据
    assign id_src1_o = 
        (shift == `SHIFT_ENABLE ) ? {27'b0, sa}:
        (fwrd1 == 2'b01         ) ? exe2id_wd:
        (fwrd1 == 2'b10         ) ? mem2id_wd:
        (fwrd1 == 2'b11         ) ? rd1 : `ZERO_WORD;

    // 获得源操作数2，如果immsel信号有效，则源操作数2为立即数;可能是定向前推的数据;也可能为从通用寄存器堆端口1获得的数据
    assign id_src2_o = 
        (immsel == `IMM_ENABLE  ) ? imm_ext :
        (fwrd2 == 2'b01         ) ? exe2id_wd:
        (fwrd2 == 2'b10         ) ? mem2id_wd:
        (fwrd2 == 2'b11         ) ? rd2 : `ZERO_WORD;

    //异常处理相关
    //判断下一条指令是否为延迟槽指令
    assign next_delay_o=is_jump;

    //判断当前处于译码阶段的指令是否存在异常，并设置相应的异常类型编码
    wire inst_known=inst_add | inst_addi | inst_addu | inst_addiu | inst_sub | inst_subu | inst_slt| inst_slti |
             inst_sltu | inst_sltiu | inst_div | inst_divu | inst_mult | inst_multu |
            inst_and | inst_andi | inst_lui | inst_nor | inst_or | inst_ori | inst_xor | inst_xori | 
            inst_sllv | inst_sll | inst_srav | inst_sra | inst_srlv | inst_srl | 
            inst_beq | inst_bne | inst_bgez | inst_bgtz | inst_blez | inst_bltz | 
            inst_bgezal | inst_bltzal | inst_j | inst_jal | inst_jr | inst_jalr |
            inst_mfhi | inst_mflo | inst_mthi | inst_mtlo |
            inst_lb | inst_lbu | inst_lh | inst_lhu | inst_lw | inst_sb | inst_sh | inst_sw |
            inst_syscall | inst_eret | inst_mfc0 | inst_mtc0|inst_break | inst_mul;

    assign id_exccode_o = 
            //(id_exccode_i == `EXC_ADEL) ? id_exccode_i :
            (!inst_known) ? `EXC_RI :
            (inst_syscall == `TRUE_V ) ? `EXC_SYS : 
            (inst_eret == `TRUE_V    ) ? `EXC_ERET :
            (inst_break == `TRUE_V) ? `EXC_BREAK : 
            id_exccode_i;

    //获得cp0寄存器的访问地址
    assign cp0_addr=rd;

endmodule
