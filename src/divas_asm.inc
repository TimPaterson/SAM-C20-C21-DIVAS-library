/*
 * divas_asm.inc
 *
 * Created: 6/22/2020 3:55:40 PM
 *  Author: Tim Paterson
 */ 


// DIVAS module base address on AHB and IOBUS
.set	DIVAS,			0x48000000
.set	DIVAS_IOBUS,		0x60000200

// DIVAS registers
.set	REG_DIVAS_CTRLA,        0x00
.set	REG_DIVAS_STATUS,       0x04
.set	REG_DIVAS_DIVIDEND,     0x08
.set	REG_DIVAS_DIVISOR,      0x0C
.set	REG_DIVAS_RESULT,       0x10
.set	REG_DIVAS_REM,          0x14
.set	REG_DIVAS_SQRNUM,       0x18

// DIVAS control register A
.set	DIVAS_CTRLA_UNSIGNED,	0
.set	DIVAS_CTRLA_SIGNED,	1
