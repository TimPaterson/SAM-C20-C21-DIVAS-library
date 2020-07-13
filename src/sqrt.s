
/*
 * sqrt.s
 *
 * Created: 6/26/2020 3:03:11 PM
 *  Author: Tim
 */ 
 

.include "macros.h"
.include "Ieee64.h"
.include "divas_asm.h"


	.global	sqrt


// 32-bit IEEE floating-point square root
//
// Entry:
//	r1:r0 = input
// Exit:
//	r1:r0 = root

	.func	sqrt

	.thumb_func
sqrt:
	push	{r4, r5, r6, lr}
	lsl	r2, r1, #1		// clear input sign
	lsr	r4, r2, #MANT_BITS_HI + 1	// input exponent
	beq	Denormal
	ldr	r3, =#EXP_SPECIAL
	cmp	r4, r3
	beq	SpclExp
	cmp	r1, #0
	bmi	ReturnNan		// must not be negative
Normalized:

	// Set implied bit
	mov	r2, #1
	lsl	r2, #MANT_BITS_HI
	orr	r1, r2

	// Normalize so that MSB is in bit 30 or 31, depending
	// on whether exponent is even or odd, respectively.
	lsr	r3, r0, #(32 - (EXP_BITS - 1))
	lsl	r2, r1, #EXP_BITS		// over shift to zero MSB
	lsl	r1, r0, #EXP_BITS - 1
	lsr	r2, #1			// back to bit 30
	orr	r2, r3		// r2:r1 = input
	// Result exponent is current exponent / 2
	// Take out exponent bias since it's odd
	ldr	r3, =#EXP_BIAS
	sub	r4, r3
	// exp >>= 1
	asr	r4, #1
	bcc	1f		// was it even?
	add	r1, r1		// if not, shift left on bit
	adc	r2, r2
1:
	add	r4, r3

	// Use hardware accelerator to compute first 16 bits of square root
	mov	r3, #(DIVAS >> 24)
	lsl	r3, #24		// address of DIVAS module
	mrs	r6, PRIMASK	// Save state of interrupt flag
	cpsid	i		// Disable interrupts
	str	r2, [r3, #REG_DIVAS_SQRNUM]
	// Bus will stall until ready, no need to wait
	ldr	r0, [r3, #REG_DIVAS_RESULT]
	ldr	r5, [r3, #REG_DIVAS_REM]
	msr	PRIMASK, r6	// restore interrupt flag

// Compute square root bit-by-bit.  For each bit, remainder/input will
// be shifted left 2 bits, root will be shifted left 1 bit, and trial
// bit will hold position.
	lsl	r0, #1		// current root * 2
	mov	r3, #14		// compute 14 more bits
Root32:
	// r0 = root * 2
	// r1 = input
	// r3 = bit count down
	// r4 = exponent
	// r5 = remainder

	// Set trial bit
	lsl	r0, #1		// shift root
	add	r0, #1		// add trial bit

	// Shift two bits of input into remainder
	add	r1, r1
	adc	r5, r5
	add	r1, r1
	adc	r5, r5

	sub	r5, r0		// Does trial root bit fit?
	bhs	RootBit32	// Bit works, fix up root

	// Bit didn't fit, restore things
	add	r5, r0		// restore remainder
	sub	r0, #1		// remove trial bit
	sub	r3, #1		// count down
	bne	Root32
	b	Root32Done

RootBit32:
	add	r0, #1		// double trial bit
	sub	r3, #1		// count down
	bne	Root32
Root32Done:


	// Need MANT_BITS + 1 bits plus rounding bit, have 32 bits
	mov	r2, #(MANT_BITS + 1 + 1 - 30)
Root64:
	// r0:r1 = root * 2
	// r2 = bit count down
	// r4 = exponent
	// r5:r3 = remainder

	// Set trial bit
	add	r0, r0
	adc	r1, r1		// shift root
	add	r0, #1		// add trial bit

	// shift remainder two bits
	add	r5, r5
	adc	r3, r3
	add	r5, r5
	adc	r3, r3
	sub	r5, r0		// Does trial root bit fit?
	sbc	r3, r1
	bhs	RootBit64	// Bit works, fix up root

	// Bit didn't fit, restore things
	add	r5, r0		// restore remainder
	adc	r3, r1
	sub	r0, #1		// remove trial bit
	sub	r2, #1		// count down
	bne	Root64
	b	Root64Done

RootBit64:
	add	r0, #1		// double trial bit
	sub	r2, #1		// count down
	bne	Root64
Root64Done:
	orr	r5, r3
	bne	RoundUp		// non-zero remainder, round up
	lsl	r5, r0, #29	// test bit 2 for round even
	bpl	NoRound
RoundUp:
	add	r0, #2		// add to rounding bit
	adc	r1, r2
NoRound:
	// remove rounding & sticky bits
	lsr64const	r0, r1, 2, r3
	// Zero implied bit
	// root &= ~(1 << MANT_BITS);
	mov	r3, #1
	lsl	r3, #MANT_BITS_HI
	bic	r1, r3
	// root |= exp << MANT_BITS
	lsl	r4, #MANT_BITS_HI
	orr	r1, r4
	pop	{r4, r5, r6, pc}

Denormal:
	// r1:r0 = input
	// r2 = r1 << 1
	// r4 = exponent, currently zero
	orr	r2, r0		// Is it zero?
	beq	Exit
	cmp	r1, #0		// Is it negative?
	bmi	ReturnNan
	// __clz_divas uses tailored calling convention
	// r5 = input to count leading zeros
	// r0 - r4 preserved
	// r6, r7 trashed
	push	{r7}
	mov	r5, r1		// pass hi half
	beq	SmallVal
	bl	__clz_divas	// Get leading zeros
	sub	r5, #EXP_BITS
	lsl64short	r0, r1, r5, r6
	// lsl64short leaves count at 32 - count; we need 1 - count
FinishNorm:
	sub	r5, #31
	mov	r4, r5
	pop	{r7}
	b	Normalized

SmallVal:
	// val <<= 32
	mov	r1, r0
	mov	r0, #0
	mov	r5, r1
	bl	__clz_divas	// Get leading zeros
	sub	r5, #EXP_BITS
	bmi	ValRight
	lsl	r1, r5
FixExp:
	neg	r5, r5
	b	FinishNorm

ValRight:
	neg	r7, r5
	lsr64short	r0, r1, r7, r6
	b	FixExp

SpclExp:
	// r1:r0 = input
	// r4 = exponent, currently EXP_SPECIAL
	lsl	r4, r1, #MANT_BITS_HI + 1
	orr	r4, r0
	bne	Exit		// It's NAN, just return it
	cmp	r1, #0
	bpl	Exit		// Positive Infinity, return it
	// Negative Infinity, return NAN
ReturnNan:
	ldr	r1, =#NAN
	mov	r0, #0
Exit:
	pop	{r4, r5, r6, pc}
	
	.endfunc
