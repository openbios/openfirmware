purpose: Conexant CX2058x codec
\ See license at end of file
hex

\ \ Conexant

: power-on   ( -- )  h# 70500 cmd  ;  \ Set power state - on
: power-off  ( -- )  h# 70503 cmd  ;  \ Set power state - off
: power-on-all  ( -- )
   " "(01 10 11 12 14 15 16 17 18 19 1a 1b 1c 1d 1e 1f 20 21 22 23 24)"
   bounds  do  i c@ to node  power-on  loop
;

: set-node  ( node-id -- )  to node  ;

fload ${BP}/dev/hdaudio/cx2058x-nodes.fth

: volume-on-all  ( -- )
   adc1   h# 36006 cmd  h# 35006 cmd  \ Left gain/mute, right gain/mute
   portj  h# 36004 cmd  h# 35004 cmd  \ Left gain, right gain
   mux    h# 3a004 cmd  h# 39004 cmd  \ Left gain, right gain
   mux2   h# 3a004 cmd  h# 39004 cmd  \ Left gain, right gain
   adc1   h# 36200 cmd  h# 35200 cmd  \ Left gain/mute, right gain/mute
   dac1   h# 3a03e cmd  h# 3903e cmd  \ Left gain, right gain
;

: pin-sense?       ( -- ? )  h# f0900 cmd? h# 8000.0000 and 0<>  ;
: set-connection   ( n -- )  h# 70100 or cmd   ;
: enable-hp-input  ( -- )    h# 70721 cmd  ;
: disable-hp-input ( -- )    h# 70700 cmd  ;

fload ${BP}/dev/hdaudio/olpc-ports.fth

: cx2058x-enable-recording  ( -- )
   set-recording-port
;

: cx2058x-disable-recording  ( -- )
   portb  disable-hp-input
   portc  disable-hp-input
;

: cx2058x-enable-playback   ( -- )
   set-playback-port
   dac1  h# 70640 cmd    \ 706sc - stream 4, channel 0
   h# 20000 stream-format or cmd
;
: cx2058x-disable-playback  ( -- )  ;

: config-default  ( -- u )  f1c00 cmd?  ;

[ifdef] notdef  \ Unnecessary because we do it in early startup assembly language
fload ${BP}/dev/hdaudio/config.fth    \ Names for configuration settings

: )config  ( config-default -- )
   \ set the high 24 bits of the config-default value
   \ the low 8 bits (default association, sequence) are preserved
   8 rshift  dup h# ff and  71d00 or  cmd
   8 rshift  dup h# ff and  71e00 or  cmd
   8 rshift      h# ff and  71f00 or  cmd
;

: setup-config-default  ( -- )
   porta  config(  1/8" green left hp-out jack     )config
   portb  config(  1/8" pink left mic-in jack      )config
   portc  config(  builtin internal front mic-in   )config
   portd  config(  unused line-out                 )config
   porte  config(  unused line-out                 )config
   portf  config(  1/8" pink left line-in jack     )config
   portg  config(  builtin internal front speaker  )config
   porth  config(  unused spdiff-out               )config
   porti  config(  unused spdiff-out               )config
   portj  config(  unused mic-in                   )config
;

: vendor-settings  ( -- )
   vendor
   h# 290a8 cmd \ high-pass filter, semi-manual mode, 600Hz cutoff
\  h# 34001 cmd \ speaker power 1 dB gain
   h# 34003 cmd \ speaker power -2 dB gain (1.26W @ 4 ohms)
   h# 38021 cmd \ over-current / short-circuit protection, 2.6A threshold
\   h# 39019 cmd \ temperature protection at 130C
   h# 390c5 cmd \ temperature protection at 79.5C
   h# 42011 cmd \ over-temperature shutdown of class-D
;
[then]

\ check (expect) that cmd yields value
: check-cmd  ( value cmd -- )
   dup . ." cmd? => "
   cmd?                                        ( value actual )
   push-hex  dup 0 <# # # # #> type pop-base   ( value actual )
   over = if                                   ( value )
      ."  (ok)" drop
   else
      ."  but expected " .
   then
   cr
;

: over-temperature?  ( -- ? )  h# c3000 cmd? 4 and 0<>  ;

\ Test word to make sure the right settings are configured
: .vendor-settings  ( -- )
   vendor
   h# 0a8 h# a9000 check-cmd
   h# 001 h# b4000 check-cmd
   h# 001 h# b8000 check-cmd
   h# 019 h# b9000 check-cmd
   h# 011 h# c2000 check-cmd
   over-temperature? if
      ." over temperature!"
   else
      ." temperature is within bounds
   then
;

: cx2058x-open  ( -- )
   ['] dac1 to with-dac
   ['] adc1 to with-adc
   power-on-all
   volume-on-all
\   vendor-settings
\   setup-config-default
;

: cx2058x-close  ( -- )  afg power-off  ;  \ Power off entire Audio Function Group

: cx2058x-init  ( -- )
   ['] cx2058x-open  to open-codec
   ['] cx2058x-close to close-codec
   ['] cx2058x-enable-recording  to enable-codec-recording
   ['] cx2058x-disable-recording to disable-codec-recording
   ['] cx2058x-enable-playback   to enable-codec-playback
   ['] cx2058x-enable-playback   to disable-codec-playback
\   setup-config-default
;

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
