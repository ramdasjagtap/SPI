`timescale 1ns/1ps

//module tb_top_module();
module tb_top_module();

// ports.
	reg clk,arst;
	reg start,cpol,cpha;
	reg [7:0] din;
	wire [7:0] dout;
	wire tx_done,rx_done,busy;
	wire cs,sclk,mosi;
	reg miso;
	reg [1:0]rw;

// module instance.
	top_module DUT(
		.clk(clk),
		.arst(arst),
		.start(start),
		.cpol(cpol),
		.cpha(cpha),
		.din(din),
//		.dout(dout),
		.tx_done(tx_done),
		.rx_done(rx_done),
		.busy(busy),
		.cs(cs),
		.sclk(sclk),
		.mosi(mosi),
		.miso(miso)
		);

// clock generation.
	always #10 clk = ~clk;

//	initial
//		begin
//			$dumpfile("tb_top_module.vcd");
//			$dumpvars;
//		end


// stimulus generation.
	initial
		begin
			clk = 1'b0;
			arst = 1'b1;
			start = 1'b0;
			din = 8'hFF;
			cpol = 1'b0;
			cpha = 1'b0;
			rw = 2'b10;
			#50;
			arst = 1'b0;
//			rw = 1'b1;
			#30;
			start = 1'b1;
			#400;
	 	    start = 1'b0;
			#50;
			$finish();
		end
		
// monitor block.
	initial
		begin
			$monitor("time = %d | cs = %b | mosi == %b ",$time,cs,mosi);
		end
endmodule
