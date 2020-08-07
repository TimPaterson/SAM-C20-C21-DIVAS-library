/*
 * TestCase.h
 *
 * Created: 8/3/2020 2:38:04 PM
 *  Author: Tim
 */ 


#ifndef TESTCASE_H_
#define TESTCASE_H_


//*********************************************************************
// Test case declarations
//*********************************************************************

void DivI32empty(int num, int den);
int DivI32(int num, int den);
int DivU32(int num, int den);

void DivI64empty(int64_t num, int64_t den);
int64_t DivI64(int64_t num, int64_t den);
uint64_t DivU64(uint64_t num, uint64_t den);
uint64_t ModU64(uint64_t num, uint64_t den);

void DivDblempty(double num, double den);
double DivDbl(double num, double den);

void DivFltempty(float num, float den);
float DivFlt(float num, float den);

void SqrtFltEmpty(float val);
float SqrtFlt(float val);

void SqrtDblEmpty(double val);
double SqrtDbl(double val);


#endif /* TESTCASE_H_ */