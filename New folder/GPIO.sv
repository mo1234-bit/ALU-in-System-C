`timescale 1ns/1ps

module GPIO #(
    parameter GPIO_WIDTH = 8  // Width of each GPIO port
)(
    input  logic                                clk,
    input  logic                                rst_n,
    input  logic                                en,                 // Slave select
    input  logic       [2:0]                    Addr,               // Port address
    input  logic       [1:0]                    size,               // 00: byte, 01: halfword, 10: word (not used)
    input  logic                                we,                 // Write enable
    input  logic                                re,                 // Read enable
    input  logic       [31:0]                   wd_data,            // Write data
    input  logic       [GPIO_WIDTH-1:0]         GPIO_in_portA,      // Input GPIOs port A (Addr = 3'b 000)
    input  logic       [GPIO_WIDTH-1:0]         GPIO_in_portB,      // Input GPIOs port B (Addr = 3'b 001)
    input  logic       [GPIO_WIDTH-1:0]         GPIO_in_portC,      // Input GPIOs port C (Addr = 3'b 010)
    input  logic       [GPIO_WIDTH-1:0]         GPIO_in_portD,      // Input GPIOs port D (Addr = 3'b 011)
    output logic       [31:0]                   rd_data,            // Read data
    output logic       [GPIO_WIDTH-1:0]         GPIO_out_portA,     // Output GPIOs port A (Addr = 3'b 100)
    output logic       [GPIO_WIDTH-1:0]         GPIO_out_portB,     // Output GPIOs port B (Addr = 3'b 101)
    output logic       [GPIO_WIDTH-1:0]         GPIO_out_portC,     // Output GPIOs port C (Addr = 3'b 110)
    output logic       [GPIO_WIDTH-1:0]         GPIO_out_portD,     // Output GPIOs port D (Addr = 3'b 111)
    output logic                                done,               // Always ready
    output logic                                check               // Error flag (HRESP)
);

    // Drive Output GPIO Ports
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            GPIO_out_portA <= '0;
            GPIO_out_portB <= '0;
            GPIO_out_portC <= '0;
            GPIO_out_portD <= '0;
        end else if (en && we) begin
            case (Addr)
                3'b100: GPIO_out_portA <= wd_data[GPIO_WIDTH-1:0];
                3'b101: GPIO_out_portB <= wd_data[GPIO_WIDTH-1:0];
                3'b110: GPIO_out_portC <= wd_data[GPIO_WIDTH-1:0];
                3'b111: GPIO_out_portD <= wd_data[GPIO_WIDTH-1:0];
            endcase
        end
    end

    // Read from Input GPIO Ports
    always_comb begin
        rd_data = '0;
        if (en && re) begin
            case (Addr)
                3'b000:  rd_data[GPIO_WIDTH-1:0] = GPIO_in_portA;
                3'b001:  rd_data[GPIO_WIDTH-1:0] = GPIO_in_portB;
                3'b010:  rd_data[GPIO_WIDTH-1:0] = GPIO_in_portC;
                3'b011:  rd_data[GPIO_WIDTH-1:0] = GPIO_in_portD;
                default: rd_data[GPIO_WIDTH-1:0] = '0;                  // Invalid read from output ports
            endcase
        end
    end

    // Output flags
    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) 
            check <= 0;
        else if (en) begin
            if (we && ((Addr < 3'b100) || wd_data > {(GPIO_WIDTH){1'b1}}))  // Writing to input ports
                check <= 1'b1;
            if (re && ((Addr > 3'b011) || rd_data > {(GPIO_WIDTH){1'b1}}))  // Reading from output ports
                check <= 1'b1;
        end
    end
    
    // Done signal is always high
    assign done = 1'b1;

endmodule
