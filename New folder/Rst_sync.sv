`timescale 1ns/1ps

module Rst_sync (
    input  logic clk,
    input  logic async_rst_n,  // Asynchronous external reset (active low)
    output logic sync_rst_n    // Synchronized reset (active low)
);

    logic Q1;

    always_ff @(posedge clk, negedge async_rst_n) begin
        if (!async_rst_n) begin
            Q1         <= 0;
            sync_rst_n <= 0;
        end
        else begin
            Q1         <= 1;
            sync_rst_n <= Q1;
        end
    end
endmodule
