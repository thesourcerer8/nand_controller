all: iverilogs verilators


%.vcd: %.sv
	iverilog -o $@ $< -Wall -g2005-sv

clean:
	rm -f *.vcd
	rm -f *.log

dependencies: 
	sudo apt-get install iverilog yosys gtkwave sigrok-cli pulseview libsigrok-dev
	echo Build verilator from source to get a more recent version
	sudo ln -s `realpath ../SigRok` /usr/share/libsigrokdecode/decoders/onfi

iverilog:
	iverilog -o testbench testbench.sv -Wall -g2005-sv
	vvp testbench
	sigrok-cli -I vcd -i testbench.vcd -o testbench.sr
	sigrok-cli -i testbench.sr -P onfi -A onfi --protocol-decoder-samplenum || true
	echo gtkwave testbench.gtkw

yosys:
	yosys -p 'synth_ice40 -top nand_master -blif test.blif' nand_master.sv  || true

verilator:
	verilator -sc testbench.sv --coverage --no-timing

iverilogs:
	iverilog -o testbenchs34 testbenchs34.sv -Wall -g2005-sv -s testbench k9f1208.sv
	vvp testbenchs34
	sigrok-cli -I vcd -i testbenchs34.vcd -o testbenchs34.sr || true
	sigrok-cli -i testbenchs34.sr -P onfi -A onfi --protocol-decoder-samplenum || true
	echo gtkwave testbenchs34.gtkw

verilators:
	verilator -sc testbenchs34.sv --coverage --no-timing

iveriloginout:
	iverilog -o inout inout.sv -Wall -g2005-sv -s top
	vvp inout
	sigrok-cli -I vcd -i inout.vcd -C data0,data1,data2,data3 -o inout.sr
	sigrok-cli -i inout.sr -P onfi -A onfi --protocol-decoder-samplenum || true
	echo gtkwave inout.vcd

