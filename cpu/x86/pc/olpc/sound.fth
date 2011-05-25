purpose: Manage startup sound, with persistent storage for its volume
\ See license at end of file

h# -9 constant default-volume
: set-saved-volume  ( volume -- )  dup h# 80 cmos!  invert h# 81 cmos!  ;

: get-saved-volume  ( -- volume )
   h# 80 cmos@  h# 81 cmos@   ( volume check )
   over xor  h# ff  <>  if     ( volume )
      drop default-volume  set-saved-volume
      default-volume
   then

   dup h# 80 and  if  \ Sign extend
      h# ffffff00 or
   else
      dup 0>  if
         drop default-volume  set-saved-volume
         default-volume
      then
   then
;

: +volume  ( increment -- )
   get-saved-volume +  0 min  d# -50 max  set-saved-volume
   audio-ih  if  get-saved-volume " set-volume" $call-audio  then
;
: softer  ( -- )  -2 +volume  ;
: louder  ( -- )   2 +volume  ;

: sound  ( -- )
   get-saved-volume  d# -50 <=  if  exit  then
   playback-volume >r  get-saved-volume to playback-volume
   ['] load-started behavior  >r
   ['] noop to load-started
   " rom:splash" ['] $play-wav catch  if  2drop  then
   r> to load-started
   r> to playback-volume
;
: close-audio  ( -- )
   audio-ih  if
      audio-ih close-dev
      0 to audio-ih
   then
;
: sound-end  ( -- )
   " wait-sound" ['] $call-audio catch  if  2drop  then
   free-wav
   close-audio
;
: stop-sound  ( -- )
   " stop-sound" ['] $call-audio catch  if  2drop  then
   free-wav
   close-audio
;

dev /keyboard
0 value waiting-up?
: olpc-check-abort  ( scan-code -- abort? )  \ Square pressed?
   last-scan   over to last-scan  ( scan-code old-scan-code )
   h# e0 <>  if  drop false exit  then          ( scan-code )

   check-abort?  0=  if  drop false exit  then  ( scan-code )

   dup h# 7f and  h# 5d <>  if  drop false exit then  ( scan-code )

   h# 80 and  if   \ Up
      false to waiting-up?
      false                             ( abort? )
   else
      secure?  if  false  else  waiting-up?  0=  then   ( abort? )
      true to waiting-up?
   then
;
patch olpc-check-abort check-abort get-scan

: handle-volume?  ( scan-code -- scan-code flag )
   dup h# 43 =  if  dimmer    true exit  then
   dup h# 44 =  if  brighter  true exit  then
   dup h# 57 =  if  softer    true exit  then
   dup h# 58 =  if  louder    true exit  then
   false
;
' handle-volume?  to scan-handled?
dend

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
