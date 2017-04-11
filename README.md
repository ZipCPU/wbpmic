# A Wishbone Controller for a PMod-MIC

[Digilent](http://digilentinc.com) makes a
[MEMs microphone](http://store.digilentinc.com/pmod-mic3-mems-microphone-with-adjustable-gain)
that can be connected to one of their
[FPGA boards](http://store.digilentinc.com/fpga-programmable-logic/) via a
peripheral module (PMod) interface standard.  The purpose of this project is to
provide a set of open source cores that create a wishbone interface to this
device. 

Thie project provides two separate interfaces are offered in this project:
[The first one](rtl/wbmic.v) buffers its data into a FIFO, allowing a 
relaxed reading structure.  [The second](rtl/wbsmpladc.v), provides a single
sample wishbone capability.  Both cores make it possible to:
- Turn the ADC on and off
- Read single samples on command
- Read from the ADC at a programmable rate.

Further, there is a [very simple interface core](rtl/smpladc.v) which can be
used to get non-wishbone access to this data, should your application not
require a wishbone interface.

Several other [Digilent PMod ADC devices](http://store.digilentinc.com/by-communication-protocol/spi/)
use the same SPI based interface, so the utility of this core extends well
beyond that of the [PModMIC3](http://store.digilentinc.com/pmod-mic3-mems-microphone-with-adjustable-gain) alone.

# Status

The [wbmic](rtl/wbmic.v) cores has currently passed its bench test.  Neither
core has been used within an FPGA (yet).  Further, the specification for this
core has yet to be written as well, leaving the only specification for how
things work the actual code itself.

# License

Gisselquist Technology is pleased to offer these cores to all who are
interested, subject to the GPLv3 license.

# Commercial Opportunities

If the GPLv3 license is insufficient for your needs, other licenses may be
purchased from Gisselquist Technology, LLC.
