`timescale 1ns/1ps
module Hazard_unit (
    input  logic [31:0] InstrD,      // Instruction in Decode stage
    input  logic [4:0]  RdE,         // Destination reg from Execute stage
    input  logic [4:0]  Rs1E,        // Source reg1 from Execute stage
    input  logic [4:0]  Rs2E,        // Source reg2 from Execute stage
    input  logic        PCSrcE,      // PC source control from Execute stage
    input  logic [1:0]  ResultSrcE,  // Result source in Execute stage
    input  logic [4:0]  RdM,         // Destination reg from Memory stage
    input  logic        RegWriteM,   // Write enable from Memory stage
    input  logic [4:0]  RdW,         // Destination reg from Writeback stage
    input  logic        RegWriteW,   // Write enable from Writeback stage

    output logic        StallF,      // Stall Fetch stage
    output logic        StallD,      // Stall Decode stage
    output logic        FlushD,      // Flush Decode stage
    output logic        FlushE,      // Flush Execute stage
    output logic [1:0]  ForwardAE,   // Forwarding select for source A
    output logic [1:0]  ForwardBE    // Forwarding select for source B
);

    // Forwarding logic
    always_comb begin : ForwardAE_operation
        if ((Rs1E == RdM) && RegWriteM && (Rs1E != 0))
            ForwardAE = 2'b10;      // Forward from MEM
        else if ((Rs1E == RdW) && RegWriteW && (Rs1E != 0))
            ForwardAE = 2'b01;      // Forward from WB
        else
            ForwardAE = 2'b00;      // No forward
    end

    always_comb begin : ForwardBE_operation
        if ((Rs2E == RdM) && RegWriteM && (Rs2E != 0))
            ForwardBE = 2'b10;      // Forward from MEM
        else if ((Rs2E == RdW) && RegWriteW && (Rs2E != 0))
            ForwardBE = 2'b01;      // Forward from WB
        else
            ForwardBE = 2'b00;      // No forward
    end

    // Load-use hazard detection
    logic lwstall;
    assign lwstall = (ResultSrcE == 2'b01) && 
                     ((InstrD[19:15] == RdE) || (InstrD[24:20] == RdE));

    // Stall signals
    assign StallF = lwstall;
    assign StallD = lwstall;

    // Flush signals
    assign FlushD = PCSrcE;
    assign FlushE = lwstall | PCSrcE;

endmodule
