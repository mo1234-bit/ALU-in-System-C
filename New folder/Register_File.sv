`timescale 1ns/1ps

module Register_File #(
    parameter REG_WIDTH = 8,
    parameter REG_DEPTH = 32
)(
    input  logic                        clk,
    input  logic                        rst_n,
    input  logic                        en,                 // Slave select
    input  logic[$clog2(REG_DEPTH)-1:0] Addr,              // Address (5-bit for 32 entries)
    input  logic       [1:0]            size,               // 00: byte, 01: halfword, 10: word
    input  logic                        we,                 // Write enable
    input  logic                        re,                 // Read enable
    input  logic       [31:0]           wd_data,            // Write data

    output logic       [31:0]           rd_data,            // Read data
    output logic                        done,               // HREADY equivalent
    output logic                        check              // HRESP equivalent (global error)
);

    // Register file declaration
    logic [REG_WIDTH-1:0] Reg_file [REG_DEPTH-1:0];
    
    // Internal signals
    logic [31:0]          data_check;
    logic                 halfword_ov, word_ov;
    logic                 data_error, addr_error;
    
    // Safe address calculations (explicit truncation)
    logic [$clog2(REG_DEPTH)-1:0] safe_addr_plus_1;
    logic [$clog2(REG_DEPTH)-1:0] safe_addr_plus_2;
    logic [$clog2(REG_DEPTH)-1:0] safe_addr_plus_3;

    assign safe_addr_plus_1 = Addr + 1;
    assign safe_addr_plus_2 = Addr + 2;
    assign safe_addr_plus_3 = Addr + 3;

    // Calculate overflow conditions
    assign halfword_ov = (size == 2'b01) && (Addr >= REG_DEPTH-1);
    assign word_ov     = (size == 2'b10) && (Addr >= REG_DEPTH-3);
    assign addr_error  = (we | re) & (halfword_ov | word_ov);

    // Data validation
    assign data_error = (size == 2'b00) ? (data_check > 8'hFF) :
                       (size == 2'b01) ? (data_check > 16'hFFFF) : 1'b0;

    // Output flags
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) 
            check <= 0;
        else
            check <= (en & (addr_error | data_error));
    end
    
    assign done = 1'b1;  // Always ready


    // Write operation (with boundary protection)
    always_ff @(posedge clk or negedge rst_n) begin 
        if (!rst_n) begin
            for (int i = 0; i < REG_DEPTH; i++) 
                Reg_file[i] <= '0;
        end else if (en && we && !addr_error) begin
            case (size)
                2'b00: Reg_file[Addr] <= wd_data[7:0];
                2'b01: begin
                    Reg_file[Addr]           <= wd_data[7:0];
                    Reg_file[safe_addr_plus_1] <= wd_data[15:8];
                end
                2'b10: begin
                    Reg_file[Addr]           <= wd_data[7:0]; 
                    Reg_file[safe_addr_plus_1] <= wd_data[15:8]; 
                    Reg_file[safe_addr_plus_2] <= wd_data[23:16];
                    Reg_file[safe_addr_plus_3] <= wd_data[31:24];
                end
                default: Reg_file[Addr] <= wd_data[7:0];
            endcase
        end
    end

    // Read operation (safe access)
    always_comb begin
        if (!rst_n) begin
            rd_data = '0;
        end else if (en && re) begin
            case (size)
                2'b00: rd_data = {24'h0, Reg_file[Addr]};
                2'b01: rd_data = addr_error ? 32'h0 : 
                                {16'h0, Reg_file[safe_addr_plus_1], Reg_file[Addr]};
                2'b10: rd_data = addr_error ? 32'h0 : 
                                {Reg_file[safe_addr_plus_3], Reg_file[safe_addr_plus_2], 
                                 Reg_file[safe_addr_plus_1], Reg_file[Addr]};
                default: rd_data = {24'h0, Reg_file[Addr]};
            endcase
        end else begin
            rd_data = '0;
        end
    end

    // Data check assignment
    always_comb begin
        data_check = we ? wd_data : (re ? rd_data : '0);
    end
endmodule