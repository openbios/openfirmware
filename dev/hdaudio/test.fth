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
: connect-headphones  ( -- )
   headphone-jack pin-sense? 0= if
      ." Connect headphones to continue.. "
      begin  ?key-abort  pin-sense?  until  cr
   then
;
: disconnect-headphones  ( -- )
   headphone-jack pin-sense?  if
      ." Disconnect headphones to continue.. "
      begin  ?key-abort  pin-sense? 0=  until  cr
   then
;
: speaker-test  ( -- )
   disconnect-headphones
   2 to #channels
   ." Playing left to right sweep "
   make-sweep  0 set-volume  play  cr
;

: headphones-test  ( -- )
   2 to #channels
   connect-headphones
   speakers-off  \ turn off speaker
   make-sweep  -9 set-volume  play
   speakers-on   \ turn speaker back on
;

: louder-mic-test  ( -- )
   ." Recording ..." cr
   record
   ." Playing ..." cr
   d# 0 set-volume  play
;

: connect-mic
   external-mic pin-sense? 0= if
      ." Connect microphone to continue.. "
      begin  ?key-abort pin-sense?  until  cr
   then
;
: disconnect-mic  ( -- )
   external-mic pin-sense?  if
      ." Disconnect microphone to continue.. "
      begin  ?key-abort  pin-sense? 0=  until  cr
   then
;

: builtin-mic-test  ( -- )
   disconnect-mic
   ." Press a key to test recording / playback on the built-in microphone.. "
   key drop cr
   louder-mic-test
;

: external-mic-test  ( -- )
   connect-mic
   ." Press a key to test recording / playback on the external microphone.. "
   key drop cr
   mic-test
;

0 value analyzer-ih
: $call-analyzer  ( ? name$ -- ? )  analyzer-ih $call-method  ;
: open-analyzer  ( -- )
   analyzer-ih  0=  if
      " "  " audio-test" $open-package  to analyzer-ih
   then
;
: close-analyzer  ( -- )
   analyzer-ih  if
      analyzer-ih close-package
      0 to analyzer-ih
   then
;
: test-common  ( setup$ -- error? )
   $call-analyzer                    ( )
   " prepare-signal" $call-analyzer  ( pb /pb rb /rb )
   \ First time lets the input channel settle
   2over 2over out-in                ( pb /pb rb /rb )
   out-in                            ( )
   " analyze-signal" $call-analyzer  ( okay? )
;
: input-common-settings  ( -- )
   open-in  48kHz  16bit  with-adc d# 73 input-gain
;
: output-common-settings  ( -- )
   open-out 48kHz  16bit stereo
;
: test-with-case  ( -- )
   " setup-case" $call-analyzer
\   xxx - this needs to use the internal speakers and mic even though the loopback cable is attached
   true to force-speakers?  true to force-internal-mic?
   input-common-settings  mono
   output-common-settings  d# -9 set-volume
   " setup-case" test-common
   false to force-speakers?  false to force-internal-mic?
;
: test-with-fixture  ( -- error? )
   true to force-speakers?  true to force-internal-mic?
   input-common-settings  mono
   output-common-settings  d# -23 set-volume  \ -23 prevents obvious visible clipping
   " setup-fixture" test-common
   false to force-speakers?  false to force-internal-mic?

;
: test-with-loopback  ( -- error? )
   input-common-settings  stereo
   output-common-settings  d# -33 set-volume  \ -23 prevents obvious visible clipping
   " setup-loopback" test-common
;

0 value saved-volume
: (interactive-test)  ( -- error? )
   alloc-buffer
   headphones-test
   external-mic-test
   speaker-test
   builtin-mic-test
   dealloc-buffer
   " confirm-selftest?" eval
;
: interactive-test  ( -- )
   " playback-volume" evaluate to saved-volume
   0 " to playback-volume" evaluate
   ['] (interactive-test) catch  if  true  then
   saved-volume " to playback-volume" evaluate
;
: loopback-connected?  ( -- flag )
   headphone-jack pin-sense? external-mic pin-sense?  and
;
: loopback-disconnected?  ( -- flag )
   headphone-jack pin-sense? 0=  external-mic pin-sense? 0=  and
;
: connect-loopback  ( -- )
   loopback-connected?  0=  if  
      ." Connect loopback cable to continue.. "
      begin  ?key-abort  loopback-connected?  until  cr
   then
   d# 500 ms  \ Time to make sure the plug is all the way in
;
: disconnect-loopback  ( -- )
   loopback-disconnected?  0=  if  
      ." Disconnect loopback cable to continue.. "
      begin  ?key-abort  loopback-disconnected?  until  cr
   then
;
\ Returns failure by throwing
: automatic-test  ( -- )
   " smt-test?" evaluate  if
      test-with-fixture throw
   else
      test-with-case throw
   then
   connect-loopback
   test-with-loopback throw
   disconnect-loopback
;
: selftest  ( -- error? )
   diagnostic-mode?  if
      open 0=  if  ." Failed to open /audio" cr true exit  then
      open-analyzer
      ['] automatic-test catch  ( error? )
      close-analyzer   ( error? )
      close            ( error? )
   else
      selftest         ( error? )
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
