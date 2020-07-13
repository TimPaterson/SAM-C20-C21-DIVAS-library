
/*
 * uidiv.s
 *
 * Created: 6/12/2020 4:11:02 PM
 *  Author: Tim
 */ 


.include "divas_asm.h"


// Basic driver for SAMC DIVAS hardware.
//
// Provides 32-bit support for division and modulo operators
// for the compiler, both signed and unsigned. Unsigned is 
// given the slight advantage as it's used by other functions.
//
// NOTE: These functions also preserve r12, which fact is
// utilized by other functions in this math package.

	.global	__aeabi_idivmod
	.global	__aeabi_uidivmod
	.global	__aeabi_idiv
	.global	__aeabi_uidiv


// Signed division & modulo. Just set flag and jump to base routine.

	.func	__aeabi_idivmod

	.thumb_func
__aeabi_idivmod:
	.thumb_func
__aeabi_idiv:
	mov	r2, #DIVAS_CTRLA_SIGNED
	b	__divas_divmod

	.endfunc


// Unsigned division & modulo.

	.func	__aeabi_uidivmod

	.thumb_func
__aeabi_uidivmod:
	.thumb_func
__aeabi_uidiv:
	mov	r2, #DIVAS_CTRLA_UNSIGNED
	// fall into __divas_divmod
__divas_divmod:
	push	{r4, lr}
	mov	r4, #(DIVAS >> 24)
	lsl	r3, #24		// address of DIVAS module
	mrs	r3, PRIMASK	// Save state of interrupt flag
	cpsid	i		// Disable interrupts
	strb	r2, [r4, #REG_DIVAS_CTRLA]
	str	r0, [r4, #REG_DIVAS_DIVIDEND]
	str	r1, [r4, #REG_DIVAS_DIVISOR]
	// Bus will stall until ready, no need to wait
	ldr	r0, [r4, #REG_DIVAS_RESULT]
	ldr	r1, [r4, #REG_DIVAS_REM]
	msr	PRIMASK, r3	// restore interrupt flag
	pop	{r4, pc}

	.endfunc
