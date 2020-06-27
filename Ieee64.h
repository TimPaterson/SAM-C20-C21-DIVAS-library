/*
 * Ieee64.h
 *
 * Created: 6/22/2020 5:22:39 PM
 *  Author: Tim
 */ 


#ifndef IEEE64_H_
#define IEEE64_H_


// IEEE double
#define MANT_BITS		52
#define MANT_BITS_HI	(MANT_BITS - 32)
#define EXP_BITS		11
#define EXP_BIAS		((1 << (EXP_BITS - 1)) - 1)
#define EXP_MIN			(-EXP_BIAS + 1)
#define EXP_SPECIAL		((1 << EXP_BITS) - 1)
#define SIGN_BIT		(1LL << 63)


#endif /* IEEE64_H_ */