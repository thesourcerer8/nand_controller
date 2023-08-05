all: iverilog verilator

dependencies: 
	sudo apt-get install iverilog yosys verilator gtkwave sigrok-cli pulseview libsigrok-dev

iverilog:
	iverilog -o testbench testbench.sv -Wall -g2005-sv
	vvp testbench
	sigrok-cli -i testbench.vcd -C nand_nwp,nand_nwe,nand_nre,nand_nce,nand_cle,nand_ale,io0,io1,io2,io3,io4,io5,io6,io7 -o testbench.sr
	sigrok-cli -i testbench.sr -P onfi -A onfi --protocol-decoder-samplenum
	echo gtkwave testbench.vcd

yosys:
	yosys -p 'synth_ice40 -top nand_master -blif test.blif' nand_master.sv  || true

verilator:
	verilator -sc testbench.sv  --coverage

