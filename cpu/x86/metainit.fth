\ See license at end of file
\ Metacompiler initialization

\ Debugging aids

0 #words ! th 2a0 threshold ! 10 granularity !

warning off
forth definitions

metaon
meta definitions

\ We want the kernel to be romable, so we put variables in the user area
:-h variable  ( -- )  nuser  ;-h
alias \m  \

initmeta

th 11000 alloc-mem  target-image  \ Allocate space for the target image

\ org sets the lowest address that is used by Forth kernel.
\ This number is a target token rather than an absolute address.
hex

0.0000 org  0.0000
   voc-link-t token-t!

ps-size-t equ ps-size

assembler

\ This is at the first location in the Forth image.

\ init-forth is the initialization entry point.  It should be called
\ exactly once, with arguments (dictionary_start, dictionary_size).
\ init-forth sets up some global variables which allow Forth to locate
\ its RAM areas, including the data stack, return stack, user area,
\ cpu-state save area, and dictionary.

hex
mlabel cld

\ boot.fth will store a jmp instruction to cold-code at this location,
\ so that the PharLap DOS extender may execute the Forth image directly
\ by jumping to its beginning address.
( offset 0 )   0 c,-t  0 l,-t

\ This byte is unused
( offset 5 )   0 c,-t

\ The Zortech loader will put a far pointer to EMACS at location 6
( offset 6 )   0 l,-t  0 w,-t

\ boot.fth will store the address of cold-code at this location.
\ The Zortech-based protected-mode loader reads this location to find the
\ place to begin execution.  Zortech's null-pointer detection prevents
\ the use of location zero.
( offset c )   0 l,-t

\ These location are used for the argc and argv values for the Zortech loader

( offset 10 )  0 l,-t  \ argc  (set by Zortech loader, read by cold-code)
( offset 14 )  0 l,-t  \ argv  (set by Zortech loader, read by cold-code)

( offset 18 )  0 l,-t  \ padding
( offset 1c )  0 l,-t  \ padding
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
