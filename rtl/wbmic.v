////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	wbmic.v
//
// Project:	WBPMIC, wishbone control of a MEMs PMod MIC
//
// Purpose:	To implement a wishbone controlled PMod-MIC (MEMs microphone)
//		interface, so as to allow the microphone to be controlled
//	(sample rate, on/off, etc) from a wishbone master, while also recording
//	the results from the microphone.
//
// Registers:
//	0	Data register
//	 Bits
//	  31-16	Number of samples currently in the FIFO
//	  15- 0	Next Sample from the sample FIFO
//	Writes to this register, with a 0 sample rate, will initiate a request
//	for a single sample.
//
//	1	Sample rate control register
//	 Bits
//	  31-28	(READ-ONLY) LOG FIFO size minus two (2^2 ... 2^17)
//	  27-25	Unused
//	     24	True on FIFO overflow, set to reset the FIFO and overflow
//		  condition
//	     22 True if you want a half-full FIFO interrupt, else a single
//		  sample interrupt
//	     22 True if the FIFO is half full or more
//	     21 True if a sample is ready
//	     20 Enable interface
//	  19- 0	Sample rate control
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
`default_nettype	none
//
module	wbmic(i_clk, i_rst, i_wb_cyc, i_wb_stb, i_wb_we, i_wb_addr, i_wb_data,
		o_wb_ack, o_wb_stall, o_wb_data,
		o_csn, o_sck, i_miso,
		o_int);
	parameter [4:0]			TIMING_BITS = 5'd20;
	parameter [(TIMING_BITS-1):0]	DEFAULT_RELOAD = 1814;
	parameter [4:0]	 LGFLEN = 5'h9;
	parameter [0:0]		VARIABLE_RATE = 1'b1;
	parameter [8:0]		CKPCK = 3;
	localparam [4:0] LCLTIMING_BITS
				= (TIMING_BITS > 19)? 5'd20 : TIMING_BITS;
	localparam [4:0] LCLLGFLEN = (LGFLEN < 5'h2) ? 5'h2 : LGFLEN;
	input	wire		i_clk, i_rst;
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
	//
	output	wire		o_int;


	//
	//
	//
	reg		no_timer, r_enabled, r_halfint, fifo_reset, last_addr,
			zclk, pre_ack, adc_req;
	reg	[(LCLTIMING_BITS-1):0]	r_timer_val, r_max_timer;
	wire		w_fifo_err, w_fifo_empty_n, w_fifo_half_full;
	wire	[15:0]	w_fifo_status;
	wire	[11:0]	w_fifo_data;
	wire	[13:0]	w_adc_data;
	wire	[19:0]	w_max_timer;


	initial	r_enabled   = 1'b0;
	initial	r_halfint   = 1'b1;
	initial	fifo_reset  = 1'b1;
	initial	r_max_timer = DEFAULT_RELOAD;
	always @(posedge i_clk)
		if (i_rst)
		begin
			r_enabled   <= 1'b0;
			r_halfint   <= 1'b0;
			fifo_reset  <= 1'b1;
		end else if ((i_wb_stb)&&(i_wb_we)&&(i_wb_addr))
		begin
			if (!VARIABLE_RATE)
				r_max_timer <= i_wb_data[(LCLTIMING_BITS-1):0];
			r_enabled   <= !i_wb_data[20];
			r_halfint   <=  i_wb_data[22];
			fifo_reset  <=  i_wb_data[24];
		end else
			fifo_reset <= 1'b0;

	initial	r_max_timer = DEFAULT_RELOAD;
	always @(posedge i_clk)
		if ((i_wb_stb)&&(i_wb_we)&&(i_wb_addr)&&(VARIABLE_RATE))
			r_max_timer <= i_wb_data[(LCLTIMING_BITS-1):0];

	assign	w_max_timer[(TIMING_BITS-1):0] = r_max_timer;
	generate
	if (TIMING_BITS<20)
		assign	w_max_timer[19:TIMING_BITS] = 0;
	endgenerate

	always @(posedge i_clk)
		last_addr <= i_wb_addr;
	always @(posedge i_clk)
		case(i_wb_addr)
		1'b0: o_wb_data <= { w_fifo_status, w_fifo_data, 4'h0 };
		1'b1: o_wb_data <= { 3'h0, LGFLEN,
				w_fifo_err, r_halfint,
				w_fifo_half_full,
				w_fifo_empty_n,
				w_max_timer };
		endcase

	initial	pre_ack = 1'b0;
	always @(posedge i_clk)
		pre_ack <= (i_wb_stb)&&(!i_rst);
	always @(posedge i_clk)
		o_wb_ack <= (pre_ack)&&(i_wb_cyc)&&(!i_rst);
	assign	o_wb_stall = 1'b0;

	smpladc	#(CKPCK)
		llsample(i_clk, adc_req, w_adc_data[12], r_enabled, o_csn,o_sck,
			i_miso, w_adc_data);

	initial	no_timer = 1'b1;
	always @(posedge i_clk)
		no_timer <= (r_max_timer == 0);

	initial	r_timer_val = 0;
	always @(posedge i_clk)
		if ((!r_enabled)&&(!w_adc_data[13]))
			r_timer_val <= 0;
		else if (r_timer_val == 0)
			r_timer_val <= r_max_timer;
		else
			r_timer_val <= r_timer_val - 1'b1;

	initial	zclk = 1'b0;
	always @(posedge i_clk)
		zclk <= (r_timer_val == { {(LCLTIMING_BITS-1){1'b0}}, {1'b1} });

	initial	adc_req = 1'b0;
	always @(posedge i_clk)
		adc_req <= (zclk)||((no_timer)&&(i_wb_stb)&&(i_wb_we)&&(!i_wb_addr));


	smplfifo #(.BW(12), .LGFLEN(LCLLGFLEN)) thefifo(i_clk,
		fifo_reset, w_adc_data[12], w_adc_data[11:0],
		w_fifo_empty_n,
		(i_wb_stb)&&(!i_wb_we)&&(!i_wb_addr), w_fifo_data,
		w_fifo_status, w_fifo_err);
	assign	w_fifo_half_full = w_fifo_status[1];

	assign	o_int = (r_halfint) ? w_fifo_half_full : w_fifo_empty_n;

`ifdef FORMAL

