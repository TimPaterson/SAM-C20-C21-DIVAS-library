
/*
 * uldivmod.S
 *
 * Created: 6/18/2020 3:35:19 PM
 *  Author: Tim
 */ 


#include "macros.h"


	.global	__aeabi_uldivmod

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

	.func	__aeabi_uldivmod

__aeabi_uldivmod:
	push	{r4, r5, r6, r7, lr}
	mov	r4, #0

	cmp	r3, #0
	bne	2f //Normalize
	// High half of denominator is zero
	cmp	r2, #0
	beq	3f //DivByZero
	cmp	r1, #0
	bne	1f //ShiftDen
	// 32 x 32 divide
	mov	r1, r2
	bl	__aeabi_uidivmod
	// Zero extend results in r0 & r1 to r1:r0 & r3:r2
	mov	r2, r1
	mov	r1, #0
	mov	r3, #0
	pop	{r4, r5, r6, r7, pc}

1: //ShiftDen:
	// den <<= 32;
	mov	r3, r2
	mov	r2, #0
	// oDig = 2
	mov	r4, #2
2: //Normalize:
	// __clz_divas uses tailored calling convention
	// r5 = input to count leading zeros
	// r0 - r4 preserved
	// r6, r7 trashed
	mov	r5, r3		// pass high denominator
	bl	__clz_divas	// Get leading zeros in denominator

	// remShf = cDig == 0 ? cShift : cShift + 32;
	lsl	r7, r4, #4	// r4 is 0 or 2, so r7 is 0 or 32
	add	r7, r5		// full shift count needed after call to __div64_divas
	push	{r7}		// save over call

	// Normalize denominator
	// den <<= cShift;
	lsl	r3, r5
	mov	r7, r2
	lsl	r2, r5
	mov	r6, #32
	sub	r6, r5
	lsr	r7, r6
	orr	r3, r7

	// cDig += cShift >> 4;
	lsr	r6, r5, #4	// count of 16-bit "digits"
	add	r4, r6
	lsl	r4, #1		// *2 to make it address offset

	// shfNum  = (cShift & 0xF) + 16;
	mov	r6, #0x0F
	and	r6, r5
	add	r6, #16

	// numExt = (num << shfNum) >> 16;
	mov	r5, r0
	lsl	r5, r6
	lsr	r5, #16

	// num >>= 32 - shfNum
	mov	r7, r1
	lsl	r7, r6
	sub	r6, #32
	neg	r6, r6
	lsr	r0, r6
	lsr	r1, r6
	orr	r0, r7

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

3: //DivByZero:
	// Set remainder = numerator, quotient = 0
	mov	r2, r0
	mov	r3, r1
	mov	r0, #0
	mov	r1, #0
	pop	{r4, r5, r6, r7, pc}

	.endfunc

