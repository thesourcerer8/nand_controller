`ifdef __TIMESCALE__
`else

`define __TIMESCALE__
// synthesis translate_off

`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps

// synthesis translate_on

`endif //__TIMESCALE__

