// Memory_register - standardized reset as rst_n, always_ff style
`timescale 1ns/1ps
module Memory_register(
    input  logic        clk,
    input  logic        rst_n,    // active-low sync reset
    input  logic        MemWriteE,
    input  logic        RegWriteE,
    input  logic [1:0]  ResultSrcE,
    input  logic [31:0] ALUResult,
    input  logic [31:0] WriteData,
    input  logic [4:0]  RdE,
    input  logic [31:0] PC_plus4E,
    output logic        MemWriteM,
    output logic        RegWriteM,
    output logic [1:0]  ResultSrcM,
    output logic [31:0] ALUResultM,
    output logic [31:0] WriteDataM,
    output logic [31:0] PC_plus4M,
    output logic [4:0]  RdM
);
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            MemWriteM   <= 1'b0;
            RegWriteM   <= 1'b0;
            ResultSrcM  <= 2'b00;
            ALUResultM  <= 32'b0;
            WriteDataM  <= 32'b0;
            PC_plus4M   <= 32'b0;
            RdM         <= 5'b0;
        end
        else begin
            MemWriteM   <= MemWriteE;
            RegWriteM   <= RegWriteE;
            ResultSrcM  <= ResultSrcE;
            ALUResultM  <= ALUResult;
            WriteDataM  <= WriteData;
            PC_plus4M   <= PC_plus4E;
            RdM         <= RdE;
        end
    end
endmodule
