\ Intel HD Audio driver
\ See license at end of file

\ warning off
hex

\ \ Defers

\ detect-codec fills in the defers below to suit the available hardware
defer detect-codec

defer open-codec               ' noop to open-codec
defer close-codec              ' noop to close-codec
defer enable-codec-recording   ' noop to enable-codec-recording
defer disable-codec-recording  ' noop to disable-codec-recording
defer enable-codec-playback    ' noop to enable-codec-playback
defer disable-codec-playback   ' noop to disable-codec-playback

defer with-dac \ select digital to analogue converter node
defer with-adc \ select analogue to digital converter node

\ \ DMA setup

0 value au

my-address my-space encode-phys
0 encode-int encode+  0 encode-int encode+

0 0    my-space h# 0300.0010 + encode-phys encode+
0 encode-int encode+  h# 4000 encode-int encode+
" reg" property

: my-w@  ( offset -- w )  my-space +  " config-w@" $call-parent  ;
: my-w!  ( w offset -- )  my-space +  " config-w!" $call-parent  ;

: map-regs  ( -- )
    0 0 my-space h# 0300.0010 +  h# 4000  " map-in" $call-parent to au
    4 my-w@  6 or  4 my-w!
;
: unmap-regs  ( -- )
    4 my-w@  7 invert and  4 my-w!
    au h# 4000 " map-out" $call-parent
;

: dma-alloc    ( len -- adr )  " dma-alloc" $call-parent  ;
: dma-free     ( adr size -- )  " dma-free" $call-parent  ;
: dma-map-in   ( adr len flag -- adr )  " dma-map-in" $call-parent  ;
: dma-map-out  ( adr len -- )  " dma-map-out" $call-parent  ;

\ \ Register definitions

: icw        h# 60 au +  ; \ Immediate Command Write
: irr        h# 64 au +  ; \ Immediate Response Read
: ics        h# 68 au +  ; \ Immediate Command Status
: gctl       h# 08 au +  ;
: wakeen     h# 0c au +  ; \ Wake enable
: statests   h# 0e au +  ; \ Wake status
: counter    h# 30 au +  ; \ Wall Clock Counter
: ssync      h# 38 au +  ; \ Stream synchronization
: corblbase  h# 40 au +  ;
: corbubase  h# 44 au +  ;
: corbwp     h# 48 au +  ;  \ CORB write pointer (last valid command)
: corbrp     h# 4a au +  ;  \ CORB read pointer (last processed command)
: corbctl    h# 4c au +  ;
: corbsts    h# 4d au +  ;
: corbsize   h# 4e au +  ;
: rirblbase  h# 50 au +  ;
: rirbubase  h# 54 au +  ;
: rirbwp     h# 58 au +  ;
: rirbctl    h# 5c au +  ;
: rirbsts    h# 5d au +  ;
: rirbsize   h# 5e au +  ;
: dplbase    h# 70 au +  ;
: dpubase    h# 74 au +  ;

0 value time-limit
: set-time-limit  ( ms -- )   get-msecs  +  to time-limit  ;
: 1sec-time-limit  ( -- )  d# 1000 set-time-limit  ;
: ?timeout  ( -- )
   get-msecs  time-limit -  0>  if
      ." Audio device timeout!" cr
      abort
   then
;
: running?  ( -- ? )  gctl rl@ 1 and 0<> ;
: reset  ( -- )
   0 gctl rl!
   1sec-time-limit   begin  ?timeout  running? 0= until
;
: start  ( -- )
   1 gctl rl!
   1sec-time-limit  begin   ?timeout  running? until
;

\ \\ Stream Descriptors
\ Default: 48kHz 16bit stereo
0 value sample-base
0 value sample-mul
0 value sample-div
1 value sample-format
2 value #channels

variable  in-stream-format  h# 10 in-stream-format !  \ 48kHz 16bit mono
variable out-stream-format  h# 11 out-stream-format !  \ 48kHz 16bit stereo

