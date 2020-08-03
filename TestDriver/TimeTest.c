/*
 * TimeTest.c
 *
 * Created: 8/3/2020 2:29:59 PM
 *  Author: Tim
 */ 

#include "stdio.h"
#include "TimeTest.h"
#include "TestCase.h"
#include "Timer.h"
#include <math.h>


//*********************************************************************
// Timed test case drivers
//*********************************************************************

void TimeTest()
{
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
}

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

//*********************************************************************

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

//*********************************************************************

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

//*********************************************************************

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

//*********************************************************************

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

//*********************************************************************

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

//*********************************************************************

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
