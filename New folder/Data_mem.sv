// Data memory with AHB interface (combinational AHB)
`timescale 1ns/1ps
module Data_Mem(
    input  logic        clk,
    input  logic        rst, 
    input  logic        WE,
    input  logic [31:0] WriteData,   // Write Data
    input  logic [31:0] A,           // Address
    output logic [31:0] ReadData,    // Read Data
    output logic        flag,
    
    // AHB signals (combinational)
    input  logic [31:0] PRDATA_A,
    input  logic        PREADY_A,
    input  logic        PRESP_A, 
    output logic        AHB_en,
    output logic [31:0] ReadData_AHB,
    output logic [31:0] PADDR_A,
    output logic        PWRITE_A,
    output logic [1:0]  PSIZE_A,
    output logic [1:0]  PTRANS_A,
    output logic [2:0]  PBURST_A,
    output logic [31:0] PWDATA_A
);

localparam WIDTH   = 32;   // Width of memory word
localparam DEPTH   = 256;  // Depth of Memory (256 entries)
localparam OFFSET  = 32'd65535; // AHB peripheral base address

// Local memory array
logic [WIDTH-1:0] Data_memory [0:DEPTH-1]; 
logic [31:0] AHB_address [1:0];
logic [1:0]  count;
logic first;
// Sequential write for local memory (addresses < OFFSET)
always_ff @(posedge clk) begin
    if (WE && (A < OFFSET)) begin
        Data_memory[A[31:2]] <= WriteData;
    end
    AHB_address [1] <= AHB_address [0];
    AHB_address [0] <= A;
end

// AHB slaves address offset
logic [15:0] addr_offset, Timer_offset, register_file_offset;

// AHB signals (combinational for A >= OFFSET)
always_comb begin
    // Default idle
    PADDR_A  = 32'hF000_0000;
    PWRITE_A = 0;
    PSIZE_A  = 2'b10;
    PTRANS_A = 2'b00;
    PBURST_A = 3'b000;
    PWDATA_A = '0;

    if (A >= OFFSET) begin
        // Compute offset from AHB base
        addr_offset             = A - OFFSET;
        Timer_offset            = addr_offset - 32;  
        register_file_offset    = addr_offset - 64;
        // Decode ranges
        if (addr_offset < 32) begin
            PADDR_A = {16'h0000, addr_offset};          // GPIO
        end else if (addr_offset < 64) begin
            PADDR_A = {16'h1000, Timer_offset};         // Timer
        end else begin
            PADDR_A = {16'h2000, register_file_offset}; // Regfile
        end

        PWRITE_A = WE;
        PTRANS_A = 2'b10; // NONSEQ
        
        if(WE)
            PWDATA_A = WriteData;
    end
end

assign ReadData = (A < OFFSET)? Data_memory[A[31:2]]: '0;         // Local memory read

// Read Operation (Combinational)
always_comb begin
    ReadData_AHB = '0;
    AHB_en = 0;

    if (((AHB_address [1] >= OFFSET) && (AHB_address [1] != 32'hF000_0000)) && !PRESP_A && PREADY_A && !WE) 
        AHB_en = 1;
        ReadData_AHB = PRDATA_A;
end

always_ff @(posedge clk, negedge rst) begin
    if(~rst) begin
        count <= 0;
        flag <= 0;
        first <= 1;
    end else begin
        if(AHB_address [1] >= OFFSET && AHB_address [1] != 32'hF000_0000 && count <= 2) begin

            if(first) begin
                if(count == 1) begin
                    if(AHB_address [1] >= OFFSET && AHB_address [1] != 32'hF000_0000) begin
                        first <= 1;
                        count <= 1;
                        flag  <= 1;
                    end else begin
                        first <= 0;
                        count <= 0;
                        flag  <= 0;
                    end
                end else begin
                    count <= count + 1;
                    flag <= 1;
                end
            end else begin
                if(count == 2) begin
                    if(AHB_address [1] >= OFFSET && AHB_address [1] != 32'hF000_0000) begin
                        first <= 1;
                        count <= 1;
                        flag  <= 1;
                    end else begin
                        first <= 0;
                        count <= 0;
                        flag  <= 0;
                    end
                end else begin
                    count <= count + 1;
                    flag <= 1;
                end
            end
        end else begin
            first <= 0;
            count <= 0;
            flag  <= 0;
        end
    end
end
endmodule
