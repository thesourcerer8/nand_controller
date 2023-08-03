all: iverilog

dependencies: 
	sudo apt-get install iverilog yosys verilator gtkwave

iverilog:
	iverilog -o testbench testbench.sv -Wall
	vvp testbench
	echo gtkwave testbench.vcd

yosys:
	yosys -p 'synth_ice40 -top nand_master -blif test.blif' nand_master.sv  || true

verilator:
	verilator -sc testbench.sv

