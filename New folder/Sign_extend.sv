//sign_extend Module
`timescale 1ns/1ps
module Sign_extend(Instr,Immsrc,ImmExt);

input bit[1:0] Immsrc;
input bit[31:7] Instr;
output bit[31:0] ImmExt;

always_comb begin

    case (Immsrc)
        2'b00: ImmExt = {{20{Instr[31]}}, Instr[31:20]};                                   //I-immediate
        2'b01: ImmExt = {{20{Instr[31]}}, Instr[31:25], Instr[11:7]};                      //S-immediate 
        2'b10: ImmExt = {{20{Instr[31]}}, Instr[7], Instr[30:25], Instr[11:8], 1'b0};      //B-immediate   
        2'b11: ImmExt = {{12{Instr[31]}}, Instr[19:12], Instr[20], Instr[30:21], 1'b0};    //J-immediate
        default:   ImmExt = 0;                                                                 //Default
    endcase  
end
endmodule
