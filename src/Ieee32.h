/*
 * Ieee32.h
 *
 * Created: 6/22/2020 5:23:27 PM
 *  Author: Tim
 */ 


#ifndef IEEE32_H_
#define IEEE32_H_


// IEEE single
#define MANT_BITS		23
#define EXP_BITS		8
#define EXP_BIAS		((1 << (EXP_BITS - 1)) - 1)
#define EXP_MIN			(-EXP_BIAS + 1)
#define EXP_SPECIAL		((1 << EXP_BITS) - 1)
#define SIGN_BIT		(1LL << 31)


#endif /* IEEE32_H_ */