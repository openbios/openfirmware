\ See license at end of file
purpose: x86 real mode startup code.

command: &native &this
build-now

\ 386/486 processors begin executing at address ffff.fff0 in real mode
\ when they come out of reset.  Normally, that address would not be
\ accessable in real mode, but the processor does some magic things to
\ the Code Segment register so that the high order address lines are
\ "boosted" up to the ffff.xxxx range just after reset.  The "boosting"
\ persists until the CS register is modified (i.e. with a far jump).

\ The other segment register are not "boosted", so they can only access
\ the normal real mode range, essentially just the first megabyte.

\ The startup code must establish a Global Descriptor Table containing
\ suitable mappings, and then enter protected mode.  The space between
\ ffff.fff0 and the end of the ROM is insufficient to do this, so the
\ first few instructions must jump elsewhere, to a place where there
\ is enough room.

\ The code below is rather tricky, especially since the Forth assembler
\ always assumes 32-bit operand size and 32-bit addressing modes.
\ The code is executing in 16-bit mode, so the assembler must be used
\ carefully to ensure generation of the correct opcodes, and override
\ prefixes where necessary.


\needs start-assembling  fload ${BP}/cpu/x86/asmtools.fth
\needs write-dropin      fload ${BP}/forth/lib/mkdropin.fth

hex

start-assembling
protected-mode
hex

\ Addresses where the following items will be located in the processor's
\ physical address space:

\ ffff.fc00:  GDT  ( 3 entries ) + padding
\ ffff.fc20:  GDT address + size ( 6 bytes ) plus padding
\ ffff.fc28:  Startup code plus padding
\ ffff.fff0:  Reset entry point - jump to startup code plus padding to end

\ Assembler macros for startup diagnostics

\ write a byte to an ISA port
: risa-c!   ( n a - )  "  # dx mov  # al mov   al dx out " evaluate  ;

: num>asc  ( al: b -- al: low ah: hi )
   " al ah mov " evaluate
   " h# f # al and " evaluate
   " h# 9 # al cmp  >  if h# 57 # al add  else  h# 30 # al add  then " evaluate

   " ah shr  ah shr  ah shr  ah shr " evaluate	\ shift down four bits
   " h# f # ah and " evaluate
   " h# 9 # ah cmp  >  if h# 57 # ah add  else  h# 30 # ah add then " evaluate

   " al bl mov  ah al mov  bl ah mov " evaluate

;

[ifdef] debug-reset
.( debug reports enabled ) cr
\ Assembler macro to assemble code to send the character "char" to COM1
: report  ( char -- )
   " begin   3fd # dx mov   dx al in   20 # al and  0<> until" evaluate
   ( char )  " # al mov   3f8 # dx mov  al dx out  " evaluate
   " begin   3fd # dx mov   dx al in   20 # al and  0<> until" evaluate
;
\ Put character in al
: reportc
   " al ah mov " eval
   " begin   3fd # dx mov  dx al in   20 # al and  0<> until" evaluate
   ( char )  " ah al mov   3f8 # dx mov  al dx out  " evaluate
   " begin   3fd # dx mov  dx al in   20 # al and  0<> until" evaluate
;
: init-com1  ( -- )
    1 3fc  risa-c!	\ DTR on
   80 3fb  risa-c!	\ Switch to bank 1 to program baud rate
   01 3f8  risa-c!	\ Baud rate divisor low - 115200 baud
    0 3f9  risa-c!	\ Baud rate divisor high - 115200 baud
    3 3fb  risa-c!	\ 8 bits, no parity, switch to bank 0
;

[else]
: report    ( char -- )  drop  ;
: reportc  ( -- )    ;
[then]

hex

\ odds for testing, evens for release
d# 8 constant loader-version#	\ monotonic
2 constant loader-format#	\ >1 when crc present

