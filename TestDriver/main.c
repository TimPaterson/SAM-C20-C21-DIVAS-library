/*
 * TestDriver.c
 *
 * Created: 6/12/2020 5:52:05 PM
 * Author : Tim
 */


#include "sam.h"
#include "sam_spec.h"
#include "stdio.h"
#include <math.h>


// Set up clock speed, baud rate
#define F_CPU		48000000
#define BAUD_RATE	500000

//*********************************************************************
// Test case declarations
//*********************************************************************

void DivI32empty(int num, int den);
int DivI32(int num, int den);
int DivU32(int num, int den);

void DivI64empty(int64_t num, int64_t den);
int64_t DivI64(int64_t num, int64_t den);
uint64_t DivU64(uint64_t num, uint64_t den);

void DivDblempty(double num, double den);
double DivDbl(double num, double den);

void DivFltempty(float num, float den);
float DivFlt(float num, float den);

void IsqrtEmpty(int val);
int Isqrt(int val);

void SqrtFltEmpty(float val);
float SqrtFlt(float val);

void SqrtDblEmpty(double val);
double SqrtDbl(double val);

//*********************************************************************
// Initialization Helpers
//*********************************************************************

enum RxPad
{
	RXPAD_Pad0,
	RXPAD_Pad1,
	RXPAD_Pad2,
	RXPAD_Pad3
};

enum TxPad
{
	TXPAD_Pad0,
	TXPAD_Pad2,
	TXPAD_Pad0_RTS_Pad2_CTS_Pad3,
	TXPAD_Pad0_TE_Pad2
};

//*********************************************************************

void StartClock()
{
	// Two wait states needed for 48MHz operation
	NVMCTRL->CTRLB.reg = NVMCTRL_CTRLB_RWS(2) | NVMCTRL_CTRLB_MANW;

	// Initialize 48MHz clock
	OSCCTRL->CAL48M.reg = NVM_SOFTWARE_CAL->CAL48M_3V3;
	OSCCTRL->OSC48MDIV.reg = 0;		// Bump it to 48 MHz
}

//*********************************************************************

uint16_t CalcBaudRate(uint32_t rate, uint32_t clock)
{
	uint32_t	quo;
	uint32_t	quoBit;

	rate *= 16;		// actual clock frequency
	// Need 17-bit result of rate / clock
	for (quo = 0, quoBit = 1 << 16; quoBit != 0; quoBit >>= 1)
	{
		if (rate >= clock)
		{
			rate -= clock;
			quo |= quoBit;
		}
		rate <<= 1;
	}
	// Round
	if (rate >= clock)
		quo++;
	return (uint16_t)-quo;
}

//*********************************************************************

void Init()
{
	// Set up serial port

	SERCOM_USART_CTRLA_Type	serCtrlA;

	// Enable clock
	MCLK->APBCMASK.reg |= MCLK_APBCMASK_SERCOM3;

	// Clock it with GCLK0
	GCLK->PCHCTRL[SERCOM3_GCLK_ID_CORE].reg = GCLK_PCHCTRL_GEN_GCLK0 |
		GCLK_PCHCTRL_CHEN;

	PORT->Group[0].WRCONFIG.reg =
			PORT_WRCONFIG_WRPMUX |
			PORT_WRCONFIG_PMUX(MUX_PA24C_SERCOM3_PAD2) |
			PORT_WRCONFIG_INEN |
			PORT_WRCONFIG_PMUXEN |
			PORT_WRCONFIG_WRPINCFG |
			PORT_WRCONFIG_HWSEL |
			PORT_WRCONFIG_PINMASK((PORT_PA24 | PORT_PA25) >> 16);

	SERCOM3->USART.BAUD.reg = CalcBaudRate(BAUD_RATE, F_CPU);

	// standard 8,N,1 parameters
	serCtrlA.reg = 0;
	serCtrlA.bit.DORD = 1;		// LSB first
	serCtrlA.bit.MODE = 1;		// internal clock
	serCtrlA.bit.RXPO = RXPAD_Pad3;
	serCtrlA.bit.TXPO = TXPAD_Pad2;
	serCtrlA.bit.ENABLE = 1;
	SERCOM3->USART.CTRLA.reg = serCtrlA.reg;
	SERCOM3->USART.CTRLB.reg = SERCOM_USART_CTRLB_TXEN | SERCOM_USART_CTRLB_RXEN;

	// Set up counter to time execution

	MCLK->APBCMASK.reg |= MCLK_APBCMASK_TC0;
	GCLK->PCHCTRL[TC0_GCLK_ID].reg = GCLK_PCHCTRL_GEN_GCLK0 | GCLK_PCHCTRL_CHEN;
	TC0->COUNT16.CTRLA.reg = TC_CTRLA_ENABLE;
	TC0->COUNT16.CTRLBSET.reg = TC_CTRLBSET_CMD_STOP;
}

