/*
 * FunctionTest.c
 *
 * Created: 8/3/2020 2:39:14 PM
 *  Author: Tim
 */ 

#include "stdio.h"
#include "FunctionTest.h"
#include "TestCase.h"
#include <math.h>


//*********************************************************************
// Validity test case drivers
//*********************************************************************

void FunctionTest()
{
	DivDblTest();
	DivFltTest();
	SqrtFltTest();
	SqrtDblTest();
}

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

	// IEEE rounding test. Denormals used for ease
	// in creating bit patterns in LSBs.
	float scale = 1024 * 1024 * 1024.0f;
	printf("Rounding inexact\n");
	for (int i = 1; i < 8; i++)
	{
		flt = (i + 0.1f) / scale;
		flt = DivFlt(DivFlt(flt, TwoTo120 * 2), 1 / TwoTo120);
		printf("%g, ", flt * scale);
	}
	printf("\nRounding exact\n");
	for (int i = 1; i < 8; i++)
	{
		flt = i / scale;
		flt = DivFlt(DivFlt(flt, TwoTo120 * 2), 1 / TwoTo120);
		printf("%g, ", flt * scale);
	}
	float one = 0xFFFFFF / (1024 * 1024 * 16.0f);	// 1 LSB less than 1
	printf("\nNear one: %.8f\n", one);
	printf("Rounding inexact full denominator\n");
	for (int i = 1; i < 8; i++)
	{
		flt = (i + 0.1f) / scale;
		flt = DivFlt(DivFlt(flt, TwoTo120 * 2 * one), 1 / TwoTo120);
		printf("%g, ", flt * scale);
	}
	printf("\nRounding full denominator\n");
	for (int i = 1; i < 8; i++)
	{
		flt = i / scale;
		flt = DivFlt(DivFlt(flt, TwoTo120 * 2 * one), 1 / TwoTo120);
		printf("%g, ", flt * scale);
	}
	printf("\n");
}

//*********************************************************************

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

	// IEEE rounding test. Denormals used for ease
	// in creating bit patterns in LSBs.
	double scale = 1024.0 * 1024 * 1024 * 1024 * 1024 * 8;
	printf("Rounding inexact\n");
	for (int i = 1; i < 8; i++)
	{
		dbl = (i + 0.1) / scale;
		dbl = DivDbl(DivDbl(dbl, TwoTo1022 * 2), 1 / TwoTo1022);
		printf("%g, ", dbl * scale);
	}
	printf("\nRounding exact\n");
	for (int i = 1; i < 8; i++)
	{
		dbl = i / scale;
		dbl = DivDbl(DivDbl(dbl, TwoTo1022 * 2), 1 / TwoTo1022);
		printf("%g, ", dbl * scale);
	}
	double one = 0x1FFFFFFFFFFFFFLL / scale;	// 1 LSB less than 1
	printf("\nNear one: %.18f\n", one);
	printf("Rounding inexact full denominator\n");
	for (int i = 1; i < 8; i++)
	{
		dbl = (i + 0.1) / scale;
		dbl = DivDbl(DivDbl(dbl, TwoTo1022 * 2 * one), 1 / TwoTo1022);
		printf("%g, ", dbl * scale);
	}
	printf("\nRounding full denominator\n");
	for (int i = 1; i < 8; i++)
	{
		dbl = i / scale;
		dbl = DivDbl(DivDbl(dbl, TwoTo1022 * 2 * one), 1 / TwoTo1022);
		printf("%g, ", dbl * scale);
	}
	printf("\n");
}

//*********************************************************************

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

//*********************************************************************

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
