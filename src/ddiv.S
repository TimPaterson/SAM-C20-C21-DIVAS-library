
/*
 * ddiv.S
 *
 * Created: 6/21/2020 11:33:44 AM
 *  Author: Tim
 */ 

 
#include "macros.h"
#include "Ieee64.h"


	.global	__aeabi_ddiv

// 64-bit IEEE floating-point division
//
// Entry:
//	r1:r0 = numerator
//	r3:r2 = denominator
// Exit:
//	r1:r0 = quotient

	.func	__aeabi_ddiv

__aeabi_ddiv:
	push	{r4, r5, r6, r7, lr}
	lsl	r5, r3, #1	// clear denominator sign
	lsr	r5, #MANT_BITS_HI + 1	// denominator exponent

	lsl	r4, r1, #1	// clear numerator sign
	lsr	r4, #MANT_BITS_HI + 1	// numerator exponent

	// compute final sign
	mov	r7, #1
	lsl	r7, #31		// sign position
	mov	r6, r1
	eor	r6, r3
	and	r6, r7
	mov	r12, r6		// Save sign

	ldr	r6, ExpSpecial

	// r1:r0 = numerator
	// r3:r2 = denominator
	// r4 = numerator exponent
	// r5 = denominator exponent
	// r6 = EXP_SPECIAL
	// r7 = 0x80000000 (sign bit position)
	// r12 = final sign

	cmp	r5, r6
	beq	DenSpclExp
	cmp	r4, r6
	beq	NumSpclExp

	cmp	r5, #0
	beq	DenZeroExp
DenNormalized:
	cmp	r4, #0
	beq	NumZeroExp
NumNormalized:

	sub	r4, r5		// compute exponent

	// Set implied bit
	lsr	r7, #EXP_BITS	// move back to implied bit position
	orr	r1, r7
	orr	r3, r7

	// Normalize
	// den <<= 64 - (MANT_BITS + 1);
	lsl64const	r2, r3, (64 - (MANT_BITS + 1)), r5
	// mask numerator to mantissa
	lsl	r1, #(64 - (MANT_BITS + 1))
	lsr	r1, #(64 - (MANT_BITS + 1))	
	// add rounding & sticky bits
	// num <<= 2;
	lsl64const	r0, r1, 2

	// Call 64-bit divide helper
	push	{r4}		// save exponent
	mov	r4, #6		// compute 4 digits
	mov	r5, #0		// no extension

	// r1:r0 = num, scaled numerator
	// r3:r2 = den, normalized denominator
	// r4 = oDig, address offset of first quotient digit: 0,2,4, or 6
	// r5 = numExt, numerator extension
	bl	__div64_divas
	// r1:r0 = quotient
	// r3:r2 = scaled remainder
	// no other registers preserved

	pop	{r5}		// restore exponent
	orr	r2, r3		// remainder is sticky bit

	// See if carried into next bit
	lsl	r4, r1, #(64 - (MANT_BITS + 2 + 2))
	bpl	SetSticky
	// sticky |= quo & 1;
	mov	r3, #1
	and	r3, r0
	orr	r2, r3
	// quo >>= 1;
	lsr64const	r0, r1, 1, r4
	// exp++;
	add	r5, #1
SetSticky:
	// quo |= sticky != 0;
	sub	r4, r2, #1
	sbc	r2, r4
	orr	r0, r2
	// exp += EXP_BIAS - 1
	ldr	r4, ExpBiasM1
	add	r5, r4
	ble	DenormalResult
	// if (exp >= EXP_SPECIAL)
	lsl	r4, #1
	add	r4, #(EXP_SPECIAL - (EXP_BIAS - 1) * 2)
	cmp	r5, r4
	bhs	InfinityResult
Round:
	// r1:r0 = result mantissa w/rounding & sticky bits
	// r5 = exponent
	// r12 = final sign
	// To round even, test mantissa LSB and sticky bits at once
	// if (quo & 0b101)
	mov	r4, #5
	tst	r0, r4
	beq	1f
	// quo += 0b10;		// add to rounding bit
	mov	r3, #2
	mov	r4, #0
	add	r0, r3
	adc	r1, r4
1:
	// Remove round & sticky bits
	// quo >>= 2;
	lsr64const	r0, r1, 2, r4

	// Zero implied bit
	// quo &= ~(1LL << MANT_BITS);
	mov	r4, #1
	lsl	r4, #MANT_BITS_HI
	bic	r1, r4
	// quo |= exp << MANT_BITS
	lsl	r5, #MANT_BITS_HI
	orr	r1, r5
SetSign:
	// quo |= sgn;
	mov	r4, r12		// Get sign
	orr	r1, r4
	pop	{r4, r5, r6, r7, pc}

DenSpclExp:
	// r1:r0 = numerator
	// r3:r2 = denominator
	// r4 = numerator exponent
	// r5 = denominator exponent
	// r6 = EXP_SPECIAL
	// r7 = 0x80000000 (sign bit position)
	// r12 = final sign
	//
	// mantissa == 0?
	lsl	r5, r3, #(EXP_BITS + 1)
	orr	r5, r2
	bne	ReturnDen	// denominator is NAN, return it
	// Denominator is Infinity
	// if (expNum == EXP_SPECIAL)
	cmp	r4, r6
	bne	ZeroResult
	// Numerator is NAN or Infinity, return NAN
	lsl	r4, r1, #(EXP_BITS + 1)
	orr	r4, r0
	beq	ReturnNan	// Go get a NAN
	// Numerator is NAN, return it
	pop	{r4, r5, r6, r7, pc}

