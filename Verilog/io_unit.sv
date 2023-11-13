//-------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------
//-- Title						: ONFI compliant NAND interface
//-- File							: io_unit.vhd
//-- Author						: Alexey Lyashko <pradd@opencores.org>
//-- License						: LGPL
//-------------------------------------------------------------------------------------------------
//-- Description:
//-- This file implements data IO unit of the controller.
//-------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------

//`include "timescale.sv"
`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps


module io_unit(clk,activate,data_in,io_ctrl,data_out,busy,io_type);
	//generic (io_type : io_t);
	input clk;
	input activate;
	input [15:0] data_in;
	input io_type;
	output io_ctrl; // := '1';
	output [15:0] data_out;
	output busy;

        reg io_ctrl = 1'b1; // We want it initialized but overwritten on demand
	reg busy = 1'b0;
	reg [15:0] data_out;
	wire io_type;
	
//	typedef enum {IO_IDLE, IO_HOLD, IO_DELAY} io_state_t; 
`define IO_IDLE 0
`define IO_HOLD 1
`define IO_DELAY 2

	
	reg [2:0] state; // = (io_state_t == IO_IDLE);
	reg [2:0] n_state; //= (io_state_t == IO_IDLE);
	
	reg [31:0] delay; // This should be an integer, I guess 31:0 should be fine?
	reg [15:0] data_reg;

always @(posedge clk) begin

	if(state == `IO_IDLE) begin
		busy = 1'b0;
	end else begin
		busy = 1'b1;
	end

	if ((io_type == `IO_WRITE & state != `IO_IDLE) | io_type == `IO_READ) begin
		data_out = data_reg;
	end else begin
		data_out = 0;
	end

	if (state == `IO_DELAY & n_state == `IO_HOLD) begin
		io_ctrl = 1'b0;
	end else begin
		io_ctrl = 1'b1;
	end

	// IO: process(clk, activate)
	case (state)
		`IO_IDLE:
		begin
			if (io_type == `IO_WRITE) begin
				data_reg = data_in;
			end
			if (activate == 1'b1) begin
				if (io_type == `IO_WRITE) begin
					delay = `t_wp;
				end else begin
					delay = `t_rea;
				end
				n_state = `IO_HOLD;
				state = `IO_DELAY;
			end ;
		end
		`IO_HOLD:
		begin
			if (io_type == `IO_WRITE) begin
				delay = `t_wh;
			end else begin
				delay = `t_reh;
			end
			n_state = `IO_IDLE;
			state = `IO_IDLE;
		end
	 	`IO_DELAY:
		begin
			if (delay >1) begin	
				delay = delay - 1 ;
				if (delay==2 & io_type == `IO_READ) begin
					data_reg = data_in;
				end
			end else begin
				if (io_type == `IO_READ & n_state == `IO_IDLE) begin
					data_reg = data_in; //This thing needs to be checked with real hardware. Assignment may be needed somewhat earlier.
				end
				state = n_state;
			end
		end
		default:
			state = `IO_IDLE;
	endcase

end
endmodule	
