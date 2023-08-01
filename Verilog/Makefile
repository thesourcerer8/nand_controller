all: iverilog yosys

iverilog:
	iverilog testbench.sv || true

yosys:
	yosys -p 'synth_ice40 -top tb -blif test.blif' testbench.sv  || true
