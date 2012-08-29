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

: ts-clock  ( offset -- )
   7 over apbc!  3 swap apbc!   ( n )
;

: ts-clocks
   h# 90 ts-clock
   h# 98 ts-clock
   h# 9c ts-clock
   h# a0 ts-clock
;

h# 03.b000 value tsense  \ p2021

: +ts  ( offset -- io-offset )  tsense swap la+  ;
: ts@  ( offset -- l )  +ts io@  ;
: ts!  ( l offset -- )  +ts io!  ;

\ last system reset was caused by thermal sensor?
\ : tsr?  ( -- flag )  h# 0028 mpmu@  h# 10  and  ;  \ p282
\ : tsr?  ( -- flag )  h# 1028 mpmu@  h# 10  and  ;  \ p311

\ last thermal sensor watchdog reset was caused by THSENS1 unit?
\ (polarity differs from documentation)
\ : thsens1?  ( -- flag )  h# 00a4 mpmu@  h# 10  and  ;  \ p345

\ thsens1 is requesting interrupt service?  (true if auto run enabled)
\ : thsens1-int?  ( -- flag )  h# 00a4 mpmu@  h#  1  and  ;  \ p346

\ thermal sensor interrupt is masked?  (normally true)
\ : thsens1-int-masked?  h# 180 icu@  800 and  ;  \ p700
\ : thsens1-int-status?  h# 188 icu@  800 and  ;  \ p702

\ thermal sensor watchdog to system reset enable  (normally already set)
\ : wdtr?  h# 200 mpmu@ 1 7 lshift and 0=  ;  \ p302

: ts-auto-read  ( n -- )  \ undocumented
   dup ts@  h# 20.0000 or  swap ts!
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
   ts@                  ( gc )
;

: ts-range-low  ( n -- )
   dup ts@  h# 0800.0000 or  swap ts!
;

: ts-range-high  ( n -- )
   dup ts@  h# 0800.0000 invert and  swap ts!
;

: ts-watchdog-enable  ( n -- )
   dup ts@  h# 0400.0300 or  swap ts!  \ 85-87.5C
;

: init-thermal-sensor  ( -- )
   ts-clocks
   0 ts-range-high
   0 ts-watchdog-enable
   1 ts-range-low
   2 ts-range-low
   3 0 do  i ts-auto-read  loop
;

\ read and average the two sensors on lowrange duty
: cpu-temperature  ( -- celcius )
   1 ts-read  gc>c
   2 ts-read  gc>c
   + d# 20 /
;

: ?thermal  ( -- )
   0 ts-read  gc>c  d# 850 > abort " CPU too hot"
;

: .c.c  ( n -- )  0 <# # [char] . hold #s #> type ." C " ;

: .c  ( n -- )  (.) type ." C " ;

: .thermal
   push-decimal
   time&date >unix-seconds .
   ." sensors: "
   0 ts@  dup h# f and 0=  if  drop ." <80C "  else  gc>c  .c.c  then
   1 ts@  gc>c  .c.c  \ FIXME: show <n and >n too here
   2 ts@  gc>c  .c.c
   ." cpu: "  cpu-temperature  .c
   ." battery: "  bat-temp  .c
   pop-base
;

: watch-thermal
   begin
      .thermal cr d# 1000 ms key?
   until key drop cr
;

\ .thermal 0 ts@ f and . d# 1000 ms cr many

string-array tsense-regx-bits
   ," 31=reserved"
   ," 30=start"
   ," 29=status"
   ," 28=over_int"
   ," 27=lowrange"
   ," 26=en_wdog"
   ," 25=temp_int"
   ," 24=en_over_int"
   ," 23=en_temp_int"
   ," 22=reserved"
   ," 21=auto_read_en"
end-string-array

: .tc  ( n -- )
   dup .
   push-decimal
   gc>c .c.c
   pop-base
;

: .tsense  ( n -- )
   dup . cr 4 spaces
   d# 11 0 do
      dup i lshift h# 8000.0000 and if
         i tsense-regx-bits count type space
      then
   loop cr
   \ dup d# 12 rshift h# 7ff and dup if 4 spaces ." reserved=" . cr else drop then
   4 spaces dup 8 rshift h# f and ." wdog_tshld=" .tc cr
   4 spaces dup 4 rshift h# f and ." int_tshld=" .tc cr
   4 spaces dup          h# f and ." temp_value=" .tc cr
   drop
;

: .ts
   0 ts@ ." tsense_reg[0]=" .tsense
   1 ts@ ." tsense_reg[1]=" .tsense
   2 ts@ ." tsense_reg[2]=" .tsense
;

: test-thermal
   ." press against heat spreader and press a key once temperature is low"
   watch-thermal
   h# 200 mpmu@ 1 7 lshift and 0=  if
      ." THRSENS_WDTR_EN was not set" cr
      h# 200 mpmu@ 1 7 lshift or h# 200 mpmu!
   then
   0 ts@
   1 d# 27 lshift or  \ set the lowrange bit
   h# 0020.0000 or    \ set the autorun bit (undocumented)
   h# 0400.0000 or    \ set the watchdog enable bit
   h# b h# f and d# 8 lshift or       \ set the watchdog temperature (58-60.5C)
   b# 0101.1111.1010.0000.0000.1111.1111.0000
   and \ always write zero to reserved bits
   0 ts!
   ." thermal watchdog enabled" cr
   watch-thermal
;

: force-thermal-watchdog
   h# 200 mpmu@ 1 7 lshift or h# 200 mpmu! \ thrsens_wdtr_en
   h# 0c20.0000 h# 03.b000 io! \ lowrange, en_wdog, auto_read_en, wdog_tshld 26C
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
