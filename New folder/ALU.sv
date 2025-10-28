//ALU module
`timescale 1ns/1ps
module ALU (SrcA, SrcB, ALUControl, ALUResult, Zero);

input logic [2:0] ALUControl;
input logic [31:0] SrcA,SrcB;
output logic signed [31:0] ALUResult;
output logic Zero;

always_comb begin 

case(ALUControl)                                            //Some operations will be signed and the rest is unsigned

    3'b000: ALUResult = $signed(SrcA) + $signed(SrcB);      
    3'b001: ALUResult = $signed(SrcA) - $signed(SrcB);
    3'b010: ALUResult = SrcA & SrcB;
    3'b011: ALUResult = SrcA | SrcB;
    3'b101: begin                                           //SLT operation

        if($signed(SrcA) < $signed(SrcB)) ALUResult = 1;
        else ALUResult=0;
    end
    default: ALUResult = 0;
endcase
end 

assign Zero = (ALUResult==0)? 1'b1 : 1'b0;                    //Zero flag

endmodule
