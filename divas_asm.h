/*
 * divas_asm.h
 *
 * Created: 6/22/2020 3:55:40 PM
 *  Author: Tim
 */ 


#ifndef DIVAS_ASM_H_
#define DIVAS_ASM_H_


// DIVAS module base address on AHB and IOBUS
#define DIVAS			0x48000000
#define DIVAS_IOBUS		0x60000200

// DIVAS registers
#define REG_DIVAS_CTRLA         0x00
#define REG_DIVAS_STATUS        0x04
#define REG_DIVAS_DIVIDEND      0x08
#define REG_DIVAS_DIVISOR       0x0C
#define REG_DIVAS_RESULT        0x10
#define REG_DIVAS_REM           0x14
#define REG_DIVAS_SQRNUM        0x18

// DIVAS control register A
#define DIVAS_CTRLA_UNSIGNED	0
#define DIVAS_CTRLA_SIGNED	1



#endif /* DIVAS_ASM_H_ */