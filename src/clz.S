
/*
 * clz.S
 *
 * Created: 6/24/2020 9:51:10 AM
 *  Author: Tim
 */ 


#include "macros.h"


	.global	__clz_divas

// Count Leading Zeros for DIVAS module
//
// WARNING!!: This function does not follow the standard
// calling convention!
//
// Entry:
//	r5 = argument to count leading zeros, non-zero
// Exit:
//	r5 = count of leading zeros, 0 - 31
//	r0, r1, r2, r3, r4 preserved
//	r6, r7 destroyed

	.func	__clz_divas

__clz_divas:
	CLZ	r5, r6, r7

	.endfunc
