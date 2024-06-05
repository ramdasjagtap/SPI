`timescale 1ns / 1ps

// Transaction class
class transaction;
	rand bit start;
	rand bit [7:0] data_in;
	rand bit cpol;
	rand bit cpha;
	bit cs;
	bit MOSI;
	rand bit MISO;
	bit [7:0] data_o;
	bit tx_done,rx_done,busy;

	// display function.
	function void display(input string tag);
		$display("[%0s] : START : %0b DIN : %0d CS : %b MOSI : %0b ",tag,start,data_in,cs,MOSI);
		$display(" -------------------------------------------------------------------------------------- ");
	endfunction

	// This function will store the copy of transaction class.
	function transaction copy();
		copy = new();
		copy.start = this.start;
		copy.data_in = this.data_in;
		copy.cpol = this.cpol;
		copy.cpha = this.cpha;
		copy.cs = this.cs;
		copy.MOSI = this.MOSI;
		copy.MISO = this.MISO;
		copy.data_o = this.data_o;
	endfunction
	
endclass

// Generator class
class generator;
	transaction tr;
	mailbox #(transaction) mbx;
	event done;

	int count = 0;

	event drvnext;
	event sconext;

	function new(mailbox #(transaction) mbx);
		this.mbx = mbx;
		tr = new();
	endfunction

	// Generate transactions.
	task run();
		repeat(count) begin
			assert(tr.randomize) else $error("[GEN] : Randomization Error!!");
			mbx.put(tr.copy);
			tr.display("GEN");
			@(drvnext);
			@(sconext);
		end
		-> done;
	endtask
endclass

// Driver Class
class driver;
	virtual master_if vif;
//   master_if vif;
	transaction tr;
	mailbox #(transaction) mbx;
	mailbox #(bit [7:0]) mbxds;  //mailbox driver to scoreboard
	event  drvnext;

	bit [7:0] data_in;

	function new(mailbox #(bit [7:0] ) mbxds, mailbox #(transaction) mbx);
		this.mbx = mbx;
		this.mbxds = mbxds;
	endfunction

	// reset the driver.
	task reset();
		vif.arst <= 1'b1;
		vif.cs <= 1'b1;
		vif.start <= 1'b0;
		vif.data_in <= 'b0;
		vif.MOSI <= 1'hz;
		vif.MISO <= 1'hz;
		vif.cpol <= 1'b0;                 // clock polarity.
		vif.cpha <= 1'b0;                // clock phase.
		repeat(10) @(posedge vif.clk);
		vif.arst <= 1'b0;
		repeat(5) @(posedge vif.clk);

		$display("[DRV] : RESET DONE ");
		$display(" ---------------------------------------------- ");
	endtask

	// driver run
	task run();
		forever begin
			mbx.get(tr);
			@(posedge vif.clk);
			vif.start <= 1'b1;
			vif.data_in <= tr.data_in;
			mbxds.put(tr.data_in);
			@(posedge vif.sclk);
//			vif.start <= 1'b0;
			wait(vif.cs == 1'b1);
			$display("[DRV] : DATA SENT : %0d  ",tr.data_in);
			$display(" ---------------------------------------------------------------  ");
			->drvnext;
		end
	endtask

endclass

// Monitor class
class monitor;
	transaction tr;
	mailbox #(bit [7:0]) mbx;
	bit [7:0] srx;		// received data

	virtual master_if vif;
//    master_if vif;
    
	function new(mailbox #(bit [7:0])mbx);
		this.mbx = mbx;
	endfunction

	// run task.
	task run();
		forever begin
			@(posedge vif.sclk);
			wait(vif.cs == 1'b0);	// start the transaction.
//			@(posedge vif.sclk);
			for(int i = 0; i <= 8;i++)
			begin
				@(posedge vif.sclk);
				srx[i] = vif.MOSI;
			end

            vif.start <= 1'b0;
			wait(vif.cs == 1'b1);	// end of transaction.

			$display("[MON] : DATA SENT : %0d ",srx);
		    $display(" ---------------------------------------------------------------  ");
			mbx.put(srx);
		end
	endtask
endclass

// Scoreboard Class.
class scoreboard;
	mailbox #(bit [7:0]) mbxds;
	mailbox #(bit [7:0]) mbxms;
	bit [7:0] ds;  // data from driver.
	bit [7:0] ms;	//  data from monitor.
	
	event sconext;

	function new(mailbox #(bit [7:0]) mbxds,mailbox #(bit [7:0])mbxms);
		this.mbxds = mbxds;
		this.mbxms = mbxms;
	endfunction

	// run task
	task run();
		forever begin
			mbxds.get(ds);
			mbxms.get(ms);
			$display("[SCO] :DRV : %0d MON : %0d ",ds ,ms);
			
			if(ds == ms)
				$display("[SCO] : DATA MATCHED");
			else
				$display("[SCO] : DATA MISMATCHED");

			$display(" --------------------------------------- ");
			-> sconext;
		end
	endtask
endclass

class environment;
	generator gen;
	driver drv;
	monitor mon;
	scoreboard sco;

	event nextgd;	// gen to drv.
	event nextgs;

	mailbox #(transaction) mbxgd;	// gen to drv.
	mailbox #(bit [7:0]) mbxds;	// drv to sco.
	mailbox #(bit [7:0]) mbxms;	// mon to sco.

	virtual master_if vif;
//       master_if vif;

	function new(virtual master_if vif);
		mbxgd = new();
		mbxds = new();
		mbxms = new();
		gen = new(mbxgd);
		drv = new(mbxds,mbxgd);
		mon = new(mbxms);
		sco = new(mbxds,mbxms);

		this.vif = vif;
		drv.vif = this.vif;
		mon.vif = this.vif;
		
		gen.sconext = nextgs;
		sco.sconext = nextgs;
		gen.drvnext = nextgd;
		drv.drvnext = nextgd;
	endfunction

	task pre_test();
		drv.reset();
	endtask

	task test();
		fork
			gen.run();
			drv.run();
			mon.run();
			sco.run();
		join_any
	endtask

	task post_test();
		wait(gen.done.triggered);
		$finish();
	endtask

	task run();
		pre_test();
		test();
		post_test();
	endtask
endclass

// testbench master module
module tb_master();

// virtual interface.
    master_if vif();
    
    // environment declaration.
	environment env;

// master module instance
master MASTER(
     .clk(vif.clk),
      .arst(vif.arst),
      .start(vif.start),
      .cpol(vif.cpol),
      .cpha(vif.cpha),
      .data_in(vif.data_in),
      .data_o(vif.data_o),
      .tx_done(vif.tx_done),
      .rx_done(vif.rx_done),
      .busy(vif.busy),
      .cs(vif.cs),
      .sclk(vif.sclk),
      .MOSI(vif.MOSI),
      .MISO(vif.MISO)
);

// clock signal initialization.
	initial
		begin
			vif.clk <= 0;
		end

// clock generation.
		always #10 vif.clk <= ~vif.clk;

// vcd file
		initial
			begin
				$dumpfile("tb_master.vcd");
				$dumpvars;
			end

// stimulus generation
		initial
			begin
				env = new(vif);
				env.gen.count = 20;
				env.run();
			end
			
endmodule
