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
	output wire io_ctrl;
	output wire [15:0] data_out;
	output wire busy;

	wire io_type;
	
//	typedef enum {IO_IDLE, IO_HOLD, IO_DELAY} io_state_t; 
`define IO_IDLE 0
`define IO_HOLD 1
`define IO_DELAY 2

	
	reg [2:0] state = `IO_IDLE;
	reg [2:0] n_state = `IO_IDLE;
	
	reg [31:0] delay; // This should be an integer, I guess 31:0 should be fine?
	reg [15:0] data_reg;

	assign busy = (state != `IO_IDLE);
	assign io_ctrl = (state == `IO_DELAY) ? 1'b0 : 1'b1;
	assign data_out = ((io_type == `IO_WRITE & state != `IO_IDLE) | io_type == `IO_READ) ? data_reg : 16'b0;

always @(posedge clk) begin

	// IO: process(clk, activate)
	case (state)
		`IO_IDLE:
		begin
			if (io_type == `IO_WRITE) begin
				data_reg <= data_in;
			end
			if (activate == 1'b1) begin
				if (io_type == `IO_WRITE) begin
					delay <= `t_wp + 2;
				end else begin
					delay <= `t_rea + 2;
				end
				n_state <= `IO_HOLD;
				state <= `IO_DELAY;
			end
		end
		`IO_HOLD:
		begin
			if (io_type == `IO_WRITE) begin
				delay <= `t_wh + 1;
			end else begin
				delay <= `t_reh + 1;
			end
			n_state <= `IO_IDLE;
			state <= `IO_IDLE;
		end
	 	`IO_DELAY:
		begin
			if (delay > 1) begin
				delay <= delay - 1;
			end else begin
				if (io_type == `IO_READ) begin
					//$display("NM:%0t IO_READ data_reg latching: %x",$realtime,data_in);
					data_reg <= data_in;
				end
				state <= n_state;
			end
		end
		default:
			state <= `IO_IDLE;
	endcase

end
endmodule
