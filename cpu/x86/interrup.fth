\ See license at end of file

\ The value of the flags register is on the return stack between
\ lock[ and ]unlock

code (lock)    ( -- )  pushf  ax pop   4 # rp sub   ax  0 [rp]  mov   cli  c;
code (unlock)  ( -- )  0 [rp]  ax  mov   4 # rp add  ax push  popf  c;

code (enable-interrupts)  ( -- )  sti  c;
code (disable-interrupts)  ( -- )  cli  c;

' (enable-interrupts) to enable-interrupts
' (disable-interrupts) to disable-interrupts
' (lock) to lock[
' (unlock) to ]unlock

code interrupts-enabled?  ( -- flag )
   ax ax xor		\ Assume false
   pushf  bx pop	\ Get EFLAGS into bx
   h# 200 # bx test  0<> if  ax dec  then   \ Test interrupt flag bit
   ax push
c;

\ Unconditional halt - stops instruction execution until an interrupt.
\ If interrupts are disabled, this could hang forever.
code halt  hlt  c;

\ Safe halt that is a no-op if interrupts are disabled
code ?halt  ( -- )
   pushf  ax pop
   h# 200 # ax  test  0<>  if  hlt  then
c;

\ You can install this in "key" to lower the idle power or to make
\ the system use fewer CPU cycles when running on an emulator.

: halting-key  ( -- )
   begin  key? 0=  while  ?halt  repeat
   (key
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
