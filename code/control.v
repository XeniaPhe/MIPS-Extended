module control(
    input [5:0] in,
    input [5:0] funct,
    output regdest,
    output alusrc,
    output shift,
    output jz,
    output js,
    output jmem,
    output bmem,
    output memtoreg,
    output pctoreg,
    output regwrite,
    output memread,
    output memwrite,
    output branch,
    output aluop1,
    output aluop2);

wire rformat,lw,sw,beq;

assign rformat=~|in;
assign lw=in[5]& (~in[4])&(~in[3])&(~in[2])&in[1]&in[0];
assign sw=in[5]& (~in[4])&in[3]&(~in[2])&in[1]&in[0];
assign beq=~in[5]& (~in[4])&(~in[3])&in[2]&(~in[1])&(~in[0]);
assign regdest=rformat|shift;
assign alusrc=lw|sw|bmem;
assign memtoreg=lw;
assign regwrite=rformat|lw|shift;
assign memread=lw|bmem|jmem|js;
assign memwrite=sw|js;
assign branch=beq;
assign aluop1=rformat;
assign aluop2=beq;
assign pctoreg = rformat & (~funct[5]) & funct[4] & (~funct[3] & funct[2] & funct[1] & (~funct[0]));
assign jmem = rformat & (funct[5] & (~funct[4]) & (funct[3]) & funct[2] & (~funct[1]) & funct[0]);
assign bmem = (~in[5]) & in[4] & (~in[3]) & in[2] & (~in[1]) & (~in[0]);
assign js = (~in[5]) & in[4] & (~in[3]) & (~in[2]) & in[1] & in[0];
assign jz = (~in[5]) & in[4] & in[3] & (~in[2]) & (in[1]) & (~in[0]);
assign shift = rformat & (~funct[5]) & (~funct[4]) & (~funct[3]) & funct[2] & (~funct[1]) & (~funct[0]);
endmodule
