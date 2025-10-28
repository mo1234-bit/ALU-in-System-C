`timescale 1ns/1ps

module Multiplexor_2to1(
    input  logic in1,      // First input
    input  logic in2,      // Second input
    input  logic sel,      // Select line
    output logic mux_out   // Output of the mux
);

    // If sel = 1, output in2; else output in1
    assign mux_out = (sel) ? in2 : in1;

endmodule
