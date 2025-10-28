//Register file of WIDTH =32 bits  & Depth = 2^[A3 width] = 32 location
`timescale 1ns/1ps
module Reg_file(clk,rst_n,WE3,A1,A2,A3,AHB_en_rf,AHB_address_write_rf,ReadData_AHB_rf,WD3,flag,RD1,RD2);

input bit clk,rst_n,WE3;
input bit[4:0] A1,A2,A3;
input bit[31:0] WD3;
input bit       flag;
output bit[31:0] RD1,RD2;

// AHB read signals
input logic        AHB_en_rf;
input logic [4:0]  AHB_address_write_rf;
input logic [31:0] ReadData_AHB_rf;

//Declare all registers and initializing
logic [31:0] Registers [31:0];

initial $readmemh("Register_file_init.dat",Registers);
               
//Sequential Write
always @(negedge clk) begin                        // Write operation
    if(AHB_address_write_rf == A3) begin           // Give priority to the AHB bus as thats the project scope rather than the RV32I
        if (AHB_en_rf)                    
            Registers[AHB_address_write_rf] <= ReadData_AHB_rf;                      
    end else begin
        if (WE3 && (flag == 0))                                   // Give priority to the AHB bus as thats the project scope rather than the RV32I 
            Registers[A3] <= WD3;                           // Do the write operation if the Write enable is high but don't write in zero register
    
        if(AHB_en_rf)
            Registers [AHB_address_write_rf] <= ReadData_AHB_rf;
    end
end

//Combinational Read                              // Two read operation from the addresses A1, A2 if they not equal to zero
assign  RD1 = (rst_n)? Registers[A1]: '0;
assign  RD2 = (rst_n)? Registers[A2]: '0; 
endmodule