`timescale 1ns/1ps
module AHB_lite_master (
    // Global Signals
    input  logic HCLK,
    input  logic HRESETn,
    // Processor signals
    input  logic [31:0] PADDR,
    input  logic [31:0] PWDATA,
    input  logic        PWRITE,
    input  logic [1:0]  PSIZE,
    input  logic [1:0]  PTRANS,
    input  logic [2:0]  PBURST,
    // Transfer response (from slave)
    input  logic HREADY,
    input  logic HRESP,
    // Data (from slave)
    input  logic [31:0] HRDATA,
    // Processor-side response signals
    output logic [31:0] PRDATA,
    output logic        PREADY,
    output logic        PRESP,
    // Outputs (to bus)
    output logic [31:0] HADDR,
    output logic [31:0] HWDATA,
    output logic        HWRITE,
    output logic [1:0]  HSIZE,
    output logic [1:0]  HTRANS,
    output logic [2:0]  HBURST
);

    // ------------------------------------------------------------
    // Typedefs
    // ------------------------------------------------------------
    typedef enum logic [1:0] {IDLE, BUSY, NONSEQ, SEQ} STATES; 

    // ------------------------------------------------------------
    // Internal registers
    // ------------------------------------------------------------
    STATES cs, ns;
    logic [4:0] count;
    logic HREADY_reg;
    logic [31:0] HWDATA_reg;   // pipeline register for write data

    // ------------------------------------------------------
    // Determine burst end count (when to return to IDLE)
    // ------------------------------------------------------
    logic [4:0] end_count;
    logic [31:0] consq_beat;

    // ------------------------------------------------------------
    // State register
    // ------------------------------------------------------------
    always_ff @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn)
            cs <= IDLE;
        else
            cs <= ns;
    end

    // ------------------------------------------------------------
    // Next state logic
    // ------------------------------------------------------------
    always_comb begin
        ns = (PTRANS == 2'bxx)? IDLE: cs; // hold by default
        case (cs)
        IDLE:   ns = ((PTRANS == 2'b10)) ? NONSEQ : IDLE;
        BUSY:   ns = ((PTRANS == 2'b11) && HREADY) ? SEQ : BUSY;
        NONSEQ: begin
            if(HREADY) begin
            if      (PTRANS == 2'b11) ns = SEQ;
            else if (PTRANS == 2'b01) ns = BUSY;
            else if (PTRANS == 2'b00) ns = IDLE;
            else if (PTRANS == 2'b10) ns = NONSEQ;
            else ns = SEQ;
            end else
            // If slave is not ready, stay in NONSEQ until HREADY
            ns = NONSEQ;
        end
        SEQ: begin
            
            if      (count == end_count) ns = IDLE;
            else                         ns = SEQ;
        end
        default: ns = IDLE;
        endcase
    end

    // End count for bursts
    always_comb begin
    case (PBURST)
        3'b010, 3'b011: end_count = 4;   // INCR4 / WRAP4
        3'b100, 3'b101: end_count = 8;    // INCR8 / WRAP8
        3'b110, 3'b111: end_count = 16;   // INCR16 / WRAP16
        default:        end_count = 0;    // single / undefined
    endcase
    end

    // ------------------------------------------------------------
    // Data phase pipeline (HWDATA delayed one cycle)
    // ------------------------------------------------------------
    always_ff @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            HWDATA    <= 32'b0;
            HREADY_reg <= 1'b0;
            count <= 5'b0;
        end else if (HREADY) begin
            // HWDATA is the previous cycle's PWDATA (pipeline)
            HWDATA    <= HWDATA_reg;
            HREADY_reg <= HREADY;
            // Count beats while not in IDLE (simple beat counter)
            if (ns == IDLE)
                count <= 5'b0;
            else if (ns == NONSEQ || ns == BUSY)
                count <= 1; // start counting from 1 on first beat
            else if(HREADY) 
                count <= count + 1;
        end
    end

    // ------------------------------------------------------------
    // Address/control and H* outputs (registered)
    // ------------------------------------------------------------
    always_ff @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            HADDR  <= 32'hF000_0000;
            HWRITE <= 1'b0;
            HSIZE  <= 2'b00;
            HTRANS <= 2'b00;
            HBURST <= 3'b000;
            HWDATA_reg <= 32'b0;
        end 
        else begin
            // Update outputs only when slave is ready
            if ((cs == IDLE)) begin
                if (ns == IDLE) begin
                    HADDR  <= 32'hF000_0000;
                    HWRITE <= 1'b0;
                    HSIZE  <= 2'b00;
                    HTRANS <= 2'b00;
                    HBURST <= 3'b000;
                    HWDATA_reg <= 32'b0;
                end else begin
                    // Starting new transfer: present processor control/address
                    HADDR  <= PADDR;
                    HWRITE <= PWRITE;
                    HSIZE  <= PSIZE;
                    HTRANS <= PTRANS;
                    HBURST <= PBURST;
                    HWDATA_reg <= PWDATA;
                end
            end 
            else if (HREADY) begin
                if (cs == NONSEQ || cs == BUSY) begin
                    if(PBURST == 3'b000) begin
                        HADDR  <= PADDR;
                    end 
                    else begin
                        if(PSIZE == 2'b00)       HADDR <= PADDR + 1;
                        else if(PSIZE == 2'b01)  HADDR <= PADDR + 2;
                        else if(PSIZE == 2'b10)  HADDR <= PADDR + 4;
                    end
                    HWRITE <= PWRITE;
                    HSIZE  <= PSIZE;
                    HTRANS <= PTRANS;
                    HBURST <= PBURST;
                    HWDATA_reg <= PWDATA;
                end 
                else if (cs == SEQ) begin
                    // SEQUENTIAL transfers: update HADDR based on burst/size
                    // ---------- INCR ----------
                    if (PBURST == 3'b001) begin  
                        if (PSIZE == 2'b00)       HADDR <= HADDR + 1;
                        else if (PSIZE == 2'b01)   HADDR <= HADDR + 2;
                        else if (PSIZE == 2'b10)   HADDR <= HADDR + 4;
                        HTRANS <= PTRANS;
                    end

                    // ---------- INCR4 ----------
                    else if (PBURST == 3'b011) begin  
                        if (PSIZE == 2'b00)       HADDR <= (count == 4) ? HADDR : HADDR + 1;
                        else if (PSIZE == 2'b01)  HADDR <= (count == 4) ? HADDR : HADDR + 2;
                        else if (PSIZE == 2'b10)  HADDR <= (count == 4) ? HADDR : HADDR + 4;
                    end

                    // ---------- INCR8 ----------
                    else if (PBURST == 3'b101) begin  
                        if (PSIZE == 2'b00 && count <= 9)       HADDR <= (count == 9) ? HADDR : HADDR + 1;
                        else if (PSIZE == 2'b01 && count <= 9)  HADDR <= (count == 9) ? HADDR : HADDR + 2;
                        else if (PSIZE == 2'b10 && count <= 9)  HADDR <= (count == 9) ? HADDR : HADDR + 4;
                    end

                    // ---------- INCR16 ----------
                    else if (PBURST == 3'b111) begin  
                        if (PSIZE == 2'b00 && count <= 17)       HADDR <= (count == 17) ? HADDR : HADDR + 1;
                        else if (PSIZE == 2'b01 && count <= 17)  HADDR <= (count == 17) ? HADDR : HADDR + 2;
                        else if (PSIZE == 2'b10 && count <= 17)  HADDR <= (count == 17) ? HADDR : HADDR + 4;
                    end

                    // ---------- WRAP4 ----------
                    else if (PBURST == 3'b010) begin  
                        if (PSIZE == 2'b00) begin
                            if      (count == 2) HADDR <= HADDR - 3;
                            else if (count == 4) HADDR <= HADDR;
                            else                 HADDR <= HADDR + 1;
                        end else if (PSIZE == 2'b01) begin
                            if      (count == 2) HADDR <= HADDR - 6;
                            else if (count == 4) HADDR <= HADDR;
                            else                 HADDR <= HADDR + 2;
                        end else if (PSIZE == 2'b10) begin
                            if      (count == 2) HADDR <= HADDR - 12;
                            else if (count == 4) HADDR <= HADDR;
                            else                 HADDR <= HADDR + 4;
                        end
                    end

                    // ---------- WRAP8 ----------
                    else if (PBURST == 3'b100) begin  
                        if (PSIZE == 2'b00) begin
                            if      (count == 4) HADDR <= HADDR - 7;
                            else if (count == 8) HADDR <= HADDR;
                            else                 HADDR <= HADDR + 1;
                        end else if (PSIZE == 2'b01) begin
                            if      (count == 4) HADDR <= HADDR - 14;
                            else if (count == 8) HADDR <= HADDR;
                            else                 HADDR <= HADDR + 2;
                        end else if (PSIZE == 2'b10) begin
                            if      (count == 4) HADDR <= HADDR - 28;
                            else if (count == 8) HADDR <= HADDR;
                            else                 HADDR <= HADDR + 4;
                        end
                    end

                    // ---------- WRAP16 ----------
                    else if (PBURST == 3'b110) begin  
                        if (PSIZE == 2'b00) begin
                            if      (count == 8)  HADDR <= HADDR - 15;
                            else if (count == 16) HADDR <= HADDR;
                            else                  HADDR <= HADDR + 1;
                        end else if (PSIZE == 2'b01) begin
                            if      (count == 8)  HADDR <= HADDR - 30;
                            else if (count == 16) HADDR <= HADDR;
                            else                  HADDR <= HADDR + 2;
                        end else if (PSIZE == 2'b10) begin
                            if      (count == 8)  HADDR <= HADDR - 60;
                            else if (count == 16) HADDR <= HADDR;
                            else                  HADDR <= HADDR + 4;
                        end
                    end

                    // ---------- SINGLE ----------
                    else if (PBURST == 3'b000) begin
                        HADDR  <= PADDR;
                        HWRITE <= PWRITE;
                        HSIZE  <= PSIZE;
                        HTRANS <= PTRANS;
                        HBURST <= PBURST;
                    end

                    // Update HTRANS for end of bursts
                    // Non-sequential transfers: update HTRANS based on burst/size
                    if (count == end_count)
                        HTRANS <= 2'b00; // IDLE after this
                    else
                        HTRANS <= 2'b11; // SEQ for ongoing bursts

                    // common: present size/write/burst/ptrans for seq beats
                    HWRITE <= PWRITE;
                    HSIZE  <= PSIZE;
                    HBURST <= PBURST;
                    HWDATA_reg <= PWDATA;
                end
        end
        end
    end

    // ------------------------------------------------------------
    // Processor-side response sampling (PRDATA/PREADY/PRESP)
    // ------------------------------------------------------------
    // The master observes HREADY/HRESP/HRDATA from the selected slave.
    // - PREADY reflects HREADY (synchronized)
    // - PRESP reflects HRESP (synchronized)
    // - PRDATA captures HRDATA when HREADY is asserted and the completed transfer was a READ (HWRITE == 0)
    always_comb begin
        // Default assignments
        PREADY = HREADY;
        PRESP  = HRESP;
        PRDATA = 32'b0;
        // Drive PRDATA directly when slave is ready and it's a read
        if (HREADY) begin
            PRDATA = HRDATA;
        end
    end

endmodule
