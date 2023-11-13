//-----------------------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------------------
// Title						: ONFI compliant NAND interface
// File							: latch_unit.vhd
// Author						: Alexey Lyashko <pradd@opencores.org>
// License						: LGPL
//-----------------------------------------------------------------------------------------------
// Description:
// This file implements command/address latch component of the NAND controller, which takes 
// care of dispatching commands to a NAND chip.
//-----------------------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------------------

//`include "timescale.sv"
`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps


module latch_unit (clk,activate,data_in,latch_ctrl,write_enable,busy,data_out,latch_type);
	//generic (latch_type : latch_t);
	input clk;
	input activate;
	input [15:0] data_in;
	input latch_type;
	output latch_ctrl; // := '0';
	output write_enable; // := '1';
	output busy; // :=0;
	output [15:0] data_out;

//	typedef enum {LATCH_IDLE, LATCH_HOLD, LATCH_WAIT, LATCH_DELAY} latch_state_t;
`define LATCH_IDLE  2'b00
`define LATCH_HOLD  2'b01
`define LATCH_WAIT  2'b10
`define LATCH_DELAY 2'b11

	reg [1:0] state; // = LATCH_IDLE;
	reg [1:0] n_state; // = LATCH_IDLE;
	reg [31:0] delay = 0;
	reg busy =0;
	reg latch_ctrl=0;
	reg write_enable=1;
	reg [15:0] data_out;
	wire latch_type;


always @(posedge clk) begin

	if (state != `LATCH_IDLE) begin
		busy = 1;
	end else begin
		busy = 0;
	end

	if (state == `LATCH_HOLD | (state == `LATCH_DELAY & (n_state == `LATCH_HOLD | n_state == `LATCH_WAIT))) begin
		latch_ctrl = 1;
	end else begin
		latch_ctrl = 0;
	end

	if (state == `LATCH_DELAY & n_state == `LATCH_HOLD) begin
		write_enable = 1'b0;
	end else if (state != `LATCH_IDLE) begin
		write_enable = 1'b1;
	end else begin
		write_enable = 1'b1; // 'H'; // ?!?!?! HIGH = 1 ?
	end
									
	if (state != `LATCH_IDLE & state != `LATCH_WAIT & n_state != `LATCH_IDLE) begin
		data_out = data_in;
	end else begin
		data_out = 0; // "LLLLLLLLLLLLLLLLLL";
	end

		case(state)
			`LATCH_IDLE:
			begin
				if(activate == 1'b1) begin
					n_state	= `LATCH_HOLD;
					state	= `LATCH_DELAY;
					delay	= `t_wp;
				end
			end
			`LATCH_HOLD:
			begin
				if(latch_type == `LATCH_CMD) begin
					delay	= `t_clh;
				end else begin
					delay	= `t_wh;
				end
				n_state	= `LATCH_WAIT;
				state	= `LATCH_DELAY;
			end			
			`LATCH_WAIT:
			begin
				if(latch_type == `LATCH_CMD) begin
				//		-- Delay has been commented out. It is component's responsibility to 
				//		--	execute proper delay on command submission.
//--						state					= LATCH_DELAY;
					state	= `LATCH_IDLE;
					n_state	= `LATCH_IDLE;
//--					delay	=	t_wb;						
				end else begin
					state	= `LATCH_IDLE;
				end
			end	
			`LATCH_DELAY:
				if(delay > 1) begin
					delay 	= delay - 1;
				end else begin
					state	= n_state;
				end
			default:	
				state	= `LATCH_IDLE;
		endcase
	end
endmodule
