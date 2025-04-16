
/*
 * sqrtu.s
 *
 * Created: 4/12/2025 10:30:20 AM
 *  Author: Tim Paterson
 */ 

.syntax unified
.cpu cortex-m0plus
.thumb

.include "divas_asm.inc"
.include "macros.inc"


// Unsigned integer square root
//
// Entry:
//	r0 = square
// Exit:
//	r0 = root of square, rounded toward zero
//	r1 = remainder = input - result^2

FUNC_START	__divas_sqrt, __sqrtu

	MOV_IMM	r2, DIVAS	// address of DIVAS module
	mrs	r3, PRIMASK	// Save state of interrupt flag
	cpsid	i		// Disable interrupts
	str	r0, [r2, #REG_DIVAS_SQRNUM]
	// Bus will stall until ready, no need to wait
	ldr	r0, [r2, #REG_DIVAS_RESULT]
	ldr	r1, [r2, #REG_DIVAS_REM]
	msr	PRIMASK, r3	// restore interrupt flag
	bx	lr

	.endfunc
