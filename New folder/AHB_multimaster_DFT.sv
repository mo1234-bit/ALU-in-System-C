`timescale 1ns/1ps

module AHB_multimaster_DFT #(
    parameter REG_WIDTH = 8,
    parameter REG_DEPTH = 32,
    parameter GPIO_WIDTH = 8,
    parameter COUNTER_WIDTH = 32
)(
    input                       HCLK,
    input                       HRESETn,
    input                       arbiter_WR, // 0: A has priority, 1: B has priority

    // DFT signals
    input                       scan_in,
    input                       scan_en,
    input                       scan_mode,
    input                       scan_clk,
    input                       scan_rst,
    output                      scan_out,

    // Master B inputs
    input  [31:0]               PADDR_B,
    input                       PWRITE_B,
    input  [1:0]                PSIZE_B,
    input  [1:0]                PTRANS_B,
    input  [2:0]                PBURST_B,
    input  [31:0]               PWDATA_B,

    // GPIO inputs
    input  [GPIO_WIDTH-1:0]     GPIO_in_portA,      
    input  [GPIO_WIDTH-1:0]     GPIO_in_portB,      
    input  [GPIO_WIDTH-1:0]     GPIO_in_portC,      
    input  [GPIO_WIDTH-1:0]     GPIO_in_portD,      
    input                       Register_File_En,
    input                       GPIO_En,
    input                       Timer_En,

    // Master B outputs
    output                      PREADY_B,
    output                      PRESP_B,
    output [31:0]               PRDATA_B,

    // GPIO outputs
    output [GPIO_WIDTH-1:0]     GPIO_out_portA,     
    output [GPIO_WIDTH-1:0]     GPIO_out_portB,     
    output [GPIO_WIDTH-1:0]     GPIO_out_portC,     
    output [GPIO_WIDTH-1:0]     GPIO_out_portD    
);

    // DFT internal signals
    logic        sys_clk;
    logic        sync_rst;
    logic        sys_rst;
    logic        rst_n;

    // RISCV32I - pipelined signals
    logic  [31:0]               PADDR_A;
    logic                       PWRITE_A;
    logic  [1:0]                PSIZE_A;
    logic  [1:0]                PTRANS_A;
    logic  [2:0]                PBURST_A;
    logic  [31:0]               PWDATA_A;
    logic                       PREADY_A;
    logic                       PRESP_A;
    logic [31:0]                PRDATA_A;

    // Master A inputs
    logic  [31:0]               HADDR_A;
    logic                       HWRITE_A;
    logic  [1:0]                HSIZE_A;
    logic  [1:0]                HTRANS_A;
    logic  [2:0]                HBURST_A;
    logic  [31:0]               HWDATA_A;

    // Master B inputs
    logic  [31:0]               HADDR_B;
    logic                       HWRITE_B;
    logic  [1:0]                HSIZE_B;
    logic  [1:0]                HTRANS_B;
    logic  [2:0]                HBURST_B;
    logic  [31:0]               HWDATA_B;

    // Master A outputs
    logic                      HREADY_A;
    logic                      HRESP_A;
    logic [31:0]               HRDATA_A;

    // Master B outputs
    logic                      HREADY_B;
    logic                      HRESP_B;
    logic [31:0]               HRDATA_B;


    // -----------------------
    // Scan MUXing
    // -----------------------
    Multiplexor_2to1 DFT_clock (
        .in1    (HCLK),
        .in2    (scan_clk),
        .sel    (scan_mode),
        .mux_out(sys_clk)
    );

    Multiplexor_2to1 DFT_rst (
        .in1    (HRESETn),
        .in2    (scan_rst),
        .sel    (scan_mode),
        .mux_out(sys_rst)
    );


    Multiplexor_2to1 DFT_sync_rst (
        .in1    (sys_sync_rst),
        .in2    (scan_rst),
        .sel    (scan_mode),
        .mux_out(rst_n)
    );

    // -----------------------------------------------
    // Reset synchronizer
    // -----------------------------------------------
    Rst_sync Reset_synchronizer(
        .clk(HCLK),
        .async_rst_n(sys_rst),
        .sync_rst_n(sys_sync_rst)
    );


    // -----------------------------------------------
    // Slave selects
    // -----------------------------------------------
    logic HSEL_G_A, HSEL_T_A, HSEL_R_A;
    logic HSEL_G_B, HSEL_T_B, HSEL_R_B;

    // -----------------------------------------------
    // Internal slave bus signals (separate for each slave)
    // -----------------------------------------------
    // Register File
    logic [31:0] HADDR_R; logic HWRITE_R; logic [1:0] HSIZE_R; logic [1:0] HTRANS_R; logic [2:0] HBURST_R; logic [31:0] HWDATA_R;
    logic [31:0] HRDATA_R; logic HREADY_R; logic HRESP_R;
    logic [31:0] Addr_R, wd_data_R; logic [1:0] size_R; 
    logic register_file_we, register_file_re;
    logic [31:0] register_file_rd_data; logic register_file_ready, register_file_response;

    // GPIO
    logic [31:0] HADDR_G; logic HWRITE_G; logic [1:0] HSIZE_G; logic [1:0] HTRANS_G; logic [2:0] HBURST_G; logic [31:0] HWDATA_G;
    logic [31:0] HRDATA_G; logic HREADY_G; logic HRESP_G;
    logic [31:0] Addr_G, wd_data_G; logic [1:0] size_G;
    logic gpio_we, gpio_re;
    logic [31:0] gpio_rd_data; logic gpio_ready, gpio_response;

    // Timer
    logic [31:0] HADDR_T; logic HWRITE_T; logic [1:0] HSIZE_T; logic [1:0] HTRANS_T; logic [2:0] HBURST_T; logic [31:0] HWDATA_T;
    logic [31:0] HRDATA_T; logic HREADY_T; logic HRESP_T;
    logic [31:0] Addr_T, wd_data_T; logic [1:0] size_T;
    logic timer_we, timer_re;
    logic [31:0] timer_rd_data; logic timer_ready, timer_response;

    // -----------------------------------------------
    // RISCV32I
    // -----------------------------------------------
    RV32I_pipelined RiscV (
        .clk(sys_clk),
        .rst_n(rst_n),             // active-low reset
        .PRDATA_A(PRDATA_A),
        .PREADY_A(PREADY_A),
        .PRESP_A(PRESP_A),
        .PADDR_A(PADDR_A),
        .PWRITE_A(PWRITE_A),
        .PSIZE_A(PSIZE_A),
        .PTRANS_A(PTRANS_A),
        .PBURST_A(PBURST_A),
        .PWDATA_A(PWDATA_A)
    );

    // -----------------------------------------------
    // Master A interface
    // -----------------------------------------------
    AHB_lite_master AHB_Master_A_Interface_block (
        .HCLK(sys_clk), .HRESETn(rst_n),
        .PADDR(PADDR_A), .PWRITE(PWRITE_A), .PSIZE(PSIZE_A), .PTRANS(PTRANS_A), .PBURST(PBURST_A), .PWDATA(PWDATA_A),
        .HADDR(HADDR_A), .HWRITE(HWRITE_A), .HSIZE(HSIZE_A), .HTRANS(HTRANS_A), .HBURST(HBURST_A), .HWDATA(HWDATA_A),
        .HREADY(HREADY_A), .HRESP(HRESP_A), .HRDATA(HRDATA_A),
        .PREADY(PREADY_A), .PRESP(PRESP_A), .PRDATA(PRDATA_A)
    );

    // -----------------------------------------------
    // Master B interface
    // -----------------------------------------------
    AHB_lite_master AHB_Master_B_Interface_block (
        .HCLK(sys_clk), .HRESETn(rst_n),
        .PADDR(PADDR_B), .PWRITE(PWRITE_B), .PSIZE(PSIZE_B), .PTRANS(PTRANS_B), .PBURST(PBURST_B), .PWDATA(PWDATA_B),
        .HADDR(HADDR_B), .HWRITE(HWRITE_B), .HSIZE(HSIZE_B), .HTRANS(HTRANS_B), .HBURST(HBURST_B), .HWDATA(HWDATA_B),
        .HREADY(HREADY_B), .HRESP(HRESP_B), .HRDATA(HRDATA_B),
        .PREADY(PREADY_B), .PRESP(PRESP_B), .PRDATA(PRDATA_B)
    );

    // -----------------------------------------------
    // Address decoder
    // -----------------------------------------------
    Decoder AHB_Decoder_block (
        .HADDR_A(HADDR_A),
        .HADDR_B(HADDR_B),
        .HSEL_G_A(HSEL_G_A),
        .HSEL_T_A(HSEL_T_A),
        .HSEL_R_A(HSEL_R_A),
        .HSEL_G_B(HSEL_G_B),
        .HSEL_T_B(HSEL_T_B),
        .HSEL_R_B(HSEL_R_B)
    );

    // -----------------------------------------------
    // Multiplexer to select HRDATA/HREADY/HRESP
    // -----------------------------------------------
    Mux AHB_Multiplexer_block (
        .arbiter_WR(arbiter_WR), .clk(sys_clk), .rst_n(rst_n),
        // A-side
        .HSEL_G_A(HSEL_G_A), .HSEL_T_A(HSEL_T_A), .HSEL_R_A(HSEL_R_A),
        .HRDATA_G_A(HRDATA_G), .HRDATA_T_A(HRDATA_T), .HRDATA_R_A(HRDATA_R),
        .HREADY_G_A(HREADY_G), .HREADY_T_A(HREADY_T), .HREADY_R_A(HREADY_R),
        .HRESP_G_A(HRESP_G), .HRESP_T_A(HRESP_T), .HRESP_R_A(HRESP_R),
        // B-side
        .HSEL_G_B(HSEL_G_B), .HSEL_T_B(HSEL_T_B), .HSEL_R_B(HSEL_R_B),
        .HRDATA_G_B(HRDATA_G), .HRDATA_T_B(HRDATA_T), .HRDATA_R_B(HRDATA_R),
        .HREADY_G_B(HREADY_G), .HREADY_T_B(HREADY_T), .HREADY_R_B(HREADY_R),
        .HRESP_G_B(HRESP_G), .HRESP_T_B(HRESP_T), .HRESP_R_B(HRESP_R),
        // Outputs
        .HRDATA_A(HRDATA_A), .HREADY_A(HREADY_A), .HRESP_A(HRESP_A),
        .HRDATA_B(HRDATA_B), .HREADY_B(HREADY_B), .HRESP_B(HRESP_B)
    );

    // -----------------------------------------------
    // Register File Arbiter and Slave
    // -----------------------------------------------
    AHB_arbiter AHB_arbiter_RF (
        .arbiter_WR(arbiter_WR), .HCLK(sys_clk), .HRESETn(rst_n),
        .HADDR_A(HADDR_A), .HWRITE_A(HWRITE_A), .HSIZE_A(HSIZE_A), .HTRANS_A(HTRANS_A), .HBURST_A(HBURST_A), .HWDATA_A(HWDATA_A), .HSEL_P_A(HSEL_R_A),
        .HADDR_B(HADDR_B), .HWRITE_B(HWRITE_B), .HSIZE_B(HSIZE_B), .HTRANS_B(HTRANS_B), .HBURST_B(HBURST_B), .HWDATA_B(HWDATA_B), .HSEL_P_B(HSEL_R_B),
        .HSEL_P(HSEL_R), 
        .HADDR(HADDR_R), .HWRITE(HWRITE_R), .HSIZE(HSIZE_R), .HTRANS(HTRANS_R), .HBURST(HBURST_R), .HWDATA(HWDATA_R)
    );

    AHB_slave_if AHB_Register_file_Interface_block (
        .HCLK(sys_clk), .HRESETn(rst_n), .arbiter_WR(arbiter_WR),
        .HADDR(HADDR_R), .HWRITE(HWRITE_R), .HSIZE(HSIZE_R), .HTRANS(HTRANS_R), .HWDATA(HWDATA_R),
        .HSEL_P(HSEL_R), .HREADY_A(HREADY_A), .HREADY_B(HREADY_B),
        .peripheral_rd_data(register_file_rd_data), .peripheral_ready(register_file_ready), .peripheral_response(register_file_response),
        .HRDATA_P(HRDATA_R), .HREADY_P(HREADY_R), .HRESP_P(HRESP_R),
        .peripheral_we(register_file_we), .peripheral_re(register_file_re),
        .Addr(Addr_R), .size(size_R), .wd_data(wd_data_R)
    );

    Register_File #(
        .REG_WIDTH(REG_WIDTH),
        .REG_DEPTH(REG_DEPTH)
    ) Register_File_slave (
        .clk(sys_clk), .rst_n(rst_n), .en(Register_File_En),
        .Addr(Addr_R[$clog2(REG_DEPTH)-1:0]), .size(size_R), .we(register_file_we), .re(register_file_re),
        .wd_data(wd_data_R), .rd_data(register_file_rd_data),
        .done(register_file_ready), .check(register_file_response)
    );

    // -----------------------------------------------
    // GPIO Arbiter and Slave
    // -----------------------------------------------
    AHB_arbiter AHB_arbiter_GPIO (
        .arbiter_WR(arbiter_WR), .HCLK(sys_clk), .HRESETn(rst_n),
        .HADDR_A(HADDR_A), .HWRITE_A(HWRITE_A), .HSIZE_A(HSIZE_A), .HTRANS_A(HTRANS_A), .HBURST_A(HBURST_A), .HWDATA_A(HWDATA_A), .HSEL_P_A(HSEL_G_A),
        .HADDR_B(HADDR_B), .HWRITE_B(HWRITE_B), .HSIZE_B(HSIZE_B), .HTRANS_B(HTRANS_B), .HBURST_B(HBURST_B), .HWDATA_B(HWDATA_B), .HSEL_P_B(HSEL_G_B),
        .HSEL_P(HSEL_G), 
        .HADDR(HADDR_G), .HWRITE(HWRITE_G), .HSIZE(HSIZE_G), .HTRANS(HTRANS_G), .HBURST(HBURST_G), .HWDATA(HWDATA_G)
    );

    AHB_slave_if AHB_GPIO_Interface_block (
        .HCLK(sys_clk), .HRESETn(rst_n), .arbiter_WR(arbiter_WR),
        .HADDR(HADDR_G), .HWRITE(HWRITE_G), .HSIZE(HSIZE_G), .HTRANS(HTRANS_G), .HWDATA(HWDATA_G),
        .HSEL_P(HSEL_G), .HREADY_A(HREADY_A), .HREADY_B(HREADY_B),
        .peripheral_rd_data(gpio_rd_data), .peripheral_ready(gpio_ready), .peripheral_response(gpio_response),
        .HRDATA_P(HRDATA_G), .HREADY_P(HREADY_G), .HRESP_P(HRESP_G),
        .peripheral_we(gpio_we), .peripheral_re(gpio_re),
        .Addr(Addr_G [2:0]), .size(size_G), .wd_data(wd_data_G)
    );

    GPIO #(
        .GPIO_WIDTH(GPIO_WIDTH)
    ) GPIO_slave (
        .clk(sys_clk), .rst_n(rst_n), .en(GPIO_En),
        .Addr(Addr_G [2:0]), .size(size_G), .we(gpio_we), .re(gpio_re),
        .wd_data(wd_data_G),
        .GPIO_in_portA(GPIO_in_portA), .GPIO_in_portB(GPIO_in_portB),
        .GPIO_in_portC(GPIO_in_portC), .GPIO_in_portD(GPIO_in_portD),
        .rd_data(gpio_rd_data),
        .GPIO_out_portA(GPIO_out_portA), .GPIO_out_portB(GPIO_out_portB),
        .GPIO_out_portC(GPIO_out_portC), .GPIO_out_portD(GPIO_out_portD),
        .done(gpio_ready), .check(gpio_response)
    );

    // -----------------------------------------------
    // Timer Arbiter and Slave
    // -----------------------------------------------
    AHB_arbiter AHB_arbiter_Timer (
        .arbiter_WR(arbiter_WR), .HCLK(sys_clk), .HRESETn(rst_n),
        .HADDR_A(HADDR_A), .HWRITE_A(HWRITE_A), .HSIZE_A(HSIZE_A), .HTRANS_A(HTRANS_A), .HBURST_A(HBURST_A), .HWDATA_A(HWDATA_A), .HSEL_P_A(HSEL_T_A),
        .HADDR_B(HADDR_B), .HWRITE_B(HWRITE_B), .HSIZE_B(HSIZE_B), .HTRANS_B(HTRANS_B), .HBURST_B(HBURST_B), .HWDATA_B(HWDATA_B), .HSEL_P_B(HSEL_T_B),
        .HSEL_P(HSEL_T),
        .HADDR(HADDR_T), .HWRITE(HWRITE_T), .HSIZE(HSIZE_T), .HTRANS(HTRANS_T), .HBURST(HBURST_T), .HWDATA(HWDATA_T)
    );

    AHB_slave_if AHB_Timer_Interface_block (
        .HCLK(sys_clk), .HRESETn(rst_n), .arbiter_WR(arbiter_WR),
        .HADDR(HADDR_T), .HWRITE(HWRITE_T), .HSIZE(HSIZE_T), .HTRANS(HTRANS_T), .HWDATA(HWDATA_T),
        .HSEL_P(HSEL_T), .HREADY_A(HREADY_A), .HREADY_B(HREADY_B),
        .peripheral_rd_data(timer_rd_data), .peripheral_ready(timer_ready), .peripheral_response(timer_response),
        .HRDATA_P(HRDATA_T), .HREADY_P(HREADY_T), .HRESP_P(HRESP_T),
        .peripheral_we(timer_we), .peripheral_re(timer_re),
        .Addr(Addr_T), .size(size_T), .wd_data(wd_data_T)
    );

    Timer #(
        .COUNTER_WIDTH(COUNTER_WIDTH)
    ) Timer_slave (
        .clk(sys_clk), .rst_n(rst_n), .en(Timer_En),
        .Addr(Addr_T[1:0]), .size(size_T), .we(timer_we), .re(timer_re),
        .load(wd_data_T[COUNTER_WIDTH-1:0]),
        .counter_value(timer_rd_data[COUNTER_WIDTH-1:0]),
        .done(timer_ready), .check(timer_response)
    );

endmodule
