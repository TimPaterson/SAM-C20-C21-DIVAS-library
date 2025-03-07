
/*
 * ldivmod.s
 *
 * Created: 6/18/2020 2:40:47 PM
 *  Author: Tim Paterson
 */ 

.syntax unified
.cpu cortex-m0plus
.thumb
 
.include "macros.inc"


// 64-bit signed integer division & modulo
//
// Entry:
//	r1:r0 = numerator
//	r3:r2 = denominator
// Exit:
//	r1:r0 = quotient, rounded toward zero
//	r3:r2 = remainder, same sign as numerator

FUNC_START	__divas_ldivmod, __aeabi_ldivmod
	push	{r4, r5, lr}
	asrs	r4, r1, #31	// sign of numerator
	asrs	r5, r3, #31	// sign of denominator
	// Get abs(numerator)
	eors	r0, r4
	eors	r1, r4
	subs	r0, r4
	sbcs	r1, r4
	// Get abs(denominator)
	eors	r2, r5
	eors	r3, r5
	subs	r2, r5
	sbcs	r3, r5

	// Perform unsigned division
	bl	__divas_uldivmod

	// Adjust sign of remainder to match numerator
	eors	r2, r4
	eors	r3, r4
	subs	r2, r4
	sbcs	r2, r4
	// Compute result sign and adjust quotient
	eors	r4, r5
	eors	r0, r4
	eors	r1, r4
	subs	r0, r4
	sbcs	r1, r4

	pop	{r4, r5, pc}

	.endfunc