//****************************************************************************
// Timer
//****************************************************************************

inline void StartTimer()
{
	while (TC0->COUNT16.SYNCBUSY.reg);
	TC0->COUNT16.CTRLBSET.reg = TC_CTRLBSET_CMD_RETRIGGER;
}

inline uint16_t GetTime()
{
	int		res;

	TC0->COUNT16.CTRLBSET.reg = TC_CTRLBSET_CMD_READSYNC;
	while (TC0->COUNT16.SYNCBUSY.reg);
	res = TC0->COUNT16.COUNT.reg;
	TC0->COUNT16.CTRLBSET.reg = TC_CTRLBSET_CMD_STOP;
	return res;
}

//*********************************************************************
// Device File I/O
//*********************************************************************

void WriteByte(void *pv, char c)
{
	while (!SERCOM3->USART.INTFLAG.bit.DRE);
	SERCOM3->USART.DATA.reg = c;
}

int ReadByte(void *pv)
{
	while (!SERCOM3->USART.INTFLAG.bit.RXC);
	return SERCOM3->USART.DATA.reg;
}

FILE SercomIo = FDEV_SETUP_STREAM(WriteByte, ReadByte, _FDEV_SETUP_RW | _FDEV_SETUP_CRLF);

FDEV_STANDARD_STREAMS(&SercomIo, &SercomIo);	// stdout, stdin

//*********************************************************************
// Timed test case drivers
//*********************************************************************

int TimeTestFp64(double num, double den)
{
	int		t1, t2;
	double	res;

	DivDblempty(num, den);
	StartTimer();
	DivDblempty(num, den);
	t1 = GetTime();

	res = DivDbl(num, den);
	StartTimer();
	DivDbl(num, den);
	t2 = GetTime();

	printf("Divide Dbl: %g, Time: %i\n", res, t2 - t1);
	return t2 - t1;
}

int TimeTestFp32(float num, float den)
{
	int		t1, t2;
	float	res;

	DivFltempty(num, den);
	StartTimer();
	DivFltempty(num, den);
	t1 = GetTime();

	res = DivFlt(num, den);
	StartTimer();
	DivFlt(num, den);
	t2 = GetTime();

	printf("Divide Flt: %g, Time: %i\n", res, t2 - t1);
	return t2 - t1;
}

int TimeTestI64(int64_t num, int64_t den)
{
	int		t1, t2;
	int64_t	res;

	DivI64empty(num, den);
	StartTimer();
	DivI64empty(num, den);
	t1 = GetTime();

	res = DivI64(num, den);
	StartTimer();
	DivI64(num, den);
	t2 = GetTime();

	printf("Divide Int64: %lli, Rem: %lli, Time: %i\n", res, num % den, t2 - t1);
	return t2 - t1;
}

int TimeTestU64(uint64_t num, uint64_t den)
{
	int		t1, t2;
	uint64_t	res;

	DivI64empty(num, den);
	StartTimer();
	DivI64empty(num, den);
	t1 = GetTime();

	res = DivU64(num, den);
	StartTimer();
	DivU64(num, den);
	t2 = GetTime();

	printf("Divide Uint64: %llu, Rem: %llu, Time: %i\n", res, num % den, t2 - t1);
	return t2 - t1;
}

int TimeTestI32(int num, int den)
{
	int		t1, t2, res;

	DivI32empty(num, den);
	StartTimer();
	DivI32empty(num, den);
	t1 = GetTime();

	res = DivI32(num, den);
	StartTimer();
	DivI32(num, den);
	t2 = GetTime();

	printf("Divide Int32: %i, %i\n", res, t2 - t1);
	return t2 - t1;
}