defer selected-stream-format  ' out-stream-format to selected-stream-format

: stream-format  ( -- u )
   sample-base    d# 14 lshift      ( acc )
   sample-mul     d# 11 lshift  or  ( acc )
   sample-div     d#  8 lshift  or  ( acc )
   sample-format      4 lshift  or  ( acc )
   #channels 1-                 or  ( fmt )
;

: sample-rate!  ( base mul div -- )
   8 lshift  swap d# 11 lshift  or  swap d# 14 lshift  or  ( rate-code )
   selected-stream-format @  h# ffffff00 invert and  or  selected-stream-format !
;
: sample-width!  ( code -- )
   4 lshift
   selected-stream-format @  h# f0 invert and  or  selected-stream-format !
;
: channels!  ( #channels -- )
   1-
   selected-stream-format @  h# f invert and  or  selected-stream-format !
;

:   48kHz  ( -- )  0 0 0 sample-rate!  ;
: 44.1kHz  ( -- )  1 0 0 sample-rate!  ;
:   96kHz  ( -- )  0 1 0 sample-rate!  ;
:  192kHz  ( -- )  0 3 0 sample-rate!  ;

:  8bit  ( -- )  0 sample-width!  ;
: 16bit  ( -- )  1 sample-width!  ;
: 20bit  ( -- )  2 sample-width!  ;
: 24bit  ( -- )  3 sample-width!  ;
: 32bit  ( -- )  4 sample-width!  ;

: mono    ( -- )  1 channels!  ;
: stereo  ( -- )  2 channels!  ;

\ Stream descriptor register interface.
\ There are multiple stream descriptors, each with their own register set.
0 value sd#
: sd+  ( offset -- adr )  sd# h# 20 * + au +  ;

: sdctl    h# 80 sd+  ;
: sdsts    h# 83 sd+  ;
: sdlpib   h# 84 sd+  ;
: sdcbl    h# 88 sd+  ;
: sdlvi    h# 8c sd+  ;
: sdfifos  h# 90 sd+  ;
: sdfmt    h# 92 sd+  ;
: sdbdpl   h# 98 sd+  ;
: sdbdpu   h# 9c sd+  ;
: sdlicba  h# 2084 sd+  ;

\ \ CORB/RIRB command interface
\ DMA-based circular command / response buffers.

\ \\ CORB - Command Output Ring Buffer

d# 1024 constant /corb
0 value corb
0 value corb-phys
0 value corb-pos

: corb-dma-on   ( -- )  2 corbctl rb!  ;
: corb-dma-off  ( -- )
   0 corbctl rb!
   1sec-time-limit  begin  ?timeout  corbctl rb@  2 and 0= until
;

: init-corb  ( -- )
    /corb dma-alloc  to corb
    corb /corb 0 fill
    corb /corb true dma-map-in  to corb-phys
    corb-dma-off
    corb-phys corblbase rl!
    0 corbubase rl!
    2 corbsize rb!      \ 256 entries
    corbrp rw@ to corb-pos
    corb-dma-on
;

: wait-for-corb-sync  ( -- )
   1sec-time-limit
   begin  ?timeout corbrp rw@ corb-pos = until
;

: corb-tx  ( u -- )
    corb-pos 1+ d# 256 mod to corb-pos
    corb-pos cells corb + ! ( )
    corb-pos corbwp rw!
    wait-for-corb-sync
;

\ \\ RIRB - Response Inbound Ring Buffer

d# 256 2* cells constant /rirb
0 value rirb
0 value rirb-phys
0 value rirb-pos

: rirb-dma-off  ( -- )  0 rirbctl rb!  ;
: rirb-dma-on   ( -- )  2 rirbctl rb!  ;

: init-rirb  ( -- )
    rirb-dma-off
    /rirb dma-alloc  to rirb
    rirb /rirb 0 fill
    rirb /rirb true dma-map-in  to rirb-phys
    rirb-phys rirblbase rl!
    0 rirbubase rl!
    2 rirbsize rb! \ 256 entries
    rirbwp rw@ to rirb-pos
    rirb-dma-on
;

: rirb-data?  ( -- )  rirb-pos rirbwp rw@ <>  ;

: rirb-read  ( -- resp solicited? )
    1sec-time-limit  begin  ?timeout  rirb-data? until
    rirb-pos 1+ d# 256 mod to rirb-pos
    rirb-pos 2 * cells rirb +      ( adr )
    dup @                          ( adr resp )
    swap cell+ @                   ( resp resp-ex )
    h# 10 and 0=                   ( resp? solicited? )
;

: rirb-rx  ( -- )
    begin
        rirb-read ( resp solicited? )
        if  exit else ." unsolicited response: " . cr  then
    again
;

\ \ Commands to codecs

0 0  value codec value node  \ current target for commands

: encode-command  ( verb -- )
   codec d# 28 lshift  node d# 20 lshift  or or
;

: cmd?  ( verb -- resp )  encode-command corb-tx rirb-rx  ;
: cmd   ( verb --      )  cmd? drop  ;

\ \ Streams
\ \\ Starting and stopping channels

: assert-stream-reset    ( -- )
   1 sdctl rb!
   1sec-time-limit  begin  ?timeout  sdctl rb@ 1 and 1 =  until
;
: deassert-stream-reset  ( -- )
   0 sdctl rb!
   1sec-time-limit  begin  ?timeout  sdctl rb@ 1 and 0 =  until
;

: reset-stream  ( -- )  assert-stream-reset deassert-stream-reset  ;
: start-stream  ( -- )
   2 sdctl rb!
   1sec-time-limit  begin  ?timeout  sdctl rb@ 2 and  0<> until
;
: stop-stream   ( -- )
   0 sdctl rb!
   1sec-time-limit  begin  ?timeout  sdctl rb@ 2 and  0=  until
   4 sdsts rb! \ clear completion flag
;

defer playback-alarm
0 value alarmed?

: install-playback-alarm     ( -- )
   true to alarmed?  ['] playback-alarm d# 20 alarm
;
: uninstall-playback-alarm   ( -- )
   alarmed?  if
      ['] playback-alarm d#  0 alarm
      false to alarmed?
   then
;

\ \ Device open and close

: restart-controller  ( -- )  reset  start  1 ms ( 250us wait required )  ;
: init-controller     ( -- )  map-regs  restart-controller  init-corb  init-rirb  ;
: init-codec          ( -- )  detect-codec  open-codec  ;
: close-controller    ( -- )  reset  unmap-regs  ;

d# 48.000 value sample-rate
1 value scale-factor
: upsampling?  ( -- ? )  scale-factor 1 <>  ;

: low-rate?  ( Hz )  dup d# 48.000 <  swap d# 44.100 <>  and  ;

: set-sample-rate  ( Hz -- )
   dup to sample-rate  ( Hz )
   dup low-rate?  if   ( Hz )
      48kHz  d# 48.000 swap / to scale-factor
   else                ( Hz )
      1 to scale-factor
      d# 48.000 / case \ find nearest supported rate
         0   of  44.1kHz  endof
         1   of    48kHz  endof
         2   of    96kHz  endof
         3   of    48kHz   2 to scale-factor  endof
         dup of   192kHz  endof
      endcase
   then
;

0 value open-count
: open   ( -- flag )
   open-count 0=  if  init-controller  init-codec  then
   open-count 1+ to open-count
   true
;
: close  ( -- )
   open-count 1 =  if
      uninstall-playback-alarm  close-codec  close-controller
   then
   open-count 1- 0 max to open-count
;

\ \ Streams

\ \\ Sound buffer
\ Sample data for playback or recording.

0 value in-buffer
0 value in-buffer-phys
0 value /in-buffer

0 value out-buffer
0 value out-buffer-phys
0 value /out-buffer

: install-in-buffer  ( adr len -- )
   2dup  to /in-buffer  to in-buffer
   true dma-map-in to in-buffer-phys
;

: release-in-buffer  ( -- )
   in-buffer in-buffer-phys /in-buffer dma-map-out
;

: install-out-buffer  ( adr len -- )
   2dup  to /out-buffer  to out-buffer
   true dma-map-in to out-buffer-phys
;

: release-out-buffer  ( -- )
   out-buffer out-buffer-phys /out-buffer dma-map-out
   \ If we are upsampling, we allocated out-buffer so we need to free it.
   \ If not, the caller owns out-buffer.
   upsampling?  if  out-buffer /out-buffer dma-free  then
;

\ Pad buffer: filled with zeros to pad out the end of the stream.
\ (Streams automatically repeat -- this is so we'll have time to stop
\ before that happens.)

d# 8092 value /pad-buffer

0 value in-pad
0 value in-pad-phys

: alloc-in-pad  ( -- )
   /pad-buffer dma-alloc to in-pad
   in-pad /pad-buffer true dma-map-in to in-pad-phys
   in-pad /pad-buffer 0 fill
;

: free-in-pad  ( -- )
   in-pad in-pad-phys /pad-buffer dma-map-out
   in-pad /pad-buffer dma-free
;

0 value out-pad
0 value out-pad-phys

: alloc-out-pad  ( -- )
   /pad-buffer dma-alloc to out-pad
   out-pad /pad-buffer true dma-map-in to out-pad-phys
   out-pad /pad-buffer 0 fill
;

: free-out-pad  ( -- )
   out-pad out-pad-phys /pad-buffer dma-map-out
   out-pad /pad-buffer dma-free
;

\ \\ Buffer Descriptor List
 
struct  ( buffer descriptor )
    4 field >bd-laddr
    4 field >bd-uaddr
    4 field >bd-len
    4 field >bd-ioc
constant /bd

: set-buffer-descriptor  ( phys uaddr len ioc bd-adr -- )
   tuck >bd-ioc !  tuck >bd-len !  tuck >bd-uaddr !  >bd-laddr !
;

d# 256 /bd * value /bdl

0 value in-bdl
0 value in-bdl-phys

: in-buffer-descriptor  ( n -- adr )  /bd * in-bdl +  ;

: allocate-in-bdl  ( -- )
    /bdl dma-alloc to in-bdl
    in-bdl /bdl 0 fill
    in-bdl /bdl true dma-map-in to in-bdl-phys
;

: free-in-bdl  ( -- ) in-bdl in-bdl-phys /bdl dma-map-out   in-bdl /bdl dma-free ;

: setup-in-bdl  ( -- )
   allocate-in-bdl
   in-buffer-phys  0  /in-buffer   1   0 in-buffer-descriptor set-buffer-descriptor
   alloc-in-pad
   in-pad-phys     0  /pad-buffer  0   1 in-buffer-descriptor set-buffer-descriptor
;

: teardown-in-bdl  ( -- )  free-in-bdl free-in-pad  ;

0 value out-bdl
0 value out-bdl-phys

: out-buffer-descriptor  ( n -- adr )  /bd * out-bdl +  ;

: allocate-out-bdl  ( -- )
    /bdl dma-alloc to out-bdl
    out-bdl /bdl 0 fill
    out-bdl /bdl true dma-map-in to out-bdl-phys
;

: free-out-bdl  ( -- ) out-bdl out-bdl-phys /bdl dma-map-out   out-bdl /bdl dma-free ;

: setup-out-bdl  ( -- )
   allocate-out-bdl
   out-buffer-phys 0 /out-buffer 1  0 out-buffer-descriptor set-buffer-descriptor
   alloc-out-pad
   out-pad-phys    0 /pad-buffer 0  1 out-buffer-descriptor set-buffer-descriptor
;

: teardown-out-bdl  ( -- )  free-out-bdl free-out-pad  ;

\ \\ Stream descriptor (DMA engine)

: setup-out-stream  ( -- )
   reset-stream
   /out-buffer /pad-buffer + sdcbl rl! \ bytes of stream data
   h# 440000 sdctl rl!            \ stream 4
   1 sdlvi rw!                    \ two buffers
   1c sdsts rb!                   \ clear status flags
   out-bdl-phys  sdbdpl rl!
   0             sdbdpu rl!
   out-stream-format @  sdfmt  rw!
;

: stream-done?      ( -- )  sdsts c@ 4 and 0<>  ;
: wait-stream-done  ( -- )
   d# 20,000 set-time-limit  begin  ?timeout  stream-done?  until
;

\ \\ Upsampling

0 value src
0 value /src
0 value dst
0 value /dst
0 value upsample-factor

: dst!  ( value step# sample# -- )
   upsample-factor *  + ( value dst-sample# ) 4 * dst +  w!
;

\ Copy source sample N into a series of interpolated destination samples.
: copy-sample  ( n -- )
   dup 4 * src +              ( n src-adr )
   dup <w@  swap 4 + <w@     ( n s1 s2 )
   over - upsample-factor /  ( n s1 step )
   upsample-factor 0 do
      2dup i * +             ( n s1 step s )
      i  4 pick              ( n s1 step s i n )
      dst!
   loop
   3drop
;

: upsample-channel  ( -- )
   upsample-factor 6 =  if
      src /src dst 4 " 8khz>48khz" evaluate
   else
      /src 4 /  1 do  i copy-sample  loop
   then
;

: upsample  ( adr len factor -- adr len )
   to upsample-factor  to /src  to src
   /src upsample-factor * to /dst
   /dst dma-alloc to dst
   upsample-channel \ left
   src 2+ to src  dst 2+ to dst
   upsample-channel \ right
   dst 2- to dst             ( )
   dst /dst                  ( dst dst-len )
;

\ \\ Amplifier control

: output-gain  ( gain -- )  h# 3b000 or cmd  ;
: input-gain   ( gain -- )  h# 37000 or cmd  ;

: amp-caps  ( -- u )  h# f0012 cmd?  ;

: gain-steps  ( -- n )  amp-caps      8 rshift  h# 7f and  1+  ;  \ how many steps?
: step-size   ( -- n )  amp-caps  d# 16 rshift  h# 7f and  1+  ;  \ in units of -0.25dB
: 0dB-step    ( -- n )  amp-caps                h# 7f and  ;      \ which step is 0dB?

: steps/dB  ( -- #steps )     step-size 4 *  ;
: dB>steps  ( dB -- #steps )  -4 *  step-size /  ;
: dB>step#  ( dB -- step )    dB>steps 0dB-step swap -  ;

\ \\ Playback

4 constant out-sd

false value playing?

: open-out  ( -- )
   ['] out-stream-format to selected-stream-format
   d# 48.000 set-sample-rate
;

: start-audio-out  ( adr len -- )
   install-out-buffer  ( )
   setup-out-bdl
   out-sd to sd#
   setup-out-stream
   enable-codec-playback
   start-stream
   true to playing?
;
: audio-out  ( adr len -- actual ) 
   dup >r
   upsampling?  if  scale-factor upsample  then  ( adr len )
   start-audio-out
   r>                    ( actual )
;

: stop-out  ( -- )
   out-sd to sd#
   stop-stream
   teardown-out-bdl
   release-out-buffer
   uninstall-playback-alarm
   false to playing?  
;
: write-done  ( -- )  out-sd to sd#  wait-stream-done  stop-out  ;

: write  ( adr len -- actual )
   audio-out  install-playback-alarm
;

: ?end-playing  ( -- )
   out-sd to sd#  stream-done?  if  stop-out  then
;

false value stop-lock
: stop-sound  ( -- )
   true to stop-lock
   playing?  if  stop-out  then
   false to stop-lock
;

\ Alarm handle to stop the stream when the content has been played.
: playback-completed-alarm  ( -- )
   stop-lock  if  exit  then
   playing?  if
      ?end-playing
   else
      \ If playback has already stopped as a result of
      \ someone else having waited for completion, we
      \ just uninstall ourself.
      uninstall-playback-alarm
   then
;

' playback-completed-alarm is playback-alarm

: still-playing?  ( -- flag )
   playing?  0=  if  false exit  then
   stop-lock  if  true exit  then
   ?end-playing
   playing?
;

: wait-sound  ( -- )
   true to stop-lock
   begin  playing?  while   d# 10 ms  ?end-playing  repeat
   false to stop-lock
;

false value left-mute?
false value right-mute?

: set-volume  ( dB -- )
   with-dac
   dB>step#
   dup  left-mute?  if  h# 80 or  then  h# 3a000 or cmd  \ left gain
        right-mute? if  h# 80 or  then  h# 39000 or cmd  \ right gain
;

\ \\ Recording

0 constant in-sd
0 value recbuf
0 value recbuf-phys

: open-in  ( -- )
   ['] in-stream-format to selected-stream-format
   d# 48.000 set-sample-rate
;

: setup-in-stream  ( -- )
   in-sd to sd#
\   1 to #channels
   reset-stream
   /in-buffer /pad-buffer + sdcbl rl! \ buffer length
   h# 100000 sdctl rl!     \ stream 1, input
   1 sdlvi rw!             \ two buffers
   h# 1c sdsts c!          \ clear status flags
   in-bdl-phys sdbdpl rl!
   0 sdbdpu rl!
   in-stream-format @ sdfmt rw!
   with-adc
   h# 70610 cmd \ 706sc - stream 1, channel 0
   h# 20000 in-stream-format @ or cmd \ stream format
;

0 value recording?
: start-audio-in  ( adr len -- )
   install-in-buffer   ( )
   setup-in-bdl
   setup-in-stream
   enable-codec-recording
   start-stream
   true to recording?
;
: stop-in  ( -- )
   in-sd is sd#
   stop-stream
   teardown-in-bdl
   release-in-buffer
   false to recording?
;
: ?end-recording  ( -- )
   in-sd to sd#
   stream-done?  if  stop-in  then
;
: audio-in  ( adr len -- actual )
   start-audio-in
   wait-stream-done
   stop-in
   /in-buffer
;

: out-in  ( out-adr out-len in-adr in-len -- )
   upsampling?  if  2swap  scale-factor upsample  2swap  then  ( out-adr,len  in-adr,len )
   1 out-sd lshift  1 in-sd lshift  or  ssync rl!  \ Block the streams while setting up
   start-audio-in   ( out-adr out-len )
   start-audio-out  ( )
   0 ssync rl!      ( )        \ Unblock the streams to start them simultaneously
   begin
      recording?  if  ?end-recording  then
      playing?    if  ?end-playing    then
      recording? 0=  playing? 0=  and
   until
;

: close-in  ( -- )  disable-codec-recording  ;

: pbuf  " load-base 10000" evaluate  ;
: rbuf  " load-base 1meg + 20000" evaluate  ;
: bufs  ( -- pbuf,len rbuf,len )  pbuf rbuf  ;

0 value boost-db

: mic+20db  ( -- )  d# 20 to boost-db ;
: mic+0db   ( -- )      0 to boost-db ;

: set-record-gain  ( dB -- )  ; \ with-adc  step# input-gain  ;
: in-amp-caps  ( -- u )  h# f000d cmd?  ;
: in-gain-steps  ( -- n )  in-amp-caps  8 rshift h# 7f and  1+  ;
: set-record-gain  ( dB -- )  drop ( hardcoded for now ) with-adc  h# 40 input-gain  ;


\ LICENSE_BEGIN
\ Copyright (c) 2009 Luke Gorrie <luke@bup.co.nz>
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
