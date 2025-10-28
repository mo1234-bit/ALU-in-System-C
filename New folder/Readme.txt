Master A test
-------------
0470A023        sw   x7, 64(x1) --> Regfile[0] = FF
0220A023        sw   x2, 32(x1) --> Timer load = 2    
0220A0A3        sw   x7, 64(x1) --> Timer mode = down
0400A283        lw   x5, 64(x1) --> x5 = FF
0230A203        lw   x4, 35(x1) --> pulling on the finish flag till its 1     
0230A203        lw   x4, 35(x1) --> pulling on the finish flag till its 1    
0230A203        lw   x4, 35(x1) --> pulling on the finish flag till its 1    
0230A203        lw   x4, 35(x1) --> finish flag = 1
0050A223        sw   x7, 4(x1)  --> GPIO port A is driven with value = FF 
-------------
RV32I-test
-------------
00500113        addi x2, x0, 5  --> x2 = 5     
00C00193        addi x3,x0,12   --> x3 = 12
 

