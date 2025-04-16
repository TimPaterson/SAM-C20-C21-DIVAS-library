# Software Library for Microchip SAM C20/C21 and PIC32CM-JH MCU Divide and Square Root (DIVAS) Module
The Microchip SAM C20/C21 and PIC32CM-JH microcontrollers belong to a class of ARM
processors that use the ARM Cortex M0+ instruction set which has no divide
instruction. As such, division must normally be performed in software
and is relatively slow. These particular MCUs, however, have a module
called DIVAS (DIVide And Square root) that provides hardware-acclerated
32-bit integer division and square root. This functionality is not
integrated into the processor instruction set, so a thin software
layer is required to pass data to and from the module. Microchip provides
only the barest software, supporting just the specific 32-bit integer
operations provided by the hardware module.

This library provides DIVAS hardware accleration for the `/` (divsion)
and `%` (modulo) operators for integer types (int32_t, uint32_t, int64_t, uint64_t). 
All you need to do is link the library (archive, as GNU
calls it) ahead of the standard math archive `libm`. It also provides
access to the unsigned integer square root capability with the function 
`__sqrtu()`, which has a prototype in `include/divas.h`.

This library does not use the DIVAS module for floating point operations
because it still wouldn't be as fast as my `ArmMathM0` library at 
https://github.com/TimPaterson/ArmMathM0.

### Usage
This repository includes `libDivas.a`, a compiled and ready-to-link 
archive in the `lib-out` folder. Copy this file to a folder on your
machine in the place where you keep your projects. 

Modify your build process to link `libDivas` before `libm` but
after any other archives you may have. (This order ensures any other
archives get the accelerated math, while keeping `libm` from providing
slow math that is present in `libDivas`.)

### Performance
All cases provide substantial speed improvement at reduced code size.
Execution time is typically reduced by roughly 50%, but this varies
with both operands and data type. For example, on just a few tests
the improvement for 64-bit integer divison was as much as 80% or as
little as 30%. 

Interrupts are disabled while the DIVAS module is being used. This
could increase interrupt service latency by up to about 26 clock cycles.

### Repository Notes
Since this library specifically targets certain Microchip MCUs, it was
built with Microchip Studio version 7. Project files are included.
