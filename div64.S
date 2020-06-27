
/*
 * div64.S
 *
 * Created: 6/19/2020 2:27:09 PM
 *  Author: Tim
 */ 
 

#include "macros.h"


	.global	__div64_divas

// Helper for 64-bit integer & floating point division
//
// WARNING!!: This function does not follow the standard
// calling convention!
//
// Entry:
//	r1:r0 = num, scaled numerator
//	r3:r2 = den, normalized denominator
//	r4 = oDig, address offset of first quotient digit: 0,2,4, or 6
//	r5 = NumExt, numerator extension
// Exit:
//	r1:r0 = quotient, rounded toward zero
//	r3:r2 = remainder
//	r4 - r7 trashed!!

	.func	__div64_divas

// Offset of variables in stack
#define	QuoLo	0
#define	QuoHi	4
// denominator is accessed as 16-bit "digits"
#define	Den0	8
#define	Den1	10
#define	Den2	12
#define	Den3	14
#define oDig	16
#define NumExt	20

__div64_divas:
	mov	r6, r0
	mov	r0, #0
	push	{r0, r1, r2, r3, r4, r5, lr}// zero quotient, save den, oDig, NumExt
	mov	r7, sp		// point to stack variables
	str	r0, [r7, #QuoHi]
	// r1:r6 = numerator
	mov	r0, r1
	ldrh	r1, [r7, #Den3]
DivLoop:
	// if (num < den)
	cmp	r0, r1
	blo	ZeroQuo

	// Compute 16-bit "digit" guess
	bl	__aeabi_uidivmod

	// Check out our guess.
	// Currently, remainder = numerator - (quotient * high word denominator).
	// The definition of remainder is numerator - (quotient * all denominator).
	// So if we subtract (quotient * low 3 words denominator), we'll get
	// the true remainder.  If it's negative, our guess was too big.
	//
	// prod = (quoDig * Den1) << 16;
	ldrh	r2, [r7, #Den1]
	mul	r2, r0
	lsr	r3, r2, #16
	lsl	r2, #16
	// prod += quoDig * Den0;
	ldrh	r4, [r7, #Den0]
	mul	r4, r0
	mov	r5, #0
	add	r2, r4
	adc	r3, r5
	// prodHi += quoDig * Den2
	ldrh	r5, [r7, #Den2]
	mul	r5, r0
	add	r3, r5
Normalize:
	// Re-normalize numerator by shifting left one digit,
	// incorporating numerator extension.
	//
	// num <<= 16;
	lsl64const	r6, r1, 16, r4
	// num |= numExt;
	ldr	r4, [r7, #NumExt]
	orr	r6, r4
	// numExt = 0;
	mov	r4, #0
	str	r4, [r7, #NumExt]

	// Subtract to calculate full remainder
	// Carry clear means negative remainder, quotient too large
	//
	// num -= prod;
	sub	r6, r2
	sbc	r1, r3
	bcs	QuoGood
	// Quotient digit was too big. Decrement and add a denominator back
	ldr	r4, [r7, #Den0]
	ldr	r5, [r7, #Den2]
ShrinkQuo:
	// quoDig--;
	sub	r0, #1
	// num += den;
	add	r6, r4
	adc	r1, r5
	bcc	ShrinkQuo
QuoGood:
	// quo[oDig] = quoDig
	ldr	r4, [r7, #oDig]
	strh	r0, [r7, r4]
	// oDig -= 2;
	sub	r4, #2
	bmi	DivComplete
	str	r4, [r7, #oDig]
	// r1:r6 = numerator
	mov	r0, r1
	ldrh	r1, [r7, #Den3]
	// if ((num >> 16) >= den)
	lsr	r2, r0, #16
	cmp	r2, r1
	blo	DivLoop
	// High 16 bits of numerator equal denominator, so result of
	// division would be quotient >= 0x10000. Actual quotient digit
	// can't be that big. Assume a result of 2^16-1, thus remainder =
	// numerator - ( denominator * (2^16-1) ) =
	// numerator - denominator * 2^16 + denominator.
	//
	// num -= den;
	ldr	r4, [r7, #Den0]
	ldr	r5, [r7, #Den2]
	sub	r6, r4
	sbc	r0, r5
	// num <<= 16;
	lsl	r1, r0, #16
	lsr	r4, r6, #16
	orr	r1, r4
	lsl	r6, #16
	// quoDig = 0;
	mov	r0, #0
	b	ShrinkQuo

DivComplete:
// Divide complete
	mov	r3, r1
	mov	r2, r6		// r2:r3 has remainder
	pop	{r0, r1, r4, r5, r6, r7, pc}

ZeroQuo:
	mov	r1, r0		// restore numerator
	mov	r0, #0		// zero quotient "digit"
	mov	r2, #0		// zero product
	mov	r3, #0
	b	Normalize

	.endfunc
