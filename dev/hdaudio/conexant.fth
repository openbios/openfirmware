purpose: Conexant CX2058x codec
\ See license at end of file
hex

\ \ Conexant

: power-on   ( -- )  h# 70500 cmd  ;
: power-off  ( -- )  h# 70503 cmd  ;
: power-on-all  ( -- )
   " "(01 10 11 12 14 15 16 17 18 19 1a 1b 1c 1d 1e 1f 20 21 22 23 24)"
   bounds  do  i c@ to node  power-on  loop
;   

: volume-on-all  ( -- )
   h# 14 to node  h# 36006 cmd  h# 35006 cmd
   h# 23 to node  h# 36004 cmd  h# 35004 cmd
   h# 17 to node  h# 3a004 cmd  h# 39004 cmd
   h# 18 to node  h# 3a004 cmd  h# 39004 cmd
   h# 14 to node  h# 36200 cmd  h# 35200 cmd
   h# 10 to node  h# 3a03e cmd  h# 3903e cmd
;

h# 1a value mic-in   \ Port B
h# 1b value mic      \ Port C
h# 17 value mux      \ mux between the two

: pin-sense?       ( -- ? )  h# f0900 cmd? h# 8000.0000 and 0<>  ;
: set-connection   ( n -- )  h# 70100 or cmd   ;
: enable-hp-input  ( -- )    h# 70721 cmd  ;
: disable-hp-input ( -- )    h# 70700 cmd  ;

: cx2058x-enable-recording  ( -- )
   mic-in to node  pin-sense?  if
      mux to node  0 set-connection  mic-in to node enable-hp-input
   else
      mux to node  1 set-connection  mic to node enable-hp-input
   then
;

: cx2058x-disable-recording  ( -- )
   mic-in to node  disable-hp-input
   mic    to node  disable-hp-input
;

: cx2058x-enable-playback   ( -- )
   h# 19 to node  pin-sense?  if  \ headphones attached
      h# 1f to node  power-off    \ turn off speaker
   else                           \ no headphones
      h# 1f to node  power-on     \ turn on speaker 
   then 
   h# 10 to node  h# 70640 cmd   h# 20000 stream-format or cmd
;
: cx2058x-disable-playback  ( -- )  ;

: 1/8"        ( u -- u )  h#    10000 or  ;
: green       ( u -- u )  h#     4000 or  ;
: pink        ( u -- u )  h#     9000 or  ;
: hp-out      ( u -- u )  h#   200000 or  ;
: spdiff-out  ( u -- u )  h#   400000 or  ;
: mic-in      ( u -- u )  h#   a00000 or  ;
: line-in     ( u -- u )  h#   800000 or  ;
: line-out    ( u -- u )                  ;
: speaker     ( u -- u )  h#   100000 or  ;
: left        ( u -- u )  h#  3000000 or  ;
: front       ( u -- u )  h#  2000000 or  ;
: internal    ( u -- u )  h# 10000000 or  ;
: jack        ( u -- u )  h# 00000000 or  ;
: unused      ( u -- u )  h# 40000000 or  ;
: builtin     ( u -- u )  h# 80000000 or  ;

: config(   ( node -- null-config-default )  to node  0  ;

: )config  ( config-default -- )
   \ set the high 24 bits of the config-default value
   \ the low 8 bits (default association, sequence) are preserved
   8 rshift  dup h# ff and  71d00 or  cmd
   8 rshift  dup h# ff and  71e00 or  cmd
   8 rshift      h# ff and  71f00 or  cmd
;

: port-a  ( -- u )  19 config(  1/8" green left hp-out jack     )config  ;
: port-b  ( -- u )  1a config(  1/8" pink left mic-in jack      )config  ;
: port-c  ( -- u )  1b config(  builtin front mic-in            )config  ;
: port-d  ( -- u )  1c config(  unused line-out                 )config  ;
: port-e  ( -- u )  1d config(  unused line-out                 )config  ;
: port-f  ( -- u )  1e config(  1/8" pink left line-in jack     )config  ;
: port-g  ( -- u )  1f config(  builtin front speaker           )config  ;
: port-h  ( -- u )  20 config(  unused spdiff-out               )config  ;
: port-i  ( -- u )  22 config(  unused spdiff-out               )config  ;
: port-j  ( -- u )  23 config(  unused mic-in                   )config  ;

: config-default  ( -- u )  f1c00 cmd?  ;

: setup-config-default  ( -- )
   port-a port-b port-c port-d port-e port-f port-g port-h port-i port-j
;

: vendor-settings  ( -- )
   h# 25 to node
   h# 290a8 cmd \ high-pass filter, semi-manual mode, 600Hz cutoff
   h# 34001 cmd \ speaker power 1 dB gain
   h# 38001 cmd \ over-current / short-circuit protection, 2.6A threshold
   h# 39019 cmd \ temperature protection at 130C
   h# 42011 cmd \ over-temperature shutdown of class-D
;

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
   h# 25 to node
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
   h# 10 to dac
   h# 14 to adc
   power-on-all
   volume-on-all
   vendor-settings
   setup-config-default
;

: cx2058x-close  ( -- )
   1 to node ( function group) power-off
;

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
