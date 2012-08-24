\ See license at end of file
purpose: Driver for the MMP3 thermal sensor

\ FIXME: characterise the observations using an IR thermometer,
\ because the datasheet and the registers manual disagree on
\ interpretation of these gray code values.

create gc0 \ high range
d#  780 w, \ 0000
d#  830 w, \ 0001
d#  855 w, \ 0010
d#  805 w, \ 0011
d#  955 w, \ 0100
d#  930 w, \ 0101
d#  880 w, \ 0110
d#  905 w, \ 0111
d#    0 w, \ 1000
d# 1130 w, \ 1001
d# 1080 w, \ 1010
d# 1105 w, \ 1011
d#  980 w, \ 1100
d# 1005 w, \ 1101
d# 1055 w, \ 1110
d# 1030 w, \ 1111

create gc1 \ low range
d# 260 w, \ 0000
d# 285 w, \ 0001
d# 335 w, \ 0010
d# 310 w, \ 0011
d# 435 w, \ 0100
d# 410 w, \ 0101
d# 360 w, \ 0110
d# 385 w, \ 0111
d# 0 w,   \ 1000
d# 610 w, \ 1001
d# 560 w, \ 1010
d# 585 w, \ 1011
d# 460 w, \ 1100
d# 485 w, \ 1101
d# 535 w, \ 1110
d# 510 w, \ 1111

: gc>c  ( gray-code -- tenths-of-celcius )
   dup h# 0800.0000 and                 ( gray-code low-range? )
   if gc1 else gc0 then                 ( gray-code table )
   swap h# f and wa+ w@
;

h# 03.b000 value tsense

: +ts  ( offset -- io-offset )  tsense swap la+  ;
: ts@  ( offset -- l )  +ts io@  ;
: ts!  ( l offset -- )  +ts io!  ;

: ts-clock  ( offset -- )
   7 over apbc!  3 swap apbc!   ( n )
;

: ts-clocks
   h# 90 ts-clock
   h# 98 ts-clock
   h# 9c ts-clock
   h# a0 ts-clock
;

: ts-start  ( n -- )
   dup ts@  h# 4000.0000 or  swap ts!
;

: ts-wait  ( n -- )
   d# 10 get-msecs +                    ( n limit )
   begin
      over ts@  h# 2000.0000 and        ( n limit ready? )
      if  2drop exit  then
      dup get-msecs -  0<               ( n limit timeout? )
   until                                ( n limit )
   2drop                                ( )
;

: ts-read  ( n -- gc )
   dup ts-wait          ( n )
   dup ts@              ( n gc )
   swap ts-start        ( gc )
;

: ts-range-low  ( n -- )
   dup ts@  h# 0800.0000 or  swap ts!
;

: ts-range-high  ( n -- )
   dup ts@  h# 0800.0000 invert and  swap ts!
;

: init-thermal-sensor  ( -- )
   ts-clocks
   3 0 do  i ts-range-low  i ts-start  loop
;

\ switch the sensors out of low range - does not work
[ifdef] notyet
: hot
   ts-clocks
   3 0 do  i ts-range-high  i ts-start  loop
;
[then]

\ read and average the three sensors
: cpu-temperature  ( -- celcius )
   0 ts-read  gc>c
   1 ts-read  gc>c
   2 ts-read  gc>c
   + + d# 30 /
;

: ?thermal  ( -- )
   cpu-temperature d# 70 > abort " CPU too hot"
   \ FIXME: choose an appropriate limit, because
   \ - the sample unit easily reaches 61C,
   \ - using the low range we can't see greater than 61C, and
   \ - the high range doesn't actually work.
;

: .c.c  ( n -- )  0 <# # [char] . hold #s #> type ." C " ;

: .c  ( n -- )  (.) type ." C " ;

: .thermal
   push-decimal
   time&date >unix-seconds .
   ." sensors: "
   0 ts@  gc>c  .c.c  \ innermost?
   1 ts@  gc>c  .c.c
   2 ts@  gc>c  .c.c  \ outermost?
   ." cpu: "  cpu-temperature  .c
   ." battery: "  bat-temp  .c
   pop-base
;

: watch-thermal
   begin
      .thermal cr d# 1000 ms key?
   until key drop cr
;

[ifdef] notyet \ FIXME
: test-thermal
   .thermal cr

   \ save the threshold set by cforth
   thermal-base 4 + io@ >r

   \ temporarily set the threshold close to current value
   thermal-base io@  h# 3ff and  8 +  wd-thresh!

   begin
      (cr .thermal kill-line d# 500 ms key?
   until key drop cr

   \ restore the threshold
   r> wd-thresh!
   .thermal cr
;
[then]

stand-init: Thermal sensor
   init-thermal-sensor
;

\ LICENSE_BEGIN
\ Copyright (c) 2012 FirmWorks
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
