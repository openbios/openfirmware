purpose: Generic tools for load image handlers
\ See license at end of file

: +base  ( n -- adr )  load-base +  ;

: (init-program)  ( pc sp -- )
   clear-save-area  state-valid on
   \ PowerPC calling conventions store the link register at SP+8,
   \ so we start with r1 a little below the top of the allocated region
   h# 20 - to %r1  to %pc
   cif-handler to %r5

   msr@  interrupt-enable-bit invert and  to %msr

   restartable? on
   true to already-go?
;

dev /client-services
: chain  ( len args entry size virt -- )
   release                                       ( len args entry )
   h# 8000 alloc-mem h# 8000 +  (init-program)   ( len args )
   to %r6  to %r7
   go
;
device-end

\ LICENSE_BEGIN
\ Copyright (c) 2007 FirmWorks
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
