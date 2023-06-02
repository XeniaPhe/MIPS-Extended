module mult3_to_1_32(out, i0, i1, i2, s);
input [31:0] i0, i1, i2;
input [1:0] s;
output [31:0] out;

always @(i0 or i1 or i2 or s)
begin
	case(s)
		2'b00: out = i0;
		2'b01: out = i1;
		2'b10: out = i2;
		2'b11: out = 32'b0;
	endcase

endmodule