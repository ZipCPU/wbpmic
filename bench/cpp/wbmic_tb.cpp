////////////////////////////////////////////////////////////////////////////////
//
// Filename:	wbi2c_tb.cpp
//
// Project:	WBPMIC, wishbone control of a MEMs PMod MIC
//
// Purpose:	Bench testing for the divide unit found within the Zip CPU.
//
//
// Creator:	Dan Gisselquist, Ph.D.
//		Gisselquist Technology, LLC
//
////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2017-2019, Gisselquist Technology, LLC
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
#include <signal.h>
#include <stdint.h>
#include <time.h>
#include <unistd.h>
#include <assert.h>

#include <ctype.h>

#include "verilated.h"
// #define	WBMIC
#ifdef	WBMIC
#include "Vwbmic.h"
#define	DEVICECLASS	Vwbmic
#else
#include "Vwbsmpladc.h"
#define	DEVICECLASS	Vwbsmpladc
#endif

#include "testb.h"
#include "wb_tb.h"
#include "micnco.h"

#define	ADC_CLOCKS_48KHZ	(100000/48)
#define	NCO_CLK_ONEHZ		((1<<30)/25.e6)
#define	ADC_DISABLE		(1<<20)
#define	ADC_ENABLE		0
#define	ADC_HALFFIFO_INT	(1<<22)
#define	ADC_FIFO_RESET		(1<<24)

class	WBMIC_TB : public WB_TB<DEVICECLASS> {
public:
	MICNCO	micnco;
	WBMIC_TB(void) {
	}

	~WBMIC_TB(void) {}

	void	reset(void) {
		// m_flash.debug(false);
		TESTB<DEVICECLASS>::reset();
	}

	void	dbgdump(void) {}

	void	tick(void) {
		const bool	debug = false;

		m_core->i_miso = micnco(m_core->o_sck, m_core->o_csn);

		if (debug)
			dbgdump();
		WB_TB<DEVICECLASS>::tick();

		TBASSERT(*this, !micnco.m_bomb);
	}
};

//
// Standard usage functions.
//
// Notice that the test bench provides no options.  Everything is
// self-contained.
void	usage(void) {
	printf("USAGE: wbmic_tb\n");
	printf("\n");
	printf("\t\n");
}

//
int	main(int argc, char **argv) {
	// Setup
	Verilated::commandArgs(argc, argv);
	WBMIC_TB	*tb = new WBMIC_TB();
	unsigned	*buf, ctrl;
	unsigned	lglen, bflen;

#ifdef	WBMIC
	tb->opentrace("wbmic_tb.vcd");
#else
	tb->opentrace("wbsimpl_tb.vcd");
#endif
	tb->reset();

	tb->micnco.step(500*(unsigned)NCO_CLK_ONEHZ);	// 2^32/100e6

	// 1. It should all be off
	for(unsigned i=0; i<4000; i++) {
		tb->tick();
		TBASSERT(*tb, tb->m_core->o_csn == 1);
		TBASSERT(*tb, tb->m_core->o_sck == 1);
	}

	// 2. Setting a sample rate (48kHz) shouldn't turn it on either
	tb->wb_write(1, (ADC_CLOCKS_48KHZ) | ADC_DISABLE | ADC_HALFFIFO_INT);
	for(unsigned i=0; i<4000; i++) {
		tb->tick();
		TBASSERT(*tb, tb->m_core->o_csn == 1);
		TBASSERT(*tb, tb->m_core->o_sck == 1);
	}

#ifdef WBMIC
	// 3. Verify that the FIFO is empty
	TBASSERT(*tb, 0 == tb->m_core->o_int);
	// Verify that it hasn't started (yet)
	TBASSERT(*tb, ((ctrl=tb->wb_read(1)) & 0x0100000)==0);
	lglen = (ctrl>>24)&0x0ff;
	bflen = (1<<lglen);
#endif

	// 4. Setting the enable should get it started
#ifdef WBMIC
	tb->wb_write(1, ADC_CLOCKS_48KHZ | ADC_HALFFIFO_INT | ADC_ENABLE);
#else
	tb->wb_write(0,0);
#endif

#ifdef	WBMIC
	// 5. Wait for the FIFO to get to half full
	while(0 == tb->m_core->o_int)
		tb->tick();
#endif

	buf = new unsigned[(bflen)];
	// 6. Read a half-FIFO's worth from the FIFO
#define	ADC_DATFILL(A)	(A>>18)
#define	ADC_NONEMPTY	(1<<16)
#define	ADC_HALFFULL	(1<<17)
#ifdef	WBMIC
	tb->wb_read(0, bflen, buf, 0);
	for(unsigned i=1; i<bflen/2-1; i++) {
		TBASSERT(*tb, (buf[i] & ADC_NONEMPTY));
		TBASSERT(*tb, ((buf[i] & ADC_HALFFULL)==0));
	}
	for(unsigned i=bflen/2+1; i<bflen; i++) {
		TBASSERT(*tb, (ADC_DATFILL(buf[i])==0));
		TBASSERT(*tb, ((buf[i] & ADC_NONEMPTY)==0));
		TBASSERT(*tb, ((buf[i] & ADC_HALFFULL)==0));
	}
#else
	for(int i=0; i<bflen; i++) {
		while(!m_core->o_int)
			tb->tick();
		buf[i] = tb->read(0);
	}
#endif

	FILE	*fp;
	fp = fopen("outpt.txt", "w");
	for(unsigned i=0; i<bflen; i++) {
		fprintf(fp, "%d %d %d %d\n",
			(buf[i] >> 18),
			(buf[i] & ADC_HALFFULL) ? 1 : 0,
			(buf[i] & ADC_NONEMPTY) ? 1 : 0,
			(int)((short)buf[i]));
	} fclose(fp);

	delete	tb;

	// And declare success
	printf("SUCCESS!\n");
	exit(EXIT_SUCCESS);
}

