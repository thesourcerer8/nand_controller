//-------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------
//-- Title							: ONFI compliant NAND interface
//-- File							: nand_master.vhd
//-- Author						: Alexey Lyashko <pradd@opencores.org>
//-- License						: LGPL
//-------------------------------------------------------------------------------------------------
//-- Description:
//-- The nand_master entity is the topmost entity of this ONFi (Open NAND Flash interface <http://www.onfi.org>)
//-- compliant NAND flash controller. It provides very simple interface and short and easy to use
//-- set of commands.
//-- It is important to mention, that the controller takes care of delays and proper NAND command
//-- sequences. See documentation for further details.
//-------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------
//

`include "onfi_package.sv"
`include "latch_unit.sv"
`include "io_unit.sv"

module nand_master(clk,enable,nand_cle,nand_ale,nand_nwe,nand_nwp,nand_nce,nand_nre,nand_rnb,nand_data,nreset,data_out,data_in,busy,activate,cmd_in);

	// System clock
	input clk;
	input enable;
	// NAND chip control hardware interface. These signals should be bound to physical pins.
	output reg nand_cle=0; // := '0';
	output reg nand_ale=0; // := '0';
	output reg nand_nwe=1; // := '1';
	output reg nand_nwp=0; // := '0';
	output reg nand_nce=1; // := '1';
	output reg nand_nre=1; // := '1';
	input nand_rnb;
	// NAND chip data hardware interface. These signals should be boiund to physical pins.
	inout [15:0] nand_data;
	reg [15:0] nand_data_reg;
	assign nand_data = nand_data_reg;
		
	// Component interface
	input nreset;
	output reg [7:0] data_out;
	input [7:0] data_in;
	output reg busy; // := '0';
	input activate;
	input [7:0] cmd_in;


	// Latch unit related signals
	reg cle_activate;
	wire cle_latch_ctrl;
	wire cle_write_enable;
	wire cle_busy;
	reg [15:0] cle_data_in;
	wire [15:0] cle_data_out;
	
	reg ale_activate;
	wire ale_latch_ctrl;
	wire ale_write_enable;
	wire ale_busy;
	reg [15:0] ale_data_in;
	wire [15:0] ale_data_out;

	// IO Unit.
	// This component implements NAND's read/write interfaces.
	
	// IO Unit related signals
	reg io_rd_activate	;
	wire io_rd_io_ctrl	;
	wire io_rd_busy		;
	reg [15:0] io_rd_data_in;
	wire [15:0] io_rd_data_out;
	
	reg io_wr_activate	;
	wire io_wr_io_ctrl	;
	wire io_wr_busy		;
	reg [15:0] io_wr_data_in;
	wire [15:0] io_wr_data_out;
	
	// FSM
	reg [5:0] state; // = `M_RESET;
	reg [5:0] n_state; //= `M_RESET;
	reg [4:0] substate; // := MS_BEGIN;
	reg [4:0] n_substate; // := MS_BEGIN;
	
	reg [31:0] delay=0;
	
	reg [31:0] byte_count=0;
	reg [31:0] page_idx=0;
	reg [7:0] page_data [`max_page_idx:0];
	reg [7:0] page_param [255:0];
	reg [7:0] chip_id [4:0];
	reg [7:0] current_address [4:0];
	reg [31:0] data_bytes_per_page;
	reg [31:0] oob_bytes_per_page;
	reg [10:0] addr_cycles;

	
//	The following is a sort of a status register. Bit set to 1 means TRUE, bit set to 0 means FALSE:
//	0 - is ONFI compliant
//	1 - bus width (0 - x8 / 1 - x16)
//	2 - is chip enabled
//	3 - is chip write protected
//	4 - array pointer out of bounds
//	5 - 
//	6 - 
//	7 - 
	reg [7:0] status=8'h00;
	reg [31:0] tmp_int;
	reg [31:0] tmp;

	
	// Asynchronous command latch interface.
	latch_unit ACL 
	(
		.latch_type (`LATCH_CMD),
		.activate (cle_activate),
		.latch_ctrl (cle_latch_ctrl),
		.write_enable (cle_write_enable),
		.busy (cle_busy),
		.clk (clk),
		.data_in (cle_data_in),
		.data_out (cle_data_out)
	);

	// Asynchronous address latch interface.
	latch_unit AAL (
		.latch_type (`LATCH_ADDR),
		.activate (ale_activate),
		.latch_ctrl (ale_latch_ctrl),
		.write_enable (ale_write_enable),
		.busy (ale_busy),
		.clk (clk),
		.data_in (ale_data_in),
		.data_out (ale_data_out)
	);
	
	// Output to NAND
	io_unit IO_WR (
		.io_type (`IO_WRITE),
		.clk (clk),
		.activate (io_wr_activate),
		.data_in (io_wr_data_in),
		.data_out (io_wr_data_out),
		.io_ctrl (io_wr_io_ctrl),
		.busy (io_wr_busy)
	);
	
	// Input from NAND
	io_unit IO_RD (
		.io_type (`IO_READ),
		.clk (clk),
		.activate (io_rd_activate),
		.data_in (io_rd_data_in),
		.data_out (io_rd_data_out),
		.io_ctrl (io_rd_io_ctrl),
		.busy (io_rd_busy)
	);
	
always @(posedge clk) begin

	// Busy indicator
	if (state == `M_IDLE) begin
		busy = 1'b0;
	end else begin
		busy = 1'b1;
	end

	// Bidirection NAND data interface.
	//nand_data	<=	(cle_data_out or ale_data_out or io_wr_data_out) when (cle_busy or ale_busy or io_wr_busy) = '1' else 16'hZZZZ;
	if (cle_busy == 1'b1) begin
		nand_data_reg = cle_data_out;
	end else if (ale_busy == 1'b1) begin
		nand_data_reg = ale_data_out;
	end else if (io_wr_busy == 1'b1) begin
		nand_data_reg = io_wr_data_out;
	end else begin
		nand_data_reg = 0;
	end

	io_rd_data_in = nand_data;
	
	// Command Latch Enable
	nand_cle = cle_latch_ctrl;
	
	// Address Latch Enable
	nand_ale = ale_latch_ctrl;
	
	// Write Enable
	nand_nwe = cle_write_enable & ale_write_enable & io_wr_io_ctrl;
	
	// Read Enable
	nand_nre = io_rd_io_ctrl;
	
	// Activation of command latch unit
	if ( state == `M_NAND_RESET |				// initiate submission of RESET command
			(state == `M_NAND_READ_PARAM_PAGE & substate == `MS_BEGIN) |		// initiate submission of READ PARAMETER PAGE command
			(state == `M_NAND_BLOCK_ERASE & substate == `MS_BEGIN) |			// initiate submission of BLOCK ERASE command
			(state == `M_NAND_BLOCK_ERASE & substate == `MS_SUBMIT_COMMAND1) |	// initiate submission of BLOCK ERASE 2 command
			(state == `M_NAND_READ_STATUS & substate == `MS_BEGIN) |			// initiate submission of READ STATUS command
			(state == `M_NAND_READ & substate == `MS_BEGIN) |				// initiate read mode for READ command
			(state == `M_NAND_READ & substate == `MS_SUBMIT_COMMAND1) |		// initiate submission of READ command
			(state == `M_NAND_PAGE_PROGRAM & substate == `MS_BEGIN) |			// initiate write mode for PAGE PROGRAM command
			(state == `M_NAND_PAGE_PROGRAM & substate == `MS_SUBMIT_COMMAND1) |	// initiate submission for PAGE PROGRAM command
			(state == `M_NAND_READ_ID & substate == `MS_BEGIN) |			// initiate submission of READ ID command
			(state == `MI_BYPASS_COMMAND & substate == `MS_SUBMIT_COMMAND) ) begin 	// direct command byte submission
		cle_activate = 1'b1;
	end else begin
		cle_activate = 1'b0;
	end
							
	// Activation of address latch unit
	if ( (state == `M_NAND_READ_PARAM_PAGE  &  substate == `MS_SUBMIT_COMMAND) |		// initiate address submission for READ PARAMETER PAGE command
			(state == `M_NAND_BLOCK_ERASE  &  substate == `MS_SUBMIT_COMMAND) |	// initiate address submission for BLOCK ERASE command
			(state == `M_NAND_READ  &  substate == `MS_SUBMIT_COMMAND) |		// initiate address submission for READ command
			(state == `M_NAND_PAGE_PROGRAM  &  substate == `MS_SUBMIT_ADDRESS) |	// initiate address submission for PAGE PROGRAM command
			(state == `M_NAND_READ_ID  &  substate == `MS_SUBMIT_COMMAND) |		// initiate address submission for READ ID command
			(state == `MI_BYPASS_ADDRESS  &  substate == `MS_SUBMIT_ADDRESS) ) begin	// direct address byte submission

		ale_activate = 1'b1;
	end else begin
		ale_activate = 1'b0;
	end
							
	// Activation of read byte mechanism
	if ( (state == `M_NAND_READ_PARAM_PAGE & substate == `MS_READ_DATA0) |			// initiate byte read for READ PARAMETER PAGE command
			(state == `M_NAND_READ_STATUS & substate == `MS_READ_DATA0) |		// initiate byte read for READ STATUS command
			(state == `M_NAND_READ & substate == `MS_READ_DATA0) |			// initiate byte read for READ command
			(state == `M_NAND_READ_ID & substate == `MS_READ_DATA0) |			// initiate byte read for READ ID command
			(state == `MI_BYPASS_DATA_RD & substate == `MS_BEGIN) ) begin 		// reading byte directly from the chip
		io_rd_activate = 1'b1;
	end else begin
		io_rd_activate = 1'b0;
	end
							
	// Activation of write byte mechanism
	if ( (state == `M_NAND_PAGE_PROGRAM & substate == `MS_WRITE_DATA3) | 			// initiate byte write for PAGE_PROGRAM command
		(state == `MI_BYPASS_DATA_WR & substate == `MS_WRITE_DATA0) ) begin 		// writing byte directly to the chip
		io_wr_activate = 1'b1;
	end else begin
		io_wr_activate = 1'b0;
	end



	//MASTER: process(clk, nreset, activate, cmd_in, data_in, state_switch)
	//always @(posedge clk) begin

		if(nreset == 1'b0) begin
			state = `M_RESET;
		end
//		end else if(activate = '1') begin
//			state	<= state_switch(to_integer(unsigned(cmd_in)));
		else if(enable == 1'b0) begin
			case(state)
				// RESET state. Speaks for itself
				`M_RESET: begin
					state = `M_IDLE;
					substate = `MS_BEGIN;
					delay = 0;
					byte_count = 0;
					page_idx = 0;
					current_address[0]=0;
					current_address[1]=0;
					current_address[2]=0;
					current_address[3]=0;
					current_address[4]=0;
					data_bytes_per_page = 0;
					oob_bytes_per_page = 0;
					addr_cycles = 0;
					status	= 8'h08;		// We start write protected!
					nand_nce = 1'b1;
					nand_nwp = 1'b0;
				end	
				// This is in fact a command interpreter
				`M_IDLE: begin
					if(activate == 1'b1) begin
						state= cmd_in;
					end
				end	
				// Reset the NAND chip
				`M_NAND_RESET: begin
					cle_data_in = 16'h00ff;
					state = `M_WAIT;
					n_state	= `M_IDLE;
					delay = `t_wb + 8;
				end	
				// Read the status register of the controller
				`MI_GET_STATUS: begin
					data_out = status;
					state    = `M_IDLE;
				end	
				// Set CE# to '0' (enable NAND chip)
				`MI_CHIP_ENABLE: begin
					nand_nce = 1'b0;
					state	 = `M_IDLE;
					status[2]= 1'b1;
				end
				// Set CE# to 1'b1 (disable NAND chip)
				`MI_CHIP_DISABLE: begin
					nand_nce = 1'b1;
					state	 = `M_IDLE;
					status[2]= 1'b0;
				end
				// Set WP# to 1'b0 (enable write protection)
				`MI_WRITE_PROTECT: begin
					nand_nwp = 1'b0;
					status[3]= 1'b1;
					state	 = `M_IDLE;
				end
				// Set WP# to 1'b1 (disable write protection)
				// By default, this controller has WP# set to 0 on reset
				`MI_WRITE_ENABLE: begin
					nand_nwp = 1'b1;
					status[3]= 1'b0;
					state	 = `M_IDLE;
				end
				// Reset the index register.
				// Index register holds offsets into JEDEC ID, Parameter Page buffer or Data Page buffer depending on
				// the operation being performed
				`MI_RESET_INDEX: begin
					page_idx = 0;
					state	 = `M_IDLE;
				end	
				// Read 1 byte from JEDEC ID and increment the index register.
				// If the value points outside the 5 byte JEDEC ID array, 
				// the register is reset to 0 and bit 4 of the status register
				// is set to 1'b1
				`MI_GET_ID_BYTE: begin
					if(page_idx < 5) begin
						data_out = chip_id[page_idx];
						page_idx = page_idx + 1;
						status[4] = 1'b0;
					end else begin
						data_out = 8'h00;
						page_idx = 0;
						status[4]= 1'b1;
					end
					state = `M_IDLE;
				end	
				// Read 1 byte from 256 bytes buffer that holds the Parameter Page.
				// If the value goes beyond 255, then the register is reset and 
				// bit 4 of the status register is set to 1'b1
				`MI_GET_PARAM_PAGE_BYTE: begin
					if(page_idx < 256) begin
						data_out = page_param[page_idx];
						page_idx = page_idx + 1;
						status[4]<= 1'b0;
					end else begin
						data_out = 8'h00;
						page_idx = 0;
						status[4] = 1'b1;
					end
					state = `M_IDLE;
				end	
				// Read 1 byte from the buffer that holds the content of last read 
				// page. The limit is variable and depends on the values in 
				// the Parameter Page. In case the index register points beyond 
				// valid page content, its value is reset and bit 4 of the status
				// register is set to 1'b1
				`MI_GET_DATA_PAGE_BYTE: begin
					if(page_idx < data_bytes_per_page + oob_bytes_per_page) begin
						data_out = page_data[page_idx];
						page_idx = page_idx + 1;
						status[4] = 1'b0;
					end else begin
						data_out = 8'h00;
						page_idx = 0;
						status[4] = 1'b1;
					end
					state = `M_IDLE;
				end
				// Write 1 byte into the Data Page buffer at offset specified by
				// the index register. If the value of the index register points 
				// beyond valid page content, its value is reset and bit 4 of
				// the status register is set to 1'b1
				`MI_SET_DATA_PAGE_BYTE: begin
					if(page_idx < data_bytes_per_page + oob_bytes_per_page) begin
						page_data[page_idx] = data_in;
						page_idx = page_idx + 1;
						status[4] = 1'b0;
					end else begin
						page_idx = 0;
						status[4] = 1'b1;
					end
					state = `M_IDLE;
				end	
				// Gets the address byte specified by the index register. Bit 4 
				// of the status register is set to 1'b1 if the value of the index 
				// register points beyond valid address data and the value of 
				// the index register is reset
				`MI_GET_CURRENT_ADDRESS_BYTE: begin
					if(page_idx < addr_cycles) begin
						data_out = current_address[page_idx];
						page_idx = page_idx + 1;
						status[4] = 1'b0;
					end else begin
						page_idx = 0;
						status[4] = 1'b1;
					end
					state = `M_IDLE;
				end	
				// Sets the value of the address byte specified by the index register.Bit 4 
				// of the status register is set to 1'b1 if the value of the index 
				// register points beyond valid address data and the value of 
				// the index register is reset
				`MI_SET_CURRENT_ADDRESS_BYTE: begin
					if(page_idx < addr_cycles) begin
						current_address[page_idx] = data_in;
						page_idx = page_idx + 1;
						status[4] = 1'b0;
					end else begin
						page_idx = 0;
						status[4] = 1'b1;
					end 
					state= `M_IDLE;
				end
				// Program one page.
				`M_NAND_PAGE_PROGRAM: begin
					if(substate == `MS_BEGIN) begin
						cle_data_in = 16'h0080;
						substate= `MS_SUBMIT_COMMAND;
						state 	= `M_WAIT;
						n_state	= `M_NAND_PAGE_PROGRAM;
						byte_count = 0;
					end else if(substate == `MS_SUBMIT_COMMAND) begin
						byte_count = byte_count + 1;
						ale_data_in = 8'h00 & current_address[byte_count];
						substate = `MS_SUBMIT_ADDRESS;
					end else if(substate == `MS_SUBMIT_ADDRESS) begin
						if(byte_count < addr_cycles) begin
							substate = `MS_SUBMIT_COMMAND;
						end else begin
							substate = `MS_WRITE_DATA0;
						end
						state = `M_WAIT;
						n_state	= `M_NAND_PAGE_PROGRAM;
					end else if(substate == `MS_WRITE_DATA0) begin
						delay = `t_adl;
						state = `M_DELAY;
						n_state = `M_NAND_PAGE_PROGRAM;
						substate =	`MS_WRITE_DATA1;
						page_idx = 0;
						byte_count = 0;
					end else if(substate == `MS_WRITE_DATA1) begin
						byte_count = byte_count + 1;
						page_idx = page_idx + 1;
						io_wr_data_in= 8'h00 & page_data[page_idx];
						if(status[1] == 1'b0) begin
							substate = `MS_WRITE_DATA3;
						end else begin
							substate = `MS_WRITE_DATA2;
						end
					end else if(substate == `MS_WRITE_DATA2) begin
						page_idx = page_idx + 1;
						io_wr_data_in[15:8] = page_data[page_idx];
						substate = `MS_WRITE_DATA3;
					end else if(substate == `MS_WRITE_DATA3) begin
						if(byte_count < data_bytes_per_page + oob_bytes_per_page) begin
							substate = `MS_WRITE_DATA1;
						end else begin
							substate = `MS_SUBMIT_COMMAND1;
						end
						n_state	= `M_NAND_PAGE_PROGRAM;
						state	= `M_WAIT;
					end else if(substate == `MS_SUBMIT_COMMAND1) begin
						cle_data_in = 16'h0010;
						n_state	 = `M_NAND_PAGE_PROGRAM;
						state	 = `M_WAIT;
						substate = `MS_WAIT;
					end else if(substate == `MS_WAIT) begin
						delay	= `t_wb + `t_prog;
						state	= `M_DELAY;
						n_state	= `M_NAND_PAGE_PROGRAM;
						substate= `MS_END;
						byte_count= 0;
						page_idx= 0;
					end else if(substate == `MS_END) begin
						state	= `M_WAIT;
						n_state	= `M_IDLE;
						substate= `MS_BEGIN;
					end
				end	
				// Reads single page into the buffer.
				`M_NAND_READ: begin
					if(substate == `MS_BEGIN) begin
						cle_data_in	= 16'h0000;
						substate	= `MS_SUBMIT_COMMAND;
						state		= `M_WAIT;
						n_state		= `M_NAND_READ;
						byte_count	= 0;
					end else if(substate == `MS_SUBMIT_COMMAND) begin
						byte_count	= byte_count + 1;
						ale_data_in	= {8'h00 , current_address[byte_count]};
						substate	= `MS_SUBMIT_ADDRESS;
					end else if(substate == `MS_SUBMIT_ADDRESS) begin
						if(byte_count < addr_cycles) begin
							substate	= `MS_SUBMIT_COMMAND;
						end else begin
							substate	= `MS_SUBMIT_COMMAND1;
						end
						state			= `M_WAIT;
						n_state			= `M_NAND_READ;
					end else if(substate == `MS_SUBMIT_COMMAND1) begin
						cle_data_in		= 16'h0030;
						//delay 			= `t_wb;
						substate		= `MS_DELAY;
						state 			= `M_WAIT;
						n_state			= `M_NAND_READ;
					end else if(substate == `MS_DELAY) begin
						delay			= `t_wb;
						substate		= `MS_READ_DATA0;
						state			= `M_WAIT; //M_DELAY;
						n_state			= `M_NAND_READ;
						byte_count		= 0;
						page_idx		= 0;
					end else if(substate == `MS_READ_DATA0) begin
						byte_count		= byte_count + 1;
						n_state			= `M_NAND_READ;
						delay			= `t_rr;
						state			= `M_WAIT;
						substate		= `MS_READ_DATA1;
					end else if(substate == `MS_READ_DATA1) begin
						page_data[page_idx]	= io_rd_data_out[7:0];
						page_idx		= page_idx + 1;
						if(byte_count == data_bytes_per_page + oob_bytes_per_page & status[1] == 1'b0) begin
							substate	= `MS_END;
						end else begin
							if(status[1] == 1'b0) begin
								substate		= `MS_READ_DATA0;
							end else begin
								substate		= `MS_READ_DATA2;
							end
						end
						
					end else if(substate == `MS_READ_DATA2) begin
						page_idx		= page_idx + 1;
						page_data[page_idx]	= io_rd_data_out[15:8];
						if(byte_count == data_bytes_per_page + oob_bytes_per_page) begin
							substate	= `MS_END;
						end else begin
							substate	= `MS_READ_DATA0;
						end
					end else if(substate == `MS_END) begin
						substate		= `MS_BEGIN;
						state			= `M_IDLE;
						byte_count		= 0;
					end
				end	
				// Read status byte
				`M_NAND_READ_STATUS: begin
					if(substate == `MS_BEGIN) begin
						cle_data_in		= 16'h0070;
						substate		= `MS_SUBMIT_COMMAND;
						state			= `M_WAIT;
						n_state			= `M_NAND_READ_STATUS;
					end else if(substate == `MS_SUBMIT_COMMAND) begin
						delay			= `t_whr;
						substate		= `MS_READ_DATA0;
						state			= `M_DELAY;
						n_state			= `M_NAND_READ_STATUS;
					end else if(substate == `MS_READ_DATA0) begin
						substate		= `MS_READ_DATA1;
						state			= `M_WAIT;
						n_state			= `M_NAND_READ_STATUS;
					end else if(substate == `MS_READ_DATA1) begin // This is to make sure 'data_out' has valid data before 'busy' goes low.
						data_out		= io_rd_data_out[7:0];
						state			= `M_NAND_READ_STATUS;
						substate		= `MS_END;
					end else if(substate == `MS_END) begin
						substate		= `MS_BEGIN;
						state			= `M_IDLE;
					end
				end	
				// Erase block specified by current_address
				`M_NAND_BLOCK_ERASE: begin
					if(substate == `MS_BEGIN) begin
						cle_data_in		= 16'h0060;
						substate		= `MS_SUBMIT_COMMAND;
						state			= `M_WAIT;
						n_state			= `M_NAND_BLOCK_ERASE;
						byte_count		= 3;							// number of address bytes to submit
						
					end else if(substate == `MS_SUBMIT_COMMAND) begin
						byte_count		= byte_count - 1;
						ale_data_in[15:8]= 8'h00;
						ale_data_in[7:0]	= current_address[5 - byte_count];
						substate		= `MS_SUBMIT_ADDRESS;
						state			= `M_WAIT;
						n_state			= `M_NAND_BLOCK_ERASE;
						
					end else if(substate == `MS_SUBMIT_ADDRESS) begin
						if(0 < byte_count) begin
							substate	= `MS_SUBMIT_COMMAND;
						end else begin
							substate	= `MS_SUBMIT_COMMAND1;
						end
						
					end else if(substate == `MS_SUBMIT_COMMAND1) begin
						cle_data_in		= 16'h00d0;
						substate		= `MS_END;
						state			= `M_WAIT;
						n_state			= `M_NAND_BLOCK_ERASE;
						
					end else if(substate == `MS_END) begin
						n_state			= `M_IDLE;
						delay 			= `t_wb + `t_bers;
						state			= `M_DELAY;
						substate		= `MS_BEGIN;
						byte_count		= 0;
					end
				end	
				// Read NAND chip JEDEC ID
				`M_NAND_READ_ID: begin
					if(substate == `MS_BEGIN) begin
						cle_data_in		= 16'h0090;
						substate		= `MS_SUBMIT_COMMAND;
						state			= `M_WAIT;
						n_state 		= `M_NAND_READ_ID;
					end else if(substate == `MS_SUBMIT_COMMAND) begin
						ale_data_in		= 16'h0000;
						substate		= `MS_SUBMIT_ADDRESS;
						state 			= `M_WAIT;
						n_state			= `M_NAND_READ_ID;
					end else if(substate == `MS_SUBMIT_ADDRESS) begin
						delay			= `t_wb;
						state			= `M_DELAY;
						n_state			= `M_NAND_READ_ID;
						substate		= `MS_READ_DATA0;
						byte_count		= 5;
						page_idx		= 0;
					end else if(substate == `MS_READ_DATA0) begin
						byte_count		= byte_count - 1;
						state			= `M_WAIT;
						n_state			= `M_NAND_READ_ID;
						substate		= `MS_READ_DATA1;
					end else if(substate == `MS_READ_DATA1) begin
						chip_id[page_idx]	= io_rd_data_out[7:0];
						if(0 < byte_count) begin
							page_idx	= page_idx + 1;
							substate	= `MS_READ_DATA0;
						end else begin
							substate	= `MS_END;
						end
					end else if(substate == `MS_END) begin
						byte_count		= 0;
						page_idx		= 0;
						substate		= `MS_BEGIN;
						state			= `M_IDLE;
					end
				end	
				// *data_in is assigned one clock cycle after *_activate is triggered!!!!
				// According to ONFI's timing diagrams this should be normal, but who knows...
				`M_NAND_READ_PARAM_PAGE: begin
					if(substate == `MS_BEGIN) begin
						cle_data_in		= 16'h00ec;
						substate		= `MS_SUBMIT_COMMAND;
						state			= `M_WAIT;
						n_state 		= `M_NAND_READ_PARAM_PAGE;
					end else if(substate == `MS_SUBMIT_COMMAND) begin
						ale_data_in		= 16'h0000;
						substate		= `MS_SUBMIT_ADDRESS;
						state 			= `M_WAIT;
						n_state			= `M_NAND_READ_PARAM_PAGE;
					end else if(substate == `MS_SUBMIT_ADDRESS) begin
						delay			= `t_wb + `t_rr;
						state			= `M_WAIT;//M_DELAY;
						n_state			= `M_NAND_READ_PARAM_PAGE;
						substate		= `MS_READ_DATA0;
						byte_count		= 256;
						page_idx		= 0;
					end else if(substate == `MS_READ_DATA0) begin
						byte_count		= byte_count - 1;
						state			= `M_WAIT;
						n_state			= `M_NAND_READ_PARAM_PAGE;
						substate		= `MS_READ_DATA1;
					end else if(substate == `MS_READ_DATA1) begin
						page_param[page_idx]	= io_rd_data_out[7:0];
						if(0 < byte_count) begin
							page_idx	= page_idx + 1;
							substate	= `MS_READ_DATA0;
						end else begin
							substate	= `MS_END;
						end
					end else if(substate == `MS_END) begin
						byte_count		= 0;
						page_idx		= 0;
						substate		= `MS_BEGIN;
						state			= `M_IDLE;
						
						// Check the chip for being ONFI compliant
						if(page_param[0] == 8'h4f & page_param[1] == 8'h4e & page_param[2] == 8'h46 & page_param[3] == 8'h49) begin
							// Set status bit 0
							status[0]	= 1'b1;
							
							// Bus width
							status[1]	= page_param[6][0];
						 
							// Setup counters:
							// Normal FLAsh
							if(page_param[63] == 8'h20) begin
								// Number of bytes per page
								tmp_int			= {page_param[83],page_param[82],page_param[81],page_param[80]};
								data_bytes_per_page 	= tmp_int;
								
								// Number of spare bytes per page (OOB)
								tmp_int			= {6'b0,page_param[85],page_param[84]};
								oob_bytes_per_page	= tmp_int;
								
								// Number of address cycles
								addr_cycles		= page_param[101][3:0] + page_param[101][7:4];
							end else begin
								// Number of bytes per page
								tmp_int			= {page_param[82],page_param[81],page_param[80],page_param[79]};
								data_bytes_per_page 	= tmp_int;
								
								// Number of spare bytes per page (OOB)
								tmp_int			= {62'b0,page_param[84],page_param[83]};
								oob_bytes_per_page	= tmp_int;
								
								// Number of address cycles
								addr_cycles		= page_param[100][3:0] + page_param[100][7:4];
							end
						end
					end
				end	
				// Wait for latch and IO modules to become ready as well as for NAND's R/B# to be 1'b1
				`M_WAIT: begin
					if(delay > 1) begin
						delay		= delay - 1;
					end else if(1'b0 == (cle_busy | ale_busy | io_rd_busy | io_wr_busy | (!nand_rnb))) begin
						state		= n_state;
					end
				end	
				// Simple delay mechanism
				`M_DELAY: begin
					if(delay > 1) begin
						delay 		= delay - 1;
					end else begin
						state		= n_state;
					end
				end	
				`MI_BYPASS_ADDRESS: begin
					if(substate == `MS_BEGIN) begin
						ale_data_in	= {8'h00,data_in[7:0]};
						substate	= `MS_SUBMIT_ADDRESS;
						state 		= `M_WAIT;
						n_state		= `MI_BYPASS_ADDRESS;
						
					end else if(substate == `MS_SUBMIT_ADDRESS) begin
						delay		= `t_wb + `t_rr;
						state		= `M_WAIT;//M_DELAY;
						n_state		= `MI_BYPASS_ADDRESS;
						substate	= `MS_END;
						
					end else if(substate == `MS_END) begin
						substate 	= `MS_BEGIN;
						state 		= `M_IDLE;
					end
				end	
				`MI_BYPASS_COMMAND: begin
					if(substate == `MS_BEGIN) begin
						cle_data_in	= {8'h00,data_in[7:0]};
						substate	= `MS_SUBMIT_COMMAND;
						state 		= `M_WAIT;
						n_state		= `MI_BYPASS_COMMAND;
						
					end else if(substate == `MS_SUBMIT_COMMAND) begin
						delay		= `t_wb + `t_rr;
						state		= `M_WAIT;//M_DELAY;
						n_state		= `MI_BYPASS_COMMAND;
						substate	= `MS_END;
						
					end else if(substate == `MS_END) begin
						substate 	= `MS_BEGIN;
						state 		= `M_IDLE;
					end
				end	
				`MI_BYPASS_DATA_WR: begin
					if(substate == `MS_BEGIN) begin
						io_wr_data_in[15:0] = {8'h00,data_in[7:0]}; //page_data(page_idx);
						substate 	= `MS_WRITE_DATA0;
						state 		= `M_WAIT;
						n_state		= `MI_BYPASS_DATA_WR;
						
					end else if(substate == `MS_WRITE_DATA0) begin
						state 		= `M_WAIT;
						n_state 	= `M_IDLE;
						substate	= `MS_BEGIN;
					end
				end	
				`MI_BYPASS_DATA_RD: begin
					if(substate == `MS_BEGIN) begin
						substate	= `MS_READ_DATA0;
						
					end else if(substate == `MS_READ_DATA0) begin
						//page_data(page_idx) = io_rd_data_out[7:0];
						data_out[7:0] = io_rd_data_out[7:0];
						substate	= `MS_BEGIN;
						state 		= `M_IDLE;
					end
				end	
				// For just in case ("Shit happens..." (C) Forrest Gump)
				default:
					state 			= `M_RESET;
			endcase
		end
	end
endmodule

