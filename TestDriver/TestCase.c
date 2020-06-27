/*
 * TestCase.c
 *
 * Created: 6/13/2020 10:20:01 AM
 *  Author: Tim
 */ 


#include <stdint.h>
#include <math.h>

int isqrt(int);


void DivI32empty(int num, int den)
{
}

int DivI32(int num, int den)
{
	return num / den;
}

void DivI64empty(int64_t num, int64_t den)
{
}

int64_t DivI64(int64_t num, int64_t den)
{
	return num / den;
}

uint64_t DivU64(uint64_t num, uint64_t den)
{
	return num / den;
}

void DivDblempty(double num, double den)
{
}

double DivDbl(double num, double den)
{
	return num / den;
}

void DivFltempty(float num, float den)
{
}

float DivFlt(float num, float den)
{
	return num / den;
}

void IsqrtEmpty(int val)
{
}

int Isqrt(int val)
{
	return isqrt(val);
}

void SqrtFltEmpty(float val)
{
}

float SqrtFlt(float val)
{
	return sqrtf(val);
}

void SqrtDblEmpty(double val)
{
}

double SqrtDbl(double val)
{
	return sqrt(val);
}
