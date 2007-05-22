purpose: Setup and tests for suspend/resume to RAM
\ See license at end of file

stand-init:  Suspend/resume
   " resume" find-drop-in  if
      suspend-base swap move
      msr-init-range                    ( adr len )
      resume-data h# 34 + !             ( adr )
      >physical  resume-data h# 30 + !  ( )
   then
;

\ Useful for debugging suspend/resume problems
\ : sum-forth  ( -- )  0  here origin  do  i c@ +  loop  .  cr  ;

code ax-call  ( ax-value dst -- )  bx pop  ax pop  bx call  c;

: s3
   \ Enable wakeup from power button, also clearing
   \ any status bits in the low half of the register.
   h# 1840 pl@  h# 100.0000 or  h# 1840 pl!

\  sum-forth
   [ also dev /mmu ]  pdir-va  h# f0000 ax-call  [ previous definitions ]
\  sum-forth
;
: suspend
  " video-save" stdout @ $call-method  \ Freeze display
  s3
   " video-restore" stdout @ $call-method  \ Unfreeze display
   " /usb@f,5" open-dev  ?dup  if  " resume" 2 pick $call-method  close-dev  then
;
alias s suspend

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
