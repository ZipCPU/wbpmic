# A Wishbone Controller for a PMod-MIC

[Digilent](http://digilentinc.com) makes a
[MEMs microphone](http://store.digilentinc.com/pmod-mic3-mems-microphone-with-adjustable-gain)
that can be connected to one of their
[FPGA boards](http://store.digilentinc.com/fpga-programmable-logic/) via a
PMod standard.  The purpose of this core is to provide an open source wishbone
interface to that device. 

Thie project provides two separate interfaces are offered in this project:
[The first one](rtl/wbmic_tb.v) buffers its data into a FIFO, allowing a 
relaxed reading structure.  [The second](rtl/wbsmpladc.v), provides a single
sample wishbone capability.  Both cores make it possible to:
- Turn the ADC on and off
- Read single samples on command
- Read from the ADC at a programmable rate.

Several other Digilent PMod devices use the same A/D interface, so the utility
of this core extends well beyond that of the [PModMIC3](http://store.digilentinc.com/pmod-mic3-mems-microphone-with-adjustable-gain) alone.

# Status

These two cores have currently passed their bench testing.  They have yet to
be used within an FPGA.  Further, the specification for this core has yet to
be written as well, leaving the only specification for how things work
the actual code itself.

# License

Gisselquist Technology is pleased to offer these cores to all who are
interested, subject to the GPLv3 license.

# Commercial Opportunities

If the GPLv3 license is insufficient for your needs, other licenses may be
purchased from Gisselquist Technology, LLC.
