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

`include "nand_master.sv"
//`include "timescale.sv"
`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps

`define toggle_activate \
	activate = 1'b1; \
	#2.5ns \
	activate = 1'b0; \
	#2.5ns


module testbench ();
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

	assign nand_data=nand_data_drive;
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



always
begin
	clk = 1'b1;
	#1.25ns;
	clk = 1'b0;
	#1.25ns;
end


initial
begin
	$display("TB:Init...");
	$dumpfile("testbench.vcd");
	$dumpvars(0,testbench);
	$timeformat(-9, 0, "ns", 8);

	$display ("TB:%0t Busy: %h", $realtime, busy);

	$display ("TB:%0t Start of simulation", $realtime);
        #1
	activate = 1'b0;
	nreset = 1'b1;
	nand_data_drive = 16'hZZZZ;
	#10
	nreset = 1'b0;
	#2
	nreset = 1'b1;
	#2

        // Should we do a RESET or does the controller do it itself?

	$display ("TB:%0t Busy: %h should be 0", $realtime, busy);

	// RESET the flash controller
	$display ("TB:%0t Reset the controller (0x01)", $realtime);
	#5
	cmd_in = `M_RESET;
	`toggle_activate;



	// Enable the chip
	$display ("TB:%0t Enable the chip (0x0E)", $realtime);
	#5ns
	cmd_in = `MI_CHIP_ENABLE;
	data_in = 8'h00; // Which CE line?
	`toggle_activate;

	// We need a NAND RESET
	$display ("TB:%0t NAND RESET (0x04)", $realtime);
	#5ns
	cmd_in = `M_NAND_RESET;
	`toggle_activate;
	#150 //wait(~busy);
	#2.5ns

	// Read JEDEC ID
	#2.5ns
	$display ("TB:%0t Read JEDEC ID (0x06)", $realtime);
	data_in = 8'h00;
	cmd_in = `M_NAND_READ_ID;
	#5ns
	`toggle_activate;

	// Provide ID
	$display ("TB:%0t Provide ID", $realtime);
	#155ns
	nand_data_drive = 16'h002c;
	#32.5ns
	nand_data_drive = 16'h00e5;
	#32.5ns
	nand_data_drive = 16'h00ff;
	#32.5ns
	nand_data_drive = 16'h0003;
	#32.5ns
	nand_data_drive = 16'h0086;
	#32.5ns
	nand_data_drive = 16'hZZZZ;
	#5ns


	// Read the bytes of the ID
	$display ("TB:%0t Read the bytes of the ID (0x13)", $realtime);
	cmd_in = `MI_GET_ID_BYTE;
	// 1
	`toggle_activate;
	#10ns
	$display ("TB:%0t ID0: %h", $realtime, data_out);

	// 2
	`toggle_activate;
	#10ns
	$display ("TB:%0t ID1: %h", $realtime, data_out);

	// 3
	`toggle_activate;
	#10ns
	$display ("TB:%0t ID2: %h", $realtime, data_out);

	// 4
	`toggle_activate;
	#10ns
	$display ("TB:%0t ID3: %h", $realtime, data_out);

	// 5
	`toggle_activate;
	#10ns
	$display ("TB:%0t ID4: %h", $realtime, data_out);

	// 5
	`toggle_activate;
	#10ns
	$display ("TB:%0t ID4: %h", $realtime, data_out);

	// 5
	`toggle_activate;
	$display ("TB:%0t ID4: %h", $realtime, data_out);
	#10ns

	// 5
	`toggle_activate;
	$display ("TB:%0t ID4: %h", $realtime, data_out);

	#10ns

	// GET STATUS
	$display ("TB:%0t Get Status (0x0D)", $realtime);
	cmd_in = `MI_GET_STATUS;
	`toggle_activate;
	$display ("Status: %h", data_out);


	// Perhaps the READ PAGE needs a Reset Buffer Index so that it writes
	// it at the right place
	$display ("TB:%0t Reset Buffer Index (0x12)", $realtime);
	cmd_in = `MI_RESET_INDEX;
	`toggle_activate;

	$display ("Waiting at %0t ... busy: %d",$realtime,busy);
	//wait (busy == 1'b0);
	$display ("Waiting done at %0t ...",$realtime);



	// READ PAGE
	$display ("TB:%0t NAND READ Page into internal buffer (0x09)", $realtime);
	cmd_in = `M_NAND_READ;
	`toggle_activate;
        #10ns


	// Resetting the Buffer index again to make sure we read it from the
	// start
	$display ("TB:%0t Reset Buffer Index (0x12)", $realtime);
	cmd_in = `MI_RESET_INDEX;
	`toggle_activate;

	// Now we can read each byte
	$display ("TB:%0t Read Data Page Byte (0x15)", $realtime);
	cmd_in = `MI_GET_DATA_PAGE_BYTE;
	`toggle_activate;
	$display ("Data Page Byte: %h", data_out);


	#5ns

	$display ("TB:%0t Successful End of simulation", $realtime);
	$finish;
end

endmodule
