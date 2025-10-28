`timescale 1ns/1ps

module RV32I_pipelined_tb;

    // Testbench signals
    logic clk;
    logic rst_n;   // active-low reset

    // AHB interface signals
    logic [31:0] PRDATA_A;
    logic        PREADY_A;
    logic        PRESP_A;
    logic [31:0] PADDR_A;
    logic        PWRITE_A;
    logic [1:0]  PSIZE_A;
    logic [1:0]  PTRANS_A;
    logic [2:0]  PBURST_A;
    logic [31:0] PWDATA_A;

    // DUT outputs (example, adjust based on your DUT ports)
    logic [31:0] PC_next;

    // DUT instantiation
    RV32I_pipelined dut (
        .clk      (clk),
        .rst_n    (rst_n),
        // AHB interface connections
        .PRDATA_A (PRDATA_A),
        .PREADY_A (PREADY_A),
        .PRESP_A  (PRESP_A),
        .PADDR_A  (PADDR_A),
        .PWRITE_A (PWRITE_A),
        .PSIZE_A  (PSIZE_A),
        .PTRANS_A (PTRANS_A),
        .PBURST_A (PBURST_A),
        .PWDATA_A (PWDATA_A)
    );

    // Clock generation (100 MHz -> 10 ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // toggle every 5ns
    end

    // Reset & stimulus
    initial begin
        // Initialize AHB inputs
        PRDATA_A = 32'h00000000;
        PREADY_A = 1'b1;    // ready by default
        PRESP_A  = 1'b0;    // no error

        // Apply reset
        rst_n = 0;   // assert reset low
        #20;
        rst_n = 1;   // release reset

        // Example stimulus: mimic AHB slave returning data
        #50  PRDATA_A = 32'hDEADBEEF;  // when core tries to read
        #100 PRDATA_A = 32'h12345678;

        // Run for some time
        #500;
        $stop;
    end

endmodule
