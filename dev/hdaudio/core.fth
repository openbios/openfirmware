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

0 value dac \ digital to analogue converter node id
0 value adc \ analogue to digital converter node id 

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

: running?  ( -- ? )  gctl rl@ 1 and 0<> ;
: reset  ( -- )  0 gctl rl!  begin running? 0= until ;
: start  ( -- )  1 gctl rl!  begin running? until ;

\ \\ Stream Descriptors
\ Default: 48kHz 16bit stereo
0 instance value sample-base
0 instance value sample-mul
0 instance value sample-div
1 instance value sample-format
2 instance value #channels

: stream-format  ( -- u )
   sample-base    d# 14 lshift      ( acc )
   sample-mul     d# 11 lshift  or  ( acc )
   sample-div     d#  8 lshift  or  ( acc )
   sample-format      4 lshift  or  ( acc )
   #channels 1-                 or  ( fmt )
;

: sample-rate!  ( base mul div )  to sample-div to sample-mul to sample-base  ;

:   48kHz  ( -- )  0 0 0 sample-rate!  ;
: 44.1kHz  ( -- )  1 0 0 sample-rate!  ;
:   96kHz  ( -- )  0 1 0 sample-rate!  ;
:  192kHz  ( -- )  0 3 0 sample-rate!  ;

:  8bit  ( -- )  0 to sample-format  ;
: 16bit  ( -- )  1 to sample-format  ;
: 20bit  ( -- )  2 to sample-format  ;
: 24bit  ( -- )  3 to sample-format  ;
: 32bit  ( -- )  4 to sample-format  ;

\ Stream descriptor register interface.
\ There are multiple stream descriptors, each with their own register set.
0 instance value sd#
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
: corb-dma-off  ( -- )  0 corbctl rb!  begin corbctl rb@  2 and 0= until  ;

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

: wait-for-corb-sync  ( -- )  begin corbrp rw@ corb-pos = until  ;

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
    begin rirb-data? until
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

: encode-command  ( codec node verb -- )
   codec d# 28 lshift  node d# 20 lshift  or or
;

: cmd?  ( verb -- resp )  encode-command corb-tx rirb-rx  ;
: cmd   ( verb --      )  cmd? drop  ;

\ \ Streams
\ \\ Starting and stopping channels

: assert-stream-reset    ( -- )  1 sdctl rb!  begin  sdctl rb@ 1 and 1 =  until  ;
: deassert-stream-reset  ( -- )  0 sdctl rb!  begin  sdctl rb@ 1 and 0 =  until  ;

: reset-stream  ( -- )  assert-stream-reset deassert-stream-reset  ;
: start-stream  ( -- )  2 sdctl rb! begin  sdctl rb@ 2 and  0<> until  ;
: stop-stream   ( -- )
   0 sdctl rb! begin  sdctl rb@ 2 and  0=  until
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

d# 48.000 instance value sample-rate
1 instance value scale-factor

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

0 value sound-buffer
0 value sound-buffer-phys
0 value /sound-buffer

: install-sound-buffer  ( adr len -- )
   2dup  to /sound-buffer  to sound-buffer
   true dma-map-in to sound-buffer-phys
;

\ Pad buffer: filled with zeros to pad out the end of the stream.
\ (Streams automatically repeat -- this is so we'll have time to stop
\ before that happens.)

0 value pad-buffer
0 value pad-buffer-phys
d# 8092 value /pad-buffer

: alloc-pad-buffer  ( -- )
   /pad-buffer dma-alloc to pad-buffer
   pad-buffer /pad-buffer true dma-map-in to pad-buffer-phys
   pad-buffer /pad-buffer 0 fill
;

: free-pad-buffer  ( -- )
   pad-buffer pad-buffer-phys /pad-buffer dma-map-out
   pad-buffer /pad-buffer dma-free
;

\ \\ Buffer Descriptor List
 
struct  ( buffer descriptor )
    4 field >bd-laddr
    4 field >bd-uaddr
    4 field >bd-len
    4 field >bd-ioc
constant /bd

0 value bdl
0 value bdl-phys
d# 256 /bd * value /bdl

: buffer-descriptor  ( n -- adr )  /bd * bdl +  ;

: allocate-bdl  ( -- )
    /bdl dma-alloc to bdl
    bdl /bdl 0 fill
    bdl /bdl true dma-map-in to bdl-phys
;

: free-bdl  ( -- ) bdl bdl-phys /bdl dma-map-out   bdl /bdl dma-free ;

