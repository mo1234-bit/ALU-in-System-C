// Write_back_register - standardized reset as rst_n, always_ff style
`timescale 1ns/1ps
module Write_back_register(
    input  logic        clk,
    input  logic        rst_n,       // active-low sync reset
    // Inputs from Memory stage (M)
    input  logic        RegWriteM,
    input  logic [1:0]  ResultSrcM,
    input  logic [31:0] ALUResultM,
    input  logic [31:0] ReadDataM,
    input  logic [4:0]  RdM,
    input  logic [31:0] PC_plus4M, 

    // Outputs to Write-back stage (W)
    output logic        RegWriteW,
    output logic [1:0]  ResultSrcW,
    output logic [31:0] ALUResultW,
    output logic [31:0] ReadDataW,
    output logic [4:0]  RdW,
    output logic [31:0] PC_plus4W, 
    
    // AHB signals
    input  logic        AHB_en,
    input  logic [31:0] ReadData_AHB,
    output logic        AHB_en_rf,
    output logic [31:0] ReadData_AHB_rf,
    output logic [4:0]  AHB_address_write_rf  
    
);

    logic [4:0] AHB_A_rf  [1:0];
    logic AHB_en_reg;
    logic AHB_en_reg1;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            RegWriteW       <= 1'b0;
            ResultSrcW      <= 2'b00;
            ALUResultW      <= 32'b0;
            ReadDataW       <= 32'b0;
            RdW             <= 5'b0;
            PC_plus4W       <= 32'b0;
            ReadData_AHB_rf <= 32'b0;
            AHB_en_reg      <= 1'b0;
            AHB_en_reg1     <= 1'b0;
            AHB_en_rf       <= 1'b0;  
            AHB_A_rf [1]    <= 5'b0;
            AHB_A_rf [0]    <= 5'b0;
        end
        else begin
            RegWriteW       <= RegWriteM;
            ResultSrcW      <= ResultSrcM;
            ALUResultW      <= ALUResultM;
            ReadDataW       <= ReadDataM;
            RdW             <= RdM;
            PC_plus4W       <= PC_plus4M;
            ReadData_AHB_rf <= ReadData_AHB;
            AHB_en_reg      <= AHB_en;
            AHB_en_reg1     <= AHB_en_reg;
            AHB_en_rf       <= AHB_en_reg1;  
            AHB_A_rf [1]    <= AHB_A_rf [0];
            AHB_A_rf [0]    <= RdW;
        end
    end

assign AHB_address_write_rf = AHB_A_rf [1];

endmodule
