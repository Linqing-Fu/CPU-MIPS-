module mips_cpu(
	input  rst,
	input  clk,

	output [31:0] PC,
	input  [31:0] Instruction,

	output [31:0] Address,
	output MemWrite,
	output [31:0] Write_data,

	input  [31:0] Read_data,
	output MemRead
);

reg [31:0] PC;
wire [31:0] sign_extend;

//control's relevant wire define
wire RegDst;
wire Branch;
wire MemtoReg;
wire [1:0] ALUOp;
wire ALUSrc;
wire RegWrite;

//register's relevant wire define 
wire [4:0] write_reg;
wire [31:0] read_da1;
wire [31:0] read_da2;
wire [31:0] write_da;

//output of alu_control, which is alu's input:ALUop
wire [2:0] ALUctr;

//alu's relevant wire define
wire [31:0] B;
wire Zero;
wire [31:0] alu_resl;

assign sign_extend={{16{Instruction[15]}},Instruction[15:0]};//sign extend of 16bits Instruction
assign Write_data=read_da2;//one of output:
assign Address =alu_resl ;//calculate from alu

always@(posedge clk)
begin
    if(rst)//if not reset,PC=PC+4 or PC=(Branch&Zero==0)?PC+4:PC+4+(sign_extend<<2)
        PC<=32'b0;
    else
        PC<=((Branch==1&Zero==0)?PC+4+(sign_extend<<2):PC+4);
end

//assign PC=(rst==1)?32'b0:((Branch&Zero==0)?PC+4:PC+4+(sign_extend<<2));

Control contrl1(
	.Opcode(Instruction[31:26]),
	.RegDst(RegDst),
	.Branch(Branch),
	.MemRead(MemRead),
	.MemtoReg(MemtoReg),
	.ALUOp(ALUOp),
	.MemWrite(MemWrite),
	.ALUSrc(ALUSrc),
	.RegWrite(RegWrite)

	);
	
//alu control module
ALUcontrol aluctrl(.ALUOp(ALUOp),.ALUctr(ALUctr));

assign write_reg =(RegDst==1)?Instruction[15:11]:Instruction[20:16] ;
assign write_da =(MemtoReg==0)?alu_resl:Read_data ;

reg_file reg1(
	.clk(clk),
	.rst(rst),
	.waddr(write_reg),
	.raddr1(Instruction[25:21]),
	.raddr2(Instruction[20:16]),
	.wen(RegWrite),
	.wdata(write_da),
	.rdata1(read_da1),
	.rdata2(read_da2)
);

assign B =(ALUSrc==0)?read_da2:sign_extend;

alu alu1(
	.A(read_da1),
	.B(B),
	.ALUop(ALUctr),
	.Zero(Zero),
	.Result(alu_resl)
);

endmodule

	


module Control(
	input [5:0] Opcode,
	output RegDst,
	output Branch,
	output MemRead,
	output MemtoReg,
	output [1:0] ALUOp,
	output MemWrite,
	output ALUSrc,
	output RegWrite
	);
/*
	ADDIU: Opcode[0]&~Opcode[1]&~Opcode[2]&Opcode[3]&~Opcode[4]&~Opcode[5]
	lw: Opcode[0]&Opcode[1]&~Opcode[2]&~Opcode[3]&~Opcode[4]&Opcode[5]
	sw: Opcode[0]&Opcode[1]&~Opcode[2]&Opcode[3]&~Opcode[4]&Opcode[5]
	bne: Opcode[0]&~Opcode[1]&Opcode[2]&~Opcode[3]&~Opcode[4]&~Opcode[5]
*/
	assign Branch =Opcode[0]&~Opcode[1]&Opcode[2]&~Opcode[3]&~Opcode[4]&~Opcode[5];
	assign MemRead =Opcode[0]&Opcode[1]&~Opcode[2]&~Opcode[3]&~Opcode[4]&Opcode[5];
	assign MemWrite =Opcode[0]&Opcode[1]&~Opcode[2]&Opcode[3]&~Opcode[4]&Opcode[5];
	assign ALUOp ={Opcode[0]&~Opcode[1]&~Opcode[2]&Opcode[3]&~Opcode[4]&~Opcode[5],Branch};
	assign RegWrite =MemRead|ALUOp[1];
	assign ALUSrc =RegWrite|MemWrite;
	assign MemtoReg =MemRead;
	assign RegDst =0;

endmodule



module ALUcontrol(
	input [1:0] ALUOp,
	output [2:0] ALUctr
	);

	assign ALUctr={(ALUOp[0]&~ALUOp[1]),1'b1,1'b0};//if not stated, 0 will be considered 32bits

endmodule