: setup-bdl  ( -- )
   allocate-bdl
   sound-buffer-phys 0 buffer-descriptor >bd-laddr !  ( len )
   0                 0 buffer-descriptor >bd-uaddr !  ( len )
   /sound-buffer     0 buffer-descriptor >bd-len   !  ( )
   1                 0 buffer-descriptor >bd-ioc   !
   \ pad buffer
   alloc-pad-buffer
   pad-buffer-phys  1 buffer-descriptor >bd-laddr !
                 0  1 buffer-descriptor >bd-uaddr !
       /pad-buffer  1 buffer-descriptor >bd-len   !
                 0  1 buffer-descriptor >bd-ioc   !
;

: teardown-bdl  ( -- )
   free-bdl
   free-pad-buffer
;

\ \\ Stream descriptor (DMA engine)

: setup-stream  ( -- )
   reset-stream
   /sound-buffer /pad-buffer + sdcbl rl! \ bytes of stream data
   h# 440000 sdctl rl!            \ stream 4
   1 sdlvi rw!                    \ two buffers
   1c sdsts rb!                   \ clear status flags
   bdl-phys sdbdpl rl!
   0        sdbdpu rl!
   stream-format sdfmt rw!
;

: stream-done?      ( -- ) sdsts c@ 4 and 0<> ;
: wait-stream-done  ( -- ) begin stream-done? until ;

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
   dst 2 -  /dst             ( dst dst-len )
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

false value playing?

: upsampling?  ( -- ? )  scale-factor 1 <>  ;

: open-out  ( -- )
   4 to sd#
   d# 48.000 set-sample-rate
;

: audio-out  ( adr len -- actual ) 
   dup >r
   upsampling?  if  scale-factor upsample  then  ( adr len )
   install-sound-buffer  ( )
   setup-bdl
   setup-stream
   enable-codec-playback
   start-stream
   r>                    ( actual )
;

: release-sound-buffer  ( -- )
   sound-buffer sound-buffer-phys /sound-buffer dma-map-out
   upsampling?  if  sound-buffer /sound-buffer dma-free  then
;

: (write-done)  ( -- )
   stop-stream
   free-bdl
   release-sound-buffer
;
: write-done  ( -- )  wait-stream-done  (write-done)  ;

: write  ( adr len -- actual )
   4 to sd#  audio-out  install-playback-alarm  true to playing?
;

false value stop-lock
: stop-sound  ( -- )
   true to stop-lock
   playing?  if  (write-done)  false to playing?  then
   false to stop-lock
;

\ Alarm handle to stop the stream when the content has been played.
: playback-completed-alarm  ( -- )
   stop-lock  if  exit  then
   playing?  if
      sd#  4 to sd#                                          ( sd# )
      stream-done?  if  (write-done)  false to playing?  then  ( sd# )
      to sd#                                                 ( )
   then
;

' playback-completed-alarm is playback-alarm

: wait-sound  ( -- )  begin  playing?  0= until  ;

false value left-mute?
false value right-mute?

: set-volume  ( dB -- )
   dac to node
   dB>step#
   dup  left-mute?  if  h# 80 or  then  h# 3a000 or cmd  \ left gain
        right-mute? if  h# 80 or  then  h# 39000 or cmd  \ right gain
;

\ \\ Recording

0 value recbuf
0 value recbuf-phys
d# 65535 value /recbuf 

: open-in  ( -- )  d# 48.000 set-sample-rate  ;

: record-stream  ( -- )
   0 to sd#
   1 to #channels
   reset-stream
   /sound-buffer /pad-buffer + sdcbl rl! \ buffer length
   h# 100000 sdctl rl!     \ stream 1, input
   1 sdlvi rw!             \ two buffers
   h# 1c sdsts c!          \ clear status flags
   bdl-phys sdbdpl rl!
          0 sdbdpu rl!
   stream-format sdfmt rw!
   adc to node 
   h# 70610 cmd \ stream 1, channel 0
   h# 20000 stream-format or cmd \ stream format
;

: audio-in  ( adr len -- actual )
   install-sound-buffer   ( )
   setup-bdl
   record-stream
   enable-codec-recording
   start-stream
   wait-stream-done
   stop-stream
   release-sound-buffer
   free-pad-buffer
   /recbuf
;

: close-in  ( -- )  disable-codec-recording  ;

0 value boost-db

: mic+20db  ( -- )  d# 20 to boost-db ;
: mic+0db   ( -- )      0 to boost-db ;

: set-record-gain  ( dB -- )  ; \ adc to node  step# input-gain  ;
: in-amp-caps  ( -- u )  h# f000d cmd?  ;
: in-gain-steps  ( -- n )  in-amp-caps  8 rshift h# 7f and  1+  ;
: set-record-gain  ( dB -- )  drop ( hardcoded for now ) adc to node  h# 40 input-gain  ;


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
