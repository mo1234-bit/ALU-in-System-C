`timescale 1ns/1ps

module Decoder(
    input [31:0]    HADDR_A,
    input [31:0]    HADDR_B,
    output          HSEL_G_A,
    output          HSEL_T_A,
    output          HSEL_R_A,
    output          HSEL_G_B,
    output          HSEL_T_B,
    output          HSEL_R_B
);

// Address decode logic for slave selection from master A
assign HSEL_G_A = (HADDR_A[31:28] == 4'b0000);  //(32'h0000_0000 -> 32'h0FFF_FFFF)
assign HSEL_T_A = (HADDR_A[31:28] == 4'b0001);  //(32'h1000_0000 -> 32'h1FFF_FFFF)
assign HSEL_R_A = (HADDR_A[31:28] == 4'b0010);  //(32'h2000_0000 -> 32'h2FFF_FFFF)

// Address decode logic for slave selection from master B
assign HSEL_G_B = (HADDR_B[31:28] == 4'b0000);  //(32'h0000_0000 -> 32'h0FFF_FFFF)
assign HSEL_T_B = (HADDR_B[31:28] == 4'b0001);  //(32'h1000_0000 -> 32'h1FFF_FFFF)
assign HSEL_R_B = (HADDR_B[31:28] == 4'b0010);  //(32'h2000_0000 -> 32'h2FFF_FFFF)
endmodule