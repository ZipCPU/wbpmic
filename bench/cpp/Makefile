################################################################################
##
## Filename:	Makefile
##
## Project:	WBPMIC, wishbone control of a MEMs PMod MIC
##
## Purpose:	This makefile builds the final verilator simulation of the
##		PMod MIC controller core(s).  Specifically, it builds the
##	final C++ portion of the simulator, and thus the final simulator
##	executable.
##
##	Useful targets of this makefile include:
##
##	all	Builds wbmic_tb and wbsmpladc_tb, the two test benches for
##		this repository
##
##	wbmic_tb The real target of this make file.  This is the test program.
##
##	wbsmpladc_tb	An alternate test program, designed to test the simple
##		wishbone interface to the ADC.
##
##	test	Run the test program (wbmic_tb), to see if it works or not
##
##	clean
##		Removes all the products of compilation and testing
##
##
## Creator:	Dan Gisselquist, Ph.D.
##		Gisselquist Technology, LLC
##
################################################################################
##
## Copyright (C) 2015-2017, Gisselquist Technology, LLC
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
all: wbmic_tb wbsmpladc_tb

CXX	:= g++
CFLAGS	:= -Wall -Og -g
OBJDIR  := obj-pc
RTLD	:= ../../rtl
RTLOBJD := $(RTLD)/obj_dir
VERILATOR_ROOT ?= $(shell bash -c 'verilator -V|grep VERILATOR_ROOT | head -1 | sed -e " s/^.*=\s*//"')
VROOT   := $(VERILATOR_ROOT)
VINCS	:= -I$(VROOT)/include -I$(VROOT)/include/vltstd
INCS	:= -I$(RTLOBJD) $(VINCS)
MICSRCS := wbmic_tb.cpp micnco.cpp
MICOBJS := $(addprefix $(OBJDIR)/,$(subst .cpp,.o,$(MICSRCS)))
SMPLSRC := wbsmpladc_tb.cpp byteswap.cpp micnco.cpp
SMPLOBJ := $(addprefix $(OBJDIR)/,$(subst .cpp,.o,$(MICSRCS)))
SOURCES := $(MICSRCS)
VLSRCS	:= verilated.cpp verilated_vcd_c.cpp
VLOBJS  := $(OBJDIR)/verilated.o $(OBJDIR)/verilated_vcd_c.o
VLIB	:= $(addprefix $(VROOT)/include/,$(VLSRCS))
LIBS	:= $(RTLOBJD)/Vwbmic__ALL.a

$(OBJDIR)/%.o: %.cpp
	$(CXX) $(CFLAGS) $(INCS) -c $< -o $@

$(OBJDIR)/wbmic_tb.o: wbmic_tb.cpp
	$(CXX) -DWBMIC $(CFLAGS) $(INCS) -c $< -o $@

$(OBJDIR)/wbsmpladc_tb.o: wbmic_tb.cpp
	$(CXX) $(CFLAGS) $(INCS) -c $< -o $@

$(OBJDIR)/%.o: $(VROOT)/include/%.cpp
	$(CXX) $(CFLAGS) $(INCS) -c $< -o $@

wbmic_tb: $(MICOBJS) $(VLOBJS) $(RTLOBJD)/Vwbmic__ALL.a
	$(CXX) $(CFLAGS) $(INCS) $(MICOBJS) $(VLOBJS) $(RTLOBJD)/Vwbmic__ALL.a -o $@

wbsmpladc_tb: $(SMPLOBJ) $(VLOBJS) $(RTLOBJD)/Vwbmic__ALL.a
	$(CXX) $(CFLAGS) $(INCS) $(MICOBJS) $(VLOBJS) $(RTLOBJD)/Vwbmic__ALL.a -o $@

.PHONY: test
test: wbsmpladc_tb
test: wbmic_tb
	./wbmic_tb

define	build-depends
	@echo "Building dependencies"
	@$(CXX) $(CPPFLAGS) $(INCS) -MM $(VLIB) $(SOURCES) > $(OBJDIR)/xdepends.txt
	@sed -e 's/^.*.o: /$(OBJDIR)\/&/' < $(OBJDIR)/xdepends.txt > $(OBJDIR)/depends.txt
	@rm $(OBJDIR)/xdepends.txt
endef

tags: $(VLIB) $(SOURCES)
	@ctags $(SOURCES) $(VLIB)

.PHONY: depends
depends: tags $(OBJDIR)/
	$(build-depends)

$(OBJDIR)/:
	@bash -c "if [ ! -e $(OBJDIR) ]; then mkdir -p $(OBJDIR)/; fi"

$(OBJDIR)/depends.txt: $(OBJDIR)/ depends

.PHONY: clean
clean:
	rm -rf $(OBJDIR)/ ./wbmic_tb ./wbsmpladc_tb *.vcd

-include $(OBJDIR)/depends.txt
