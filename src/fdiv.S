
/*
 * fdiv.S
 *
 * Created: 6/22/2020 5:24:59 PM
 *  Author: Tim
 */ 
 

#include "macros.h"
#include "Ieee32.h"


	.global	__aeabi_fdiv

// 32-bit IEEE floating-point division
//
// Entry:
//	r0 = numerator
//	r1 = denominator
// Exit:
//	r0 = quotient

	.func	__aeabi_fdiv

__aeabi_fdiv:
	push	{r4, r5, r6, r7, lr}
	lsl	r3, r1, #1	// clear denominator sign
	lsr	r3, #MANT_BITS + 1	// denominator exponent

	lsl	r4, r0, #1	// clear numerator sign
	lsr	r4, #MANT_BITS + 1	// numerator exponent

	// compute final sign
	mov	r2, #1
	lsl	r2, #31		// sign position
	mov	r5, r1
	eor	r5, r0
	and	r5, r2
	mov	r12, r5		// Save sign

	// r0 = numerator
	// r1 = denominator
	// r2 = 0x80000000 (sign bit position)
	// r3 = denominator exponent
	// r4 = numerator exponent
	// r12 = final sign

	cmp	r3, #EXP_SPECIAL
	beq	DenSpclExp
	cmp	r4, #EXP_SPECIAL
	beq	NumSpclExp

	cmp	r3, #0
	beq	DenZeroExp
DenNormalized:
	cmp	r4, #0
	beq	NumZeroExp
NumNormalized:

	sub	r4, r3		// compute exponent

	// Set implied bit
	lsr	r2, #EXP_BITS	// move back to implied bit position
	orr	r0, r2
	orr	r1, r2

	// Normalize denominator and split into two 16-bit "digits"
	lsl	r5, r1, #(32 - (MANT_BITS + 1) + 16)
	lsr	r5, #16
	lsl	r6, r1, #(32 - (MANT_BITS + 1))
	eor	r6, r5		// clear low bits
	// mask numerator to mantissa, adding one rounding bit
	lsl	r0, #(32 - (MANT_BITS + 1))
	lsr	r0, #(32 - (MANT_BITS + 1)  - 1)	

	// r0 = numerator with 1 extra bit
	// r4 = result exponent, unbiased
	// r5 = low 16-bit denominator "digit"
	// r6 = high 16-bit denominator "digit"
	// r7 = reserved for quotient
	// r12 = sign of result

	// compute a 16-bit "digit"
	lsr	r1, r6, #16	// move digit to low half
	// Our version of this function preserves r12
	bl	__aeabi_uidivmod
	mov	r7, r0		// save 16-bit quotient digit

	// Check out our guess.
	// Currently, remainder = numerator - (quotient * high digit denominator).
	// The definition of remainder is numerator - (quotient * all denominator).
	// So if we subtract (quotient * low digit denominator), we'll get
	// the true remainder.  If it's negative, our guess was too big.
	//
	// prod = quoDig * denLo
	mul	r0, r5
	lsl	r1, #16		// normalize remainder
	// Subtract to calculate full remainder
	// Carry clear means negative remainder, quotient too large
	//
	// num -= prod;
	sub	r1, r0		// compute full remainder
	bcs	QuoGood1
	// Quotient digit was too big. Decrement and add a denominator back
	// Need to rebuild full 32-bit denominator from the two digits
	add	r2, r5, r6
ShrinkQuo1:
	// quoDig--;
	sub	r7, #1
	// num += den;
	add	r1, r2
	bcc	ShrinkQuo1
QuoGood1:
	// Repeat the process above to compute next 16-bit "digit"
	// But first check end conditions that can't happen the first time
	// if (num >= (den << 16))
	cmp	r1, r6
	bhs	MaxQuo
	// if (num < den)
	lsr	r3, r6, #16
	cmp	r1, r3
	blo	ZeroQuo

	// Compute 16-bit "digit" guess
	mov	r0, r1
	lsr	r1, r6, #16	// move digit to low half
	bl	__aeabi_uidivmod
	mov	r3, r0		// save 16-bit quotient digit
	// prod = quoDig * denLo
	mul	r0, r5
	lsl	r1, #16		// normalize remainder
	// rem -= prod;
	sub	r1, r0		// compute full remainder
	bcs	QuoGood2
	add	r2, r5, r6
ShrinkQuo2:
	// quoDig--;
	sub	r3, #1
AddBack:
	// rem += den;
	add	r1, r2
	bcc	ShrinkQuo2
QuoGood2:
	// Merge quotient digits
	lsl	r0, r7, #16
	orr	r0, r3

	// r0 = quotient
	// r1 = remainder (sticky bits)
	// r4 = exponent
	// r12 = final sign
	//
	// See if quotient carried into next bit
	lsl	r5, r0, #(32 - (MANT_BITS + 2 + 1))
	bpl	CheckSpecialRes
	// sticky |= quo != 0;
	lsl	r3, r0, #31	// mask to quotient LSB
	orr	r1, r3		// save in sticky bits
	// quo >>= 1;
	lsr	r0, #1
	// exp++;
	add	r4, #1
CheckSpecialRes:
	// r0 = result mantissa w/rounding bit
	// r1 = sticky bits
	// r4 = exponent
	// r12 = final sign
	//
	// exp += EXP_BIAS - 1
	add	r4, #(EXP_BIAS - 1)
	ble	DenormalResult
	// if (exp >= EXP_SPECIAL)
	cmp	r4, #EXP_SPECIAL
	bhs	InfinityResult
