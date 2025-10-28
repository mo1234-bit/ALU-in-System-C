`timescale 1ns/1ps
module AHB_arbiter (
    input  logic                       HCLK,
    input  logic                       HRESETn,
    input  logic                       arbiter_WR, 
    input  logic  [31:0]               HADDR_A,
    input  logic                       HWRITE_A,
    input  logic  [1:0]                HSIZE_A,
    input  logic  [1:0]                HTRANS_A,
    input  logic  [2:0]                HBURST_A,
    input  logic  [31:0]               HWDATA_A,
    input  logic                       HSEL_P_A,  

    input  logic  [31:0]               HADDR_B,
    input  logic                       HWRITE_B,
    input  logic  [1:0]                HSIZE_B,
    input  logic  [1:0]                HTRANS_B,
    input  logic  [2:0]                HBURST_B,
    input  logic  [31:0]               HWDATA_B,
    input  logic                       HSEL_P_B,  

    output logic                       HSEL_P,
    output logic  [31:0]               HADDR,
    output logic                       HWRITE,
    output logic  [1:0]                HSIZE,
    output logic  [1:0]                HTRANS,
    output logic  [2:0]                HBURST,
    output logic  [31:0]               HWDATA
);

    //===============================
    // Pipeline registers (1-cycle delay)
    //===============================
    logic                       arbiter_WR_reg;
    logic  [31:0]               HADDR_A_reg;
    logic                       HWRITE_A_reg;
    logic  [1:0]                HSIZE_A_reg;
    logic  [1:0]                HTRANS_A_reg;
    logic  [2:0]                HBURST_A_reg;
    logic                       HSEL_P_A_reg;  

    logic  [31:0]               HADDR_B_reg;
    logic                       HWRITE_B_reg;
    logic  [1:0]                HSIZE_B_reg;
    logic  [1:0]                HTRANS_B_reg;
    logic  [2:0]                HBURST_B_Reg;
    logic                       HSEL_P_B_reg;  

    always_ff @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            arbiter_WR_reg <= 1'b0;
            // Reset A
            HADDR_A_reg  <= 32'b0;
            HWRITE_A_reg <= 1'b0;
            HSIZE_A_reg  <= 2'b0;
            HTRANS_A_reg <= 2'b0;
            HBURST_A_reg <= 3'b0;
            HSEL_P_A_reg <= 1'b0; 

            // Reset B
            HADDR_B_reg  <= 32'b0;
            HWRITE_B_reg <= 1'b0;
            HSIZE_B_reg  <= 2'b0;
            HTRANS_B_reg <= 2'b0;
            HBURST_B_Reg <= 3'b0;
            HSEL_P_B_reg <= 1'b0; 

        end else begin
            arbiter_WR_reg <= arbiter_WR;
            // Capture A
            HADDR_A_reg  <= HADDR_A;
            HWRITE_A_reg <= HWRITE_A;
            HSIZE_A_reg  <= HSIZE_A;
            HTRANS_A_reg <= HTRANS_A;
            HBURST_A_reg <= HBURST_A;
            HSEL_P_A_reg <= HSEL_P_A; 

            // Capture B
            HADDR_B_reg  <= HADDR_B;
            HWRITE_B_reg <= HWRITE_B;
            HSIZE_B_reg  <= HSIZE_B;
            HTRANS_B_reg <= HTRANS_B;
            HBURST_B_Reg <= HBURST_B;
            HSEL_P_B_reg <= HSEL_P_B; 
        end
    end


    // Arbiter 
    always_comb begin : Arbiter
        HADDR  = 32'b0;
        HWRITE = 1'b0;
        HSIZE  = 2'b0;
        HTRANS = 2'b0;
        HBURST = 3'b0;
        HSEL_P = 1'b0;  
        if(HSEL_P_A && HSEL_P_B) begin
            if(arbiter_WR) begin
                HADDR  = HADDR_B;
                HWRITE = HWRITE_B;
                HSIZE  = HSIZE_B;
                HTRANS = HTRANS_B;
                HBURST = HBURST_B;
                HSEL_P = HSEL_P_B;
            end else begin
                HADDR  = HADDR_A;
                HWRITE = HWRITE_A;
                HSIZE  = HSIZE_A;
                HTRANS = HTRANS_A;
                HBURST = HBURST_A;
                HSEL_P = HSEL_P_A;
            end 
        end else begin 
            if (HSEL_P_A) begin
                HADDR  = HADDR_A;
                HWRITE = HWRITE_A;
                HSIZE  = HSIZE_A;
                HTRANS = HTRANS_A;
                HBURST = HBURST_A;
                HSEL_P = HSEL_P_A;
            end  
            else if (HSEL_P_B) begin
                HADDR  = HADDR_B;
                HWRITE = HWRITE_B;
                HSIZE  = HSIZE_B;
                HTRANS = HTRANS_B;
                HBURST = HBURST_B;
                HSEL_P = HSEL_P_B;
            end 
        end
    end


    always_comb begin : Data
        if(HSEL_P_A_reg && HSEL_P_B_reg) begin
            if(arbiter_WR_reg) begin
                HWDATA = HWDATA_B;
            end else begin
                HWDATA = HWDATA_A;
            end 
        end else begin 
            if (HSEL_P_A_reg) begin
                HWDATA = HWDATA_A;
            end  
            else if (HSEL_P_B_reg) begin
                HWDATA = HWDATA_B;
            end 
        end
    end

endmodule
