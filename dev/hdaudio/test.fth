purpose: Manufacturing testing
\ See license at end of file

: alloc-buffer  ( -- )
   record-len la1+  " dma-alloc" $call-parent to record-base
;
: dealloc-buffer  ( -- )
   record-base record-len la1+  " dma-free" $call-parent
;

: ?key-abort  ( -- )
   key?  if
      key h# 1b =  if  ." Aborting" abort  then
   then
;
: speaker-test  ( -- )
   h# 19 to node
   pin-sense?  if
      ." Disconnect headphones to continue.. "
      begin  ?key-abort  pin-sense? 0=  until  cr
   then
   ." Playing left to right sweep "
   make-sweep  0 set-volume  play  cr
;

: headphones-test  ( -- )
   h# 19 to node
   pin-sense? 0= if
      ." Connect headphones to continue.. "
      begin  ?key-abort  pin-sense?  until  cr
   then
   h# 1f to node  power-off  \ turn off speaker
   make-sweep  -9 set-volume  play
   h# 1f to node  power-on   \ turn speaker back on
;

: builtin-mic-test  ( -- )
   h# 1a to node
   pin-sense?  if
      ." Disconnect microphone to continue.. "
      begin  ?key-abort  pin-sense? 0=  until  cr
   then
   ." Press a key to test recording / playback on the built-in microphone.. "
   key drop cr
   mic-test
;

: external-mic-test  ( -- )
   h# 1a to node
   pin-sense? 0= if
      ." Connect microphone to continue.. "
      begin  ?key-abort pin-sense?  until  cr
   then
   ." Press a key to test recording / playback on the external microphone.. "
   key drop cr
   mic-test
;

0 value saved-volume
: interactive-test  ( -- error? )
   alloc-buffer
   headphones-test
   external-mic-test
   speaker-test
   builtin-mic-test
   dealloc-buffer
   " confirm-selftest?" eval
;
: selftest  ( -- )
   diagnostic-mode?  if
      open 0=  if  ." Failed to open /audio" cr true exit  then
      " playback-volume" evaluate to saved-volume
      0 " to playback-volume" evaluate
      ['] interactive-test catch  if  true  then
      saved-volume " to playback-volume" evaluate
      close
   else
      selftest
   then
;

\ LICENSE_BEGIN
\ Copyright (c) 2009 Luke Gorrie
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
