`timescale 1ns/1ps;

// spi master module
module master(
    input clk,arst,
    input start,
    input cpol,cpha,
    input  [7:0] data_in,
    output reg [7:0] data_o,
    // flag signal
   output reg  tx_done,rx_done,
   output  busy,
    // SPI interface
    output reg cs,
    output reg sclk,
    output MOSI,
    input MISO
    );
    
  // intermmediate signal.
reg mux_out;
reg [3:0] mux_sel;
reg [7:0] demux_out;
reg [3:0] demux_sel;
reg [1:0] clk_div;
reg [3:0] count;
reg [7:0] data_i;

// clock division.
always @(posedge clk or posedge arst)
    begin
     if(arst)
        clk_div <= 0;
      else
         clk_div <= clk_div  + 1;
    end
    
    // slave select generation.
    always @(posedge clk )
        begin
            cs <= ~start;
        end
        
//        assign cs = !start;
//      wire freq_div;
//      assign freq_div = clk_div[1];
      
        // sclk generation.
    always @(posedge clk_div[1])
        begin
        if(cs == 0)
         sclk <= ~sclk;
       else if(cpol == 1 && cs == 1)
          sclk <= 1;
        else if (cpol == 0 && cs == 1)
          sclk <= 0;
         end
         
    //  counter declaration for tx and rx of data.
    reg [3:0] mux_sel_cnt0, mux_sel_cnt1;
    reg [3:0] demux_sel_cnt0, demux_sel_cnt1;

    // couter selection line for mux & demux.. 
    // negative edge triggered circuit.
always @(negedge sclk or posedge cs or posedge arst)
    begin
        if(arst || cs)
            begin
                mux_sel_cnt0 <= 0;
                demux_sel_cnt0 <= 0;
            end
         else if(!cs)
            begin
                    mux_sel_cnt0 <= mux_sel_cnt0 + 1;
                    demux_sel_cnt0 <= demux_sel_cnt0 + 1;
                    if(mux_sel_cnt0 == 'd8)
                      mux_sel_cnt0 <= 1;
                     if(demux_sel_cnt0 == 'd8)
                      demux_sel_cnt0 <= 1;
            end
    end
    
       // couter selection line for mux & demux.. 
       // positive edge triggered circuit.
  always @(posedge sclk or posedge cs or posedge arst)
    begin
        if(cs || arst)
          begin
               mux_sel_cnt1 <= 0;
               demux_sel_cnt1 <= 0;
          end
         else if(!cs)
           begin
                 mux_sel_cnt1 <= mux_sel_cnt1 + 1;
                  if(mux_sel_cnt1 == 'd8)
                    mux_sel_cnt1 <= 1;
                 demux_sel_cnt1 <= demux_sel_cnt1 + 1;
                   if(demux_sel_cnt1 == 'd8)
                       demux_sel_cnt1 <= 1;
           end
    end
    
    // selection of selection line for tx and rx of data depends on cpha.
    always @(*)
        begin
            case(cpha)
            1'b0:  begin
                mux_sel = mux_sel_cnt0;
                demux_sel = demux_sel_cnt1;
            end
            1'b1: begin
                 mux_sel = mux_sel_cnt1;
                 demux_sel = demux_sel_cnt0;
            end
            endcase
         end
         
//      tx flag signal generation.
   always @(posedge clk)
     begin
         if(mux_sel == 'd8)
          tx_done <= 1;
        else
          tx_done <= 0;
     end
   
    // rx  flag signal generation.
   always @(negedge clk )
     begin
         if(demux_sel == 'd8)
          rx_done <= 1;
        else
          rx_done <= 0;
     end
  
      assign busy = start;
     
      always @(posedge clk)
      begin
          data_i <= data_in;
      end
      
   // mux as TX.
	 always@(*)
	    begin
	       case(mux_sel)
		  4'b0001: mux_out = data_i[0];
		  4'b0010: mux_out = data_i[1];
		  4'b0011: mux_out = data_i[2];
		  4'b0100: mux_out = data_i[3];
		  4'b0101: mux_out = data_i[4];
		  4'b0110: mux_out = data_i[5];
		  4'b0111: mux_out = data_i[6];
		  4'b1000: mux_out = data_i[7];
		  default: mux_out = 'hz;
	       endcase
	    end

            // output data on mosi line.
	    assign MOSI = mux_out;
	   
	   // demux as rx.
	   always @(*)
	     begin
	       case(demux_sel)
	            4'b0001: demux_out[0] = MISO;
		    4'b0010: demux_out[1] = MISO;
		    4'b0011: demux_out[2] = MISO;
		    4'b0100: demux_out[3] = MISO;
		    4'b0101: demux_out[4] = MISO;
		    4'b0110: demux_out[5] = MISO;
		    4'b0111: demux_out[6] = MISO;
		    4'b1000: demux_out[7] = MISO;
		    default: demux_out = 'hz;
	       endcase
	     end
	   
	   // synchronising slave data with clock. 
             always @(posedge clk)
                begin
                    data_o <= demux_out;
                end
                
endmodule


// spi master interface
interface master_if;
    bit clk;
    bit arst;
    bit start;
    bit cpol,cpha;
    logic  [7:0] data_in;
    logic [7:0] data_o;
    // flag signal
    bit tx_done,rx_done,busy;
    // SPI interface
    logic cs;
    logic  sclk;
    logic MOSI;
    logic MISO;

endinterface