Round:
	// r0 = result mantissa w/rounding bit
	// r1 = sticky bits
	// r4 = exponent
	// r12 = final sign
	//
	cmp	r1, #0		// test sticky bits
	bne	1f		// non-zero remainder, round up
	lsl	r5, r0, #30	// test LSB for round even
	bpl	2f
1:
	add	r0, #1		// add to rounding bit
2:

	// Remove rounding bit
	// quo >>= 1;
	lsr	r0, #1

	// Zero implied bit
	// quo &= ~(1LL << MANT_BITS);
	lsl	r0, #EXP_BITS + 1
	lsr	r0, #EXP_BITS + 1
	// quo |= exp << MANT_BITS
	lsl	r4, #MANT_BITS
	orr	r0, r4
SetSign:
	// quo |= sgn;
	mov	r2, r12		// Get sign
	orr	r0, r2
	pop	{r4, r5, r6, r7, pc}

DenSpclExp:
	// r0 = numerator
	// r1 = denominator
	// r2 = 0x80000000 (sign bit position)
	// r3 = denominator exponent
	// r4 = numerator exponent
	// r12 = final sign
	//
	// mantissa == 0?
	lsl	r5, r1, #(EXP_BITS + 1)
	bne	ReturnDen	// denominator is NAN, return it
	// Denominator is Infinity
	// if (expNum == EXP_SPECIAL)
	cmp	r4, #EXP_SPECIAL
	bne	ZeroResult
	// Numerator is NAN or Infinity, return NAN
	lsl	r5, r0, #(EXP_BITS + 1)
	beq	ReturnNan	// Go get a NAN
	// Numerator is NAN, return it
	pop	{r4, r5, r6, r7, pc}

ReturnDen:
	mov	r0, r1
NumSpclExp:
	// r0 = numerator
	// r1 = denominator
	// r2 = 0x80000000 (sign bit position)
	// r3 = denominator exponent
	// r4 = numerator exponent
	// r12 = final sign
	bic	r0, r2		// clear existing sign
	// Return whatever numerator is, Infinity or NAN
	b	SetSign
	
DenZeroExp:
	// r0 = numerator
	// r1 = denominator
	// r2 = 0x80000000 (sign bit position)
	// r3 = denominator exponent
	// r4 = numerator exponent
	// r12 = final sign
	bic	r1, r2		// clear existing sign
	beq	DivByZero
	// Denominator is denormal, so normalize it

	// __clz_divas uses tailored calling convention
	// r5 = input to count leading zeros
	// r0 - r4 preserved
	// r6, r7 trashed
	mov	r5, r1		// pass denominator
	bl	__clz_divas	// Get leading zeros in denominator
	sub	r5, #EXP_BITS
	lsl	r1, r5
	mov	r3, #1
	sub	r3, r5
	b	DenNormalized

NumZeroExp:
	// r0 = numerator
	// r1 = denominator
	// r2 = 0x80000000 (sign bit position)
	// r3 = denominator exponent
	// r4 = numerator exponent
	// r12 = final sign
	bic	r0, r2		// clear existing sign
	beq	ZeroResult
	// numerator is denormal, so normalize it

	// __clz_divas uses tailored calling convention
	// r5 = input to count leading zeros
	// r0 - r4 preserved
	// r6, r7 trashed
	mov	r5, r0		// pass numerator
	bl	__clz_divas	// Get leading zeros in numerator
	sub	r5, #EXP_BITS
	lsl	r0, r5
	mov	r4, #1
	sub	r4, r5
	b	NumNormalized

DivByZero:
	bic	r0, r2		// check numerator by clearing its sign
	beq	ReturnNan	// 0 / 0, return NAN
InfinityResult:
	ldr	r0, Infinity
	b	SetSign

ReturnNan:
	ldr	r0, Nan
	b	SetSign

ZeroQuo:
	// Quotient is just first digit. Put in position, leaving
	// rounding bit
	lsl	r0, r7, #16
	// See if carried into next bit
	lsl	r5, r0, #(32 - (MANT_BITS + 2 + 1))
	bpl	CheckSpecialRes
	// quo >>= 1;
	lsr	r0, #1
	// exp++;
	add	r4, #1
	b	CheckSpecialRes

MaxQuo:
	// High 16 bits of numerator equal denominator, so result of
	// division would be quotient >= 0x10000. Actual quotient digit
	// can't be that big. Assume a result of 2^16-1, thus remainder =
	// numerator - ( denominator * (2^16-1) ) =
	// numerator - denominator * 2^16 + denominator.
	//
	// Need to rebuild full 32-bit denominator from the two digits
	add	r2, r5, r6
	// num -= den;
	sub	r1, r2
	// num <<= 16;
	lsl	r1, #16
	// quoDig = 0;
	ldr	r3, MaxQuoVal
	b	AddBack

DenormalResult:
	// r0 = result mantissa w/rounding bit
	// r1 = sticky bits
	// r4 = exponent
	// r12 = final sign
	mov	r2, #MANT_BITS
	add	r2, r4
	bmi	ZeroResult
	// Denormalize the result
	// First save the bits we're shifting off
	// sticky |= quo << (exp + 31)
	add	r4, #31
	mov	r2, r0
	lsl	r2, r4
	orr	r1, r2
	// quo >>= 32 - (exp + 31)
	sub	r4, #32
	neg	r4, r4
	lsr	r0, r4
	// exp = 0
	mov	r4, #0
	b	Round

ZeroResult:
	mov	r0, #0
	b	SetSign

	.align	2
MaxQuoVal:	.word	0xFFFF
Infinity:	.word	EXP_SPECIAL << MANT_BITS
// Quiet NAN has MSB of mantissa set
Nan:		.word	(EXP_SPECIAL << MANT_BITS) | (1 << (MANT_BITS - 1))

	.endfunc
