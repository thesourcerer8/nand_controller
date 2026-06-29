# nand_controller
NAND Controller, targeting ONFI and non-compliant flash

This project is based on the VHDL sources from https://opencores.org/projects/nand_controller which were ported to Verilog

We are targeting the specifications from ONFI: https://onfi.org/specs.html

Current status: It is currently being verified, it does not seem to behave properly in all situations yet.

Verification is done with Flash models from https://freemodelfoundry.com/

Tools used for Verification:
* https://github.com/steveicarus/iverilog/
* http://www.sigrok.org/
* https://gtkwave.sourceforge.net/
* https://www.veripool.org/verilator/
* https://surfer-project.org/
* https://github.com/YosysHQ/yosys

Installation of required tools:
```sudo apt-get install iverilog sigrok gtkwave verilator yosys```

To view the waveforms from the testbench simulations in the Surfer Project, just click this link:
https://app.surfer-project.org/?load_url=https://raw.githubusercontent.com/thesourcerer8/nand_controller/refs/heads/main/Verilog/testbenchs34.vcd&startup_commands=module_add%20testbench%3BNM%20top%3B
