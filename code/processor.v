`include "adder.v"
`include "alu32.v"
`include "alucont.v"
`include "control.v"
`include "mult2_to_1_32.v"
`include "mult6_to_1_32.v"
`include "mult2_to_1_5.v"
`include "shift.v"
`include "signext.v"

module processor;
reg [31:0] pc; //32-bit prograom counter
reg clk; //clock
reg [7:0] datmem[0:31],mem[0:31]; //32-size data and instruction memory (8 bit(1 byte) for each location)
wire [31:0] 
dataa,	//Read data 1 output of Register File
datab,	//Read data 2 output of Register File
out2,		//Output of mux with ALUSrc control-mult2
out3,		//Output of mux with MemToReg control-mult3
out6,		//Output of mux with (Branch&ALUZero) control-mult6
sum,		//ALU result
extad,	//Output of sign-extend unit
pcnext,	//Output of adder which adds PC and 4-add1
brlabel,	//Output of adder which adds PC+4 and 2 shifted sign-extend result-add2
sextad;	//Output of shift left 2 unit

wire [5:0] inst31_26, inst5_0;	//31-26 bits of instruction
wire [4:0] 
inst25_21,	//25-21 bits of instruction
inst20_16,	//20-16 bits of instruction
inst15_11,	//15-11 bits of instruction
out1;		//Write data input of Register File

wire [15:0] inst15_0;	//15-0 bits of instruction

wire [31:0] instruc,	//current instruction
dpack;	//Read data output of memory (data read from memory)

wire [2:0] gout;	//Output of ALU control unit

wire _n, _v;	//Values of status registers returned from the ALU(zout also)
reg z, n, v;	//Status registers

wire zout,	//Zero output of ALU
//Control signals
shift,jz,js,bmem,jmem,pctoreg,regdest,alusrc,memtoreg,regwrite,memread,memwrite,branch,aluop1,aluop0;

//32-size register file (32 bit(1 word) for each register)
reg [31:0] registerfile[0:31];

integer i;

// datamemory connections

/**
	1- read the datmem[registerfile[29]] assign it to var x
	2- assign x to the 5th port of the MUX
	3- write pc to the datmem[registerfile[29]]
	4- jump to the address x (will happen in negedge clk)
*/

reg [31:0] stackvalue;

always @(posedge clk)
begin
	//write data to memory
	if(jmem || pctoreg || jz)
		registerfile[pctoreg ? inst15_11 : 31] = pc;
	else if(regwrite)
		registerfile[out1]= out3;

	if (memwrite)
	begin 
		if (js)
		begin
			
			stackvalue=datmem[registerfile[29]];
			datmem[registerfile[29]]=pc;
		end else
		begin
			//sum stores address,datab stores the value to be written
			datmem[sum[4:0]+3]=datab[7:0];
			datmem[sum[4:0]+2]=datab[15:8];
			datmem[sum[4:0]+1]=datab[23:16];
			datmem[sum[4:0]]=datab[31:24];
		end	
	end
end

// load pc
always @(negedge clk)
begin
	pc = out6;
	z = zout;
	n = _n;
	v = _v;

	
end

//instruction memory
//4-byte instruction
 assign instruc={mem[pc[4:0]],mem[pc[4:0]+1],mem[pc[4:0]+2],mem[pc[4:0]+3]};
 assign inst31_26=instruc[31:26];
 assign inst5_0=instruc[5:0];
 assign inst25_21=instruc[25:21];
 assign inst20_16=instruc[20:16];
 assign inst15_11=instruc[15:11];
 assign inst15_0=instruc[15:0];

// registers

assign dataa=registerfile[inst25_21];//Read register 1
assign datab=registerfile[inst20_16];//Read register 2

//read data from memory, sum stores address
assign dpack={datmem[sum[5:0]],datmem[sum[5:0]+1],datmem[sum[5:0]+2],datmem[sum[5:0]+3]};

//multiplexers
//mux with RegDst control
mult2_to_1_5  mult1(out1, instruc[20:16],instruc[15:11],regdest);

//mux with ALUSrc control
mult2_to_1_32 mult2(out2, datab,extad,alusrc);

//mux with ALU sum and memory read
mult2_to_1_32 mult3(out3, sum,dpack,memtoreg);


// Declare a 2-bit wire
wire [2:0] select_bits_mult6;

// Assign values to the wire
assign select_bits_mult6[0] = (pctoreg | jz | js | jmem | bmem | branch) &
((~pctoreg) | jz | js | jmem | bmem | branch | (~z)) &
(pctoreg | jz | (~js) | jmem | bmem | branch);

assign select_bits_mult6[1] = (pctoreg & (~jz) & (~js) & (~jmem) & (~bmem) & (~branch) & z) |
((~pctoreg) & (~jz) & (~js) & jmem & (~bmem) & (~branch)) |
((~pctoreg) & (~jz) & (~js) & (~jmem) & bmem & (~branch) & z);

assign select_bits_mult6[2] = ((~pctoreg) & (~jz) & js & (~jmem) & (~bmem) & (~branch)) |
((~pctoreg) & jz & (~js) & (~jmem) & (~bmem) & (~branch) & z);

wire [31:0] jump_target;
assign jump_target = {pc[31:28], instruc[25:0], 2'b00};

//shift alu result left by 2
shift shift1(sextad,sum);

// Pass the wire as an input to the module
mult6_to_1_32 mult6(out6, pcnext,brlabel,sextad,dpack,stackvalue,jump_target,select_bits_mult6);

//ALU unit
alu32 alu1(sum,_n,_v,dataa,out2,zout,gout);

//adder which adds PC and 4
adder add1(pc,32'h4,pcnext);

//adder which adds PC+4 and 2 shifted sign-extend result
adder add2(pcnext,sextad,brlabel);

//Control unit
control cont(instruc[31:26],instruc[5:0],regdest,alusrc,shift,jz,js,jmem,bmem,memtoreg,pctoreg,regwrite,memread,memwrite,branch,
aluop1,aluop0);

//Sign extend unit
signext sext(instruc[15:0],extad);

//ALU control unit
alucont acont(aluop1,aluop0,instruc[5],instruc[4],instruc[3],instruc[2], instruc[1], instruc[0] ,gout);

//Shift-left 2 unit
shift shift2(sextad,extad);

//initialize datamemory,instruction memory and registers
//read initial data from files given in hex
initial
begin
$readmemh("initDm.dat",datmem); //read Data Memory
$readmemh("initIM.dat",mem);//read Instruction Memory
$readmemh("initReg.dat",registerfile);//read Register File

	for(i=0; i<31; i=i+1)
	$display("Instruction Memory[%0d]= %h  ",i,mem[i],"Data Memory[%0d]= %h   ",i,datmem[i],
	"Register[%0d]= %h",i,registerfile[i]);
end

initial
begin
pc=0;
#400 $finish;
	
end
initial
begin
clk=0;
//40 time unit for each cycle
forever #20  clk=~clk;
end
initial 
begin
  $monitor($time,"PC %h",pc,"  SUM %h",sum,"   INST %h",instruc[31:0],
"   REGISTER %h %h %h %h ",registerfile[4],registerfile[5], registerfile[6],registerfile[1] );
end
endmodule

