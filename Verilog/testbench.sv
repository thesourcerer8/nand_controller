//-------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------
//-- Title							: ONFI compliant NAND interface
//-- File							: testbench.vhd
//-- Author						: Alexey Lyashko <pradd@opencores.org>
//-- License						: LGPL
//-------------------------------------------------------------------------------------------------
//-- Description:
//-- This is the testbench file for the NAND_MASTER module
//-------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------
//

`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps
`include "nand_master.sv"

module tb ();
	reg clk =1'b1;

	// Internal interface
	wire nand_cle;
	wire nand_ale;
	wire nand_nwe;
	wire nand_nwp;
	wire nand_nce;
	wire nand_nre;
	reg nand_rnb = 1'b1;

	wire [15:0]nand_data;
	reg [15:0]nand_data_drive;
	wire [15:0]nand_data_recv;

	assign nand_data= nand_data_drive;
	assign nand_data_recv=nand_data;

	reg nreset = 1'b1;
	wire [7:0]data_out;
	reg [7:0]data_in;
	wire busy;
	reg activate;
	reg [7:0]cmd_in;

	nand_master NM (
		.clk      (clk),
		.nand_cle (nand_cle),
		.nand_ale (nand_ale),
		.nand_nwe (nand_nwe),
		.nand_nwp (nand_nwp),
		.nand_nce (nand_nce),
		.nand_nre (nand_nre),
		.nand_rnb (nand_rnb),
		.nand_data(nand_data),
		.nreset   (nreset),
		.data_out (data_out),
		.data_in  (data_in),
		.busy     (busy),
		.activate (activate),
		.cmd_in   (cmd_in)
	);



always
begin
	clk = 1'b1;
	#1;
	clk = 1'b0;
	#1;
end


initial
begin
	$dumpfile("testbench.vcd");
	$dumpvars(0,tb);
        #1 $display ("T=%0t Start of simulation", $realtime);
	activate = 1'b0;
	nreset = 1'b1;
	nand_data_drive = "ZZZZZZZZZZZZZZZZ";
	
	// Enable the chip
	#5;
	cmd_in = 8'h09;
	activate = 1'b1;
	#2;
	activate = 1'b0;
	
	
	// Read JEDEC ID
	data_in = 8'h00;
	cmd_in = 8'h03;
	#5;
	activate = 1'b1;
	#2;
	activate = 1'b0;
	
	// Provide ID
	#155;
	nand_data_drive = 16'h002c;
	#32;
	nand_data_drive = 16'h00e5;
	#32;
	nand_data_drive = 16'h00ff;
	#32;
	nand_data_drive = 16'h0003;
	#32;
	nand_data_drive = 16'h0086;
	#32;
	nand_data_drive = "ZZZZZZZZZZZZZZZZ";
	#5;
	
	// Read the bytes of the ID
	cmd_in = 8'h0e;
	// 1
	activate = 1'b1;
	#2;
	activate = 1'b0;
	#2;
	// 2
	activate = 1'b1;
	#2;
	activate = 1'b0;
	#2;
	// 3
	activate = 1'b1;
	#2;
	activate = 1'b0;
	#2;
	// 4
	activate = 1'b1;
	#2;
	activate = 1'b0;
	#2;
	// 5
	activate = 1'b1;
	#2;
	activate = 1'b0;
	
	cmd_in = 8'h08;
	#2;
	activate = 1'b1;
	#2;
	activate = 1'b0;
	#2;	
	$display ("T=%0t End of simulation", $realtime);
	$finish;
end

endmodule
