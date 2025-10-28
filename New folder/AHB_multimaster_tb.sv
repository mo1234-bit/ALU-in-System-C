`timescale 1ns/1ps

module AHB_multimaster_tb;

    // Parameters
    parameter CLK_PERIOD    = 10;
    parameter REG_WIDTH     = 8;
    parameter REG_DEPTH     = 32;
    parameter GPIO_WIDTH    = 8;
    parameter COUNTER_WIDTH = 32;

    // Signals declaration
    // ------------------------------
    // Common system signals
    // ------------------------------
    logic                       HCLK;
    logic                       HRESETn;
    logic                       arbiter_WR; // 0: A has priority, 1: B has priority

    // ------------------------------
    // Master B signals
    // ------------------------------
    logic  [31:0]               PADDR_B;
    logic                       PWRITE_B;
    logic  [31:0]               PWDATA_B;
    logic                       PREADY_B;
    logic                       PRESP_B;
    logic  [31:0]               PRDATA_B;

    // ------------------------------
    // Peripheral signals
    // ------------------------------
    logic  [GPIO_WIDTH-1:0]     GPIO_in_portA;      
    logic  [GPIO_WIDTH-1:0]     GPIO_in_portB;      
    logic  [GPIO_WIDTH-1:0]     GPIO_in_portC;      
    logic  [GPIO_WIDTH-1:0]     GPIO_in_portD;      

    logic                       Register_File_En;
    logic                       GPIO_En;
    logic                       Timer_En;

    logic [GPIO_WIDTH-1:0]      GPIO_out_portA;     
    logic [GPIO_WIDTH-1:0]      GPIO_out_portB;     
    logic [GPIO_WIDTH-1:0]      GPIO_out_portC;     
    logic [GPIO_WIDTH-1:0]      GPIO_out_portD;


    // Testing signals
    int correct_count = 0;
    int error_count   = 0; 

    // Typedef enums
    typedef enum logic [1:0] {IDLE, BUSY, NONSEQ, SEQ} Transfer_state;
    typedef enum logic [2:0] {SINGLE, INCR, WRAP4, INCR4, WRAP8, INCR8, WRAP16, INCR16} Burst_state;
    typedef enum logic [1:0] {BYTE, HALFWORD, WORD} Size_state;

    // add these instead:
    Transfer_state PTRANS_B;
    Burst_state    PBURST_A, PBURST_B;
    Size_state     PSIZE_A, PSIZE_B;


    logic [31:0] data_q4 [$] = {32'hA, 32'hB, 32'hC, 32'hD};
    logic [31:0] data_q8 [$] = {32'h10,32'h11,32'h12,32'h13,32'h14,32'h15,32'h16,32'h17};
    logic [31:0] data_q16[$] = {32'h20,32'h21,32'h22,32'h23,32'h24,32'h25,32'h26,32'h27,
                                32'h28,32'h29,32'h2A,32'h2B,32'h2C,32'h2D,32'h2E,32'h2F};


    // DUT instantiation
    AHB_multimaster #(
        .REG_WIDTH(REG_WIDTH),
        .REG_DEPTH(REG_DEPTH),
        .GPIO_WIDTH(GPIO_WIDTH),
        .COUNTER_WIDTH(COUNTER_WIDTH)
    ) DUT (
        .HCLK(HCLK),
        .HRESETn(HRESETn),
        .arbiter_WR(arbiter_WR), // 0: A has priority, 1: B has priority

        // Master B inputs
        .PADDR_B   (PADDR_B),
        .PWRITE_B  (PWRITE_B),
        .PSIZE_B   (PSIZE_B),
        .PTRANS_B  (PTRANS_B),
        .PBURST_B  (PBURST_B),
        .PWDATA_B  (PWDATA_B),

        // GPIO inputs
        .GPIO_in_portA(GPIO_in_portA),
        .GPIO_in_portB(GPIO_in_portB),
        .GPIO_in_portC(GPIO_in_portC),
        .GPIO_in_portD(GPIO_in_portD),

        // Control signals
        .Register_File_En(Register_File_En),
        .GPIO_En(GPIO_En),
        .Timer_En(Timer_En),

        // Master B outputs
        .PREADY_B(PREADY_B),
        .PRESP_B(PRESP_B),
        .PRDATA_B(PRDATA_B),

        // GPIO outputs 
        .GPIO_out_portA(GPIO_out_portA),
        .GPIO_out_portB(GPIO_out_portB),
        .GPIO_out_portC(GPIO_out_portC),
        .GPIO_out_portD(GPIO_out_portD)
    );

    // Clock generation
    initial begin
        HCLK = 0;
        forever #(CLK_PERIOD/2) HCLK = ~HCLK;
    end

    initial begin
        $dumpfile("AHB_multimaster.vcd");
        $dumpvars(0, AHB_multimaster_tb);

        // ------------------------------
        // Initialize inputs
        // ------------------------------
        HRESETn = 0;

        // Master B initialization
        PADDR_B   = 32'hF000_0000;
        PWDATA_B  = 32'd0;
        PWRITE_B  = 1'b0;
        PSIZE_B   = WORD;
        PTRANS_B  = IDLE;
        PBURST_B  = SINGLE;

        // Peripheral enables
        Register_File_En = 1'b0;
        GPIO_En         = 1'b0;
        Timer_En        = 1'b0;

        // Default arbiter priority
        arbiter_WR     = 1'b0; // Master A has priority by default

        // GPIO inputs
        GPIO_in_portA = 8'd20;
        GPIO_in_portB = 8'd40;
        GPIO_in_portC = 8'd60;
        GPIO_in_portD = 8'd80;

        #(2*CLK_PERIOD);

        HRESETn = 1;
        Register_File_En = 1;
        GPIO_En = 1;
        Timer_En = 1;
        //#(2*CLK_PERIOD);

    // ------------------------------------------------
    // Test cases
    // ------------------------------------------------

        // // Simple Write by Master A and Master B in register file and GPIO 
        // Single_Write(1'b0, 32'h2000_0008, 1'b1, WORD, NONSEQ, SINGLE, 32'h0000_00BB, 
        //                    32'h0000_0004, 1'b1, BYTE, NONSEQ, SINGLE, 32'h0000_00CD);

        // // Simple Write by Master A only in register file (conflict case)
        // Single_Write(1'b0, 32'h2000_0000, 1'b1, WORD, NONSEQ, SINGLE, 32'h0000_000A, 
        //                    32'h2000_0004, 1'b1, WORD, NONSEQ, SINGLE, 32'h0000_00F1);
        
        // // Simple Write by Master A and Master B in GPIO and Timer 
        // Single_Write(1'b0, 32'h0000_0005, 1'b1, BYTE, NONSEQ, SINGLE, 32'h0000_00FF, 
        //                    32'h1000_0000, 1'b1, BYTE, NONSEQ, SINGLE, 32'h0000_0022);

        // // Simple Read by Master A only in register file (conflict case)
        // Single_Read(1'b0, 32'h2000_0000, 1'b0, WORD, NONSEQ, SINGLE,
        //                   32'h2000_0004, 1'b0, BYTE, NONSEQ, SINGLE);
        

        // // Simple Read by Master A and Master B in register file and GPIO 
        // Single_Read(1'b0, 32'h2000_0004, 1'b0, WORD, NONSEQ, SINGLE,
        //                   32'h0000_0000, 1'b0, WORD, NONSEQ, SINGLE);
        

        // PTRANS = IDLE;
        // @(posedge HCLK);       

    // // ------------------------------------------------
    // // GPIO Test cases
    // // ------------------------------------------------
    //     
    //     GPIO_in_portA = 8'b0;
    //     GPIO_in_portB = 8'b0;
    //     GPIO_in_portC = 8'b0;
    //     GPIO_in_portD = 8'b0;

    //     // Incremental Drive output pins with INCR4
    //     tst_data = '{32'hA, 32'hB, 32'hC, 32'hD};
    //     burst_write(32'h0000_0004, BYTE, INCR4, 4, tst_data[3:0]);
    //     #CLK_PERIOD;

    //     // Incremental Read input pins with INCR4
    //     GPIO_in_portA = 8'b1000_0011;
    //     GPIO_in_portB = 8'b0111_0110;
    //     GPIO_in_portC = 8'b0010_0001;
    //     GPIO_in_portD = 8'b0011_0011;
    //     burst_read(32'h0000_0000, BYTE, INCR4, 4);
    //     #CLK_PERIOD;

    //     // Wrong write (read-only address)
    //     Single_Write(32'h0000_0000, 1'b1, BYTE, NONSEQ, SINGLE, 32'h0000_000A);
    //     wait(PREADY);
    //     check_write(32'h0000_000A, 1'b1, 1'b1);
    //     #CLK_PERIOD;

    //     // Wrong read (invalid addr)
    //     Single_Read(32'h0000_0004, 1'b0, BYTE, NONSEQ, SINGLE);
    //     wait(PREADY);
    //     // Expect error response
    //     if (PRESP === 1'b1) correct_count++;
    //     else error_count++;
    //     #CLK_PERIOD;

    //     // Invalid width
    //     Single_Write(32'h0000_0004, 1'b1, BYTE, NONSEQ, SINGLE, 32'h0000_ABCD);
    //     wait(PREADY);
    //     check_write(32'h0000_ABCD, 1'b1, 1'b1);
    //     #CLK_PERIOD;

    // // ------------------------------------------------
    // // Timer Test cases
    // // ------------------------------------------------
    //     Timer_En = 1;

    //     // Load value
    //     Single_Write(32'h1000_0000, 1'b1, WORD, NONSEQ, SINGLE, 32'h0000_000A);
    //     wait(PREADY);
    //     check_write(32'h0000_000A, 1'b1, 1'b0);
    //     #CLK_PERIOD;

    //     // Mode config
    //     Single_Write(32'h1000_0004, 1'b1, WORD, NONSEQ, SINGLE, 32'h0000_0002);
    //     wait(PREADY);
    //     check_write(32'h0000_0002, 1'b1, 1'b0);
    //     #CLK_PERIOD;

    //     PTRANS = IDLE;
    //     #(11*CLK_PERIOD);

    //     Single_Read(32'h1000_0000, 1'b0, WORD, NONSEQ, SINGLE);
    //     wait(PREADY);
    //     // Check read value - should be less than initial due to counting
    //     if (PRDATA < 32'hA && PREADY && !PRESP) correct_count++;
    //     else error_count++;
    //     #CLK_PERIOD;

        // PTRANS_A = IDLE;
        // PTRANS_B = IDLE;
        #200;
        #(6*CLK_PERIOD);

        // $display("----------------------------------------------");
        // $display("Correct transactions : %0d", correct_count);
        // $display("Error   transactions : %0d", error_count);
        $finish;
    end

    // ------------------------------
    // Tasks
    // ------------------------------

    // ------------------------------
    // Generic Write Task (A or B)
    // ------------------------------
    // task Single_Write(
    //     input bit master_sel,              // 0 = Master A, 1 = Master B
    //     // Master A
    //     input [31:0] addr_A,
    //     input bit wr_A,
    //     input Size_state sz_A,
    //     input Transfer_state tr_A,
    //     input Burst_state burst_A,
    //     input [31:0] data_a,
    //     // Master B
    //     input [31:0] addr_B,
    //     input bit wr_B,
    //     input Size_state sz_B,
    //     input Transfer_state tr_B,
    //     input Burst_state burst_B,
    //     input [31:0] data_B
    // );
    //     begin
    //         @(posedge HCLK);
    //         arbiter_WR = master_sel;

    //         // Master A
    //         PADDR_A   = addr_A;
    //         PWRITE_A  = wr_A;
    //         PSIZE_A   = sz_A;
    //         PTRANS_A  = tr_A;
    //         PBURST_A  = burst_A;
    //         PWDATA_A  = data_a;
    //         // Master B
    //         PADDR_B   = addr_B;
    //         PWRITE_B  = wr_B;
    //         PSIZE_B   = sz_B;
    //         PTRANS_B  = tr_B;
    //         PBURST_B  = burst_B;
    //         PWDATA_B  = data_B;


            
    //     end
    // endtask

    // // ------------------------------
    // // Generic Read Task (A or B)
    // // ------------------------------
    // task Single_Read(
    //     input bit master_sel,              // 0 = Master A, 1 = Master B
    //     // Master A
    //     input [31:0] addr_A,
    //     input bit wr_A,
    //     input Size_state sz_A,
    //     input Transfer_state tr_A,
    //     input Burst_state burst_A,
    //     // Master B
    //     input [31:0] addr_B,
    //     input bit wr_B,
    //     input Size_state sz_B,
    //     input Transfer_state tr_B,
    //     input Burst_state burst_B
    // );
    //     begin
    //         @(posedge HCLK);
    //         arbiter_WR = master_sel;

    //         // Master A
    //         PADDR_A   = addr_A;
    //         PWRITE_A  = wr_A;
    //         PSIZE_A   = sz_A;
    //         PTRANS_A  = tr_A;
    //         PBURST_A  = burst_A;
    //         // Master B
    //         PADDR_B   = addr_B;
    //         PWRITE_B  = wr_B;
    //         PSIZE_B   = sz_B;
    //         PTRANS_B  = tr_B;
    //         PBURST_B  = burst_B;
    //     end
    // endtask


    // // Burst Write
    // task automatic burst_write(input [31:0] start_addr, input Size_state size,
    //                          input Burst_state burst, input int beats, input [31:0] data []);
    //     int i;
    //     logic [31:0] addr;
    //     begin
    //         addr = start_addr;
    //         for (i = 0; i < beats; i++) begin
    //             @(posedge HCLK);
    //             PADDR  = addr;
    //             PWDATA = data[i];
    //             PWRITE = 1'b1;
    //             PSIZE  = size;
    //             PBURST = burst;
    //             PTRANS = (i == 0) ? NONSEQ : SEQ;
    //             // Wait for transfer completion
    //             wait(PREADY);
    //         end
    //         @(posedge HCLK);
    //     end
    // endtask

    // // Burst Read
    // task automatic burst_read(input [31:0] start_addr, input Size_state size,
    //                          input Burst_state burst, input int beats);
    //     int i;
    //     logic [31:0] addr;
    //     begin
    //         addr = start_addr;
    //         for (i = 0; i < beats; i++) begin
    //             @(posedge HCLK);
    //             PADDR  = addr;
    //             PWRITE = 1'b0;
    //             PSIZE  = size;
    //             PBURST = burst;
    //             PTRANS = (i == 0) ? NONSEQ : SEQ;
    //             // Wait for transfer completion
    //             wait(PREADY);
    //             // Check read data (basic check - should be enhanced with expected values)
    //             if (PREADY && !PRESP) begin
    //                 $display("Read data[%0d]: %h", i, PRDATA);
    //                 correct_count++;
    //             end else begin
    //                 $display("Read error at beat %0d", i);
    //                 error_count++;
    //             end
    //         end
    //         @(posedge HCLK);
    //     end
    // endtask

    // ------------------------------
    // Check functions
    // ------------------------------

    // // Check write
    // task check_write(
    //     input logic [31:0] HWDATA_expected
    // );
    // begin
    //     if (DUT.HSEL_R && DUT.HWDATA_R == HWDATA_expected) begin
    //         $display("[%0t] Register File write test passed", $time);
    //         $display("  HWDATA_R: %0h (expected %0h)", DUT.HWDATA_R, HWDATA_expected);
    //         correct_count++;
    //     end
    //     else if (DUT.HSEL_G && DUT.HWDATA_G == HWDATA_expected) begin
    //         $display("[%0t] GPIO write test passed", $time);
    //         $display("  HWDATA_G: %0h (expected %0h)", DUT.HWDATA_G, HWDATA_expected);
    //         correct_count++;
    //     end
    //     else if (DUT.HSEL_T && DUT.HWDATA_T == HWDATA_expected) begin
    //         $display("[%0t] Timer write test passed", $time);
    //         $display("  HWDATA_T: %0h (expected %0h)", DUT.HWDATA_T, HWDATA_expected);
    //         correct_count++;
    //     end
    //     else begin
    //         $display("[%0t] Write test failed", $time);
    //         if (DUT.HSEL_R) $display("  HWDATA_R: %0h (expected %0h)", DUT.HWDATA_R, HWDATA_expected);
    //         if (DUT.HSEL_G) $display("  HWDATA_G: %0h (expected %0h)", DUT.HWDATA_G, HWDATA_expected);
    //         if (DUT.HSEL_T) $display("  HWDATA_T: %0h (expected %0h)", DUT.HWDATA_T, HWDATA_expected);
    //         error_count++;
    //     end
    // end
    // endtask


    // // Check read
    // task automatic check_read();
    //     logic [31:0] exp_data_A;
    //     logic        exp_ready_A;
    //     logic        exp_resp_A;
    //     logic [31:0] exp_data_B;
    //     logic        exp_ready_B;
    //     logic        exp_resp_B;
    //     logic        slave_conflict;

    //     begin
    //         // Master selection
    //         slave_conflict = ((DUT.HSEL_G_A & DUT.HSEL_G_B) ||
    //                            (DUT.HSEL_T_A & DUT.HSEL_T_B) ||
    //                            (DUT.HSEL_R_A & DUT.HSEL_R_B));

    //         if(slave_conflict) begin
    //         // Address decoding
    //             if(~arbiter_WR) begin
    //                 exp_data_B  = 32'h0000_0000;
    //                 exp_ready_B = 1'b0;
    //                 exp_resp_B  = 1'b0;
                        
    //                 if (DUT.HSEL_G_A) begin
    //                     exp_data_A  = DUT.gpio_rd_data;
    //                     exp_ready_A = DUT.gpio_ready;
    //                     exp_resp_A  = DUT.gpio_response;
    //                 end
    //                 else if (DUT.HSEL_T_A) begin
    //                     exp_data_A  = DUT.timer_rd_data;
    //                     exp_ready_A = DUT.timer_ready;
    //                     exp_resp_A  = DUT.timer_response;
    //                 end
    //                 else if (DUT.HSEL_R_A)begin
    //                     exp_data_A  = DUT.register_file_rd_data;
    //                     exp_ready_A = DUT.register_file_ready;
    //                     exp_resp_A  = DUT.register_file_response;
    //                 end
    //             end else begin
    //                 exp_data_A  = 32'h0000_0000;
    //                 exp_ready_A = 1'b0;
    //                 exp_resp_A  = 1'b0;
                        
    //                 if (DUT.HSEL_G_B) begin
    //                     exp_data_B  = DUT.gpio_rd_data;
    //                     exp_ready_B = DUT.gpio_ready;
    //                     exp_resp_B  = DUT.gpio_response;
    //                 end
    //                 else if (DUT.HSEL_T_B) begin
    //                     exp_data_B  = DUT.timer_rd_data;
    //                     exp_ready_B = DUT.timer_ready;
    //                     exp_resp_B  = DUT.timer_response;
    //                 end
    //                 else if (DUT.HSEL_R_B)begin
    //                     exp_data_B  = DUT.register_file_rd_data;
    //                     exp_ready_B = DUT.register_file_ready;
    //                     exp_resp_B  = DUT.register_file_response;
    //                 end
    //             end
    //         end else begin
    //             if(DUT.HSEL_G_A) begin
    //                 exp_data_A  = DUT.gpio_rd_data;
    //                 exp_ready_A = DUT.gpio_ready;
    //                 exp_resp_A  = DUT.gpio_response;    
    //             end else if (DUT.HSEL_T_A) begin
    //                 exp_data_A  = DUT.timer_rd_data;
    //                 exp_ready_A = DUT.timer_ready;
    //                 exp_resp_A  = DUT.timer_response;
    //             end
    //             else if (DUT.HSEL_R_A)begin
    //                 exp_data_A  = DUT.register_file_rd_data;
    //                 exp_ready_A = DUT.register_file_ready;
    //                 exp_resp_A  = DUT.register_file_response;
    //             end

    //             if(DUT.HSEL_G_B) begin
    //                 exp_data_B  = DUT.gpio_rd_data;
    //                 exp_ready_B = DUT.gpio_ready;
    //                 exp_resp_B  = DUT.gpio_response;    
    //             end else if (DUT.HSEL_T_B) begin
    //                 exp_data_B  = DUT.timer_rd_data;
    //                 exp_ready_B = DUT.timer_ready;
    //                 exp_resp_B  = DUT.timer_response;
    //             end
    //             else if (DUT.HSEL_R_B)begin
    //                 exp_data_B  = DUT.register_file_rd_data;
    //                 exp_ready_B = DUT.register_file_ready;
    //                 exp_resp_B  = DUT.register_file_response;
    //             end
    //         end

    //         // Comparison
    //         if ((HRDATA_A == exp_data_A && HREADY_A == exp_ready_A && HRESP_A == exp_resp_A) && 
    //             (HRDATA_B == exp_data_B && HREADY_B == exp_ready_B && HRESP_B == exp_resp_B)) begin
    //             $display("[%0t] Read test case passed sucessfully", $time);
    //             $display("  HRDATA_A: %0h (expected %0h)", HRDATA_A, exp_data_A);
    //             $display("  HREADY_A: %0d (expected %0d)", HREADY_A, exp_ready_A);
    //             $display("  HRESP_A : %0d (expected %0d)", HRESP_A, exp_resp_A);
    //             $display("  HRDATA_B: %0h (expected %0h)", HRDATA_B, exp_data_B);
    //             $display("  HREADY_B: %0d (expected %0d)", HREADY_B, exp_ready_B);
    //             $display("  HRESP_B : %0d (expected %0d)", HRESP_B, exp_resp_B);
    //             correct_count ++;
    //         end
    //         else begin
    //             $display("[%0t] Read test case failed", $time);
    //             $display("  HRDATA_A: %0h (expected %0h)", HRDATA_A, exp_data_A);
    //             $display("  HREADY_A: %0d (expected %0d)", HREADY_A, exp_ready_A);
    //             $display("  HRESP_A : %0d (expected %0d)", HRESP_A, exp_resp_A);
    //             $display("  HRDATA_B: %0h (expected %0h)", HRDATA_B, exp_data_B);
    //             $display("  HREADY_B: %0d (expected %0d)", HREADY_B, exp_ready_B);
    //             $display("  HRESP_B : %0d (expected %0d)", HRESP_B, exp_resp_B);
    //             error_count ++;
    //         end
    //     end

    // endtask

endmodule


