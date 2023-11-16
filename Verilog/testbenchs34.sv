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
/* verilator lint_off STMTDLY */

//`include "k9f1208.v" // does not need to be included because it is given on
//the commandline
//`include "timescale.sv"
`include "nand_master.sv"
`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps



module testbench ();
	reg clk =1'b1;

	// Internal interface
	wire nand_cle;
	wire nand_ale;
	wire nand_nwe;
	wire nand_nwp;
	wire nand_nce;
	wire nand_nre;
	//
	//reg nand_rnb = 1'b1;
	wire nand_rnb;
	//wire io0;
	//wire io1;
	//wire io2;
	//wire io3;
	//wire io4;
	//wire io5;
	//wire io6;
	//wire io7;


	wire [15:0]nand_data;
        //assign nand_data1=nand_data2;
	//assign nand_data2=nand_data1;

	//reg [15:0]nand_data_drive;
	//wire [15:0]nand_data_recv;

	//assign nand_data=nand_data_drive;
	//assign nand_data_recv=nand_data;

	// Wiring up the IOs as explicit pins so that Sigrok can see them
	//assign io0 =nand_data[0];
	//assign io1 =nand_data[1];
	//assign io2 =nand_data[2];
	//assign io3 =nand_data[3];
	//assign io4 =nand_data[4];
	//assign io5 =nand_data[5];
	//assign io6 =nand_data[6];
	//assign io7 =nand_data[7];

	reg nreset = 1'b1;
	wire [7:0]data_out;
	reg [7:0]data_in;
	wire busy;
	reg activate;
	reg [5:0]cmd_in;

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
		.enable   (1'b0)
	);

        k9f1208 flash (
		.IO7 (nand_data[7]),
		.IO6 (nand_data[6]),
		.IO5 (nand_data[5]),
		.IO4 (nand_data[4]),
		.IO3 (nand_data[3]),
		.IO2 (nand_data[2]),
		.IO1 (nand_data[1]),
		.IO0 (nand_data[0]),
    		.CLE (nand_cle),
		.ALE (nand_ale),
		.CENeg (nand_nce),
		.RENeg (nand_nre),
		.WENeg (nand_nwe),
		.WPNeg (nand_nwp),
    		.R (NM.nand_rnb)
	);



always
begin
	$display("T:%0t",$realtime); 
	clk = 1'b1;
	#1.25ns;
	clk = 1'b0;
	#1.25ns;
end


always
begin
	#400ns;
	$finish;
end


