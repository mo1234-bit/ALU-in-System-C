// Generic 3-to-1 Multiplexer
`timescale 1ns/1ps
module Mux_3to1 (in0, in1, in2, sel, out);

    localparam WIDTH = 32;

    input  logic [WIDTH-1:0] in0;     // case 00
    input  logic [WIDTH-1:0] in1;     // case 01
    input  logic [WIDTH-1:0] in2;     // case 10
    input  logic [1:0]       sel;     // select line
    output logic [WIDTH-1:0] out;      // result

    always_comb begin
        case (sel)
            2'b00: out = in0;
            2'b01: out = in1;
            2'b10: out = in2;
            default: out = '0;
        endcase
    end
endmodule
