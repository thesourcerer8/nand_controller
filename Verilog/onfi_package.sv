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


//package global;
	// Clock cycle length in ns
	// IMPORTANT!!! The 'clock_cycle' is configured for 400MHz, change it appropriately!
	parameter clock_cycle	= 2;

	// NAND interface delays.
	// Delays of 7.5ns may need to be fixed to 7.0.
	parameter	t_cls	=	(10.0	/ clock_cycle);
	parameter	t_clh	=	(5.0 	/ clock_cycle);
	parameter	t_wp	=	(10.0 	/ clock_cycle);
	parameter	t_wh	=	(7.5	/ clock_cycle);
	parameter	t_wc	=	(20.0	/ clock_cycle);
	parameter	t_ds	=	(7.5	/ clock_cycle);
	parameter	t_dh	=	(5.0	/ clock_cycle);
	parameter	t_als	=	(10.0	/ clock_cycle);
	parameter	t_alh	=	(5.0	/ clock_cycle);
	parameter	t_rr	=	(20.0	/ clock_cycle);
	parameter	t_rea	=	(16.0	/ clock_cycle);
	parameter	t_rp	=	(10.0	/ clock_cycle);
	parameter	t_reh	=	(7.5	/ clock_cycle);
	parameter	t_wb	=	(100.0	/ clock_cycle);
	parameter	t_rst	=	(5000.0	/ clock_cycle);
	parameter	t_bers	=	(700000.0 / clock_cycle);
	parameter	t_whr	=	(80.0	/ clock_cycle);
	parameter	t_prog	=	(600000.0 / clock_cycle);
	parameter	t_adl	=	(70.0	/ clock_cycle);
	
	typedef enum {LATCH_CMD, LATCH_ADDR} latch_t;
	typedef enum {IO_READ, IO_WRITE} io_t;
	
	typedef enum {
		M_IDLE,								// NAND Master is in idle state - awaits commands.
		M_RESET,								// NAND Master is being reset.
		M_WAIT,								// NAND Master waits for current operation to complete.
		M_DELAY,								// Execute timed delay.
		M_NAND_RESET,						// NAND Master executes NAND 'reset' command.
		M_NAND_READ_PARAM_PAGE,			// Read ONFI parameter page.
		M_NAND_READ_ID,					// Read the JEDEC ID of the chip.
		M_NAND_BLOCK_ERASE,				// Erase block specified by address in current_address.
		M_NAND_READ_STATUS,				//	Read status byte.
		M_NAND_READ,						// Reads page into the buffer.
		M_NAND_READ_8,
		M_NAND_READ_16,
		M_NAND_PAGE_PROGRAM,				// Program one page.
		// interface commands
		MI_GET_STATUS,						// Returns the status byte.
		MI_CHIP_ENABLE,					// Sets CE# to 0.
		MI_CHIP_DISABLE,					// Sets CE# to 1.
		MI_WRITE_PROTECT,					// Sets WP# to 0.
		MI_WRITE_ENABLE,					//	Sets WP# to 1.
		MI_RESET_INDEX,					// Resets page_idx (used as indes into arrays) to 0.
		// The following states depend on 'page_idx' pointer. If its value goes beyond the limits
		// of the array, it is then reset to 0.
		MI_GET_ID_BYTE,					// Gets chip_id(page_idx) byte.
		MI_GET_PARAM_PAGE_BYTE,			// Gets page_param(page_idx) byte.
		MI_GET_DATA_PAGE_BYTE,			// Gets page_data(page_idx) byte.
		MI_SET_DATA_PAGE_BYTE,			// Sets value at page_data(page_idx).
		MI_GET_CURRENT_ADDRESS_BYTE,	// Gets current_address(page_idx) byte.
		MI_SET_CURRENT_ADDRESS_BYTE,	// Sets value at current_address(page_idx).
		// Command processor bypass commands
		MI_BYPASS_ADDRESS,				// Send address byte directly to NAND chip
		MI_BYPASS_COMMAND,				// Send command byte directly to NAND chip
		MI_BYPASS_DATA_WR,				// Send data byte directly to NAND chip
		MI_BYPASS_DATA_RD					// Read data byte directly from NAND chip
	} master_state_t;

	
	typedef enum {	MS_BEGIN,
		MS_SUBMIT_COMMAND,
		MS_SUBMIT_COMMAND1,
		MS_SUBMIT_ADDRESS,
		MS_WRITE_DATA0,
		MS_WRITE_DATA1,
		MS_WRITE_DATA2,
		MS_WRITE_DATA3,
		MS_READ_DATA0,
		MS_READ_DATA1,
		MS_READ_DATA2,
		MS_DELAY,
		MS_WAIT,
		MS_END
	} master_substate_t;

	parameter max_page_idx	= 8626;

	typedef logic [7:0] page_t [max_page_idx];
	typedef logic [7:0] param_page_t [256];
	typedef logic [7:0] nand_id_t [5];
	typedef logic [7:0] nand_address_t [5];
	typedef master_state_t states_t [256];
	
//endpackage
