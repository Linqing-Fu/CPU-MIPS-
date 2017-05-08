//`define PRJ1_FPGA_IMPL
`ifdef PRJ1_FPGA_IMPL
	// the board does not have enough GPIO, so we implement 4 4-bit registers
    `define DATA_WIDTH 4
	`define ADDR_WIDTH 2
`else
    `define DATA_WIDTH 32
	`define ADDR_WIDTH 5
`endif

module reg_file(
	input clk,
	input rst,
	input [`ADDR_WIDTH - 1:0] waddr,
	input [`ADDR_WIDTH - 1:0] raddr1,
	input [`ADDR_WIDTH - 1:0] raddr2,
	input wen,
	input [`DATA_WIDTH - 1:0] wdata,
	output [`DATA_WIDTH - 1:0] rdata1,
	output [`DATA_WIDTH - 1:0] rdata2
);


reg [`DATA_WIDTH - 1:0] r [2**`ADDR_WIDTH- 1:0];//number:addr data:2^datawidth

integer i;

always@(posedge clk) begin//write operate is controled by clock
    if(rst)
        begin
        for(i=0;i<=2**`ADDR_WIDTH- 1;i=i+1) r[i]<=0;//register initial
        end
    else 
    begin
    if(wen)
        begin
        if(waddr!=0)
        r[waddr]<=wdata;
        else
        r[waddr]<=0;//0 register always 0
        end
    end
end

assign rdata1=r[raddr1];//write isn't controled by clock
assign rdata2=r[raddr2];

endmodule
