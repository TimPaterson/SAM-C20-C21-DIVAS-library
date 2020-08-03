/*
 * TimeTest.h
 *
 * Created: 8/3/2020 2:31:15 PM
 *  Author: Tim
 */ 


#ifndef TIMETEST_H_
#define TIMETEST_H_


void TimeTest();
int TimeTestFp64(double num, double den);
int TimeTestFp32(float num, float den);
int TimeTestI64(int64_t num, int64_t den);
int TimeTestU64(uint64_t num, uint64_t den);
int TimeTestI32(int num, int den);
int TimeTestSqrt32(float val);
int TimeTestSqrt64(double val);


#endif /* TIMETEST_H_ */