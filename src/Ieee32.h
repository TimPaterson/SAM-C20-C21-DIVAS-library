/*
 * Ieee32.h
 *
 * Created: 6/22/2020 5:23:27 PM
 *  Author: Tim
 */ 


// IEEE single
// Bit fields
.set	MANT_BITS,		23
.set	EXP_BITS,		8
.set	EXP_BIAS,		((1 << (EXP_BITS - 1)) - 1)
.set	EXP_MIN,		(-EXP_BIAS + 1)
.set	EXP_SPECIAL,	((1 << EXP_BITS) - 1)
.set	SIGN_BIT,		(1LL << 31)

// Special values
.set	INFINITY,		EXP_SPECIAL << MANT_BITS
// Quiet NAN has MSB of mantissa set
.set	NAN,			INFINITY | (1 << (MANT_BITS - 1))