int TimeTestSqrt32(float val)
{
	int		t1, t2;
	float	res;

	SqrtFltEmpty(val);
	StartTimer();
	SqrtFltEmpty(val);
	t1 = GetTime();

	res = SqrtFlt(val);
	StartTimer();
	SqrtFlt(val);
	t2 = GetTime();

	printf("Root float: %.9g, %i\n", res, t2 - t1);
	return t2 - t1;
}

int TimeTestSqrt64(double val)
{
	int		t1, t2;
	double	res;

	SqrtDblEmpty(val);
	StartTimer();
	SqrtDblEmpty(val);
	t1 = GetTime();

	res = SqrtDbl(val);
	StartTimer();
	SqrtDbl(val);
	t2 = GetTime();

	printf("Root double: %.18g, %i\n", res, t2 - t1);
	return t2 - t1;
}

//*********************************************************************
// Validity test case drivers
//*********************************************************************

void DivFltTest()
{
	float	inf, ninf, nan;
	float	TwoTo120, flt;

	printf("\nFp32 division tests\n");

	inf = DivFlt(1, 0);
	ninf = DivFlt(-1, 0);
	nan = DivFlt(0, 0);

	printf("Infinity: %g, -Infinity: %g, NAN: %g\n", inf, ninf, nan);

	printf("   0/inf:  %4g, ", DivFlt(0, inf));
	printf("   1/inf:  %4g, ", DivFlt(1, inf));
	printf(" inf/0:    %4g, ", DivFlt(inf, 0));
	printf(" inf/1:    %4g\n", DivFlt(inf, 1));
					   
	printf("   0/nan:  %4g, ", DivFlt(0, nan));
	printf("   1/nan:  %4g, ", DivFlt(1, nan));
	printf(" nan/0:    %4g, ", DivFlt(nan, 0));
	printf(" nan/1:    %4g\n", DivFlt(nan, 1));

	printf(" inf/nan:  %4g, ", DivFlt(inf, nan));
	printf(" inf/inf:  %4g, ", DivFlt(inf, inf));
	printf(" nan/nan:  %4g, ", DivFlt(nan, nan));
	printf(" nan/inf:  %4g\n", DivFlt(nan, inf));

	printf("   0/ninf: %4g, ", DivFlt(0, ninf));
	printf("   1/ninf: %4g, ", DivFlt(1, ninf));
	printf("ninf/0:    %4g, ", DivFlt(ninf, 0));
	printf("ninf/1:    %4g\n", DivFlt(ninf, 1));

	printf("ninf/inf:  %4g, ", DivFlt(ninf, inf));
	printf(" inf/ninf: %4g, ", DivFlt(inf, ninf));
	printf("ninf/ninf: %4g\n", DivFlt(ninf, ninf));

	// Denormal testing
	TwoTo120 = 32768;		// 2^15
	TwoTo120 *= TwoTo120;	// 2^30
	TwoTo120 *= TwoTo120;	// 2^60
	TwoTo120 *= TwoTo120;	// 2^120

	flt = DivFlt(1.1, TwoTo120);
	flt = DivFlt(flt, 64);	// 2^-126
	printf("0: %g\n", flt);
	printf("1: %g\n", DivFlt(flt, 2));
	printf("2: %g\n", DivFlt(flt, 4));
	flt = DivFlt(flt, 16);	// slightly denormalized
	printf("A: %g\n", DivFlt(flt, M_PI));
	printf("B: %g\n", DivFlt(M_PI / 64, flt));
	flt = DivFlt(flt, 65536 * 2);	// 2^-147
	printf("C: %g\n", DivFlt(flt, M_PI / 4));
	printf("D: %g\n", DivFlt(M_PI / 4096 / 4096, flt));
	printf("21: %g\n", flt);
	printf("22: %g\n", DivFlt(flt, 2));
	printf("23: %g\n", DivFlt(flt, 4));
	printf("24: %g\n", DivFlt(flt, 8));
	printf("25: %g\n", DivFlt(flt, 16));
}

