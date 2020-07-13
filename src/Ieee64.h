/*
 * Ieee64.h
 *
 * Created: 6/22/2020 5:22:39 PM
 *  Author: Tim
 */ 


// IEEE double
.set	MANT_BITS,		52
.set	MANT_BITS_HI,	(MANT_BITS - 32)
.set	EXP_BITS,		11
.set	EXP_BIAS,		((1 << (EXP_BITS - 1)) - 1)
.set	EXP_MIN,		(-EXP_BIAS + 1)
.set	EXP_SPECIAL,	((1 << EXP_BITS) - 1)

// Special values (high word)
.set	INFINITY,		EXP_SPECIAL << MANT_BITS_HI
// Quiet NAN has MSB of mantissa set
.set	NAN,			INFINITY | (1 << (MANT_BITS_HI - 1))
