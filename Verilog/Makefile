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

iverilog: # Does not contain the Samsung Flash, only simulates NAND_MASTER
	iverilog -o testbench testbench.sv -Wall -g2005-sv
	vvp testbench |tee testbench.log
	sigrok-cli -I vcd -i testbench.vcd -o testbench.sr
	sigrok-cli -i testbench.sr -P onfi -A onfi --protocol-decoder-samplenum || true
	echo gtkwave testbench.gtkw

yosys:
	yosys -p 'synth_ice40 -top nand_master -blif test.blif' nand_master.sv  || true

verilator:
	verilator -sc testbench.sv --coverage --no-timing
verilatort:
	verilator -sc testbench.sv --coverage --timing


iverilogs: # Contains Samsung Flash
	iverilog -o testbenchs34 testbenchs34.sv -Wall -g2005-sv -s testbench s34ml01g1.sv
	# k9f1208.sv
	vvp testbenchs34 |tee testbenchs34.log
	#sigrok-cli -I vcd -i testbenchs34.vcd -o testbenchs34.sr >/dev/null || true
	#sigrok-cli -i testbenchs34.sr -P onfi -A onfi --protocol-decoder-samplenum || true
	echo gtkwave testbenchs34.gtkw

verilators:
	verilator -sc testbenchs34.sv --coverage --no-timing
verilatorst:
	verilator -sc testbenchs34.sv --coverage --timing


iveriloginout:
	iverilog -o inout inout.sv -Wall -g2005-sv -s top
	vvp inout
	sigrok-cli -I vcd -i inout.vcd -C  top.mydata[0],top.mydata[1],top.mydata[2],top.mydata[3] -o inout.sr >/dev/null
	sigrok-cli -i inout.sr -P onfi -A onfi --protocol-decoder-samplenum || true
	echo gtkwave inout.vcd
	echo "https://app.surfer-project.org/?load_url=https://app.surfer-project.org/picorv32.vcd&startup_commands=show_quick_start;module_add%20testbench.top;toggle_menu"


logs:
	make iverilog 2>&1 >log/iverilog.txt
	make iverilogs 2>&1 >log/iverilogs.txt
	make iveriloginout 2>&1 >log/iveriloginout.txt
	make yosys 2>&1 >log/yosys.txt
	make verilator 2>&1 >log/verilator.txt
	make verilatort 2>&1 >log/verilatort.txt
	make verilators 2>&1 >log/verilators.txt
	make verilatorst 2>&1 >log/verilatorst.txt



