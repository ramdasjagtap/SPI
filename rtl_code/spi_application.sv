`timescale 1ns/1ps

// Application layer for winbond slave
module spi_application(
// input ports
	input clk,arst,rw,
	input start,cpol_i,cpha_i,
	input tx_done,rx_done,
	input [7:0] din,
	
// output ports
	output reg [7:0] dout,
	output cpol_o,cpha_o,
	output reg cs
	);
	
	// states declaration
	// typedef enum bit [3:0] {idle,setup,instr,addr1,addr2,addr3,data,stop} states;
	parameter idle = 4'h0,
		setup = 4'h1,
		instr = 4'h2,
		read = 4'h3,
		addr1 = 4'h4,
		addr2 = 4'h5,
		addr3 = 4'h6,
		data = 4'h7,
		stop = 4'h8;

	// state register.
	reg [3:0] curr_state,next_state;

	//output selection count.
	reg [3:0]sel_count;

// sclk polarity selection
	assign cpol_o = cpol_i;
// sclk phase selection.
	assign cpha_o = cpha_i;

// register for counting  tx_done signal.
  reg [3:0] count = 0;	

// counting tx_done signal for next data to be transmitted.
 always @(posedge tx_done )
   begin
      count <= count + 1;
       if(count == 'h5)
         count <= 0;
   end
   
	// state transition
	always @(posedge clk or posedge arst)
		begin
			if(arst)
				curr_state <= idle;
			else
				curr_state <= next_state;
		end

	// next state logic.
	always @(*)
		begin
			case(curr_state)
				idle: begin
					if(start)
						next_state <= setup;
					else
						next_state <= idle;
				end
				setup: begin
                       if(rw == 1)
                        next_state  <= read;
                      else
                        next_state <= instr; 
				end
				read: begin
				    if(count == 1)
						next_state <= stop;
					else
						next_state <= read;
				end
				instr: begin
					if(count == 1)
						next_state <= addr1;
					else
						next_state <= instr;
				end
				addr1: begin
					if(count == 2)
						next_state <= addr2;
					else
						next_state <= addr1;
				end
				addr2: begin
					if(count == 3)
						next_state <= addr3;
					else
						next_state <= addr2;
				end
				addr3: begin
					if(count == 4)
						next_state <= data;
					else
						next_state <= addr3;
				end
				data: begin
					if(count == 5)
						next_state <= stop;
					else
						next_state <= data;
				end
				stop: begin
						next_state <= idle;
				end
				default: next_state <= idle;
			endcase
		end

	// state output logic.
	always @(*)
		begin
			case(curr_state)
				idle: begin
//					sel_count <= 'h0;
					if(start)
					   cs <= 1'b1;
				  else
					 cs <= 1'b0;
				end
				setup: begin
					sel_count <= 'h0;
					if(count == 1)
						cs <= 1'b0;
					else if(start)
						cs <= 1'b1;
					end
			   read: begin
//			        sel_count <= 4'h1;
				    cs <= 1;
				end
				instr: begin
//					sel_count <= 4'h2;
					if(start)
						cs <= 1'b1;
					else
						cs <= 1'b1;
				end
				addr1: begin
					sel_count <= 4'h1;
					cs <= 1'b1;
				end
				addr2: begin
					sel_count <= 4'h2;
					cs <= 1'b1;
				end
				addr3: begin
					sel_count <= 4'h3;
					cs <= 1'b1;
				end
				data: begin
					sel_count <= 4'h4;
					cs <= 1'b1;
					if(count == 5)
						cs <= 1'b1;
				end
				stop: begin
					cs <= 1'b1;
				end
				default: cs <= 1'b0;
			endcase
		end

	// intermediate register for storing data and address.
	reg [7:0] ADDR1 = 8'hFF;
	reg [7:0] ADDR2 =8'hF0;
	reg [7:0] ADDR3 = 8'h00;
	reg [7:0] DATA = 8'hAA;

	// Address and data generation counter.
	// This will generate the different data and address.
//	always @(posedge clk or posedge arst)
//		begin
//			if(arst)
//				begin
//					ADDR1 <= 8'h0;
//					ADDR2 <= 8'h0;
//					ADDR3 <= 8'h0;
//					DATA <= 8'h5;
//				end
//			else
//				begin 
//					if(curr_state == 4'h3)         // state = addr3 then randon address and data will be generated.
//						begin
//							ADDR3 <= ADDR3 + 8'h4;
//							DATA <= DATA + 8'h8;
//							if(ADDR3 == 8'hFF)
//								ADDR2 <= ADDR2 + 8'h4;
//							if(ADDR2 == 8'hFF)
//								ADDR1 <= ADDR1 + 8'h4;
//						end
//				end
//		end

// mux for selection of data to transmit form application to spi master.
	always @(*)
		begin
			case(sel_count)
				4'h0: dout = din;
				//4'h1: dout = din;
				//4'h2: dout = din;
				4'h1: dout = ADDR1;
				4'h2: dout = ADDR2;
				4'h3: dout = ADDR3;
				4'h4: dout = DATA;
				default: dout = din;
			endcase
		end
	
endmodule
