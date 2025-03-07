
/*
 * uldivmod.s
 *
 * Created: 6/18/2020 3:35:19 PM
 *  Author: Tim Paterson
 */ 

.syntax unified
.cpu cortex-m0plus
.thumb

.include "macros.inc"


// 64-bit unsigned integer division & modulo
//
// Entry:
//	r1:r0 = numerator
//	r3:r2 = denominator
// Exit:
//	r1:r0 = quotient, rounded toward zero
//	r3:r2 = remainder

// A problem with the debugger in Atmel Studio prevents use
// of meaningful label names.

FUNC_START	__divas_uldivmod, __aeabi_uldivmod
	push	{r4, r5, r6, r7, lr}
	movs	r4, #0

	cmp	r3, #0
	bne	Normalize
	// High half of denominator is zero
	cmp	r2, #0
	beq	DivByZero
	cmp	r1, #0
	bne	ShiftDen
	// 32 x 32 divide
	movs	r1, r2
	bl	__divas_uidivmod
	// Zero extend results in r0 & r1 to r1:r0 & r3:r2
	movs	r2, r1
	movs	r1, #0
	movs	r3, #0
	pop	{r4, r5, r6, r7, pc}

ShiftDen:
	// den <<= 32;
	movs	r3, r2
	movs	r2, #0
	// oDig = 2
	movs	r4, #2
Normalize:
	movs	r5, r3		// pass high denominator
	CLZ	r5, r6, r7	// Get leading zeros in denominator

	// remShf = cDig == 0 ? cShift : cShift + 32;
	lsls	r7, r4, #4	// r4 is 0 or 2, so r7 is 0 or 32
	adds	r7, r5		// full shift count needed after call to __div64_divas
	push	{r7}		// save over call

	// Normalize denominator
	// den <<= cShift;
	lsls	r3, r5
	movs	r7, r2
	lsls	r2, r5
	movs	r6, #32
	subs	r6, r5
	lsrs	r7, r6
	orrs	r3, r7

	// cDig += cShift >> 4;
	lsrs	r6, r5, #4	// count of 16-bit "digits"
	adds	r4, r6
	lsls	r4, #1		// *2 to make it address offset

	// shfNum  = (cShift & 0xF) + 16;
	movs	r6, #0x0F
	ands	r6, r5
	adds	r6, #16

	// numExt = (num << shfNum) >> 16;
	movs	r5, r0
	lsls	r5, r6
	lsrs	r5, #16

	// num >>= 32 - shfNum
	movs	r7, r1
	lsls	r7, r6
	subs	r6, #32
	negs	r6, r6
	lsrs	r0, r6
	lsrs	r1, r6
	orrs	r0, r7

	// r1:r0 = num, scaled numerator
	// r3:r2 = den, normalized denominator
	// r4 = oDig, address offset of first quotient digit: 0,2,4, or 6
	// r5 = numExt, numerator extension
	bl	__div64_divas
	// r1:r0 = quotient
	// r3:r2 = scaled remainder
	// no other registers preserved

	pop	{r7}		// restore remShf

	// rem >>= remShf
	lsr64	r2, r3, r7, r4, r5	// lo, hi, cnt, tmp1, tmp2

	pop	{r4, r5, r6, r7, pc}

DivByZero:
	// Set remainder = numerator, quotient = 0
	movs	r2, r0
	movs	r3, r1
	movs	r0, #0
	movs	r1, #0
	pop	{r4, r5, r6, r7, pc}

	.endfunc

