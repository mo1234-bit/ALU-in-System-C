// Decode_register - standardized reset as rst_n, always_ff style
`timescale 1ns/1ps
module Decode_register(
    input  logic        clk,
    input  logic        rst_n,    // active-low sync reset
    input  logic        en_n,     // active-low enable (stall)
    input  logic        clr,      // synchronous clear (flush)
    input  logic [31:0] Instr,
    input  logic [31:0] PC,
    input  logic [31:0] PC_plus4,
    output logic [31:0] InstrD,
    output logic [31:0] PCD,
    output logic [31:0] PC_plus4D
);
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n | clr) begin
            InstrD    <= 32'b0;
            PCD       <= 32'b0;
            PC_plus4D <= 32'b0;
        end
        else if (!en_n) begin
                // capture when not stalled
                InstrD    <= Instr;
                PCD       <= PC;
                PC_plus4D <= PC_plus4;
            end
            // else hold (stall)
        end
endmodule