ReturnDen:
	mov	r0, r2
	mov	r1, r3
NumSpclExp:
	// r1:r0 = numerator
	// r3:r2 = denominator
	// r4 = numerator exponent
	// r5 = denominator exponent
	// r6 = EXP_SPECIAL
	// r7 = 0x80000000 (sign bit position)
	// r12 = final sign
	bic	r0, r2		// clear existing sign
	// Return whatever numerator is, Infinity or NAN
	b	SetSign

DenZeroExp:
	// r1:r0 = numerator
	// r3:r2 = denominator
	// r4 = numerator exponent
	// r5 = denominator exponent
	// r6 = EXP_SPECIAL
	// r7 = 0x80000000 (sign bit position)
	// r12 = final sign
	lsl	r6, r3, #1	// clear existing sign
	orr	r6, r2
	beq	DivByZero
	// Denominator is denormal, so normalize it

	// __clz_divas uses tailored calling convention
	// r5 = input to count leading zeros
	// r0 - r4 preserved
	// r6, r7 trashed
	mov	r5, r3		// pass denominator
	beq	SmallDen
	bl	__clz_divas	// Get leading zeros in denominator
	sub	r5, #EXP_BITS
	lsl64short	r2, r3, r5, r6
	// lsl64short leaves count at 32 - count; we need 1 - count
DenFinishNorm:
	sub	r5, #31
	// r7 must be restored to 0x80000000
	mov	r7, #1
	lsl	r7, #31
	b	DenNormalized

SmallDen:
	// den <<= 32
	mov	r3, r2
	mov	r2, #0
	mov	r5, r3
	bl	__clz_divas	// Get leading zeros in denominator
	sub	r5, #EXP_BITS
	bmi	DenRight
	lsl	r3, r5
DenFixExp:
	neg	r5, r5
	b	DenFinishNorm

DenRight:
	neg	r7, r5
	lsr64short	r2, r3, r7, r6
	b	DenFixExp

NumZeroExp:
	// r1:r0 = numerator
	// r3:r2 = denominator
	// r4 = numerator exponent
	// r5 = denominator exponent
	// r6 = EXP_SPECIAL
	// r7 = 0x80000000 (sign bit position)
	// r12 = final sign
	lsl	r6, r1, #1	// clear existing sign
	orr	r6, r0
	beq	ZeroResult
	mov	r4, r5		// must preserve denominator exponent
	// numerator is denormal, so normalize it

	// __clz_divas uses tailored calling convention
	// r5 = input to count leading zeros
	// r0 - r4 preserved
	// r6, r7 trashed
	mov	r5, r1		// pass numerator
	beq	SmallNum
	bl	__clz_divas	// Get leading zeros in numerator
	sub	r5, #EXP_BITS
	lsl64short	r0, r1, r5, r6
	// lsl64short leaves count at 32 - count; we need 1 - count
NumFinishNorm:
	sub	r5, #31
	// swap denominator exponent in r4 with numerator exponent in r5
	eor	r4, r5
	eor	r5, r4
	eor	r4, r5
	// r7 must be restored to 0x80000000
	mov	r7, #1
	lsl	r7, #31
	b	NumNormalized

SmallNum:
	// num <<= 32
	mov	r1, r0
	mov	r0, #0
	mov	r5, r1
	bl	__clz_divas	// Get leading zeros in denominator
	sub	r5, #EXP_BITS
	bmi	NumRight
	lsl	r1, r5
NumFixExp:
	neg	r5, r5
	b	NumFinishNorm

NumRight:
	neg	r7, r5
	lsr64short	r0, r1, r7, r6
	b	NumFixExp

DivByZero:
	lsl	r6, r1, #1	// clear existing sign
	orr	r6, r0
	beq	ReturnNan	// 0 / 0, return NAN
InfinityResult:
	ldr	r1, Infinity
	b	LowZero

ReturnNan:
	ldr	r1, Nan
	b	LowZero

DenormalResult:
	// r1:r0 = result mantissa w/rounding & sticky bits
	// r5 = exponent
	// r12 = final sign
	mov	r2, #MANT_BITS
	add	r2, r5
	bmi	ZeroResult
	// Denormalize the result
	// First save the bits we're shifting off
	// sticky = quo << (exp + 63)
	mov	r4, #0		// extended sticky bits
	add	r5, #31
	bpl	BigDenormal
	// quo >>= 32
	mov	r4, r0
	mov	r0, r1
	mov	r1, #0
	add	r5, #32
BigDenormal:
	mov	r2, r0
	lsl	r2, r5		// Bits we're discarding
	mov	r3, r1
	lsl	r3, r5		// Upper bits for low half
	// quo >>= 32 - (exp + 31)
	sub	r5, #32
	neg	r5, r5
	lsr	r0, r5
	lsr	r1, r5
	orr	r0, r3
	// quo |= sticky != 0;
	orr	r2, r4		// combine sticky bits
	sub	r6, r2, #1
	sbc	r2, r6
	orr	r0, r2
	// exp = 0
	mov	r5, #0
	b	Round

ZeroResult:
	mov	r1, #0
LowZero:
	mov	r0, #0
	b	SetSign

	.align	2
ExpSpecial:	.word	EXP_SPECIAL
ExpBiasM1:	.word	EXP_BIAS - 1
Infinity:	.word	EXP_SPECIAL << MANT_BITS_HI
// Quiet NAN has MSB of mantissa set
Nan:		.word	(EXP_SPECIAL << MANT_BITS_HI) | (1 << (MANT_BITS_HI - 1))

	.endfunc
