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
