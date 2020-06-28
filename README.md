# Software Library for Microchip SAM C20/C21 MCU Divide and Square Root (DIVAS) Module
The Microchip SAM C20/C21 microcontrollers belong to a class of ARM
processors that use the ARM Thumb-2 instruction set which has no divide
instruction. As such, division must normally be performed in software
and is relatively slow. These particular MCUs, however, have a module
called DIVAS (DIVide And Square root) that provide hardware-acclerated
32-bit integer division and square root. This functionality is not
integrated into the processor instruction set, so a thin software
layer is required to pass data to and from the module. Microchip provides
only the barest software, supporting just the specific 32-bit integer
operations provided by the hardware module.

This library provides DIVAS hardware accleration for the "/" (divsion)
operator for all standard types (int32_t, uint32_t, int64_t, uint64_t, float,
double), as well as `sqrtf()` and `sqrt()` functions (float and double,
respectively). All you need to do is link the library (archive, as GNU
calls it) ahead of the standard math archive `libm`. Floating-point 
operations provide full support for denormalized (tiny) numbers, 
infinity, and NAN.
### Usage
This repository includes `libDivas.a`, a compiled and ready-to-link 
archive in the `lib-out` folder. Copy this file to a folder on your
machine in the place where you keep your projects. 

Modify your build process to link `libDivas` before `libm` but
after any other archives you may have. (This order ensures any other
archives get the accelerated math, while keeping `libm` from providing
slow math that is present in `libDivas`.)

If you use Atmel Studio, these changes are made in the project properties.
Right-click the project in the Solution Explorer, and select Properties.
Choose the Toolchain tab on the left, go down to ARM/GNU Linker, then
select Libraries. In the upper box, add the archive as `libDivas` (using 
the green "+" button). Adjust it's position to be just above `libm` 
(using the up & down arrows). In the lower box, add the folder where
`libDivas.a` can be found; search path order is not important. Ensure
these changes are applied to all project build configurations (typically
"Debug" and "Release").
### Performance
All cases provide substantial speed improvement at reduced code size.
Execution time is typically reduced by roughly 50%, but this varies
with both operands and data type. For example, on just a few tests
the improvement for 64-bit integer divison was as much as 80% or as
little as 30%. Times for float and double were always improved by
at least 50% on a small number of test cases. (These test cases are
included in the TestDriver folder of the repository.)

This library shares code between functions, so savings in size increase
as you use more of it. The following table shows the number of bytes
saved by this library in comparison with the `libm` shipped with Atmel Studio
version 7.0.2397. 

| Types | Saved |
|_______| ___|
| uint32_t          | 248 |
| uint32_t, int32_t | 716 |
| uint64_t          | 340 |
| uint64_t, int64_t | 788 |
| float             | 437 |
| double            | 1384 |
| sqrtf(float)      | 6264 |
| sqrt(double)      | 10276 |
| All Functions     | 12264 |

### Repository Notes
Since this library specifically targets certain Microchip MCUs, it was
built with Microchip's Atmel Studio version 7. Project files are included.

There are two projects in the solution. At the top level is the Divas
library project, whose output is a standard GNU archive. In a subfolder
is the TestDriver project, which builds a fully-functional executable
that can be programmed into a SAM C20/C21 device.
#### Using the Test Driver
The test driver uses a SERCOM module to output results as a standard
asynchrous serial stream of text. The SERCOM module used is hard-coded
but could changed by finding all the references to it.

The output from the test driver uses `printf`. This is not the `printf`
that is in the standard libraries shipped with Atmel Studio. It is in an
archive called `libstdio-ll-dbl.a` and is included in the "lib" subfolder
of the TestDriver project. It provides support for devices (like SERCOM)
to be used as a stream for a C FILE. It's origin is
https://github.com/TimPaterson/stdio-mini .

Building TestDriver in the Debug solution configuration links it with the 
DIVAS library. Building it in the Release configuration does not, allowing 
comparisons between the two.
