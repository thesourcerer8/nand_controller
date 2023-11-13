
`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps


module nand_avalon (clk,resetn,readdata,writedata,pread,pwrite,address,nand_cle,nand_ale,nand_nwe,nand_nwp,nand_nce,nand_nre,nand_rnb,nand_data);
	input clk; // =0
	input resetn; // =0
	output [31:0] readdata; 
	input [31:0] writedata; // ="0000"
	input pread; //=1
	input pwrite; //=1
	input [1:0] address;
		
	// NAND chip control hardware interface. These signals should be bound to physical pins.
	output nand_cle; //=0
	output nand_ale; //=0
	output nand_nwe; //=1
	output nand_nwp; //=0
	output nand_nce; //=1
	output nand_nre; //=1
	input nand_rnb;
	// NAND chip data hardware interface. These signals should be boiund to physical pins.
	inout [15:0] nand_data;

	reg nand_cle=0;
	reg nand_ale=0;
	reg nand_nwe=1;
	reg nand_nwp=0;
	reg nand_nce=1;
	reg nand_nre=1;
	
	nand_master NANDA (
		.clk (clk),
		.enable (0),
		.nand_cle (nand_cle),
		.nand_ale (nand_ale),
		.nand_nwe (nand_nwe),
		.nand_nwp (nand_nwp),
		.nnad_nce (nand_nce),
		.nand_nre (nand_nre),
		.nand_rnb (nand_rnb),
		.nand_data (nand_data),
		.nreset (resetn),
		.data_out (n_data_out),
		.data_in (n_data_in),
		.busy (n_busy),
		.activate (n_activate),
		.cmd_in (n_cmd_in)
	);

	reg nreset;
	reg [7:0] n_data_out;
	reg [7:0] n_data_in;
	reg n_busy;
	reg n_activate;
	reg [7:0] n_cmd_in;
	reg prev_pwrite;
	reg [1:0] prev_address;


	
always @(posedge clk) begin

	
	// Registers:
	// 0x00:		Data IO
	// 0x04:		Command input
	// 0x08:		Status output

	if (address == 2'b00) begin
		readdata[7:0] = n_data_out;
	end else if(address == 2'b10) begin
		readdata[7:0] = {2'b0000000,n_busy};
	end else begin
		readdata[7:0] = 0;
	end
	
	if (prev_address == 2'b01 & prev_pwrite == 1'b0 & pwrite ==1'b1 & n_busy ==1'b0) begin
		n_activate = 1;
	end else begin
		n_activate = 0;
	end

						
	if(pwrite == 1'b0 & address == 2'b00) begin
		n_data_in = writedata[7:0];
	end else if (pwrite == 1'b0 & address == 2'b01) begin
		n_cmd_in = writedata[7:0];
	end
	
	prev_address = address;
	prev_pwrite = pwrite;
end

endmodule
