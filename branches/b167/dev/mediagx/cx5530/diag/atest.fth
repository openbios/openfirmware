\ See license at end of file
purpose: Run audio diagnostics

headers
hex
\ ************************************************************************
\ The audio diagnostics requires that the audio driver is opened and it
\ makes use of data, structure, and methods provided by the driver.
\ This code does not work on P0 dovers because they are not wired to allow
\ this test to work.  Also, all audio I/O devices must be removed from all
\ the audio connectors.
\ ************************************************************************

fload ${BP}/dev/mediagx/cx5530/diag/ecode.fth	\ Error code place holders

/dma-buf constant dma-size	\ must be larger then #sxvect*4
dma-size 4 / constant #out-samples
1000 4* constant /skip		\ /skip+#sxvect*4 <= dma-size
0 value in-data-buf		\ audio in data buffer

\ *************************************************************************
\ Create a tone of the given frequency and duration using sine function.
\ *************************************************************************

: s+s  ( s1 a -- s1+[a] )  <w@ +  ;
: def-wave>>  ( s -- s' )  7fff min  ;
: 2wave>>  ( s -- s' )  2/  ;
: 4wave>>+  ( a s -- a s' )  2/ 2/ over s+s  ;
defer ?wave>>+              ' def-wave>> to ?wave>>+

bit/fraction d# 30 =  [if]
: sround  ( n -- n' )  
   dup 0=  if  exit  then
   dup 0< swap abs 4000 + d# 15 >> ffff and
   dup 8000 =  if  drop 7fff  then
   swap  if  negate  then
;
: wave  ( adr #samples frequency -- )
   h# 4.0000 um* frame-rate um/mod nip
   swap 0  do				( adr 40000*f/48k )
      over i la+ over			( adr 40000*f/48k adr' 40000*f/48k )
      i u* sin sround		    	( adr 40000*f/48k adr s )
      ?wave>>+				( adr 40000*f/48k adr s' )
      dup wljoin swap !			( adr 40000*f/48k )
   loop  2drop
;
[else]
: sround  ( n -- n' )  
   dup 0=  if  exit  then
   dup 0< swap abs 1+ 2/ swap
   if  negate 1+  else  1-  then
;
: wave  ( adr #samples frequency -- )
   d# 16 << d# 360 um* frame-rate um/mod nip
   swap 0  do				( adr 360*f/48k )
      over i la+ over			( adr 360*f/48k adr' 360*f/48k )
      i um* d.f2>n.f sin sround    	( adr 360*f/48k adr s )
      ?wave>>+				( adr 360*f/48k adr s' )
      dup wljoin swap !			( adr 360*f/48k )
   loop  2drop
;
[then]

\ *************************************************************************
: setup-playback  ( -- )
   0000 1c codec!		\ record gain
   0808 18 codec!		\ pcm gain
   0000  2 codec!		\ master volume
\   0000  6 codec!		\ mono volume
;
14 constant mic-gain
: setup-mic1-playback  ( -- )
   0000 1a codec!		\ record select mic
   0000 20 codec!		\ mic1 select
   mic-gain e codec!		\ mic volume
   setup-playback
;

: setup-mic2-playback  ( -- )
   0000 1a codec!		\ record select mic
   0100 20 codec!		\ mic2 select
   mic-gain e codec!		\ mic volume
   setup-playback
;

: setup-linein-playback  ( -- )
   0404 1a codec!		\ record select line in
   setup-playback
;

: mute  ( -- )
   8000  2 codec!		\ mute master volume
   8000  6 codec!		\ mute master volume mono
   8000  a codec!		\ mute pcbeep
   8008  c codec!		\ mute phone volume  (NC)
   8008  e codec!		\ mute mic volume
   8808 10 codec!		\ mute line in volume
   8808 12 codec!		\ mute CD volume (NC)
   8808 14 codec!		\ mute video volume (NC)
   8808 16 codec!		\ mute aux volume (NC)
   8808 18 codec!		\ mute PCM volume
   8000 1c codec!		\ mute record gain
;

false value got-eop?
false value got-real-data?
: get-real-data  ( -- )
   true to got-real-data?
   cur-dma-in >dma-in-entry in-data-buf /dma-buf move
   ['] noop to audio-in-hook
;
: set-got-eop  ( -- )
   true to got-eop?
   false to got-real-data?
   ['] get-real-data to audio-in-hook
;

: test-audio-playback  ( -- adr )

   \ Init audio out PRDs only.  Audio in has an ongoing PRDs loop.
   dma-size eop eot or 0 set-prd-out-flags-len
   prd-out-phys false 0 set-dma

   false to got-eop?
   ['] set-got-eop to audio-in-hook
   ?install-audio-alarm

   begin  got-eop? audio-in-timeout? or  until		\ wait for an eop
   audio-in-timeout?  if  .audio-in-timeout abort  then

   0 dma-go

   begin  got-real-data? audio-in-timeout? or  until	\ wait for next eop
   audio-in-timeout?  if  .audio-in-timeout abort  then

   0 dma-wait
   0 dma-done

   in-data-buf /skip +		( adr )
;

: clear-out-buf  ( -- )  dma-out-virt dma-size erase  ;

\ Send nothing for long enough for things to settle down
: quiet  ( -- )  clear-out-buf test-audio-playback drop  ;

: test-out  ( -- )
   open-out
   init-prds-out
   dma-size eop eot or 0 set-prd-out-flags-len
   prd-out-phys false 0 set-dma
   0 dma-go
   0 dma-wait
   0 dma-done
;

\ *************************************************************************
: use-mag  ( -- )
   d# 7 to min-log
   d# 3 to scale-log
   ['] (dump-mag) to dump-mag
   ['] small-plot-mag to small-plot-mag-buf
;
: use-db  ( -- )
   d# 22 to min-log
   d#  7 to scale-log
   ['] (dump-db) to dump-mag
   ['] small-plot-db to small-plot-mag-buf
;

: init-test-.5wave  ( f -- )
   to freq1  h# 3fff to mag1
   ['] 2wave>> to ?wave>>+
   dma-out-virt #out-samples freq1 wave
   ['] def-wave>> to ?wave>>+
;

: init-test-1wave  ( f -- )
   to freq1  h# 7fff to mag1
   ['] def-wave>> to ?wave>>+
   dma-out-virt #out-samples freq1 wave
;

: init-test-2wave  ( -- )
   d#  1125 to freq2  h# 3fff to mag2
   d# 12000 to freq1  h# 1fff to mag1
   ['] 2wave>> to ?wave>>+
   dma-out-virt #out-samples freq2 wave
   ['] 4wave>>+ to ?wave>>+
   dma-out-virt #out-samples freq1 wave
   ['] def-wave>> to ?wave>>+
;

: init-test-impulse  ( -- )
   #sxvect 2/ idx>hz to freq1
   h# 7fff to mag1
   clear-out-buf
   h# 7fff.7fff dma-out-virt #sxvect 2/ la+ !
;

: zero-out-channel  ( left? -- )
   if  ['] lsample!  else  ['] rsample!  then  to s!
   dma-size 4 / 0  do  0 dma-out-virt i s!  loop
;

\ ***************************************************************************
: run-test-noise  ( -- error? )
   use-mag
   ['] check-snr to preprocess-input
   ['] check-noise to process-result

   quiet
   0 init-test-1wave  0 to mag1
   test-audio-playback
   left? check-result
;

: (run-test-loss)  ( hz -- error? )
   use-mag
   ['] no-preprocess-input to preprocess-input
   ['] check-loss to process-result

   quiet
   init-test-.5wave
   test-audio-playback
   left? check-result
;

: run-test-loss  ( -- error? )
   d#   375 (run-test-loss)
   d# 12000 (run-test-loss) or
;

: run-test-freq-resp  ( -- error? )
   use-db
   ['] no-preprocess-input to preprocess-input
   ['] check-freq-resp to process-result

   quiet
   init-test-impulse
   test-audio-playback
   left? check-result
;

: run-test-distort  ( -- error? )
   use-mag
   ['] no-preprocess-input to preprocess-input
   ['] check-distort to process-result

   quiet
   init-test-2wave
   test-audio-playback
   left? check-result
;

: (run-test-cross-talk)  ( hz -- error? )
   use-mag
   ['] check-snr to preprocess-input
   ['] check-cross-talk to process-result

   quiet
   init-test-1wave  0 to freq1  0 to mag1
   left? zero-out-channel
   test-audio-playback
   left? check-result
;

: .cross-talk-hz  ( hz -- )
   verbose?  if
      ." At " .d ." Hz,  "
   else
      drop
   then
;
: run-test-cross-talk  ( -- error? )
   d#   375 dup .cross-talk-hz  (run-test-cross-talk)
   d# 12000 dup .cross-talk-hz  (run-test-cross-talk) or
;

\ ***************************************************************************
: .failed?  ( error? -- error? )  dup  if  ." NOT "  then  ." OK"  cr  ;
: run-test-suite  ( -- error? )
   ."       Noise detection:    "
   run-test-noise .failed?		( error? )
   dup  if  ec1  then

   ."       Loss measurement:   "
   run-test-loss .failed?		( error? error? )
   dup  if  ec2  then  or		( error? )

   ."       Frequency response: "
   run-test-freq-resp .failed?		( error? error? )
   dup  if  ec3  then  or		( error? )

   ."       Cross talk:         "
   run-test-cross-talk .failed?		( error? error? )
   dup  if  ec5  then  or		( error? )

   ."       Distortion:         "
   run-test-distort .failed?		( error? error? )
   dup  if  ec4  then  or		( error? )
;

\ ***************************************************************************
: test-linein-playback  ( left? -- error? )
   to left?

   left?  if  
      set-line-in-errors-left
   else
      set-line-in-errors-right
   then

   setup-linein-playback
   run-test-suite
   mute
;

: test-mic1-playback  ( -- error? )
   true to left?
   setup-mic1-playback
   run-test-suite
   mute
;

: test-mic2-playback  ( -- error? )
   false to left?
   setup-mic2-playback
   run-test-suite
   mute
;

\ ***************************************************************************
: test-left-noise  ( -- error? )
   true to left?
   setup-linein-playback
   run-test-noise
   mute
;
: test-left-loss  ( hz -- error? )
   true to left?
   setup-linein-playback
   (run-test-loss)
   mute
;
: test-left-freq-resp  ( -- error? )
   true to left?
   setup-linein-playback
   run-test-freq-resp
   mute
;
: test-left-distort  ( -- error? )
   true to left?
   setup-linein-playback
   run-test-distort
   mute
;
: test-left-cross-talk  ( hz -- error? )
   true to left?
   setup-linein-playback
   (run-test-cross-talk)
   mute
;
: test-right-noise  ( -- )
   false to left?
   setup-linein-playback
   run-test-noise
   mute
;
: test-right-loss  ( hz -- error? )
   false to left?
   setup-linein-playback
   (run-test-loss)
   mute
;
: test-right-freq-resp  ( -- error? )
   false to left?
   setup-linein-playback
   run-test-freq-resp
   mute
;
: test-right-distort  ( -- error? )
   false to left?
   setup-linein-playback
   run-test-distort
   mute
;
: test-right-cross-talk  ( hz -- error? )
   false to left?
   setup-linein-playback
   (run-test-cross-talk)
   mute
;

: (test-mic-noise)  ( -- )
   run-test-noise
   mute
;
: test-mic1-noise  ( -- )
   true to left?
   setup-mic1-playback
   (test-mic-noise)
;
: test-mic2-noise  ( -- )
   false to left?
   setup-mic2-playback
   (test-mic-noise)
;

: test-mic1-loss  ( hz -- error? )
   true to left?
   setup-mic1-playback
   (run-test-loss)
   mute
;
: test-mic1-freq-resp  ( -- error? )
   true to left?
   setup-mic1-playback
   run-test-freq-resp
   mute
;
: test-mic1-distort  ( -- error? )
   true to left?
   setup-mic1-playback
   run-test-distort
   mute
;
: test-mic1-cross-talk  ( hz -- error? )
   true to left?
   setup-mic1-playback
   (run-test-cross-talk)
   mute
;
: test-mic2-loss  ( hz -- error? )
   false to left?
   setup-mic2-playback
   (run-test-loss)
   mute
;
: test-mic2-freq-resp  ( -- error? )
   false to left?
   setup-mic2-playback
   run-test-freq-resp
   mute
;
: test-mic2-distort  ( -- error? )
   false to left?
   setup-mic2-playback
   run-test-distort
   mute
;
: test-mic2-cross-talk  ( hz -- error? )
   false to left?
   setup-mic2-playback
   (run-test-cross-talk)
   mute
;

\ ***************************************************************************
: test-audio  ( -- error? )
[ifdef] skip-mic-if-ok
   ."   Line-in left-channel testing ..." cr
   true test-linein-playback dup  if
      \ No sense testing mic1 if linein left channel looks ok.
      \ If linein left channel looks bad, mic1 test provides
      \ the data for isolating linein versus lineout problem.
      ."   Mic1 testing ..." cr
      set-mic1-in-errors
      test-mic1-playback  drop
   then
   ."   Line-in right-channel testing ..." cr
   false test-linein-playback dup  if
      \ No sense testing mic2 if linein right channel looks ok.
      \ If linein left channel looks bad, mic1 test provides
      \ the data for isolating linein versus lineout problem.
      ."   Mic2 testing ..." cr
      set-mic2-in-errors
      test-mic2-playback  drop
   then
   or
[else]
   ."   Line-in left-channel testing ..." cr
   true test-linein-playback
   ."   Line-in right-channel testing ..." cr
   false test-linein-playback or
   ."   Mic1 testing ..." cr
   set-mic1-in-errors
   test-mic1-playback or
   ."   Mic2 testing ..." cr
   set-mic2-in-errors
   test-mic2-playback or
[then]
;

warning @ warning off
: alloc-test-buffers  ( -- )
   alloc-test-buffers
   dma-size alloc-mem to in-data-buf
;
: free-test-buffers  ( -- )
   free-test-buffers
   in-data-buf dma-size free-mem
;
warning !

: init-test  ( -- )
   " screen-ih" $find  if  behavior to my-screen-ih  then
   alloc-test-buffers
   init-prds-out
   mute
;

: (selftest)  ( -- error? )
   ." Please unplug all audio devices." cr
   init-test
   test-audio
   free-test-buffers
;

: selftest  ( -- error? )
   open  0=  if  ." Failed to open audio device." cr exit  then
   (selftest)
   close
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
