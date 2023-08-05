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
	wire io0;
	wire io1;
	wire io2;
	wire io3;
	wire io4;
	wire io5;
	wire io6;
	wire io7;


	wire [15:0]nand_data;
	reg [15:0]nand_data_drive;
	wire [15:0]nand_data_recv;

	assign nand_data= nand_data_drive;
	assign nand_data_recv=nand_data;

	// Wiring up the IOs as explicit pins so that Sigrok can see them
	assign io0 =nand_data[0];
	assign io1 =nand_data[1];
	assign io2 =nand_data[2];
	assign io3 =nand_data[3];
	assign io4 =nand_data[4];
	assign io5 =nand_data[5];
	assign io6 =nand_data[6];
	assign io7 =nand_data[7];

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
		.cmd_in   (cmd_in),
		.enable   (1'b1)
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
	$timeformat(-9, 0, "ns", 8);

        #1 $display ("T=%0t Start of simulation", $realtime);
	activate = 1'b0;
	nreset = 1'b1;
	nand_data_drive = "ZZZZZZZZZZZZZZZZ";

        // Should we do a RESET or does the controller do it itself?
	
	// Enable the chip
	#5; $display ("T=%0t Enable the chip", $realtime);
	cmd_in = `MI_CHIP_ENABLE;
	activate = 1'b1;
	#2;
	activate = 1'b0;

	// We need a NAND RESET 
	#5; $display ("T=%0t NAND RESET", $realtime);
	cmd_in = `M_NAND_RESET;
	activate = 1'b1;
	#2;
	activate = 1'b0;
	#10;
	
	// Read JEDEC ID
	#1; $display ("T=%0t Read JEDEC ID", $realtime);
	data_in = 8'h00;
	cmd_in = `M_NAND_READ_ID;
	#5;
	activate = 1'b1;
	#2;
	activate = 1'b0;

	// Provide ID
	$display ("T=%0t Provide ID", $realtime);
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
	$display ("T=%0t Read the bytes of the ID", $realtime);
	cmd_in = `MI_GET_ID_BYTE;
	// 1
	activate = 1'b1;
	#2;
	activate = 1'b0;
	#2;
	$display ("T=%0t ID0: %h", $realtime, data_out);
	// 2
	activate = 1'b1;
	#2;
	activate = 1'b0;
	#2;
	$display ("T=%0t ID1: %h", $realtime, data_out);
	// 3
	activate = 1'b1;
	#2;
	activate = 1'b0;
	#2;
	$display ("T=%0t ID2: %h", $realtime, data_out);
	// 4
	activate = 1'b1;
	#2;
	activate = 1'b0;
	#2;
	$display ("T=%0t ID3: %h", $realtime, data_out);
	// 5
	activate = 1'b1;
	#2;
	activate = 1'b0;
	$display ("T=%0t ID4: %h", $realtime, data_out);


	// GET STATUS
	$display ("T=%0t Get Status", $realtime);
	cmd_in = `MI_GET_STATUS;
	#2;
	activate = 1'b1;
	#2;
	activate = 1'b0;
	#2;	
	$display ("Status: %h", data_out);

	// Perhaps the READ PAGE needs a Reset Buffer Index so that it writes
	// it at the right place
	$display ("T=%0t Reset Buffer Index", $realtime);
	cmd_in = `MI_RESET_INDEX;
	#2;
	activate = 1'b1;
	#2;
	activate = 1'b0;
	#2;	


	// READ PAGE
	$display ("T=%0t NAND READ Page into internal buffer", $realtime);
	cmd_in = `M_NAND_READ;
	#2;
	activate = 1'b1;
	#2;
	activate = 1'b0;
	#2;	
        #10;

	// Resetting the Buffer index again to make sure we read it from the
	// start
	$display ("T=%0t Reset Buffer Index", $realtime);
	cmd_in = `MI_RESET_INDEX;
	#2;
	activate = 1'b1;
	#2;
	activate = 1'b0;
	#2;	

	// Now we can read each byte
	$display ("T=%0t Read Data Page Byte", $realtime);
	cmd_in = `MI_GET_DATA_PAGE_BYTE;
	#2;
	activate = 1'b1;
	#2;
	activate = 1'b0;
	#2;	
	$display ("Data Page Byte: %h", data_out);




	$display ("T=%0t End of simulation", $realtime);
	$finish;
end

endmodule
