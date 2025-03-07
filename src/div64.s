
/*
 * div64.s
 *
 * Created: 6/19/2020 2:27:09 PM
 *  Author: Tim Paterson
 */ 
 

.syntax unified
.cpu cortex-m0plus
.thumb

.include "macros.inc"


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
.set	QuoLo,	0
.set	QuoHi,	4
// denominator is accessed as 16-bit "digits"
.set	Den0,	8
.set	Den1,	10
.set	Den2,	12
.set	Den3,	14
.set	oDig,	16
.set	NumExt,	20

	.thumb_func
__div64_divas:
	movs	r6, r0
	movs	r0, #0
	push	{r0, r1, r2, r3, r4, r5, lr}// zero quotient, save den, oDig, NumExt
	mov	r7, sp		// point to stack variables
	str	r0, [r7, #QuoHi]
	// r1:r6 = numerator
	movs	r0, r1
	ldrh	r1, [r7, #Den3]
DivLoop:
	// if (num < den)
	cmp	r0, r1
	blo	ZeroQuo

	// Compute 16-bit "digit" guess
	bl	__divas_uidivmod

	// Check out our guess.
	// Currently, remainder = numerator - (quotient * high word denominator).
	// The definition of remainder is numerator - (quotient * all denominator).
	// So if we subtract (quotient * low 3 words denominator), we'll get
	// the true remainder.  If it's negative, our guess was too big.
	//
	// prod = (quoDig * Den1) << 16;
	ldrh	r2, [r7, #Den1]
	muls	r2, r0
	lsrs	r3, r2, #16
	lsls	r2, #16
	// prod += quoDig * Den0;
	ldrh	r4, [r7, #Den0]
	muls	r4, r0
	movs	r5, #0
	adds	r2, r4
	adcs	r3, r5
	// prodHi += quoDig * Den2
	ldrh	r5, [r7, #Den2]
	muls	r5, r0
	adds	r3, r5
Normalize:
	// r0 = quotient digit
	// r1:r6 = remainder (next numerator)
	// r3:r2 = product to adjust remainder
	// r7 = ponter to stack variables
	//
	// Re-normalize numerator by shifting left one digit,
	// incorporating numerator extension.
	//
	// num <<= 16;
	lsl64const	r6, r1, 16, r4
	// num |= numExt;
	ldr	r4, [r7, #NumExt]
	orrs	r6, r4
	// numExt = 0;
	movs	r4, #0
	str	r4, [r7, #NumExt]

	// Subtract to calculate full remainder
	// Carry clear means negative remainder, quotient too large
	//
	// num -= prod;
	subs	r6, r2
	sbcs	r1, r3
	bcs	QuoGood
	// Quotient digit was too big. Decrement and adds a denominator back
	ldr	r4, [r7, #Den0]
	ldr	r5, [r7, #Den2]
ShrinkQuo:
	// quoDig--;
	subs	r0, #1
	// num += den;
	adds	r6, r4
	adcs	r1, r5
	bcc	ShrinkQuo
QuoGood:
	// quo[oDig] = quoDig
	ldr	r4, [r7, #oDig]
	strh	r0, [r7, r4]
	// oDig -= 2;
	subs	r4, #2
	bmi	DivComplete
	str	r4, [r7, #oDig]
	// r1:r6 = numerator
	movs	r0, r1
	ldrh	r1, [r7, #Den3]
	// if ((num >> 16) >= den)
	lsrs	r2, r0, #16
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
	subs	r6, r4
	sbcs	r0, r5
	// num <<= 16;
	lsls	r1, r0, #16
	lsrs	r3, r6, #16
	orrs	r1, r3
	lsls	r6, #16
	// quoDig = 0;
	movs	r0, #0
	b	ShrinkQuo

DivComplete:
// Divide complete
	movs	r3, r1
	movs	r2, r6		// r2:r3 has remainder
	pop	{r0, r1, r4, r5, r6, r7, pc}

ZeroQuo:
	movs	r1, r0		// restore numerator
	movs	r0, #0		// zero quotient "digit"
	movs	r2, #0		// zero product
	movs	r3, #0
	b	Normalize

	.endfunc
