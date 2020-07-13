
/*
 * ldivmod.s
 *
 * Created: 6/18/2020 2:40:47 PM
 *  Author: Tim
 */ 

 
.include "macros.h"


	.global	__aeabi_ldivmod


// 64-bit signed integer division & modulo
//
// Entry:
//	r1:r0 = numerator
//	r3:r2 = denominator
// Exit:
//	r1:r0 = quotient, rounded toward zero
//	r3:r2 = remainder, same sign as numerator

	.func	__aeabi_ldivmod

	.thumb_func
__aeabi_ldivmod:
	push	{r4, r5, lr}
	asr	r4, r1, #31	// sign of numerator
	asr	r5, r3, #31	// sign of denominator
	// Get abs(numerator)
	eor	r0, r4
	eor	r1, r4
	sub	r0, r4
	sbc	r1, r4
	// Get abs(denominator)
	eor	r2, r5
	eor	r3, r5
	sub	r2, r5
	sbc	r3, r5

	// Perform unsigned division
	bl	__aeabi_uldivmod

	// Adjust sign of remainder to match numerator
	eor	r2, r4
	eor	r3, r4
	sub	r2, r4
	sbc	r2, r4
	// Compute result sign and adjust quotient
	eor	r4, r5
	eor	r0, r4
	eor	r1, r4
	sub	r0, r4
	sbc	r1, r4

	pop	{r4, r5, pc}

	.endfunc