.( ROM loader: version# ) loader-version# .d
.( , format# )  loader-format#  .d cr

\ Real Mode Startup

hex

label rm-startup	\ Executes in real mode with 16-bit operand forms

   \ ffff.fc00	GDT

   0    w,  0         l,	 0      w,  \ 0 Mandatory null descriptor
   0    w,  0         l,	 0      w,  \ * Another null descriptor
   ffff w,  9b.000000 l,  00.c.f w,  \ 10 Code, linear=physical, full 4Gbytes
   ffff w,  93.000000 l,  00.c.f w,  \ 18 Data, linear=physical, full 4Gbytes

   \ ffff.fc20	GDT limit + address

   1f w,  ffff.fc00 l,	\ # slots (4 * 8 - 1) ,  starting address
   0  w,		\ Padding

   \ ------->>>>> Startup code, reached by branch from main entry point below
   \
   \ ffff.fc28

   here		\ Mark the beginning of this code so its size may be determined
		\ and so that a jump to it may be assembled later.

   real-mode

   h# 01 # al mov  al h# 80 out

   \ This code is highly optimized because it runs when the CPU is in
   \ it slowest operation mode, so we want to get it done fast.
   \ GLCP_SYS_RSTPLL - page 406
   \ If the PLL is already set up, we don't redo the 5536 setup
   op: h# 4c000014 # cx mov   rdmsr     \ MSR value in dx,ax
   al bl mov
   op: h# fc00.0000 # ax and  0=  if    \ Start the PLL if not already on

      h# 0017 # cx mov  rdmsr    \ Read CHIP_REVID
      h# 0014 # cx mov           \ Restore RSTPLL MSR number
      h# 30 # al cmp  >=  if     \ LX CPU
         rdmsr                             \ Get base MSR value with divisors
         op: h# 04de.0000 # ax or          \ Set the startup time (de) and breadcrumb (4)
         wrmsr                             \ Put in the base value
         op: h# 0000.1800 invert # ax and  \ Turn off the BYPASS bits
      else                       \ GX CPU
         op: dx dx xor                     \ Clear high bits
         op: h# 04de.0000 # ax mov         \ Low MSR bits

         \ The BOOTSTRAP_STAT bits (mask 70) read the straps that tell
         \ us the board revision.  ID 5 is preB1, ID7 is B1.  ID0 is B2.
         h# 70 # bl and  h# 50 # bl cmp  <  if  \ B2 or later
            h# 220 # dx mov             \ Divisor code for 66 MHz REFCLK
         else                                   \ earlier than B2
            h# 226 # dx mov             \ Divisor code for 33 MHz REFCLK
         then
         wrmsr                          \ Establish base MSR value
      then
      h# 6001 # ax or                   \ Set PD, RESETPLL
      wrmsr                             \ Start the PLL and reset the CPU

[then]
   then

   \ Return to here after the reset
   h# 02 # al mov  al h# 80 out

[ifdef] init-com1      init-com1      [then]

[ifdef] debug-reset
carret report	 \ send it to com1 if you can...
linefeed report  \ send it to com1 if you can...
ascii F report	 \ send it to com1 if you can...
[then]

   \ The following instruction uses the CS: segment override because
   \ that segment is currently "boosted" up into the ROM space.
   \ It uses the operation size override to load a 32-bit pointer.
   \ The address override is not used; the GDT limit/address data structure
   \ above is reachable with a 16-bit address and through the "boosted"
   \ code segment.
      
   op: cs:  0f c, 01 c, 16 c, fc20 w,	\ lgdte  cs:[fc20]   Setup GDT

   op: cr0  bx  mov	\ Get existing CR0 value

   1 #  bl  or		\ Set "protected mode" bit

   bx  cr0  mov		\ Enter protected mode
   eb c, 0 c,		\ jmp to next location to flush prefetch queue
                        \ note: CPL is now 0

   h# 03 # al mov  al h# 80 out

   \ We are in protected mode, but we are still executing from old
   \ 16-bit code segment, and will continue to do so until the far jump
   \ below

[ifdef] debug-reset
ascii o report
[then]

   \ set segment registers
   bx   bx  xor			\ Clear high byte
   18 # bl  mov			\ Data segment selector
   bx   ds  mov			\ Set segment register
   bx   es  mov			\ Set segment register
   bx   fs  mov			\ Set segment register
   bx   gs  mov			\ Set segment register

[ifdef] debug-reset
ascii r report
[then]

   bx   ss  mov			\ Set segment register

[ifdef] debug-reset
ascii t report
ascii h report
[then]

   h# 0f # al mov  al h# 80 out
   op: ad: ResetBase h# 10 #)  far jmp	\ Jump to Forth startup

   real-mode

   \ Pad the startup code so that the main entry point ends up at the
   \ correct address.

   here over -   ( adr , size-of-preceding-code )

   \ ffff.fc28 is the location of the code that follows the GDT
   ffff.fff0 ffff.fc28 - swap - ( address #bytes-to-pad )

   \ The code mustn't extend past ffff.ffc0, because that is where PC
   \ manufacturers put the 0x10-byte BIOS version string.
   dup h# 30 -  also forth 0< previous abort" Real mode startup code is too big"

   also forth  here over h# ff fill  previous	\ fill with FFs
   ( #bytes-to-pad ) allot	\ Pad out to ffff.fff0

   \ ------->>>>> Main Entry Point
   \ 
   \ ffff.fff0 - This is the hardwired address where the processor jumps
   \             when it comes out of reset

   cli cld		\ Turn off interrupts (does not affect NMI)
   #) jmp		\ Relative jump back to ffff.fc28
   0 w, 0 c,		\ align "pad" to end of ROM
   loader-version# l,	\ version#
   loader-format#  w,	\ "format" (>1 when crc present)
   ffff w,		\ placeholder for crc

end-code

end-assembling

writing rmstart.img
rm-startup here over - ofd @ fputs
ofd @ fclose

here rm-startup - constant /rm-startup
/rm-startup h# 400 <>  abort" Real mode startup code is not the right size"

\ LICENSE_BEGIN
\ Copyright (c) 2006 FirmWorks
\ 
\ Permission is hereby granted, free of charge, to any person obtaining
\ a copy of this software and associated documentation files (the
\ "Software"), to deal in the Software without restriction, including
\ without limitation the rights to use, copy, modify, merge, publish,
\ distribute, sublicense, and/or sell copies of the Software, and to
\ permit persons to whom the Software is furnished to do so, subject to
\ the following conditions:
\ 
\ The above copyright notice and this permission notice shall be
\ included in all copies or substantial portions of the Software.
\ 
\ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
\ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
\ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
\ NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
\ LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
\ OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
\ WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
\
\ LICENSE_END
