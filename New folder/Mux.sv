`timescale 1ns/1ps

module Mux (
    // Arbiter control
    input  logic           arbiter_WR,
    input  logic           clk,
    input  logic           rst_n,
    // A-side selects/data
    input  logic           HSEL_G_A,
    input  logic           HSEL_T_A,
    input  logic           HSEL_R_A,
    input  logic [31:0]    HRDATA_G_A,
    input  logic [31:0]    HRDATA_T_A,
    input  logic [31:0]    HRDATA_R_A,
    input  logic           HREADY_G_A,
    input  logic           HREADY_T_A,
    input  logic           HREADY_R_A,
    input  logic           HRESP_G_A,
    input  logic           HRESP_T_A,
    input  logic           HRESP_R_A,

    // B-side selects/data
    input  logic           HSEL_G_B,
    input  logic           HSEL_T_B,
    input  logic           HSEL_R_B,
    input  logic [31:0]    HRDATA_G_B,
    input  logic [31:0]    HRDATA_T_B,
    input  logic [31:0]    HRDATA_R_B,
    input  logic           HREADY_G_B,
    input  logic           HREADY_T_B,
    input  logic           HREADY_R_B,
    input  logic           HRESP_G_B,
    input  logic           HRESP_T_B,
    input  logic           HRESP_R_B,

    // Outputs
    output logic [31:0]    HRDATA_A,
    output logic           HREADY_A,
    output logic           HRESP_A,
    output logic [31:0]    HRDATA_B,
    output logic           HREADY_B,
    output logic           HRESP_B

);

    logic HREADY_A_reg;
    logic HREADY_B_reg;
    // -----------------------------
    // Register HSELs
    // -----------------------------
    logic HSEL_G_A_r, HSEL_T_A_r, HSEL_R_A_r;
    logic HSEL_G_B_r, HSEL_T_B_r, HSEL_R_B_r;

    logic HSEL_G_A_r1, HSEL_T_A_r1, HSEL_R_A_r1;
    logic HSEL_G_B_r1, HSEL_T_B_r1, HSEL_R_B_r1;

    // Sequential HRDATA registers
    logic [31:0] HRDATA_A_r, HRDATA_B_r;
    logic [31:0] HRDATA_G_A_r, HRDATA_T_A_r, HRDATA_R_A_r;
    logic [31:0] HRDATA_G_B_r, HRDATA_T_B_r, HRDATA_R_B_r;
    logic [31:0] HRDATA_G_A_r1, HRDATA_T_A_r1, HRDATA_R_A_r1;
    logic [31:0] HRDATA_G_B_r1, HRDATA_T_B_r1, HRDATA_R_B_r1;


    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            HSEL_G_A_r  <= 1'b0;
            HSEL_T_A_r  <= 1'b0;
            HSEL_R_A_r  <= 1'b0;

            HSEL_G_A_r1 <= 1'b0;
            HSEL_T_A_r1 <= 1'b0;
            HSEL_R_A_r1 <= 1'b0;

            HSEL_G_B_r  <= 1'b0;
            HSEL_T_B_r  <= 1'b0;
            HSEL_R_B_r  <= 1'b0;

            HSEL_G_B_r1 <= 1'b0;
            HSEL_T_B_r1 <= 1'b0;
            HSEL_R_B_r1 <= 1'b0;

            HRDATA_G_A_r <= 32'h0;
            HRDATA_T_A_r <= 32'h0;
            HRDATA_R_A_r <= 32'h0;

            HRDATA_G_A_r1 <= 32'h0;
            HRDATA_T_A_r1 <= 32'h0;
            HRDATA_R_A_r1 <= 32'h0;

            HRDATA_G_B_r <= 32'h0;
            HRDATA_T_B_r <= 32'h0;
            HRDATA_R_B_r <= 32'h0;

            HRDATA_G_B_r1 <= 32'h0;
            HRDATA_T_B_r1 <= 32'h0;
            HRDATA_R_B_r1 <= 32'h0;

            HREADY_A_reg <= 1;
            HREADY_B_reg <= 1;

        end else begin
            HSEL_G_A_r <= HSEL_G_A;
            HSEL_T_A_r <= HSEL_T_A;
            HSEL_R_A_r <= HSEL_R_A;

            HSEL_G_A_r1 <= HSEL_G_A_r;
            HSEL_T_A_r1 <= HSEL_T_A_r;
            HSEL_R_A_r1 <= HSEL_R_A_r;

            HSEL_G_B_r <= HSEL_G_B;
            HSEL_T_B_r <= HSEL_T_B;
            HSEL_R_B_r <= HSEL_R_B;

            HSEL_G_B_r1 <= HSEL_G_B_r;
            HSEL_T_B_r1 <= HSEL_T_B_r;
            HSEL_R_B_r1 <= HSEL_R_B_r;
            

            HRDATA_G_A_r <= HRDATA_G_A;
            HRDATA_T_A_r <= HRDATA_T_A;
            HRDATA_R_A_r <= HRDATA_R_A;

            HRDATA_G_B_r <= HRDATA_G_B;
            HRDATA_T_B_r <= HRDATA_T_B;
            HRDATA_R_B_r <= HRDATA_R_B;

            HRDATA_G_B_r1 <= HRDATA_G_B_r;
            HRDATA_T_B_r1 <= HRDATA_T_B_r;
            HRDATA_R_B_r1 <= HRDATA_R_B_r;

            HREADY_A_reg <= HREADY_A;
            HREADY_B_reg <= HREADY_B;
        end
    end

    // -----------------------------
    // HRDATA mux
    // -----------------------------

    // HRDATA registers update only when slave ready
    always_comb begin
        HRDATA_A = 32'h0;
        HRDATA_B = 32'h0;
        
        // Update A side when ready
        if (HREADY_A_reg) begin
            HRDATA_A =   (HSEL_G_A_r ? HRDATA_G_A :
                         (HSEL_T_A_r ? HRDATA_T_A :
                         (HSEL_R_A_r ? HRDATA_R_A : 32'h0)));
        end else
            HRDATA_A = HRDATA_A_r;

        // Update B side when ready
        if (HREADY_B_reg) begin
            HRDATA_B =   (HSEL_G_B_r ? HRDATA_G_B :
                          HSEL_T_B_r ? HRDATA_T_B :
                          HSEL_R_B_r ? HRDATA_R_B : 32'h0);
        end else begin 
            HRDATA_B = HRDATA_B_r;
        end
    end


    always_comb begin
        // Update A side when ready
            HRDATA_A_r = (HSEL_G_A_r1 ? HRDATA_G_A_r :
                         (HSEL_T_A_r1 ? HRDATA_T_A_r:
                         (HSEL_R_A_r1 ? HRDATA_R_A_r : 32'h0)));

        // Update B side when ready
            HRDATA_B_r = (HSEL_G_B_r1    ? HRDATA_G_B_r :
                          HSEL_T_B_r1    ? HRDATA_T_B_r :
                          HSEL_R_B_r1    ? HRDATA_R_B_r : 32'h0);
    end


    // -----------------------------
    // HREADY mux
    // -----------------------------
    always_comb begin
        HREADY_A = 1'b1;
        HREADY_B = 1'b1;

        if ((HSEL_G_A_r && HSEL_G_B_r) || (HSEL_T_A_r && HSEL_T_B_r) || (HSEL_R_A_r && HSEL_R_B_r)) begin
            if (arbiter_WR) begin
                HREADY_A = 1'b0;
                HREADY_B = HSEL_G_B_r ? HREADY_G_B :
                           HSEL_T_B_r ? HREADY_T_B :
                           HSEL_R_B_r ? HREADY_R_B : 1'b1;
            end else begin
                HREADY_A = HSEL_G_A_r ? HREADY_G_A :
                           HSEL_T_A_r ? HREADY_T_A :
                           HSEL_R_A_r ? HREADY_R_A : 1'b1;
                HREADY_B = 1'b0;
            end
        end else begin
            HREADY_A = HSEL_G_A_r ? HREADY_G_A :
                       HSEL_T_A_r ? HREADY_T_A :
                       HSEL_R_A_r ? HREADY_R_A : 1'b1;   

            HREADY_B = HSEL_G_B_r ? HREADY_G_B :
                       HSEL_T_B_r ? HREADY_T_B :
                       HSEL_R_B_r ? HREADY_R_B : 1'b1;         
        end
    end

    // -----------------------------
    // HRESP mux
    // -----------------------------
    always_comb begin
        HRESP_A = 1'b0;
        HRESP_B = 1'b0;
        
        if (((HSEL_G_A & HSEL_G_B) || (HSEL_T_A & HSEL_T_B) || (HSEL_R_A & HSEL_R_B))) begin
            if (arbiter_WR) begin
                HRESP_A = 1'b0;
                if(HREADY_B) begin
                    HRESP_B = HSEL_G_B_r ? HRESP_G_B :
                              HSEL_T_B_r ? HRESP_T_B :
                              HSEL_R_B_r ? HRESP_R_B : 1'b0;     
                end       
            end else begin
                    HRESP_A = HSEL_G_A_r ? HRESP_G_A :
                              HSEL_T_A_r ? HRESP_T_A :
                              HSEL_R_A_r ? HRESP_R_A : 1'b0;
                end
                HRESP_B = 1'b0;
            end
            else begin
                HRESP_A = HSEL_G_A_r ? HRESP_G_A :
                          HSEL_T_A_r ? HRESP_T_A :
                          HSEL_R_A_r ? HRESP_R_A : 1'b0;
                HRESP_B = HSEL_G_B_r ? HRESP_G_B :
                          HSEL_T_B_r ? HRESP_T_B :
                          HSEL_R_B_r ? HRESP_R_B : 1'b0;     
            end       
    end
endmodule


