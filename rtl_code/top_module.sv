`timescale 1ns / 1ps

// Top module of project.
module top_module(
                input clk,arst,
                input cpha,cpol,
                input start,
                output mosi,sclk,cs,
                input miso,
                input [7:0]din,
                output busy,
                input rw,
                output tx_done,rx_done,
                output reg  [6:0]display_out,
                output AN0,AN1,AN2,AN3,
                input AN2_i,AN3_i       
);
                
  
  // anode 2 & 3  logic.               
   assign AN2 = AN2_i;
   assign AN3 = AN3_i;
      
   // intermediate signals for connecting the master and application layer. 
reg  [7:0]dout;    
reg cs_wire;
reg tx_done_wire,rx_done_wire;
wire [7:0]dout_wire;
reg  [20:0] count;
wire clk_wire;
wire freq_div;
wire anode_logic;
wire [3:0] mux_out;

// spi master module instance.
master DUT(
		.clk(clk),
		.arst(arst),
		.start(cs_wire),
		.cpol(cpol),
		.cpha(cpha),
		.data_in(dout_wire),
		.data_o(dout),
		.tx_done(tx_done_wire),
		.rx_done(rx_done_wire),
		.busy(busy),
		.cs(cs),
		.sclk(sclk),
		.MOSI(mosi),
		.MISO(miso)
//		.clk_app(clk_app)
		);
    
  // spi application layer module instance
spi_application SPIAPP1(
	.clk(clk),
	.arst(arst),
	.start(start),
	.cpol_i(cpol),
	.cpha_i(cpha),
	.tx_done(tx_done_wire),
	.rx_done(rx_done_wire),
	.din(din),
	.rw(rw),
	.dout(dout_wire),
	.cpol_o(cpol_wire),
	.cpha_o(cpha_wire),
	.cs(cs_wire)
	);

//  tx flag signal.
assign tx_done = tx_done_wire;

//  rx flag signal.
assign rx_done  = rx_done_wire;

// frequency divider counter.
always @(posedge clk or posedge arst)
begin
 if(arst)
   count <= 0;
 else
 count <= count + 1;
end

// frequency divided signal assignment.
assign clk_wire = count[20];
assign freq_div = count[25];
assign anode_logic = count[18];

// mux for selection of for 7-segment display.
 mux MUX(
   .in0(dout[3:0]),
   .in1(dout[7:4]),
   .sel(anode_logic),
   .mux_out(mux_out)
  );
  
  // anode logic.
 assign AN0 = anode_logic;
 assign AN1 = !anode_logic;
 
 // decoder for 7-segment display.
always @(*)
begin 
    case(mux_out)
        4'b0000:display_out=7'b0000001;
        4'b0001:display_out=7'b1001111;
        4'b0010:display_out=7'b0010010;
        4'b0011:display_out=7'b0000110;
        4'b0100:display_out=7'b1001100;
        4'b0101:display_out=7'b0100100;
        4'b0110:display_out=7'b0100000;
        4'b0111:display_out=7'b0001111;
        4'b1000:display_out=7'b0000000;
        4'b1001:display_out=7'b0000100;
        4'b1010:display_out=7'b0000100;
        4'b1011:display_out=7'b1100000;
        4'b1100:display_out=7'b0110001;
        4'b1101:display_out=7'b1000001;
        4'b1110:display_out=7'b0110000;
        4'b1111:display_out=7'b0111000;
        default:display_out= 7'b1111111;  
    endcase
    end
    
endmodule
