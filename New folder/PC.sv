//PC (Program counter)
`timescale 1ns/1ps
module Program_counter(clk,rst,PC_next,en_n,PC);

input bit clk,rst;
input bit en_n; //enable signal to load the next value
input bit [31:0] PC_next;
output bit [31:0] PC;

    always @(posedge clk) begin
        if (~rst) //synchronous active low
            PC <= 0;
        else if(~en_n)
            PC <= PC_next;
    end
endmodule