`ifdef	WBMIC
`define	ASSUME	assume
`else
`define	ASSUME	assert
`endif
	reg	f_past_valid, f_last_clk;

//
// Assumptions about our inputs
//
//
	initial	restrict(i_rst);
	initial	restrict(!i_wb_cyc);
	initial	restrict(!i_wb_stb);
	always @($global_clock)
	begin
		restrict(i_clk == !f_last_clk);
		f_last_clk <= i_clk;
		if (!$rose(i_clk))
		begin
			// Our bus (and reset) inputs can *only* change on the
			// positive edge of the clock.  Assert that.
			`ASSUME($stable(i_rst));
			`ASSUME($stable(i_wb_cyc));
			`ASSUME($stable(i_wb_stb));
			`ASSUME($stable(i_wb_we));
			`ASSUME($stable(i_wb_addr));
			`ASSUME($stable(i_wb_data));
		end
	end

	// $past(X) only works on the second and subsequent clocks.  Here,
	// we'll create a f_past_valid signal that we can use to gate
	// whether or not a $past(X) signal is valid.
	initial	f_past_valid = 1'b0;
	always @(posedge i_clk)
		f_past_valid <= 1'b1;

	//
	// Bus assertions
	//
	// If the strobe is ever asserted, i_wb_cyc *must* also be asserted
	// at the same time.
	always @(posedge i_clk)
		if (i_wb_stb)
			`ASSUME(i_wb_cyc);

	// Don't allow both the i_rst and i_wb_cyc to be asserted at the
	// same time.
	always @(posedge i_clk)
		`ASSUME((!i_wb_cyc)||(!i_rst));

//
// Assertions about our outputs
//
//

	// The most important output is the o_wb_ack signal.  If this isn't
	// done properly, this component might hang the bus.  While it's
	// trivially correct, we'll check it anyway.  Let's make sure this
	// is properly set, only following a bus request.
	always @(posedge i_clk)
		if ((f_past_valid)&&(!$past(i_rst))
			&&(!$past(i_rst,2))&&($past(f_past_valid))
			&&($past(i_wb_cyc)))
			assert(o_wb_ack== (($past(i_wb_stb,2))));

	always @(posedge i_clk)
		if ((f_past_valid)&&(!$past(i_wb_cyc,2))&&(!$past(i_wb_cyc)))
			assert(!o_wb_ack);

	//
	// Assertions regarding the output interrupt
	//
	// These should be trivially true.
	// 
	always @(*)
		if (w_fifo_half_full)
			assert(o_int);
	always @(*)
		if ((w_fifo_empty_n)&&(!r_halfint))
			assert(o_int);

	// Make certain that our zclk timeout value is identical to the
	// (r_timer_val == 0) condition, just simplified.
	always @(posedge i_clk)
		if (zclk)
			assert(r_timer_val == 0);

	// If we aren't empty, we can only become empty by reading from the
	// bus.
	always @(posedge i_clk)
		if ($past(w_fifo_empty_n))
			assert((w_fifo_empty_n)
				||($past(fifo_reset))
				||($past(i_wb_stb))&&($past(!i_wb_we))
					&&($past(!i_wb_addr)));

	// If a FIFO error has taken place, then the FIFO error must remain
	// asserted until a FIFO reset is applied
	always @(posedge i_clk)
		if (($past(w_fifo_err))&&(!$past(fifo_reset)))
			assert(w_fifo_err);
`endif
endmodule

