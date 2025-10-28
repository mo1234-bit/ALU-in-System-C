//Instruction Memory 
`timescale 1ns/1ps
module instruction_mem(clk, A, we, data, Instr);
    input  logic        clk;
    input  logic [31:0] A;
    input  logic        we;
    input  logic [31:0] data; 
    output logic [31:0] Instr;

    localparam WIDTH = 32;                            //Width of the Mem
    localparam DEPTH = 256;                           //Depth of the Mem

    // Assuming a smaller memory size for practicality (e.g., 1024 instructions).
    logic [WIDTH-1:0] instruction_memory [0:DEPTH-1];  // 1 KB memory (word addressable)

    initial $readmemh("Inst_mem_init.dat",instruction_memory);

    always@(posedge clk) begin
        if(we)
            instruction_memory[A[31:2]] <= data; //word alligned
    end
    assign Instr = instruction_memory [A[31:2]];
endmodule
