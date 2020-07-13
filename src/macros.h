/*
 * macros.h
 *
 * Created: 6/21/2020 12:28:05 PM
 *  Author: Tim
 */


.macro	lsl64const	lo, hi, cnt, tmp

.if \cnt == 1
	add	\lo, \lo
	adc	\hi, \hi
.elseif \cnt == 2
	add	\lo, \lo
	adc	\hi, \hi
	add	\lo, \lo
	adc	\hi, \hi
.else
	lsl	\hi, #\cnt
	lsr	\tmp, \lo, #(32 - \cnt)
	orr	\hi, \tmp
	lsl	\lo, #\cnt
.endif

.endm

.macro	lsr64const	lo, hi, cnt, tmp

	lsr	\lo, #\cnt
	lsl	\tmp, \hi, #(32 - \cnt)
	orr	\lo, \tmp
	lsr	\hi, #\cnt

.endm

.macro	lsl64short	lo, hi, cnt, tmp

	lsl	\hi, \cnt
	mov	\tmp, \lo
	lsl	\lo, \cnt
	sub	\cnt, #32
	neg	\cnt, \cnt
	lsr	\tmp, \cnt
	orr	\hi, \tmp

.endm

.macro	lsr64short	lo, hi, cnt, tmp

	lsr	\lo, \cnt
	mov	\tmp, \hi
	lsr	\hi, \cnt
	sub	\cnt, #32
	neg	\cnt, \cnt
	lsl	\tmp, \cnt
	orr	\lo, \tmp

.endm

.macro lsr64	lo, hi, cnt, tmp1, tmp2
	// inspired by __aeabi_llsr
	mov	\tmp1, \hi	// hi1
	mov	\tmp2, \hi	// hi2

	//				cnt < 32			cnt >= 32
	lsr	\lo, \cnt	// lo >>= cnt		lo = 0
	lsr	\hi, \cnt	// hi >>= cnt		hi = 0
	sub	\cnt, #32	// cnt1 < 0 (=>big)	0 <= cnt1 < 32
	lsr	\tmp1, \cnt	// hi1 = 0			hi1 >>= cnt1
	orr	\lo, \tmp1	// lo1 = lo			lo1 = hi1
	neg	\cnt, \cnt	// 32 - cnt			cnt2 < 0 (=>big)
	lsl	\tmp2, \cnt	// hi2 <<= cnt2		hi2 = 0
	orr	\lo, \tmp2	// lo1 |= hi2		lo1

.endm

.macro	CLZ		arg, cnt, tmp
	mov	\cnt, #31
	lsr	\tmp, \arg, #16
	beq	1f
	mov	\arg, \tmp
	sub \cnt, #16
1:
	lsr	\tmp, \arg, #8
	beq	2f
	mov	\arg, \tmp
	sub \cnt, #8
2:
	lsr	\tmp, \arg, #4
	beq	3f
	mov	\arg, \tmp
	sub \cnt, #4
3:
	lsr	\tmp, \arg, #2
	beq	4f
	mov	\arg, \tmp
	sub \cnt, #2
4:
	lsr	\arg, #1
	sub	\arg, \cnt, \arg
	bx	lr
.endm
