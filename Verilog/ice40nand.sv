//-------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------
//-- Title						: ONFI compliant NAND interface, ICE40
//-- File						: ice40nand.sv
//-- Author						: Philipp Gühring <pg@futureware.at>
//-- License						: LGPL
//-------------------------------------------------------------------------------------------------
//-- Description:
//-- This is the ICE40 top level file for the NAND controller with a UART interface
//-------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------
//
/* verilator lint_off STMTDLY */

//`include "timescale.sv"
`include "nand_master.sv"
`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps

module ice40nand ();
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
		.nand_rnb (~nand_rnb),
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
	$display("TB:%0t",$realtime); 
	clk = 1'b1;
	#1.25ns;
	clk = 1'b0;
	#1.25ns;
end


always
begin
	#134000ns;
	$display("TB: WARNING: INTERRUPTING SIMULATION DUE TO TIMEOUT!");
	$finish;
end


initial
begin
	$display("TB:Init...");
	$dumpfile("testbenchs34.vcd");
	$dumpvars(0,testbench); //1,tb,NM,tb.flash.IO0,tb.flash.IO1,);
	$timeformat(-9, 0, "ns", 8);

	$display ("TB:%0t Busy: %h", $realtime, busy);

	$display ("TB:%0t Start of simulation", $realtime);
	activate = 1'b0;
	nreset = 1'b1;
	//nand_data_drive = 16'hZZZZ;
	#10
	nreset = 1'b0;
	#2
	nreset = 1'b1;
	#2

	#10000 // wait(PoweredUp);

        // Should we do a RESET or does the controller do it itself?
	
	$display ("TB:%0t Busy: %h should be 0", $realtime, busy);

	// RESET the flash controller
	$display ("TB:%0t Reset the controller (0x01)", $realtime);
	#5
	cmd_in = `M_RESET;
	activate = 1'b1;
	#2
	activate = 1'b0;

	#100
	wait(~busy);
	
	$display ("TB:%0t Busy: %h should be 0", $realtime, busy);

	// Enable the chip
	$display ("TB:%0t Enable the chip (0x0E)", $realtime);
	#5ns
	cmd_in = `MI_CHIP_ENABLE;
	data_in = 8'h00; // Which CE line?
	activate = 1'b1;
	#2.5ns
	activate = 1'b0;

	$display ("TB:%0t Busy: %h should be 0", $realtime, busy);

	// We need a NAND RESET 
	$display ("TB:%0t NAND RESET (0x04)", $realtime);
	#5ns 
	cmd_in = `M_NAND_RESET;
	activate = 1'b1;
	#2.5ns
	activate = 1'b0;
	#2.5ns
	wait(~busy);
	#2.5ns

	#5us

	$display ("TB:%0t TB: Busy: %h should be 0", $realtime, busy);

	// Read JEDEC ID
	#2.5ns
	$display ("TB:%0t TB: Read JEDEC ID (0x06)", $realtime);
	data_in = 8'h00;
	cmd_in = `M_NAND_READ_ID;
	#5ns
	activate = 1'b1;
	#2.5ns
	activate = 1'b0;

	#5ns
	$display ("TB:%0t TB: Busy: %h should be 1", $realtime, busy);


	wait(~busy);
	$display ("TB:%0t TB: Busy: %h should be 0", $realtime, busy);

	// Read the bytes of the ID
	$display ("TB:%0t TB: Read the bytes of the ID (0x13)", $realtime);
	cmd_in = `MI_GET_ID_BYTE;
	// 1
	activate = 1'b1;
	#2.5ns
	activate = 1'b0;
	#2.5ns
	$display ("TB:%0t TB: ID0: %h", $realtime, data_out);
        uart_send(data_out);

	// 2
	activate = 1'b1;
	#2.5ns
	activate = 1'b0;
	#2.5ns
	$display ("TB:%0t TB: ID1: %h", $realtime, data_out);
        uart_send(data_out);

	// 3
	activate = 1'b1;
	#2.5ns
	activate = 1'b0;
	#2.5ns
	$display ("TB:%0t TB: ID2: %h", $realtime, data_out);
        uart_send(data_out);

	// 4
	activate = 1'b1;
	#2.5ns
	activate = 1'b0;
	#2.5ns
	$display ("TB:%0t TB: ID3: %h", $realtime, data_out);
        uart_send(data_out);

	// 5
	activate = 1'b1;
	#2.5ns
	activate = 1'b0;
	#2.5ns
	$display ("TB:%0t TB: ID4: %h", $realtime, data_out);
        uart_send(data_out);

	// 5
	activate = 1'b1;
	#2.5ns
	activate = 1'b0;
	#2.5ns
	$display ("TB:%0t TB: ID5: %h", $realtime, data_out);
        uart_send(data_out);

	// 5
	activate = 1'b1;
	#2.5ns
	activate = 1'b0;
	#2.5ns
	$display ("TB:%0t TB: ID6: %h", $realtime, data_out);
        uart_send(data_out);

	// 5
	activate = 1'b1;
	#2.5ns
	activate = 1'b0;
	#2.5ns
	$display ("TB:%0t TB: ID7: %h", $realtime, data_out);
        uart_send(data_out);




	#10ns
        wait(~busy);
	$display ("TB:%0t Busy: %h should be 0", $realtime, busy);

	// GET STATUS
	$display ("TB:%0t Get Status (0x0D)", $realtime);
	cmd_in = `MI_GET_STATUS;
	#2.5ns
	activate = 1'b1;
	#2.5ns
	activate = 1'b0;
	#2.5ns	
	$display ("TB: Status: %h", data_out);

	wait(~busy);
	$display ("TB:%0t Busy: %h should be 0", $realtime, busy);

	// Perhaps the READ PAGE needs a Reset Buffer Index so that it writes
	// it at the right place
	$display ("TB:%0t Reset Buffer Index (0x12)", $realtime);
	cmd_in = `MI_RESET_INDEX;
	#2.5ns
	activate = 1'b1;
	#2.5ns
	activate = 1'b0;
	#2.5ns	

        wait(~busy);
	$display ("TB:%0t Busy: %h should be 0", $realtime, busy);

	// READ PAGE
	$display ("TB:%0t NAND READ Page into internal buffer (0x09)", $realtime);
	cmd_in = `M_NAND_READ;
	#2.5ns
	activate = 1'b1;
	#2.5ns
	activate = 1'b0;
	#2.5ns
        #10ns

	wait(~busy);
	$display ("TB:%0t Busy: %h should be 0", $realtime, busy);

	// Resetting the Buffer index again to make sure we read it from the
	// start
	$display ("TB:%0t Reset Buffer Index (0x12)", $realtime);
	cmd_in = `MI_RESET_INDEX;
	#2.5ns
	activate = 1'b1;
	#2.5ns
	activate = 1'b0;
	#2.5ns	

	wait(~busy);
	$display ("TB:%0t Busy: %h should be 0", $realtime, busy);


	// Now we can read each byte
	$display ("TB:%0t Read Data Page Byte (0x15)", $realtime);
	cmd_in = `MI_GET_DATA_PAGE_BYTE;
	#2.5ns
	activate = 1'b1;
	#2.5ns
	activate = 1'b0;
	#2.5ns
	$display ("TB:Data Page Byte: %h", data_out);

	wait(~busy);
        #5ns
	$display ("TB:%0t End of simulation", $realtime);
	$finish;
end

endmodule
