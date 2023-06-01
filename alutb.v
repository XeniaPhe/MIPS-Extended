`include "alu32.v"
`include "alucont.v"

module alutb();

wire [31:0] outp;
wire [2:0] gin;
wire zout;

reg [31:0] a, b;
reg op1 = 1'b1, op0 = 1'b0, f3 = 1'b0, f2 = 1'b0, f1 = 1'b0, f0 = 1'b0;

alucont cont(op1, op0, f3, f2, f1, f0, gin);
alu32 alu(outp, a, b, zout, gin);

initial begin
    $dumpfile("alutb.vcd");
    $dumpvars(0,alutb);
    
    a = 50;
    b = 100;
    #1

    a = 0;
    b = 0;
    #1

    a = -5;
    b = -10;
end

endmodule