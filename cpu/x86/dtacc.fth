\ See license at end of file
purpose: Native hardware versions of descriptor table and vector access words

0 value idt-offset
d# 255 8 * constant /idt	\ Full size

: stand-idt  ( -- offset sel )  idt-offset  ds@  ;
: stand-gdt  ( -- offset sel )  gdtr@ drop  ds@  ;  \ Assumes DS = physical!

\ Create an Interrupt Descriptor Table, and install standalone versions of
\ GDT and IDT pointers in the gdt and idt defer words.

: make-idt  ( -- )
   /idt  alloc-mem  is idt-offset
   idt-offset /idt  0  fill
   idt-offset /idt idtr!
;

: stand-set-idt  ( -- )
   flat?  if
      ['] stand-idt is idt
      ['] stand-gdt is gdt
      ['] (ldt)        is ldt
      ['] (pm-vector!) is pm-vector!
      ['] (pm-vector@) is pm-vector@
      [ also hidden ]
      ['] save-state-common to save-state
      [ previous ]
      init-exceptions
   then
;

stand-init: Exceptions
   make-idt  stand-set-idt
;

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
