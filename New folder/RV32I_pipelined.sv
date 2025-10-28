// RISCV32I Pipelined Processor
`timescale 1ns/1ps
module RV32I_pipelined(
    input  logic clk,
    input  logic rst_n,             // active-low reset
    input  logic [31:0] PRDATA_A,
    input  logic        PREADY_A,
    input  logic        PRESP_A,
    output logic [31:0] PADDR_A,
    output logic        PWRITE_A,
    output logic [1:0]  PSIZE_A,
    output logic [1:0]  PTRANS_A,
    output logic [2:0]  PBURST_A,
    output logic [31:0] PWDATA_A
);
    
    logic [31:0] PC_next;
    logic flag;

    // Pipeline control signals
    logic StallF, StallD, FlushD, FlushE;
    logic [1:0] ForwardAE, ForwardBE;

    // Fetch stage signals
    logic [31:0] InstrF, PCF, PCPlus4F;

    // Decode stage signals
    logic RegWriteD, MemWriteD, ALUSrcD, JumpD, BranchD;
    logic [1:0] ResultSrcD, ImmSrcD;
    logic [2:0] ALUControlD;
    logic [31:0] InstrD, PCD, PCPlus4D, RD1D, RD2D, ImmExtD;

    // Execute stage signals
    logic RegWriteE, MemWriteE, ALUSrcE, JumpE, BranchE, ZeroE;
    logic [1:0] ResultSrcE;
    logic [2:0] ALUControlE;
    logic [4:0] RS1E, RS2E, RdE;
    logic [31:0] RD1E, RD2E, PCE, PCPlus4E, ImmExtE, PCTarget;
    logic [31:0] SrcAE, SrcBE, ALUResultE, WriteDataE;
    logic PCSrcE;

    // Memory stage signals
    logic AHB_read_en_DM;
    logic [31:0] ReadData_AHB_DM;
    logic RegWriteM, MemWriteM;
    logic [1:0] ResultSrcM;
    logic [4:0] RdM;
    logic [31:0] ALUResultM, WriteDataM, PCPlus4M, ReadDataM;

    // Writeback stage signals
    logic RegWriteW;
    logic [1:0] ResultSrcW;
    logic [4:0] RdW;
    logic [31:0] ALUResultW, ReadDataW, PCPlus4W, ResultW;
    logic AHB_read_en;
    logic [31:0] ReadData_AHB;
    logic [4:0]  AHB_address_write_rf;

    // Hazard Unit
    Hazard_unit hazard_unit(
        .InstrD(InstrD),
        .RdE(RdE),
        .Rs1E(RS1E),
        .Rs2E(RS2E),
        .PCSrcE(PCSrcE),
        .ResultSrcE(ResultSrcE),
        .RdM(RdM),
        .RegWriteM(RegWriteM),
        .RdW(RdW),
        .RegWriteW(RegWriteW),
        .StallF(StallF),
        .StallD(StallD),
        .FlushD(FlushD),
        .FlushE(FlushE),
        .ForwardAE(ForwardAE),
        .ForwardBE(ForwardBE)
    );

    // Fetch Stage
    Mux_2to1 pc_mux(
        .A(PCPlus4F),
        .B(PCTarget), 
        .SEL(PCSrcE),
        .Y(PC_next)
    );

    Program_counter program_counter(
        .clk(clk),
        .rst(rst_n),
        .PC_next(PC_next),
        .en_n(StallF),
        .PC(PCF)
    );

    PC_increment pc_increment(
        .pc(PCF),
        .pcPlus4(PCPlus4F)
    );

    instruction_mem instruction_memory(
        .clk(0),
        .A(PCF),
        .we(0), // always read
        .data(0),
        .Instr(InstrF)
    );

    // Decode Stage
    Decode_register decode_reg(
        .clk(clk),
        .rst_n(rst_n),
        .en_n(StallD),
        .clr(FlushD),
        .Instr(InstrF),
        .PC(PCF),
        .PC_plus4(PCPlus4F),
        .InstrD(InstrD),
        .PCD(PCD),
        .PC_plus4D(PCPlus4D)
    );

    Control_Unit control_unit(
        .op(InstrD[6:0]),
        .funct3(InstrD[14:12]),
        .funct7(InstrD[30]),
        .MemWrite(MemWriteD),
        .ALUSrc(ALUSrcD),
        .RegWrite(RegWriteD),
        .Jump(JumpD),
        .Branch(BranchD),
        .ImmSrc(ImmSrcD),
        .ResultSrc(ResultSrcD),
        .ALUControl(ALUControlD)
    );

    Reg_file register_file(
        .clk(clk),
        .rst_n(rst_n),
        .WE3(RegWriteW),
        .A1(InstrD[19:15]),
        .A2(InstrD[24:20]),
        .A3(RdW),
        .AHB_en_rf(AHB_read_en),
        .AHB_address_write_rf(AHB_address_write_rf),
        .ReadData_AHB_rf(ReadData_AHB),
        .flag(flag),
        .WD3(ResultW),
        .RD1(RD1D),
        .RD2(RD2D)
    );

    Sign_extend sign_extend(
        .Instr(InstrD[31:7]),
        .Immsrc(ImmSrcD),
        .ImmExt(ImmExtD)
    );

    // Execute Stage
    Execute_register execute_reg(
        .clk(clk),
        .rst_n(rst_n),
        .clr(FlushE),
        .MemWrite(MemWriteD),
        .RegWrite(RegWriteD),
        .ALUSrc(ALUSrcD),
        .Jump(JumpD),
        .Branch(BranchD),
        .ResultSrc(ResultSrcD),
        .ALUControl(ALUControlD),
        .RD1(RD1D),
        .RD2(RD2D),
        .InstrD(InstrD),
        .PCD(PCD),
        .PC_plus4D(PCPlus4D),
        .ImmExt(ImmExtD),
        .MemWriteE(MemWriteE),
        .RegWriteE(RegWriteE),
        .ALUSrcE(ALUSrcE),
        .JumpE(JumpE),
        .BranchE(BranchE),
        .ResultSrcE(ResultSrcE),
        .ALUControlE(ALUControlE),
        .RD1E(RD1E),
        .RD2E(RD2E),
        .PCE(PCE),
        .PC_plus4E(PCPlus4E),
        .ImmExtE(ImmExtE),
        .RS1E(RS1E),
        .RS2E(RS2E),
        .RdE(RdE)
    );

    // Forwarding muxes (generic 3-to-1)
    Mux_3to1 muxA (
        .in0(RD1E),
        .in1(ResultW),
        .in2(ALUResultM),
        .sel(ForwardAE),
        .out(SrcAE)
    );

    Mux_3to1 muxB (
        .in0(RD2E),
        .in1(ResultW),
        .in2(ALUResultM),
        .sel(ForwardBE),
        .out(WriteDataE)
    );

    Mux_2to1 alu_src_mux(
        .A(WriteDataE),
        .B(ImmExtE),
        .SEL(ALUSrcE),
        .Y(SrcBE)
    );

    ALU alu(
        .SrcA(SrcAE),
        .SrcB(SrcBE),
        .ALUControl(ALUControlE),
        .ALUResult(ALUResultE),
        .Zero(ZeroE)
    );

    PC_Adder pc_adder(
        .PC(PCE),
        .ImmExt(ImmExtE),
        .PCTarget(PCTarget) // ALU used to calculate branch target
    );

    // Memory Stage
    Memory_register memory_reg(
        .clk(clk),
        .rst_n(rst_n),
        .MemWriteE(MemWriteE),
        .RegWriteE(RegWriteE),
        .ResultSrcE(ResultSrcE),
        .ALUResult(ALUResultE),
        .WriteData(WriteDataE),
        .RdE(RdE),
        .PC_plus4E(PCPlus4E),
        .MemWriteM(MemWriteM),
        .RegWriteM(RegWriteM),
        .ResultSrcM(ResultSrcM),
        .ALUResultM(ALUResultM),
        .WriteDataM(WriteDataM),
        .PC_plus4M(PCPlus4M),
        .RdM(RdM)
    );

    Data_Mem data_memory(
        .clk(clk),
        .rst(rst_n),
        .WE(MemWriteM),
        .WriteData(WriteDataM),
        .A(ALUResultM),
        .ReadData(ReadDataM),
        .PRDATA_A(PRDATA_A),
        .PREADY_A (PREADY_A),
        .PRESP_A (PRESP_A),
        .AHB_en(AHB_read_en_DM),
        .flag(flag),
        .ReadData_AHB(ReadData_AHB_DM),
        .PADDR_A (PADDR_A),
        .PWRITE_A (PWRITE_A),
        .PSIZE_A (PSIZE_A),
        .PTRANS_A (PTRANS_A),
        .PBURST_A (PBURST_A),
        .PWDATA_A (PWDATA_A)
    );    

    // Writeback Stage
    Write_back_register writeback_reg(
        .clk(clk),
        .rst_n(rst_n),
        .RegWriteM(RegWriteM),
        .ResultSrcM(ResultSrcM),
        .ALUResultM(ALUResultM),
        .ReadDataM(ReadDataM),
        .RdM(RdM),
        .PC_plus4M(PCPlus4M),
        .RegWriteW(RegWriteW),
        .ResultSrcW(ResultSrcW),
        .ALUResultW(ALUResultW),
        .ReadDataW(ReadDataW),
        .RdW(RdW),
        .PC_plus4W(PCPlus4W),
        .AHB_en(AHB_read_en_DM),
        .ReadData_AHB(ReadData_AHB_DM),
        .AHB_en_rf(AHB_read_en),
        .ReadData_AHB_rf(ReadData_AHB),
        .AHB_address_write_rf(AHB_address_write_rf)
    );

    Mux_3to1 result_mux (
        .in0(ALUResultW),
        .in1(ReadDataW),
        .in2(PCPlus4W),
        .sel(ResultSrcW),
        .out(ResultW)
    );

    // PCSrcE logic
    assign PCSrcE = (ZeroE & BranchE) | JumpE;

endmodule
