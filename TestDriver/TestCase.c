/*
 * TestCase.c
 *
 * Created: 6/13/2020 10:20:01 AM
 *  Author: Tim
 */ 


#include <stdint.h>
#include <math.h>


void DivI32empty(int num, int den)
{
}

int DivI32(int num, int den)
{
	return num / den;
}

uint32_t DivU32(uint32_t num, uint32_t den)
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

uint64_t ModU64(uint64_t num, uint64_t den)
{
	return num % den;
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
