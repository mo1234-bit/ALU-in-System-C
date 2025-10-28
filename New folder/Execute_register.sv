// Execute_register - standardized reset as rst_n, always_ff style
`timescale 1ns/1ps
module Execute_register(
    input  logic        clk,
    input  logic        rst_n,     // active-low sync reset
    input  logic        clr,       // synchronous clear (flush)
    input  logic        MemWrite,
    input  logic        RegWrite,
    input  logic        ALUSrc,
    input  logic        Jump,
    input  logic        Branch,
    input  logic [1:0]  ResultSrc,
    input  logic [2:0]  ALUControl,
    input  logic [31:0] RD1,
    input  logic [31:0] RD2,
    input  logic [31:0] InstrD,
    input  logic [31:0] PCD,
    input  logic [31:0] PC_plus4D,
    input  logic [31:0] ImmExt,
    output logic        MemWriteE,
    output logic        RegWriteE,
    output logic        ALUSrcE,
    output logic        JumpE,
    output logic        BranchE,
    output logic [1:0]  ResultSrcE,
    output logic [2:0]  ALUControlE,
    output logic [31:0] RD1E,
    output logic [31:0] RD2E,
    output logic [31:0] PCE,
    output logic [31:0] PC_plus4E,
    output logic [31:0] ImmExtE,
    output logic [4:0]  RS1E,
    output logic [4:0]  RS2E,
    output logic [4:0]  RdE
);
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n | clr) begin
            MemWriteE   <= 1'b0;
            RegWriteE   <= 1'b0;
            ALUSrcE     <= 1'b0;
            JumpE       <= 1'b0;
            BranchE     <= 1'b0;
            ResultSrcE  <= 2'b00;
            ALUControlE <= 3'b000;
            RD1E        <= 32'b0;
            RD2E        <= 32'b0;
            PCE         <= 32'b0;
            PC_plus4E   <= 32'b0;
            ImmExtE     <= 32'b0;
            RS1E        <= 5'b0;
            RS2E        <= 5'b0;
            RdE         <= 5'b0;
        end
        else begin
            // normal pipeline capture (when not flushed)
            MemWriteE   <= MemWrite;
            RegWriteE   <= RegWrite;
            ALUSrcE     <= ALUSrc;
            JumpE       <= Jump;
            BranchE     <= Branch;
            ResultSrcE  <= ResultSrc;
            ALUControlE <= ALUControl;
            RD1E        <= RD1;
            RD2E        <= RD2;
            PCE         <= PCD;
            PC_plus4E   <= PC_plus4D;
            ImmExtE     <= ImmExt;
            RS1E        <= InstrD[19:15];
            RS2E        <= InstrD[24:20];
            RdE         <= InstrD[11:7];
        end
    end

endmodule
