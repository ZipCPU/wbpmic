////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	wbsmpladc
//
// Project:	WBPMIC, wishbone control of a MEMs PMod MIC
//
// Purpose:	Provides a very simple wishbone controllable interface to the
//		smpladc.v.  The interface is controleld via a single register.
//	A separate register can be used to read the data.  The interface
//	can be used to sample single samples, or to sample continuous
//	samples depending upon how it is configured.
//
// Registers:
//
//	0	The data register.  The bottom 16 bits are the most recent
//		  sample data.
//
//		The other two bits in this register are used for controlling
//		the interface:
//
//	  Bits
//	    17	Device enable
//	    16	Sample invalid (0 if valid--just like wbuart)
//
//	1	The sample rate control register.  The CLKRATE divided by the
//		  value in this register will be the sample rate of the ADC.
//
//		If this register is set to zero, the ADC will sample
//		once and stop.
//
//
// Creator:	Dan Gisselquist, Ph.D.
//		Gisselquist Technology, LLC
//
////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2017, Gisselquist Technology, LLC
//
// This program is free software (firmware): you can redistribute it and/or
// modify it under the terms of  the GNU General Public License as published
// by the Free Software Foundation, either version 3 of the License, or (at
// your option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTIBILITY or
// FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
// for more details.
//
// You should have received a copy of the GNU General Public License along
// with this program.  (It's in the $(ROOT)/doc directory.  Run make with no
// target there if the PDF file isn't present.)  If not, see
// <http://www.gnu.org/licenses/> for a copy.
//
// License:	GPL, v3, as defined and found on www.gnu.org,
//		http://www.gnu.org/licenses/gpl.html
//
//
////////////////////////////////////////////////////////////////////////////////
//
//
module	wbsmpladc(i_clk,
		i_wb_cyc, i_wb_stb, i_wb_we, i_wb_addr, i_wb_data,
			o_wb_ack, o_wb_stall, o_wb_data,
		o_csn, o_sck, i_miso,
		o_int);
	parameter [8:0]	CKPCK = 2;
	//
	parameter [4:0]		TIMING_BITS=5'd20;
	parameter [(TIMING_BITS-1):0]	DEFAULT_RELOAD = 1814;
	parameter [0:0]		VARIABLE_RATE=1'b1;
	//
	input	wire		i_clk;
	//
	input	wire		i_wb_cyc, i_wb_stb, i_wb_we, i_wb_addr;
	input	wire	[31:0]	i_wb_data;
	//
	output	reg		o_wb_ack;
	output	wire		o_wb_stall;
	output	reg	[31:0]	o_wb_data;
	// 
	output	wire		o_csn, o_sck;
	input	wire		i_miso;
	output	wire		o_int;

	reg				no_timer, rd_req, r_enabled, zclk,
					adc_req;
	reg	[(TIMING_BITS-1):0]	r_max_timer, r_timer_val;
	wire	[13:0]			w_data;


	// First, process the wishbone
	wire	w_addr = (VARIABLE_RATE==1'b0)? 1'b0: i_wb_addr;
	//
	// Address zero: Only one writable bit
	//
	// If the timer is set to zero, though, this will initiate a conversion
	initial	r_enabled = 1'b0;
	always @(posedge i_clk)
		if ((i_wb_stb)&&(i_wb_we)&&(!w_addr))
			r_enabled <= !i_wb_data[17];

	//
	// Address one: maximum timer value, sets the sample conversion rate.
	//
	// Conversion rate should be CLKFREQHZ / (r_max_timer+1)
	initial	r_max_timer = DEFAULT_RELOAD;
	always @(posedge i_clk)
		if ((i_wb_stb)&&(i_wb_we)&&(w_addr))
			r_max_timer <= i_wb_data[(TIMING_BITS-1):0];

	//
	// Read requests.  These will invalidate the valid line, and therefore
	// reset the interrupt.
	//
	initial	rd_req = 1'b0;
	always @(posedge i_clk)
		rd_req <= (i_wb_stb)&&(!i_wb_we)&&(!w_addr);


	always @(posedge i_clk)
		if (w_addr)
			o_wb_data <= { {(32-TIMING_BITS){1'b0}},
					r_max_timer[(TIMING_BITS-1):0] };
		else
			o_wb_data <= { {(32-18){1'b0}}, w_data[13],
					!w_data[12], w_data[11:0], 4'h0 };
	always @(posedge i_clk)
		o_wb_ack <= i_wb_stb;
	assign	o_wb_stall = 1'b0;

	smpladc	#(CKPCK) lladc(i_clk, (adc_req), rd_req,
			r_enabled, o_csn, o_sck, i_miso, w_data);


	initial	no_timer = 1'b1;
	always @(posedge i_clk)
		no_timer <= (r_max_timer == 0);

	initial	r_timer_val = 0;
	always @(posedge i_clk)
		if ((!r_enabled)&&(!w_data[13]))
			r_timer_val <= 0;
		else if (r_timer_val == 0)
			r_timer_val <= (VARIABLE_RATE)?r_max_timer:DEFAULT_RELOAD;
		else
			r_timer_val <= r_timer_val - 1'b1;

	initial	zclk = 1'b0;
	always @(posedge i_clk)
		zclk <= (r_timer_val == { {(TIMING_BITS-1){1'b0}}, 1'b1 });

	always @(posedge i_clk)
		adc_req <= (zclk)||((no_timer)&&(i_wb_stb)&&(i_wb_we));

	assign	o_int = (w_data[12])&&(w_data[13]);

endmodule

