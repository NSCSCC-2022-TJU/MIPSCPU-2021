`include "defines.v"

module wb_stage(
   	// 闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柟閭﹀枟閺嗘粓鎮楅棃娑欏暈濠殿垰銈搁弻銈夊箛娴ｅ摜浠悷婊勫Ω閸ャ劎鍘垫俊鐐差儏妤犳悂宕㈤幘顔界厸濞达絽鎼弸鎴︽煙瀹勭増鍣规い鎾冲悑瀵板嫮鈧綆鍋呴鐔兼⒒娴ｈ銇熼柛娆忛叄瀹曟垿宕卞☉鏍ゅ亾閸岀儐鏁嬮柍褜鍓熼悰顔跨疀濞戞瑥鈧鏌ら幁鎺戝姕婵炲懌鍨藉娲传閸曨偀鍋撻崼鏇炵９闁哄稁鍋€閸嬫挸顫濋鍌溞ㄥΔ鐘靛仒缁舵岸寮幘缁樻櫢闁跨噦鎷�
   	input  	wire                   		wb_mreg_i,
   	input  	wire [`BSEL_BUS      ] 	    wb_dre_i,
    input  	wire [`REG_ADDR_BUS  ] 	    wb_wa_i,
    input  	wire                   		wb_wreg_i,
    input  	wire [`REG_BUS       ] 	    wb_dreg_i,
   	input  	wire                   		wb_whilo_i,
    input  	wire [`DOUBLE_REG_BUS] 	    wb_hilo_i,
    input  	wire [`ALUOP_BUS     ] 	    wb_aluop_i,
   	// 闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柟鐗堟緲閸戠姴鈹戦悩瀹犲缂佺媭鍨堕弻锝夊箣閿濆憛鎾绘煛閸涱喗鍊愰柡宀嬬節瀹曟帒螣鐞涒€充壕闁哄稁鍋€閸嬫挸顫濋鍌溞ㄩ梺鍝勮閸旀垿骞冮姀銏㈢煓閻犳亽鍔婇崑锝夋⒑鐠囨彃顒㈢紒瀣浮閺佸姊虹粙娆惧剰缂佸缍婂濠氬Ω閳哄倸浜滈梺鍛婄☉閿曪附瀵奸崟顖涒拺鐟滅増甯╁Λ鎴︽煕韫囨棑鑰跨€殿噮鍋婇獮妯兼嫚閸欏妫熼梻渚€娼ч悧鍡椢涘Δ鍜佹晜闁割偅娲橀埛鎴︽偣閹帒濡奸柡瀣灴閺岋紕鈧綆浜堕悡鍏碱殽閻愯尙绠婚柟顔界矒閹崇偤濡烽敂绛嬩户闂傚倷绀侀幖顐﹀磹閸洖纾归柡宥庡亐閸嬫挸顫濋鍌溞ㄩ梺鍝勮閸旀垿骞冮姀銈呭窛濠电姴瀚槐鏇㈡⒒娴ｅ摜绉烘い銉︽崌瀹曟顫滈埀顒€顕ｉ锕€绠婚悹鍥у级椤ユ繈姊洪棃娑氬婵☆偅顨婇、鏃堟晸閿燂拷
   	input  	wire [`WORD_BUS      ] 	    dm,
    input   wire                        mem_operation_ok,
    //闂傚倸鍊峰ù鍥р枖閺囥垹绐楅幖娣妽閸庢垿鏌涢幘妤€瀚▓浼存⒑瑜版帗锛熼柣鎺炵畵瀵煡骞栨担鍦幐闂佺ǹ鏈敋闁逞屽墯閻楁粓鍩€椤掍浇澹樼紓宥咃躬瀵濡搁埡鍌氫簻闂佸憡绋戦敃锔藉閸曨垱鈷戠憸鐗堝俯濡垿鏌涜箛鏃撹€跨€殿噮鍋婇獮妯兼嫚閸欏妫熼梻渚€娼ч悧鍡椢涘Δ鍜佹晜闁割偅娲橀埛鎴︽偣閹帒濡兼繛鍛姍閺岀喖宕欓妶鍡楊伓
    input  	wire                   		cp0_we_i,
    input  	wire [`REG_ADDR_BUS  ] 	    cp0_waddr_i,
    input  	wire [`REG_BUS       ] 	    cp0_wdata_i,

   	// 闂傚倷绀侀幉锟犲礉閺嶎厽鍋￠柍鍝勬噹閺嬩線鏌熼幑鎰靛殭婵☆偅锕㈤弻鏇㈠醇濠靛浂妫炲銈呯箰閻栧ジ寮婚敐澶婄厸濠电姴鍊归悵婵嬫⒑鏉炴壆鍔嶉柟姝屽吹缁參鎮㈤悡骞劑鏌曟竟顖氬濞肩娀姊洪崫鍕垫Ц闁绘绻樺畷鎴﹀箻閸ㄦ稑浜炬慨姗嗗墰缁夋椽鏌＄仦璇插闁诡喓鍨藉畷銊︾節閸曨亞纾块梻鍌欑缂嶅﹪藟閹捐绀傛慨妞诲亾鐎殿噮鍋婇獮妯兼嫚閸欏妫熼梻渚€娼ч悧鍡椢涘Δ鍜佹晜闁割偅娲橀埛鎴︽偣閹帒濡奸柡瀣灴閺岋紕鈧綆浜堕悡鍏碱殽閻愯尙绠婚柟顔界矒閹崇偤濡烽敂绛嬩户闂傚倷绀侀幖顐﹀磹閸洖纾归柡宥庡亐閸嬫挸顫濋悙顒€顏�
   	output 	wire [`REG_ADDR_BUS  ] 	    wb_wa_o,
    output 	wire                   		wb_wreg_o,
   	output 	wire [`WORD_BUS      ] 	    wb_wd_o,
   	output 	wire                   		wb_whilo_o,
    output 	wire [`DOUBLE_REG_BUS] 	    wb_hilo_o,
    output  wire [`ALUOP_BUS     ] 	    wb_aluop_o,
    //闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柟鐗堟緲閸戠姴鈹戦悩瀹犲缂佺媭鍨堕弻锝夊箣閿濆憛鎾绘煛閸涱喗鍊愰柡宀嬬節瀹曟帒螣鐞涒€充壕闁哄稁鍋€閸嬫挸顫濋鍌溞ㄩ悗瑙勬礃缁矂顢橀崗鐓庣窞閻庯綆鍋呴鐔兼⒒娴ｅ憡鎯堥柛濠傜埣瀹曟劙寮介鐔蜂壕婵鍋撶€氾拷
    output  wire                        wb2exe_whilo,
    output  wire [`DOUBLE_REG_BUS]      wb2exe_hilo,
    //闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柟鐗堟緲閸戠姴鈹戦悩瀹犲缂佺媭鍨堕弻锝夊箣閿濆憛鎾绘煛閸涱喗鍊愰柡宀嬬節瀹曟帒螣鐞涒€充壕闁哄稁鍋€閸嬫挸顫濋鍌溞ㄩ悗瑙勬礃缁矂顢橀崗鐓庣窞閻庯綆鍋呴鐔兼⒒娴ｈ櫣甯涢柣鐔村灩鍗遍柛鏇ㄥ幘缁€濠囨煕閵夘喖澧紒鐙€鍨堕弻锝夊箣閿濆憛鎾绘煛閸涱喗鍊愰柟顔斤耿閹瑧鎷犺娴兼劙姊虹紒妯煎ⅹ闁绘牕銈稿濠氬Ω閳哄倸浜滈梺鍛婄☉閿曪附瀵奸崟顖涒拺鐟滅増甯╁Λ鎴︽煕韫囨棑鑰跨€殿噮鍋婇獮妯兼嫚閸欏妫熼梻渚€娼ч悧鍡椢涘Δ鍜佹晜闁割偅娲橀埛鎴︽偣閹帒濡奸柡瀣灴閺岋紕鈧綆浜堕悡鍏碱殽閻愯尙绠婚柡浣规崌閺佹捇鏁撻敓锟�
    output  wire                        wb2mem_cp0_we,
    output  wire [`REG_ADDR_BUS  ]      wb2mem_cp0_wa,
    output  wire [`REG_BUS       ]      wb2mem_cp0_wd,
    output  wire                        wb2exe_cp0_we,
    output  wire [`REG_ADDR_BUS  ]      wb2exe_cp0_wa,
    output  wire [`REG_BUS       ]      wb2exe_cp0_wd,
    //闂傚倸鍊峰ù鍥р枖閺囥垹绐楅幖娣妽閸庢垿鏌涢幘妤€瀚▓浼存⒑瑜版帗锛熼柣鎺炵畵瀵煡骞栨担鍦幐闂佺ǹ鏈敋闁逞屽墯閻楁粓鍩€椤掍浇澹樼紓宥咃躬瀵濡搁埡鍌氫簻闂佸憡绋戦敃锔藉閸曨垱鈷戠憸鐗堝俯濡垿鏌涜箛鏃撹€跨€殿噮鍋婇獮妯兼嫚閸欏妫熼梻渚€娼ч悧鍡椢涘Δ鍜佹晜闁割偅娲橀埛鎴︽偣閹帒濡兼繛鍛姍閺岀喖宕欓妶鍡楊伓
    output  wire                   		cp0_we_o,
    output  wire [`REG_ADDR_BUS  ] 	    cp0_waddr_o,
    output  wire [`REG_BUS       ] 	    cp0_wdata_o

   	);
    // 闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柟鐗堟緲閸戠姴鈹戦悩瀹犲缂佺媭鍨堕弻锝夊箣閿濆憛鎾绘煛閸涱喗鍊愰柡宀嬬節瀹曟帒螣鐞涒€充壕闁哄稁鍋€閸嬫挸顫濋鍌溞ㄩ梺鍝勮嫰閹冲酣锝炲┑瀣殝闁割煈鍋呴鐔兼⒒娴ｈ銇熼柛娆忛叄瀹曟垿宕熼娑樺墾闁瑰吋鐣崹铏圭礊閸ヮ剚鐓熼柟浼存涧婢ь喗銇勮箛鎾跺煟婵﹨娅ｉ幑鍕Ω閵夛妇鈧箖姊洪崫鍕靛剰妞ゎ厾鍏橀悰顔跨疀濞戞瑥鈧鏌ら幁鎺戝姕婵炲懌鍨荤槐鎾存媴閻熸澘顫嶉梺缁橆殕缁孩绂嶉幖浣肝╅柍杞拌兌椤斿棛绱撴担鍓插剬闁哥喎绮疧闂傚倸鍊峰ù鍥р枖閺囥垹绐楃€广儱顦伴崵鎴﹀箹濞ｎ剙鐏紓宥呮喘閺岋綁骞囬棃娑橆潻濡炪倕绻愰悥鐓庮潖閾忚宕夐柕濞垮劜閻庨箖姊洪崫鍕靛剰妞ゎ厾鍏橀悰顔跨疀濞戞瑥鈧鏌ら幁鎺戝姕婵炲懌鍨藉娲传閸曨偀鍋撻崼鏇炵９闁哄稁鍋€閸嬫挸顫濋鍌溞ㄩ梺鍝勮閸旀垿骞冮姀銏″珰闁圭粯甯╁Λ婵嬫⒒娴ｈ櫣甯涢柤褰掔畺閹椽濡歌閸嬫挸顫濋悙顒€顏�
   	assign wb_wa_o      	=       wb_wa_i;
   	assign wb_wreg_o	    =       wb_wreg_i && mem_operation_ok;
   	assign wb_whilo_o   	=       wb_whilo_i && mem_operation_ok;
   	assign wb_hilo_o    	=       wb_hilo_i;
    assign wb_aluop_o    	=       wb_aluop_i;
    //闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柟鐗堟緲閸戠姴鈹戦悩瀹犲缂佺媭鍨堕弻锝夊箣閿濆憛鎾绘煛閸涱喗鍊愰柡宀嬬節瀹曟帒螣鐞涒€充壕闁哄稁鍋€閸嬫挸顫濋鍌溞ㄩ悗瑙勬礃缁矂顢橀崗鐓庣窞閻庯綆鍋呴鐔兼⒒娴ｅ憡鎯堥柛濠傜埣瀹曟劙寮介鐔蜂壕婵鍋撶€氾拷          
    assign wb2exe_whilo     =      wb_whilo_i && mem_operation_ok;
    assign wb2exe_hilo      =      wb_hilo_i;
    //闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柟鐗堟緲閸戠姴鈹戦悩瀹犲缂佺媭鍨堕弻锝夊箣閿濆憛鎾绘煛閸涱喗鍊愰柡宀嬬節瀹曟帒螣鐞涒€充壕闁哄稁鍋€閸嬫挸顫濋鍌溞ㄩ悗瑙勬礃缁矂顢橀崗鐓庣窞閻庯綆鍋呴鐔兼⒒娴ｅ憡鎯堥柛濠傜埣瀹曟劙寮介鐔蜂壕婵鍋撶€氾拷(闂傚倸鍊峰ù鍥р枖閺囥垹绐楅幖娣妽閸庢垿鏌涢幘妤€瀚▓浼存⒑瑜版帗锛熼柣鎺炵畵瀵煡骞栨担鍦幐闂佺ǹ鏈敋闁逞屽墯閻楁粓鍩€椤掍浇澹樼紓宥咃躬瀵濡搁埡鍌氫簻闂佸憡绋戦敃锔藉閸曨垱鈷戦柣鐔告緲濞堚晠鏌熼崙銈嗗)          
    assign wb2mem_cp0_we    =      cp0_we_i && mem_operation_ok;
    assign wb2mem_cp0_wa    =      cp0_waddr_i;
    assign wb2mem_cp0_wd    =      cp0_wdata_i;
    assign wb2exe_cp0_we    =      cp0_we_i && mem_operation_ok;
    assign wb2exe_cp0_wa    =      cp0_waddr_i;
    assign wb2exe_cp0_wd    =      cp0_wdata_i;
    //闂傚倷鑳堕崕鐢稿疾濠婂牆绠伴柟鎯版閺嬩線鏌熼幑鎰靛殭婵☆偅锕㈤弻鏇㈠醇濠靛浂妫炲銈呯箰閻栫厧顫忛搹瑙勫磯闁靛ǹ鍎查悗楣冩⒑閸濆嫷鍎忔い顓犲厴閻涱喛绠涘☉娆忊偓濠氭煠閹帒鍔滄繛鍛灲濮婃椽宕崟顐熷亾閸洖纾归柡宥庡亐閸嬫挸顫濇鏍уΨp0闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柟鐗堟緲閸戠姴鈹戦悩瀹犲缂佺媭鍨堕弻锝夊箣閿濆憛鎾绘煛閸涱喗鍊愰柡宀嬬節瀹曟帒螣鐞涒€充壕闁哄稁鍋€閸嬫挸顫濋鍌溞ㄩ梺鍝勮閸旀垿骞冮姀銈呭窛濠电姴瀚槐鏇㈡⒒娴ｇ儤鍤€闁搞倖鐗犻獮蹇涙晸閿燂拷 
    assign cp0_we_o     	=      cp0_we_i && mem_operation_ok;
    assign cp0_waddr_o    	=      cp0_waddr_i;
    assign cp0_wdata_o    	=      cp0_wdata_i;

    wire unsign =  (wb_aluop_i == `MINIMIPS32_LBU)|(wb_aluop_i == `MINIMIPS32_LHU);

    // 闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柟鐗堟緲閸戠姴鈹戦悩瀹犲缂佺媭鍨堕弻锝夊箣閿濆憛鎾绘煛閸涱喗鍊愰柡宀€鍠栧畷鐑筋敇閻斿搫濮芥俊鐐€栧褰掑礉濞嗘挾宓侀煫鍥ㄧ⊕閸婂鏌ら幁鎺戝姕婵炲懌鍨介弻锝夋倷鐎电硶濮囧銈冨妼濡繂顕ｉ崨濠勭瘈婵﹩鍓涢鍡涙⒑閻愵剝澹橀柛濠冩倐閸┿垼绠涘☉娆屾嫼闁荤姵浜介崝宀勫几閹达附鐓涢悗锝庝憾閻撳吋顨ラ悙鑼闁诡喗绮撻幊鐐哄Ψ閿旂瓔浠ч梻鍌欒兌閸樠囨偤閵娾晜鍤岄柟瑙勫姂娴滃綊鏌涜椤ㄥ棝寮查弻銉у彄闁搞儯鍔嶉悡銉︺亜韫囨挾鍩ｆ慨濠呮閹瑰嫰濡搁妷锔锯偓楣冩⒑閸濆嫷鍎忔い顓犲厴閻涱喛绠涘☉娆忊偓濠氭煠閹帒鍔滄繛鍛灲濮婃椽宕崟顐熷亾閸洖纾归柡宥庡亐閸嬫挸顫濋鍌溞ㄩ梺鍝勮閸旀垿骞冮姀銏㈢煓閻犳亽鍔婇崑锝夋⒑鐠囨彃顒㈢紒瀣浮閺佸姊虹粙娆惧剰缂佸缍婂濠氬Ω閳哄倸浜滈梺鍛婄☉閿曪附瀵奸崟顖涒拺鐟滅増甯╁Λ鎴︽煕韫囨棑鑰跨€殿噮鍋婇獮妯兼嫚閸欏妫熼梻渚€娼ч悧鍡椢涘Δ鍜佹晜闁割偅娲橀埛鎴︽偣閹帒濡奸柡瀣灴閺岋紕鈧綆浜堕悡鍏碱殽閻愯尙绠婚柟顔界矒閹崇偤濡烽敂绛嬩户闂傚倷绀侀幖顐﹀磹閸洖纾归柡宥庡亐閸嬫挸顫濋鍌溞ㄩ梺鍝勮閸旀垿骞冮姀銈呭窛濠电姴瀚槐鏇㈡⒒娴ｅ摜绉烘い銉︽崌瀹曟顫滈埀顒€顕ｉ锕€绠婚悹鍥у级椤ユ繈姊洪棃娑氬婵☆偅顨婇、鏃堝醇閺囩啿鎷洪柣鐘充航閸斿矂寮搁幋锔界厸閻庯綆浜堕悡鍏碱殽閻愯尙绠婚柟顔界矌閹叉挳鏁愰崨顒€顥氬┑鐘灱閸╂牠宕濋弽顓炵柧闁归棿鐒﹂悡娑㈡煕鐏炰箙顏堝焵椤掍胶澧遍柍褜鍓氶懝鍓х礊婵犲洤钃熼柕濞炬櫆閸嬪嫮绱掔€ｎ亞浠㈡い锔界叀濮婃椽骞愭惔銏㈠弳闂佸憡鑹鹃鍥焵椤掍浇澹樼紓宥咃躬瀵濡搁埡鍌氫簻闂佸憡绋戦敃锔藉閸曨垱鈷戦柛锔诲幖閸樺瓨銇勯妷锔藉磳闁诡喚鍋炵换婵嬪炊閵娧冨汲闂備胶绮ú鏍磹閸︻厸鍋撳鐐
   	wire [`WORD_BUS] data  = 
                             (wb_dre_i  == 4'b1111)             ?   dm                        :
                             ((wb_dre_i == 4'b1100) & unsign )  ?   {16'b0, dm[31:16]}        :
                             ((wb_dre_i == 4'b0011) & unsign )  ?   {16'b0, dm[15:0]}         :
                             ((wb_dre_i == 4'b1000) & unsign )  ?   {24'b0, dm[31:24]}        :
                             ((wb_dre_i == 4'b0100) & unsign )  ?   {24'b0, dm[23:16]}        :
                             ((wb_dre_i == 4'b0010) & unsign )  ?   {24'b0, dm[15:8 ]}        :
                             ((wb_dre_i == 4'b0001) & unsign )  ?   {24'b0, dm[7 :0 ]}        :
                             (wb_dre_i  == 4'b1100)             ?   {{16{dm[31]}},dm[31:16]}  :
                             (wb_dre_i  == 4'b0011)             ?   {{16{dm[15]}},dm[15:0]}   :
                             (wb_dre_i  == 4'b1000)             ?   {{24{dm[31]}}, dm[31:24]} :
                             (wb_dre_i  == 4'b0100)             ?   {{24{dm[23]}}, dm[23:16]} :
                             (wb_dre_i  == 4'b0010)             ?   {{24{dm[15]}}, dm[15:8 ]} :
                             (wb_dre_i  == 4'b0001)             ?   {{24{dm[7 ]}}, dm[7 :0 ]} : `ZERO_WORD;
                    
                    
    // 闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柟鐗堟緲閸戠姴鈹戦悩瀹犲缂佺媭鍨堕弻锝夊箣閿濆憛鎾绘煛閸涱喗鍊愰柡宀€鍠栭幃鐑藉级閹稿巩鈺呮⒑鐎癸附婢樻慨鍌溾偓瑙勬礃鐢剝淇婇幖浣哥厸闁稿本绋掗鐔兼⒒娴ｅ憡鎯堥柛濠傜埣瀹曟劙寮介鐔蜂壕婵﹩鍓涚粔娲煛鐏炶濮傞柟顔哄灲瀹曘劍绻濋崟顏嗙？闂傚倷绀佺紞濠囁夐幘璇茬婵せ鍋撶€殿噮鍋婇獮妯尖偓闈涙憸閹虫繈姊洪棃娑辨Ф闁告柨绉烽妵鎰樄闁哄瞼鍠愰ˇ鐗堟償閳ュ啿绠ｉ梻浣芥〃閻掞箓骞戦崶褜鍤曟い鎺戝鍥撮梺绯曞墲椤ㄥ繑瀵奸幘瀵哥閺夊牆澧介崚鐗堢箾绾绡€鐎殿噮鍋婇獮妯兼嫚閸欏妫熼梻渚€娼ч悧鍡椢涘Δ鍜佹晜闁割偅娲橀埛鎴︽偣閹帒濡奸柡瀣懇閺屾盯骞橀悙钘変划闂佽鍣崰姘跺焵椤掍胶鈯曢柨姘亜韫囨洦娼漴eg闂傚倸鍊峰ù鍥р枖閺囥垹绐楅柟鐗堟緲閸戠姴鈹戦悩瀹犲缂佺媭鍨堕弻锝夊箣閿涚増甯″畷鎴﹀箻閺夋垹绐為梺褰掑亰閸樿棄鈻嶉姀銈嗏拺闁告繂瀚埀顒€鐖煎畷鎰板冀椤愮喎浜炬慨姗嗗墰缁夋椽鏌＄仦璇插闁诡喓鍨藉畷銊︾節閸曨亞纾块梻鍌欑缂嶅﹪藟閹捐绀傛慨妞诲亾鐎殿噮鍋婇獮姗€宕滄担铏瑰帬婵犳鍠楃换鍌炲嫉椤掑啨浜圭憸鏃堝蓟閻旈鏆嬮柡澶嬪浜涢梻浣告憸閸犳劙骞戦崶顒€钃熼柕濞炬櫆閸嬪嫰鏌涘☉姗堝姛濞寸厧瀚板楦裤亹閹烘繃顥栭梺绋跨箲閿曘垽宕洪埀顒併亜閹哄秶顦﹂柛婵囨そ閺屸剝鎷呯憴鍕３闂佽鍨伴惌鍌炪€侀弴銏狀潊闁靛繆妲呭鐘绘⒑閸濆嫷妲搁柣妤€绻樺畷鎴﹀箻閸ㄦ稑浜炬慨姗嗗墰缁夋椽鏌＄仦璇插闁诡喓鍨藉畷銊︾節閸曨亞纾块梻鍌欑缂嶅﹪藟閹捐绀傛慨妞诲亾鐎殿噮鍋婇獮妯兼嫚閸欏妫熼梻渚€娼ч悧鍡椢涘Δ鍜佹晜闁割偅娲橀埛鎴︽偣閹帒濡奸柡瀣灴閺岋紕鈧綆浜堕悡鍏碱殽閻愯尙绠婚柟顔界矒閹崇偤濡烽敂绛嬩户闂傚倷绀侀幖顐﹀磹閸洖纾归柡宥庡亐閸嬫挸顫濋悙顒€顏�
   	assign wb_wd_o = 
                    (wb_mreg_i == `MREG_ENABLE) ? data : wb_dreg_i;

endmodule