initial
begin
	$display("Init...");
	$dumpfile("testbenchs34.vcd");
	$dumpvars(0,testbench); //1,tb,NM,tb.flash.IO0,tb.flash.IO1,);
	$timeformat(-9, 0, "ns", 8);

	$display ("T=%0t Start of simulation", $realtime);
        #1 
	activate = 1'b0;
	nreset = 1'b1;
	//nand_data_drive = 16'hZZZZ;
	#10
	nreset = 1'b0;
	#2
	nreset = 1'b1;
	#2

        // Should we do a RESET or does the controller do it itself?
	
	// RESET the flash controller
	$display ("T=%0t Reset the controller (0x01)", $realtime);
	#5
	cmd_in = `M_RESET;
	activate = 1'b1;
	#2
	activate = 1'b0;

	#100
	
	// Enable the chip
	$display ("T=%0t Enable the chip (0x0E)", $realtime);
	#5ns
	cmd_in = `MI_CHIP_ENABLE;
	data_in = 8'h00; // Which CE line?
	activate = 1'b1;
	#2.5ns
	activate = 1'b0;

	// We need a NAND RESET 
	$display ("T=%0t NAND RESET (0x04)", $realtime);
	#5ns 
	cmd_in = `M_NAND_RESET;
	activate = 1'b1;
	#2.5ns
	activate = 1'b0;
	#2.5ns
	wait(~busy);
	#2.5ns
	
	// Read JEDEC ID
	#2.5ns
	$display ("T=%0t Read JEDEC ID (0x06)", $realtime);
	data_in = 8'h00;
	cmd_in = `M_NAND_READ_ID;
	#5ns
	activate = 1'b1;
	#2.5ns
	activate = 1'b0;

	// Provide ID
	$display ("T=%0t Provide ID", $realtime);
	#155ns
	//nand_data_drive = 16'h002c;
	#32.5ns
	//nand_data_drive = 16'h00e5;
	#32.5ns
	//nand_data_drive = 16'h00ff;
	#32.5ns
	//nand_data_drive = 16'h0003;
	#32.5ns
	//nand_data_drive = 16'h0086;
	#32.5ns
	//nand_data_drive = 16'hZZZZ;
	#5ns

	
	// Read the bytes of the ID
	$display ("T=%0t Read the bytes of the ID (0x13)", $realtime);
	cmd_in = `MI_GET_ID_BYTE;
	// 1
	activate = 1'b1;
	#2.5ns
	activate = 1'b0;
	#2.5ns
	$display ("T=%0t ID0: %h", $realtime, data_out);
	// 2
	activate = 1'b1;
	#2.5ns
	activate = 1'b0;
	#2.5ns
	$display ("T=%0t ID1: %h", $realtime, data_out);
	// 3
	activate = 1'b1;
	#2.5ns
	activate = 1'b0;
	#2.5ns
	$display ("T=%0t ID2: %h", $realtime, data_out);
	// 4
	activate = 1'b1;
	#2.5ns
	activate = 1'b0;
	#2.5ns
	$display ("T=%0t ID3: %h", $realtime, data_out);
	// 5
	activate = 1'b1;
	#2.5ns
	activate = 1'b0;
	#2.5ns
	$display ("T=%0t ID4: %h", $realtime, data_out);
	// 5
	activate = 1'b1;
	#2.5ns
	activate = 1'b0;
	#2.5ns
	$display ("T=%0t ID4: %h", $realtime, data_out);
	// 5
	activate = 1'b1;
	#2.5ns
	activate = 1'b0;
	#2.5ns
	$display ("T=%0t ID4: %h", $realtime, data_out);
	// 5
	activate = 1'b1;
	#2.5ns
	activate = 1'b0;
	#2.5ns
	$display ("T=%0t ID4: %h", $realtime, data_out);




	#10ns

	// GET STATUS
	$display ("T=%0t Get Status (0x0D)", $realtime);
	cmd_in = `MI_GET_STATUS;
	#2.5ns
	activate = 1'b1;
	#2.5ns
	activate = 1'b0;
	#2.5ns	
	$display ("Status: %h", data_out);


	// Perhaps the READ PAGE needs a Reset Buffer Index so that it writes
	// it at the right place
	$display ("T=%0t Reset Buffer Index (0x12)", $realtime);
	cmd_in = `MI_RESET_INDEX;
	#2.5ns
	activate = 1'b1;
	#2.5ns
	activate = 1'b0;
	#2.5ns	


	// READ PAGE
	$display ("T=%0t NAND READ Page into internal buffer (0x09)", $realtime);
	cmd_in = `M_NAND_READ;
	#2.5ns
	activate = 1'b1;
	#2.5ns
	activate = 1'b0;
	#2.5ns
        #10ns


	// Resetting the Buffer index again to make sure we read it from the
	// start
	$display ("T=%0t Reset Buffer Index (0x12)", $realtime);
	cmd_in = `MI_RESET_INDEX;
	#2.5ns
	activate = 1'b1;
	#2.5ns
	activate = 1'b0;
	#2.5ns	

	// Now we can read each byte
	$display ("T=%0t Read Data Page Byte (0x15)", $realtime);
	cmd_in = `MI_GET_DATA_PAGE_BYTE;
	#2.5ns
	activate = 1'b1;
	#2.5ns
	activate = 1'b0;
	#2.5ns
	$display ("Data Page Byte: %h", data_out);


	$display ("T=%0t End of simulation", $realtime);
	$finish;
end

endmodule
