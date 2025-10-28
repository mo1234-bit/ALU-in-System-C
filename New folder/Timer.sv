`timescale 1ns/1ps

module Timer #(
    parameter COUNTER_WIDTH = 32
)(
    input                               clk,
    input                               rst_n,
    input                               en,                 
    input       [1:0]                   Addr,               // Register address           
    input                               we,                 
    input                               re,  
    input       [COUNTER_WIDTH-1:0]     load,                   
    input       [1:0]                   size,               // Not used here

    output logic [COUNTER_WIDTH-1:0]    counter_value,      
    output                              done,               
    output logic                        check               
);

    // Mode encoding
    typedef enum logic [2:0] {
        MODE_IDLE        = 3'b000,
        MODE_UP          = 3'b001,
        MODE_DOWN        = 3'b010,
        MODE_FREE_RUN    = 3'b011,
        MODE_PERIODIC    = 3'b100,
        MODE_UP_DOWN     = 3'b101
    } mode_t;

    // Internal registers
    logic [COUNTER_WIDTH-1:0] counter_reg;
    logic [COUNTER_WIDTH-1:0] reload_reg;
    logic finish_flag;
    mode_t mode;
    logic dir; // direction for up/down mode

    // Sequential logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_reg <= '0;
            reload_reg <= '0;
            mode <= MODE_IDLE;
            finish_flag <= 1'b0;
            dir <= 1'b1;
        end 
        else if (en && we) begin
            case (Addr)
                2'b00: counter_reg <= load;            // Load counter
                2'b01: mode <= mode_t'(load[2:0]);     // Set mode
                2'b10: reload_reg <= load;             // Load reload value (periodic)
            endcase
            finish_flag <= 1'b0;
        end
        else if (en) begin
            case (mode)
                MODE_UP: begin
                    if (counter_reg < {COUNTER_WIDTH{1'b1}})
                        counter_reg <= counter_reg + 1;
                    else begin
                        finish_flag <= 1'b1;
                        mode <= MODE_IDLE;
                    end
                end
                MODE_DOWN: begin
                    if (counter_reg > 0)
                        counter_reg <= counter_reg - 1;
                    else begin
                        finish_flag <= 1'b1;
                        mode <= MODE_IDLE;
                    end
                end
                MODE_FREE_RUN: begin //overflow
                    counter_reg <= counter_reg + 1; // wraps naturally
                end
                MODE_PERIODIC: begin
                    if (counter_reg > 0)
                        counter_reg <= counter_reg - 1;
                    else
                        counter_reg <= reload_reg; // auto reload
                end
                MODE_UP_DOWN: begin
                    if (dir) begin
                        if (counter_reg < {COUNTER_WIDTH{1'b1}})
                            counter_reg <= counter_reg + 1;
                        else dir <= 1'b0;
                    end else begin
                        if (counter_reg > 0)
                            counter_reg <= counter_reg - 1;
                        else dir <= 1'b1;
                    end
                end
            endcase
        end
    end

    // Read logic
    always_comb begin
        counter_value = '0;
        if (en && re) begin
            case (Addr)
                2'b00: counter_value = counter_reg;
                2'b01: counter_value = {{(COUNTER_WIDTH-3){1'b0}}, mode};
                2'b10: counter_value = reload_reg;
                2'b11: counter_value = {{(COUNTER_WIDTH-1){1'b0}}, finish_flag};
                default: counter_value = '0;
            endcase
        end
    end

    // Output flags
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) 
            check <= 0;
        else
            check <= (rst_n && en && we && Addr == 2'b11);
    end
    
    assign done = 1'b1;  // Always ready


endmodule