void DivDblTest()
{
	double	inf, ninf, nan;
	double	TwoTo1022, TwoTo60, TwoToM60, dbl;

	printf("\nFp64 division tests\n");

	inf = DivDbl(1, 0);
	ninf = DivDbl(-1, 0);
	nan = DivDbl(0, 0);

	printf("Infinity: %g, -Infinity: %g, NAN: %g\n", inf, ninf, nan);

	printf("   0/inf:  %4g, ", DivDbl(0, inf));
	printf("   1/inf:  %4g, ", DivDbl(1, inf));
	printf(" inf/0:    %4g, ", DivDbl(inf, 0));
	printf(" inf/1:    %4g\n", DivDbl(inf, 1));
	
	printf("   0/nan:  %4g, ", DivDbl(0, nan));
	printf("   1/nan:  %4g, ", DivDbl(1, nan));
	printf(" nan/0:    %4g, ", DivDbl(nan, 0));
	printf(" nan/1:    %4g\n", DivDbl(nan, 1));

	printf(" inf/nan:  %4g, ", DivDbl(inf, nan));
	printf(" inf/inf:  %4g, ", DivDbl(inf, inf));
	printf(" nan/nan:  %4g, ", DivDbl(nan, nan));
	printf(" nan/inf:  %4g\n", DivDbl(nan, inf));

	printf("   0/ninf: %4g, ", DivDbl(0, ninf));
	printf("   1/ninf: %4g, ", DivDbl(1, ninf));
	printf("ninf/0:    %4g, ", DivDbl(ninf, 0));
	printf("ninf/1:    %4g\n", DivDbl(ninf, 1));

	printf("ninf/inf:  %4g, ", DivDbl(ninf, inf));
	printf(" inf/ninf: %4g, ", DivDbl(inf, ninf));
	printf("ninf/ninf: %4g\n", DivDbl(ninf, ninf));

	// Denormal testing
	TwoTo60 = 32768;		// 2^15
	TwoTo60 *= TwoTo60;		// 2^30
	TwoTo60 *= TwoTo60;		// 2^60
	TwoTo1022 = TwoTo60;
	TwoTo1022 *= TwoTo1022;	// 2^120
	TwoTo1022 *= TwoTo1022;	// 2^240
	TwoTo1022 *= TwoTo1022;	// 2^480
	TwoTo1022 *= TwoTo1022;	// 2^960
	TwoTo1022 *= TwoTo60;	// 2^1020
	TwoTo1022 *= 4;			// 2^1022

	// Denormal inputs
	TwoToM60 = DivDbl(1, TwoTo60);
	dbl = DivDbl(M_PI / 4096, TwoTo1022);
	printf("Big denormal: val = %.18g, %.18g, %.18g\n", dbl, DivDbl(dbl, TwoToM60), DivDbl(TwoToM60, dbl));
	dbl = DivDbl(dbl, 65536);
	printf("Medium denormal: val = %.18g, %.18g, %.18g\n", dbl, DivDbl(dbl, TwoToM60), DivDbl(TwoToM60, dbl));
	dbl = DivDbl(dbl, 1024);
	printf("Small denormal: val = %.18g, %.18g, %.18g\n", dbl, DivDbl(dbl, TwoToM60), DivDbl(TwoToM60, dbl));

	// Denormal results
	dbl = DivDbl(1.1, TwoTo1022);
	printf("0: %g\n", dbl);
	printf("1: %g\n", DivDbl(dbl, 2));
	printf("2: %g\n", DivDbl(dbl, 4));
	dbl = DivDbl(dbl, 16);	// slightly denormalized
	dbl = DivDbl(dbl, TwoTo60 / 16384);	// 2^-1072
	printf("50: %g\n", dbl);
	printf("51: %g\n", DivDbl(dbl, 2));
	printf("52: %g\n", DivDbl(dbl, 4));
	printf("53: %g\n", DivDbl(dbl, 8));
	printf("54: %g\n", DivDbl(dbl, 16));
}

void SqrtFltTest()
{
	float	inf, ninf, nan;
	float	TwoTo120, flt;

	printf("\nFp32 square root tests\n");

	inf = DivFlt(1, 0);
	ninf = DivFlt(-1, 0);
	nan = DivFlt(0, 0);

	printf("sqrt(inf) = %g\n", SqrtFlt(inf));
	printf("sqrt(ninf) = %g\n", SqrtFlt(ninf));
	printf("sqrt(nan) = %g\n", SqrtFlt(nan));
	printf("sqrt(-2) = %g\n", SqrtFlt(-2));
	printf("2: %.8f\n", SqrtFlt(2));
	printf("4: %.8f\n", SqrtFlt(4));
	printf("8: %.8f\n", SqrtFlt(8));
	printf("big: %.9g\n", SqrtFlt(M_PI * 1E20));

	// Denormal testing
	TwoTo120 = 32768;		// 2^15
	TwoTo120 *= TwoTo120;	// 2^30
	TwoTo120 *= TwoTo120;	// 2^60
	TwoTo120 *= TwoTo120;	// 2^120

	flt = DivFlt(M_PI / 4096, TwoTo120);
	printf("denormal: val = %.9g, root = %.9g\n", flt, SqrtFlt(flt));
}

