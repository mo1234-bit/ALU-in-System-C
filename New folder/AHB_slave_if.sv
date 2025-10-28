`timescale 1ns/1ps

module AHB_slave_if (
    input  logic        HCLK,
    input  logic        HRESETn,
    input  logic        arbiter_WR,
    input  logic[31:0]  HADDR,
    input  logic        HWRITE,
    input  logic[1:0]   HSIZE,
    input  logic[1:0]   HTRANS,
    input  logic[31:0]  HWDATA,
    input  logic        HSEL_P,
    input  logic        HREADY_A,
    input  logic        HREADY_B,

    input  logic[31:0]  peripheral_rd_data,
    input  logic        peripheral_ready,
    input  logic        peripheral_response,

    output logic [31:0] HRDATA_P, 
    output logic        HREADY_P, 
    output logic        HRESP_P,
    
    output logic        peripheral_we,
    output logic        peripheral_re,
    output logic[31:0]  Addr,
    output logic[1:0]   size,
    output logic[31:0]  wd_data
);

    // FSM states
    typedef enum logic [1:0] {IDLE, BUSY, NONSEQ, SEQ} states;
    states cs, ns;

    // Pipelined signals to delay control/address by 1 cycle to match data timing
    logic [31:0] HADDR_reg;
    logic        HWRITE_reg;
    logic [1:0]  HSIZE_reg;
    logic [1:0]  HTRANS_reg;
    logic        HSEL_P_reg;

    //===============================
    // Pipeline registers (1-cycle delay)
    //===============================
    always_ff @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            HADDR_reg  <= 32'hF000_0000;
            HWRITE_reg <= 1'b0;
            HSIZE_reg  <= 2'b0;
            HTRANS_reg <= 2'b0;
            HSEL_P_reg <= 1'b0;
        end else begin
            HADDR_reg  <= HADDR;
            HWRITE_reg <= HWRITE;
            HSIZE_reg  <= HSIZE;
            HTRANS_reg <= HTRANS;
            HSEL_P_reg <= HSEL_P;
        end
    end

    //===============================
    // State Register
    //===============================
    always_ff @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn)
            cs <= IDLE;
        else
            cs <= ns;
    end

    //===============================
    // Next State Logic
    //===============================
    always_comb begin
        case (cs)
            IDLE: begin
                case (HTRANS)
                    2'b00:   ns = IDLE;
                    2'b01:   ns = BUSY;
                    2'b10:   ns = NONSEQ;
                    2'b11:   ns = SEQ;
                    default: ns = IDLE;
                endcase
            end 
            BUSY: begin
                case (HTRANS)
                    2'b00:   ns = IDLE;
                    2'b01:   ns = BUSY;
                    2'b10:   ns = NONSEQ;
                    2'b11:   ns = SEQ;
                    default: ns = IDLE;
                endcase
            end
            NONSEQ: begin
                case (HTRANS)
                    2'b00:   ns = IDLE;
                    2'b01:   ns = BUSY;
                    2'b10:   ns = NONSEQ;
                    2'b11:   ns = SEQ;
                    default: ns = IDLE;
                endcase
            end
            SEQ: begin
                case (HTRANS)
                    2'b00:   ns = IDLE;
                    2'b01:   ns = BUSY;
                    2'b10:   ns = NONSEQ;
                    2'b11:   ns = SEQ;
                    default: ns = IDLE;
                endcase
            end
            default: ns = IDLE;
        endcase
    end


    //===============================
    // Output Logic
    //===============================
    always_comb begin
        wd_data = HWDATA;
        case (cs)
            IDLE: begin       
                Addr      = 32'hF000_0000;
            end
            BUSY: begin
                Addr      = HADDR_reg;
            end
            NONSEQ, SEQ: begin
                Addr      = HADDR_reg;
            end
            default: begin
                Addr      = 32'hF000_0000;
            end
        endcase
    end
    
    //===============================
    // Write and Read Enables (based on delayed HSEL and HWRITE)
    //===============================
    assign peripheral_we = HREADY_P && HSEL_P_reg && HWRITE_reg && (HTRANS_reg == NONSEQ || HTRANS_reg == SEQ);


    assign peripheral_re = HREADY_P && HSEL_P_reg && !HWRITE_reg && (HTRANS_reg == NONSEQ || HTRANS_reg == SEQ);

    assign size = HSIZE_reg;

    //===============================
    // Read Data & Status
    //===============================
    assign HRDATA_P = peripheral_rd_data;

    assign HREADY_P = peripheral_ready;

    assign HRESP_P =  peripheral_response;

    // Default ready signal when no slave is selected
    
 
endmodule

