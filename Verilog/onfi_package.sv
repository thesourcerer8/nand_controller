//-------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------
//-- Title						: ONFI compliant NAND interface
//-- File						: onfi_package.vhd
//-- Author						: Alexey Lyashko <pradd@opencores.org>
//-- License						: LGPL
//-------------------------------------------------------------------------------------------------
//-- Description:
//-- This file contains clock cycle duration definition, delay timing parameters as well as 
//-- definition of FSM states and types used in the module.
//-------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------

//`include "timescale.sv"
`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps


//package global;
	// Clock cycle length in ns
	// IMPORTANT!!! The 'clock_cycle' is configured for 400MHz, change it appropriately!
`define clock_cycle 2.5

	// NAND interface delays.
	// Delays of 7.5ns may need to be fixed to 7.0.
`define	t_cls	$rtoi(    10.0	/ `clock_cycle)
`define	t_clh	$rtoi(     5.0 	/ `clock_cycle)
`define	t_wp	$rtoi(    10.0	/ `clock_cycle)
`define	t_wh	$rtoi(     7.5	/ `clock_cycle)
`define	t_wc	$rtoi(    20.0	/ `clock_cycle)
`define	t_ds	$rtoi(     7.5	/ `clock_cycle)
`define	t_dh	$rtoi(     5.0	/ `clock_cycle)
`define	t_als	$rtoi(    10.0	/ `clock_cycle)
`define	t_alh	$rtoi(     5.0	/ `clock_cycle)
`define	t_rr	$rtoi(    20.0	/ `clock_cycle)
`define	t_rea	$rtoi(    16.0	/ `clock_cycle)
`define	t_rp	$rtoi(    10.0	/ `clock_cycle)
`define	t_reh	$rtoi(     7.5	/ `clock_cycle)
`define	t_wb	$rtoi(   100.0	/ `clock_cycle)
`define	t_rst	$rtoi(  5000.0	/ `clock_cycle)
`define	t_bers	$rtoi(700000.0	/ `clock_cycle)
`define	t_whr	$rtoi(    80.0	/ `clock_cycle)
`define	t_prog	$rtoi(600000.0	/ `clock_cycle)
`define	t_adl	$rtoi(    70.0	/ `clock_cycle)

//typedef enum {LATCH_CMD, LATCH_ADDR} latch_t;
`define LATCH_CMD 1'b0
`define LATCH_ADDR 1'b1


//typedef enum {IO_READ, IO_WRITE} io_t;
`define IO_READ 1'b0
`define IO_WRITE 1'b1
	
//typedef enum {
`define	M_IDLE 6'd0 					// NAND Master is in idle state - awaits commands.
`define M_RESET 6'd1					// NAND Master is being reset.
`define M_WAIT 6'd2					// NAND Master waits for current operation to complete.
`define M_DELAY 6'd3					// Execute timed delay.
`define M_NAND_RESET 6'd4				// NAND Master executes NAND 'reset' command.
`define M_NAND_READ_PARAM_PAGE 6'd5			// Read ONFI parameter page.
`define M_NAND_READ_ID 6'd6				// Read the JEDEC ID of the chip.
`define M_NAND_BLOCK_ERASE 6'd7				// Erase block specified by address in current_address.
`define M_NAND_READ_STATUS 6'd8				// Read status byte.
`define M_NAND_READ 6'd9				// Reads page into the buffer.
`define M_NAND_READ_8 6'd10
`define M_NAND_READ_16 6'd11
`define M_NAND_PAGE_PROGRAM 6'd12			// Program one page.
// interface commands
`define MI_GET_STATUS 6'd13				// Returns the status byte.
`define MI_CHIP_ENABLE 6'd14				// Sets CE# to 0.
`define MI_CHIP_DISABLE 6'd15				// Sets CE# to 1.
`define MI_WRITE_PROTECT 6'd16				// Sets WP# to 0.
`define MI_WRITE_ENABLE 6'd17				// Sets WP# to 1.
`define MI_RESET_INDEX 	6'd18				// Resets page_idx (used as indes into arrays) to 0.
// The following states depend on 'page_idx' pointer. If its value goes beyond the limits
// of the array  it is then reset to 0.
`define MI_GET_ID_BYTE 6'd19				// Gets chip_id(page_idx) byte.
`define MI_GET_PARAM_PAGE_BYTE 6'd20			// Gets page_param(page_idx) byte.
`define MI_GET_DATA_PAGE_BYTE 6'd21			// Gets page_data(page_idx) byte.
`define MI_SET_DATA_PAGE_BYTE 6'd22 			// Sets value at page_data(page_idx).
`define MI_GET_CURRENT_ADDRESS_BYTE 6'd23		// Gets current_address(page_idx) byte.
`define MI_SET_CURRENT_ADDRESS_BYTE 6'd24		// Sets value at current_address(page_idx).
// Command processor bypass commands
`define MI_BYPASS_ADDRESS 6'd25				// Send address byte directly to NAND chip
`define MI_BYPASS_COMMAND 6'd26 			// Send command byte directly to NAND chip
`define MI_BYPASS_DATA_WR 6'd27 			// Send data byte directly to NAND chip
`define MI_BYPASS_DATA_RD 6'd28				// Read data byte directly from NAND chip
`define M_SET_PAGESIZE 6'd29				// Set the pagesize
`define M_GET_PAGESIZE 6'd30				// Get the pagesize
//	} master_state_t;

	
//	typedef enum {	
`define MS_BEGIN 0
`define MS_SUBMIT_COMMAND 1
`define MS_SUBMIT_COMMAND1 2
`define MS_SUBMIT_ADDRESS 3
`define MS_WRITE_DATA0 4
`define MS_WRITE_DATA1 5
`define MS_WRITE_DATA2 6
`define MS_WRITE_DATA3 7
`define MS_READ_DATA0 8
`define MS_READ_DATA1 9
`define MS_READ_DATA2 10
`define MS_DELAY 11
`define MS_WAIT 12
`define MS_END 13
//	} master_substate_t;

`define max_page_idx 10000
	//typedef logic [7:0] page_t [max_page_idx];
	//typedef logic [7:0] param_page_t [256];
	//typedef logic [7:0] nand_id_t [5];
	//typedef logic [7:0] nand_address_t [5];
	//typedef master_state_t states_t [256];
	
//endpackage
