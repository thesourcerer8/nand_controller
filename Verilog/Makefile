all: iverilog yosys

iverilog:
	iverilog -o testbench testbench.sv -Wall
	vvp testbench

yosys:
	yosys -p 'synth_ice40 -top tb -blif test.blif' testbench.sv  || true
