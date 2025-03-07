
/*
 * uidiv.s
 *
 * Created: 6/12/2020 4:11:02 PM
 *  Author: Tim Paterson
 */ 

.syntax unified
.cpu cortex-m0plus
.thumb

.include "divas_asm.inc"
.include "macros.inc"


// Basic driver for SAMC DIVAS hardware.
//
// Provides 32-bit support for division and modulo operators
// for the compiler, both signed and unsigned. Unsigned is 
// given the slight advantage as it's used by other functions.


// Signed division & modulo. Just set flag and jump to base routine.

FUNC_START	__divas_idivmod, __aeabi_idivmod
ENTRY_POINT	__divas_idiv, __aeabi_idiv
	movs	r2, #DIVAS_CTRLA_SIGNED
	b	__divas_divmod

	.endfunc


// Unsigned division & modulo.

FUNC_START	__divas_uidivmod, __aeabi_uidivmod
ENTRY_POINT	__divas_uidiv, __aeabi_uidiv
	movs	r2, #DIVAS_CTRLA_UNSIGNED
	// fall into __divas_divmod
__divas_divmod:
	push	{r4, lr}
	MOV_IMM	r4, DIVAS	// address of DIVAS module
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