void SqrtDblTest()
{
	double	inf, ninf, nan;
	double	TwoTo1022, TwoTo60, dbl;

	printf("\nFp64 square root tests\n");

	inf = DivDbl(1, 0);
	ninf = DivDbl(-1, 0);
	nan = DivDbl(0, 0);

	printf("sqrt(inf) = %g\n", SqrtDbl(inf));
	printf("sqrt(ninf) = %g\n", SqrtDbl(ninf));
	printf("sqrt(nan) = %g\n", SqrtDbl(nan));
	printf("sqrt(-2) = %g\n", SqrtDbl(-2));
	printf("2: %.18f\n", SqrtDbl(2));
	printf("4: %.18f\n", SqrtDbl(4));
	printf("8: %.18f\n", SqrtDbl(8));
	printf("big: %.18g\n", SqrtDbl(M_PI * 1E20));

	// Denormal testing
	TwoTo60 = 32768;		// 2^15
	TwoTo60 *= TwoTo60;		// 2^30
	TwoTo60 *= TwoTo60;		// 2^60
	TwoTo1022 = TwoTo60;
	TwoTo1022 *= TwoTo1022;	// 2^120
	TwoTo1022 *= TwoTo1022;	// 2^240
	TwoTo1022 *= TwoTo1022;	// 2^480
	TwoTo1022 *= TwoTo1022;	// 2^960
	TwoTo1022 *= TwoTo60;	// 2^1020
	TwoTo1022 *= 4;			// 2^1022

	dbl = DivDbl(M_PI / 4096, TwoTo1022);
	printf("Big denormal: val = %.18g, %.18g\n", dbl, SqrtDbl(dbl));
	dbl = DivDbl(dbl, 65536);
	printf("Medium denormal: val = %.18g, %.18g\n", dbl, SqrtDbl(dbl));
	dbl = DivDbl(dbl, 1024);
	printf("Small denormal: val = %.18g, %.18g\n", dbl, SqrtDbl(dbl));
}

//*********************************************************************
// Main program
//*********************************************************************

int main(void)
{
    StartClock();
    Init();

	printf("\nStarting up\n");
    while (1)
    {
	/*
		// for size comparison
		// enable desired functions
		SqrtFlt(1);
		SqrtDbl(1);
		DivDbl(1,2);
		DivFlt(1,2);
		DivI32(1,2);
		DivU32(1,2);
		DivU64(1,2);
		DivI64(1,2);
	*/
		DivDblTest();
		DivFltTest();
		SqrtFltTest();
		SqrtDblTest();

		printf("\nTest timing\n");
		TimeTestFp32(0.8, 0.1);
		TimeTestFp32(5, 0.1);
		TimeTestFp32(10.2, 0.251);

		TimeTestSqrt64(M_PI);

		TimeTestSqrt32(M_PI);
		TimeTestSqrt32(4);
		TimeTestSqrt32(M_PI * 1E20);

		TimeTestFp64(0.8, 0.1);
		TimeTestFp64(5, 0.1);
		TimeTestFp64(10.2, 0.251);

		TimeTestI32(0x7f7f7f7f, 0x7f7f7f);

		TimeTestI64(0x1000080000000, 0x80008000);
		int64_t den = 5000000000;
		int64_t num = den * 2 - 1;
		TimeTestI64(-num, den);
		TimeTestI64(-num, -den);
		TimeTestI64(num, -den);
		TimeTestI64(num, den);
		TimeTestI64(0x7f7f7f7f7f7f7f7f, 2);
		TimeTestI64(0x7f7f7f7f, 0x7f7f7f);
		TimeTestI64(2, 1);

		TimeTestU64(num, den);
		TimeTestU64(0x7f7f7f7f7f7f7f7f, 2);
		TimeTestU64(0x7f7f7f7f, 0x7f7f7f);
		TimeTestU64(2, 1);

		ReadByte(NULL);		// wait for input
    }
}
