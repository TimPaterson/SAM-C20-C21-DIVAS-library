
/*
 * sqrtf.s
 *
 * Created: 6/26/2020 10:34:58 AM
 *  Author: Tim
 */ 
 

.include "macros.h"
.include "Ieee32.h"
.include "divas_asm.h"


	.global	sqrtf


// 32-bit IEEE floating-point square root
//
// Entry:
//	r0 = input
// Exit:
//	r0 = root

	.func	sqrtf

	.thumb_func
sqrtf:
	push	{r4, lr}
	lsl	r1, r0, #1		// clear input sign
	beq	Exit			// input is zero, just return it
	lsr	r1, #MANT_BITS + 1	// input exponent
	beq	Denormal
	cmp	r1, #EXP_SPECIAL
	beq	SpclExp
	cmp	r0, #0
	bmi	ReturnNan		// must not be negative
Normalized:

	// Set implied bit
	mov	r2, #1
	lsl	r2, #MANT_BITS
	orr	r0, r2

	lsl	r0, #EXP_BITS	// normalize
	// Result exponent is current exponent / 2
	// Take out exponent bias since it's odd
	sub	r1, #EXP_BIAS
	// exp >>= 1
	asr	r1, #1
	bcs	1f		// was it odd?
	lsr	r0, #1		// if not, add leading zero
1:
	add	r1, #EXP_BIAS

	// Use hardware accelerator to compute first 16 bits of square root
	mov	r3, #(DIVAS >> 24)
	lsl	r3, #24		// address of DIVAS module
	mrs	r2, PRIMASK	// Save state of interrupt flag
	cpsid	i		// Disable interrupts
	str	r0, [r3, #REG_DIVAS_SQRNUM]
	// Bus will stall until ready, no need to wait
	ldr	r0, [r3, #REG_DIVAS_RESULT]
	ldr	r4, [r3, #REG_DIVAS_REM]
	msr	PRIMASK, r2	// restore interrupt flag

// Compute square root bit-by-bit.  For each bit, remainder/input will
// be shifted left 2 bits, root will be shifted left 1 bit, and trial
// bit will hold position.
	lsl	r0, #1		// current root * 2
	// Need MANT_BITS + 1 bits plus rounding bit, have 16 bits
	mov	r3, #(MANT_BITS + 1 + 1 - 16)
Root32:
	// r0 = root*2
	// r1 = exponent
	// r3 = bit count down
	// r4 = remainder

	// Set trial bit
	lsl	r0, #1		// shift root
	add	r0, #1		// add trial bit

	lsl	r4, #2		// Shift remainder
	sub	r4, r0		// Does trial root bit fit?
	bhs	RootBit32	// Bit works, fix up root

	// Bit didn't fit, restore things
	add	r4, r0		// restore remainder
	sub	r0, #1		// remove trial bit
	sub	r3, #1		// count down
	bne	Root32
	b	Root32Done

RootBit32:
	add	r0, #1		// double trial bit
	sub	r3, #1		// count down
	bne	Root32
Root32Done:
	cmp	r4, #0
	bne	RoundUp
	lsl	r4, r0, #29	// test bit 2 for round even
	bpl	NoRound
RoundUp:
	add	r0, #2		// add to rounding bit
NoRound:
	lsr	r0, #2		// remove rounding & sticky bits
	// Zero implied bit
	// root &= ~(1 << MANT_BITS);
	mov	r3, #1
	lsl	r3, #MANT_BITS
	bic	r0, r3
	// root |= exp << MANT_BITS
	lsl	r1, #MANT_BITS
	orr	r0, r1
	pop	{r4, pc}

Denormal:
	// r0 = input
	// r1 = exponent, currently zero
	cmp	r0, #0
	bmi	ReturnNan
	push	{r5, r6, r7}
	mov	r5, r0		// pass value
	// __clz_divas uses tailored calling convention
	// r5 = input to count leading zeros
	// r0 - r4 preserved
	// r6, r7 trashed
	bl	__clz_divas	// Get leading zeros in denominator
	sub	r5, #EXP_BITS
	lsl	r0, r5
	mov	r1, #1
	sub	r1, r5
	pop	{r5, r6, r7}
	b	Normalized

SpclExp:
	// r0 = input
	// r1 = exponent, currently EXP_SPECIAL
	lsl	r1, r0, #MANT_BITS + 1
	bne	Exit		// It's NAN, just return it
	cmp	r0, #0
	bpl	Exit		// Positive Infinity, return it
	// Negative Infinity, return NAN
ReturnNan:
	ldr	r0, =#NAN
Exit:
	pop	{r4, pc}
	
	.endfunc
