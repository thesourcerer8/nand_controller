all: iverilog verilator

dependencies: 
	sudo apt-get install iverilog yosys verilator gtkwave sigrok-cli pulseview libsigrok-dev
	sudo ln -s `realpath ../SigRok` /usr/share/libsigrokdecode/decoders/onfi

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

iverilogs:
	iverilog -o testbenchs34 testbenchs34.sv -Wall -g2005-sv -s testbench k9f1208.v
	vvp testbenchs34
	#sigrok-cli -i testbenchs34.vcd -C nand_nwp,nand_nwe,nand_nre,nand_nce,nand_cle,nand_ale,io0,io1,io2,io3,io4,io5,io6,io7 -o testbenchs34.sr
	#sigrok-cli -i testbenchs34.sr -P onfi -A onfi --protocol-decoder-samplenum
	echo gtkwave testbenchs34.vcd

verilators:
	verilator -sc testbenchs34.sv  --coverage

iveriloginout:
	iverilog -o inout inout.sv -Wall -g2005-sv -s top
	vvp inout
	#sigrok-cli -i testbenchs34.vcd -C nand_nwp,nand_nwe,nand_nre,nand_nce,nand_cle,nand_ale,io0,io1,io2,io3,io4,io5,io6,io7 -o testbenchs34.sr
	#sigrok-cli -i testbenchs34.sr -P onfi -A onfi --protocol-decoder-samplenum
	echo gtkwave inout.vcd

