
/*
 * mod64.s
 *
 * Created: 3/6/2025 3:33:18 PM
 *  Author: Tim Paterson
 */ 

.syntax unified
.cpu cortex-m0plus
.thumb

// These entry points are for debugging. They provide 
// access to the 64-bit mod functions by moving the
// result to the correct registers.

	.global	__divas_ulmod
	.global	__divas_lmod

	.func	__divas_ulmod

__divas_ulmod:
	push	{lr}
	bl	__divas_uldivmod
	movs	r0, r2
	movs	r1, r3
	pop	{pc}

	.endfunc


	.func	__divas_lmod

__divas_lmod:
	push	{lr}
	bl	__divas_ldivmod
	movs	r0, r2
	movs	r1, r3
	pop	{pc}

	.endfunc
