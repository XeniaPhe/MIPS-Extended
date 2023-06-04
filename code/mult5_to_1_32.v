module mult5_to_1_32(out, i0, i1, i2, i3, i4, s);
input [31:0] i0, i1, i2, i3, i4;
input [2:0] s;
output reg [31:0] out;

always @(i0 or i1 or i2 or i3 or i4 or s)
begin
	case(s)
		3'b000: out = i0;
		3'b001: out = i1;
		3'b010: out = i2;
		3'b011: out = i3;
		3'b100: out = i4;
	endcase
end
endmodule