`include "defines.v"

module scu (
    
    input  wire              stallreq_id,
    input  wire              stallreq_exe,
    //new
    input  wire              stallreq_if,
    input  wire              stallreq_mem,
    //new
    output wire [`STALL_BUS] stall
);

    // assign stall = (cpu_rst_n == `RST_ENABLE) ? 4'b0000 :
    //                (stallreq_exe == `STOP   ) ? 4'b1111 :
    //                (stallreq_id  == `STOP   ) ? 4'b0111 : 4'b0000;
    //new
    assign stall = 
                   (stallreq_mem == `STOP   ) ? 6'b011111 :
                   (stallreq_exe == `STOP   ) ? 6'b001111 :
                   (stallreq_id  == `STOP   ) ? 6'b000111 :
                   (stallreq_if  == `STOP   ) ? 6'b000111 : 6'b000000;
    //new
    
endmodule
