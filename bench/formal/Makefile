################################################################################
##
## Filename:	Makefile
##
## Project:	WBPMIC, wishbone control of a MEMs PMod MIC
##
## Purpose:	To direct the formal verification of the SPI A/DC (and FIFO)
##		sources.
##
## Targets:	The default target, all, tests all of the components within
##		this module.
##
## Creator:	Dan Gisselquist, Ph.D.
##		Gisselquist Technology, LLC
##
################################################################################
##
## Copyright (C) 2017, Gisselquist Technology, LLC
##
## This program is free software (firmware): you can redistribute it and/or
## modify it under the terms of  the GNU General Public License as published
## by the Free Software Foundation, either version 3 of the License, or (at
## your option) any later version.
##
## This program is distributed in the hope that it will be useful, but WITHOUT
## ANY WARRANTY; without even the implied warranty of MERCHANTIBILITY or
## FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
## for more details.
##
## You should have received a copy of the GNU General Public License along
## with this program.  (It's in the $(ROOT)/doc directory.  Run make with no
## target there if the PDF file isn't present.)  If not, see
## <http://www.gnu.org/licenses/> for a copy.
##
## License:	GPL, v3, as defined and found on www.gnu.org,
##		http://www.gnu.org/licenses/gpl.html
##
################################################################################
##
##
TESTS := smpladc smplfifo wbmic wbsmpladc
.PHONY: $(TESTS)
all: $(TESTS)
RTL := ../../rtl

ADC=smpladc
ADCBMC=$(ADC)_bmc
ADCIND=$(ADC)_ind
SMTBMC  := yosys-smtbmc
# SOLVER  := -s z3
SOLVER  := -s yices
# BMCARGS := --presat $(SOLVER)
BMCARGS := $(SOLVER)
INDARGS := $(SOLVER) -i

FIFO    := smplfifo
FIFOBMC := $(FIFO)_bmc
FIFOIND := $(FIFO)_ind

WBMIC    := wbmic
WBMICBMC := $(WBMIC)_bmc
WBMICIND := $(WBMIC)_ind

WBSMPL    := wbsmpladc
WBSMPLBMC := $(WBSMPL)_bmc
WBSMPLIND := $(WBSMPL)_ind

$(ADC).smt2: $(RTL)/$(ADC).v
	yosys -ql $(ADC).yslog -s $(ADC).ys

$(FIFO).smt2: $(RTL)/$(FIFO).v
	yosys -ql $(FIFO).yslog -s $(FIFO).ys

$(WBMIC).smt2: $(RTL)/$(WBMIC).v $(RTL)/smpladc.v $(RTL)/smplfifo.v
	yosys -ql $(WBMIC).yslog -s $(WBMIC).ys

$(WBSMPL).smt2: $(RTL)/$(WBSMPL).v $(RTL)/smpladc.v $(RTL)/smplfifo.v
	yosys -ql $(WBSMPL).yslog -s $(WBSMPL).ys

$(ADC) : $(ADC).check
$(ADC).check: $(ADC).smt2
	@rm -f $(ADC).check
	$(SMTBMC) --presat $(BMCARGS) -t 272 --dump-smt2 $(ADCBMC).smt2 --dump-vcd $(ADCBMC).vcd $(ADC).smt2
	$(SMTBMC) $(INDARGS) -t 270 --dump-smt2 $(ADCIND).smt2 --dump-vcd $(ADCIND).vcd $(ADC).smt2
	touch $@


$(FIFO) : $(FIFO).check
$(FIFO).check: $(FIFO).smt2
	@rm -f $(FIFO).check
	$(SMTBMC) --presat $(BMCARGS) -t 26 --dump-smt2 $(FIFOBMC).smt2 --dump-vcd $(FIFOBMC).vcd $(FIFO).smt2
	$(SMTBMC) $(INDARGS) -t 24 --dump-smt2 $(FIFOIND).smt2 --dump-vcd $(FIFOIND).vcd $(FIFO).smt2
	touch $@


$(WBMIC) : $(WBMIC).check
$(WBMIC).check: $(WBMIC).smt2
	@rm -f $(WBMIC).check
	$(SMTBMC) $(BMCARGS) -t 272 --dump-smt2 $(WBMICBMC).smt2 --dump-vcd $(WBMICBMC).vcd $(WBMIC).smt2
	$(SMTBMC) $(INDARGS) -t 270 --dump-smt2 $(WBMICIND).smt2 --dump-vcd $(WBMICIND).vcd $(WBMIC).smt2
	touch $@

$(WBSMPL) : $(WBSMPL).check
$(WBSMPL).check: $(WBSMPL).smt2
	@rm -f $(WBSMPL).check
	$(SMTBMC) $(BMCARGS) -t 272 --dump-smt2 $(WBSMPLBMC).smt2 --dump-vcd $(WBSMPLBMC).vcd $(WBSMPL).smt2
	$(SMTBMC) $(INDARGS) -t 270 --dump-smt2 $(WBSMPLIND).smt2 --dump-vcd $(WBSMPLIND).vcd $(WBSMPL).smt2
	touch $@


.PHONY: clean
clean:
	rm -f   $(ADC).smt2   $(ADCBMC).smt2   $(ADCIND).smt2   $(ADC)*.vcd
	rm -f  $(FIFO).smt2  $(FIFOBMC).smt2  $(FIFOIND).smt2  $(FIFO)*.vcd
	rm -f $(WBMIC).smt2 $(WBMICBMC).smt2 $(WBMICIND).smt2 $(WBMIC)*.vcd
	rm -f *.check
