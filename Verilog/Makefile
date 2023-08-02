all: iverilog yosys

iverilog:
	iverilog -o testbench testbench.sv -Wall
	vvp testbench

yosys:
	yosys -p 'synth_ice40 -top nand_master -blif test.blif' nand_master.sv  || true
