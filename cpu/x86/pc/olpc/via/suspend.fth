purpose: Setup and tests for suspend/resume to RAM
\ See license at end of file

stand-init:  Suspend/resume
   " resume" find-drop-in  if
      suspend-base swap move
   then
;

\ Useful for debugging suspend/resume problems
\ : sum-forth  ( -- )  0  here origin  do  i c@ +  loop  .  cr  ;

code ax-call  ( ax-value dst -- )  bx pop  ax pop  bx call  c;

: batlow-wakeup  ( -- )  h# 22 acpi-w@  h# 1000 or  h# 22 acpi-w!  ;
: ebook-wakeup   ( -- )  h# 22 acpi-w@  h# 0100 or  h# 22 acpi-w!  ;
: lid-wakeup     ( -- )  h# 22 acpi-w@  h# 0800 or  h# 22 acpi-w!  ;
: sci-wakeup     ( -- )  h# 22 acpi-w@  h# 0002 or  h# 22 acpi-w!  ;

: s3
   ['] noop to stdin-idle  \ Until we work out how to restore interrupt delivery

   \ Enable wakeup from power button, also clearing
   \ any status bits in the low half of the register.
   0 acpi-l@ h# 100.0000 or  0 acpi-l!

\  sum-forth
[ifdef] virtual-mode
   [ also dev /mmu ]  pdir-va  h# f0000 ax-call  [ previous definitions ]
[else]
   sp@ 4 -  h# f0000 ax-call  \ sp@ 4 - is a dummy pdir-va location
[then]
\  sum-forth
;
: kb-suspend  ( -- )
   sci-wakeup
   begin
      begin  1 ms key?  while  key  dup [char] q = abort" Quit"  emit  repeat
      s3
   again   
;
: s3-suspend
   audio-ih  if  audio-ih close-dev  0 to audio-ih  then
   " video-save" screen-ih $call-method  \ Freeze display
   s3
   " video-restore" screen-ih $call-method  \ Unfreeze display
\   " /usb@f,5" open-dev  ?dup  if  " do-resume" 2 pick $call-method  close-dev  then
;
alias s s3-suspend

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
