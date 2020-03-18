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
## Copyright (C) 2017-2020, Gisselquist Technology, LLC
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
SMTBMC  := echo
FIFO	:= smplfifo
WBMIC	:= wbmic
WBSMPL	:= wbsmpladc
WB	:= fwb_slave.v

.PHONY: $(ADC)
$(ADC) : $(ADC)_prf/PASS
$(ADC)_prf/PASS: $(ADC).sby $(RTL)/$(ADC).v
	sby -f $(ADC).sby prf


.PHONY: $(FIFO)
$(FIFO) : $(FIFO)_prf/PASS
$(FIFO)_prf/PASS: $(FIFO).sby $(RTL)/$(FIFO).v
	sby -f $(FIFO).sby prf


.PHONY: $(WBMIC)
$(WBMIC) : $(WBMIC)_prf/PASS
$(WBMIC)_prf/PASS: $(WBMIC).sby $(RTL)/$(WBMIC).v $(RTL)/$(FIFO).v $(RTL)/$(ADC).v
	sby -f $(WBMIC).sby

.PHONY: $(WBSMPL)
$(WBSMPL) : $(WBSMPL)_prf/PASS
$(WBSMPL)_prf/PASS: $(WBSMPL).sby $(RTL)/$(WBSMPL).v $(RTL)/$(ADC).v $(WB)
	sby -f $(WBSMPL).sby


.PHONY: clean
clean:
	rm -rf $(ADC)_*/
	rm -rf $(FIFO)_*/
	rm -rf $(WBMIC)_*/
	rm -rf $(WBSMPL)_*/
	rm -f *.check
