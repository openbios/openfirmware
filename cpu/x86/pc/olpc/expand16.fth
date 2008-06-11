purpose: Display a 16bpp image expanded by 2x
\ See license at end of file

\ This code has the OLPC display dimensions hardcoded

code expand-image  ( src dst --- )
   0 [sp] edi xchg
   4 [sp] esi xchg
   d# 450 # edx mov
   begin
      d# 80 # esi add   \ Skip left edge of camera image
      d# 600 # cx mov   \ Number of doubled scan lines
      begin
         op: ax lods                \ Get a pixel
         op: ax d# 2400 [edi] mov   \ Write to next line
         op: ax stos                \ Write to this line + increment
         op: ax d# 2400 [edi] mov   \ Write to next line
         op: ax stos                \ Write to this line + increment
      loopa
      d# 2400 # edi add             \ Skip the next output line - already written
      edx dec
   0= until
   edi pop
   esi pop
c;
: expand-to-screen  ( src -- )  frame-buffer-adr expand-image  ;

\ LICENSE_BEGIN
\ Copyright (c) 2008 FirmWorks
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
