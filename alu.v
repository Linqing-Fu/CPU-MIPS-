//`define PRJ1_FPGA_IMPL
`ifdef PRJ1_FPGA_IMPL
	// the board does not have enough GPIO, so we implement a 4-bit ALU
    `define DATA_WIDTH 4
`else
    `define DATA_WIDTH 32
`endif

module alu(
	input [`DATA_WIDTH - 1:0] A,
	input [`DATA_WIDTH - 1:0] B,
	input [2:0] ALUop,
	output Overflow,
	output CarryOut,
	output Zero,
	output [`DATA_WIDTH - 1:0] Result
);


wire [`DATA_WIDTH - 1:0] Bin;//add module's input:b 
wire [`DATA_WIDTH - 1:0] add;//result of add module
wire [`DATA_WIDTH - 1:0] cout;//carryout of every bit
wire cin;
reg  [`DATA_WIDTH - 1:0] Result;


assign Bin=(ALUop[2]==1)?~B:B;//if ALUop is sub,then B transform to ~B
assign cin=(ALUop[2]==1)?1:0;//if ALUop is sub,then cin=1

`ifdef PRJ1_FPGA_IMPL//use 4bits add module

add4 a1(A,Bin,cin,cout[`DATA_WIDTH - 2],cout[`DATA_WIDTH - 1],add);

`else//use 32bits add module

add32 a2(A,Bin,cin,cout[`DATA_WIDTH - 2],cout[`DATA_WIDTH - 1],add);

`endif


always@(*)
begin
    case(ALUop)
    3'b000:Result=A&B;//logic calculate
    3'b001:Result=A|B;
    3'b010:Result=add;//use advanced add module's output to Result
    3'b110:Result=add;//use advanced add module's output to Result
    3'b111:Result=add[`DATA_WIDTH - 1]^Overflow;//output slt
    default:Result=`DATA_WIDTH'bx;
    endcase
end

assign Overflow = ((ALUop[1]==1)?cout[`DATA_WIDTH - 1]^cout[`DATA_WIDTH - 2]:0);//if isn't do add,sub,then Overflow always equal 0
assign Zero =(ALUop[1]==1)?((Result==`DATA_WIDTH'b0)?1:0):0;//if isn't do add,sub,then Zero always equal 0
assign CarryOut =(ALUop[1]==1)?cout[`DATA_WIDTH-1]^cin:0;//if isn't do add,sub,then CarryOut always equal 0

endmodule

///////////////////////////////////////////////////////////////
// four-bits modules to do 4bits advanced add
///////////////////////////////////////////////////////////////
module add4(  
    input [3:0] a,  
    input [3:0] b,  
    input cin,//lowest carryin
    output cout1,//second highest carryout
    output cout2,//highest carryout
    output [3:0] result
    
    );  
wire [3:0] p;
wire [3:0] g;  
wire [3:0] c;//store every bit's carryout
assign c[0] =cin ;
assign p=a|b;
assign g=a&b;
assign c[1] =g[0]|(p[0]&c[0]) ;
assign c[2] =g[1]|(p[1]&(g[0]|(p[0]&c[0]))) ;
assign cout1 =g[2]|(p[2]&(g[1]|(p[1]&(g[0]|p[0]&c[0])))) ;
assign cout2 =g[3]|(p[3]&(g[2]|(p[2]&(g[1]|(p[1]&(g[0]|(p[0]&c[0]))))))); 
assign result=a+b+cin;
/*
assign result[0]=g[0]^p[0]^c[0];
assign result[1]=g[1]^p[1]^c[1];
assign result[2]=g[2]^p[2]^c[2];
assign result[3]=g[3]^p[3]^cout1;*/

endmodule  

///////////////////////////////////////////////////////////////
//use eight four-bits modules to do 32bits add
///////////////////////////////////////////////////////////////
module add32
(  
    input [31:0] a,  
    input [31:0] b,  
    input cin,
    output cout1,//second highest carryout
    output cout2,//highest carryout
    output [31:0] result
    
    );  
    wire [15:0] cout;

    add4 a3(a[3:0],b[3:0],cin,cout[0],cout[1],result[3:0]);
    add4 a4(a[7:4],b[7:4],cout[1],cout[2],cout[3],result[7:4]);
    add4 a5(a[11:8],b[11:8],cout[3],cout[4],cout[5],result[11:8]);
    add4 a6(a[15:12],b[15:12],cout[5],cout[6],cout[7],result[15:12]);
    add4 a7(a[19:16],b[19:16],cout[7],cout[8],cout[9],result[19:16]);
    add4 a8(a[23:20],b[23:20],cout[9],cout[10],cout[11],result[23:20]);
    add4 a9(a[27:24],b[27:24],cout[11],cout[12],cout[13],result[27:24]);
    add4 a10(a[31:28],b[31:28],cout[13],cout1,cout2,result[31:28]);
	
endmodule
