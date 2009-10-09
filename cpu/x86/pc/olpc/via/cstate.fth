purpose: Test for processor C-states
\ See license at end of file

: cpu-temperature  ( -- degrees-C )  h# 1169 msr@ drop  ;
: show-temperature  ( -- )  space cpu-temperature .d  ;

variable start-time
variable sleep-time
: acpi-time@  ( -- t0 )  8 acpi-l@  ;

: arb-dis  ( -- )  1 h# 22 pc!  ;
: arb-ena  ( -- )  0 h# 22 pc!  ;
: bm-rld-on   ( -- )  4 acpi-w@ 2 or 4 acpi-w!  ;
: bm-rld-off  ( -- )  4 acpi-w@ 2 invert and 4 acpi-w!  ;

\ Setting this makes C3 behave the same as C4
\ So there are two ways to get into C4 -
\   Either set this bit and read the LVL_3 register,
\   or just read the LVL_4 register

: lower-c3-voltage  ( -- )  h# 26 acpi-b@ 1 or h# 26 acpi-b!  ;

: can-idle?  ( -- flag )
   interrupts-enabled?  if  \ Interrupts must be enabled
      h# 21 pc@ 1 and 0=    \ Timer must be running
   else
      false
   then
;

defer do-idle  ' noop to do-idle

: safe-idle  ( -- )  can-idle?  if  do-idle  then  ;
' safe-idle to stdin-idle

alias c1-idle halt

: c2-idle  ( -- )  h# 14 acpi-b@ drop  ;
: c3-idle  ( -- )  arb-dis  h# 15 acpi-b@ drop   arb-ena  ;
: c4-idle  ( -- )  arb-dis  h# 16 acpi-b@ drop   arb-ena  ;
code c5-idle  ( -- )  acpi-io-base h# 17 + # dx mov  wbinvd  dx al in  c;

alias default-idle-state c2-idle
' default-idle-state to do-idle

: enter-idle  ( -- )
   acpi-time@   ( t )
   do-idle      ( t )
   acpi-time@ swap -  sleep-time +!
;
: idle-ms  ( ms -- )
   tick-msecs +     ( limit )
   begin  enter-idle  dup tick-msecs -  0<= until  ( limit )
   drop
;
: idling  ( xt -- )
   to do-idle

   sleep-time off
   acpi-time@ start-time !

   cursor-off
   begin
     green-letters (cr show-temperature  d# 1024 idle-ms
     black-letters (cr show-temperature  d# 1024 idle-ms
   key?  until
   cursor-on

   sleep-time @  d# 1000  acpi-time@ start-time @ -  */  ( %*10 )
   cr  ." Slept "  push-decimal  <# u# [char] . hold u#s u#> pop-base  type  ." % of the time"  cr

   ['] default-idle-state to do-idle
;
: .idling  ( $ -- )
   ." Idling in " type ."  state, showing core temperature" cr
;
: c0-test  ( -- )
   " C0" .idling
   ['] noop  idling
;
: c1-test  ( -- )
   " C1" .idling
   ['] c1-idle  idling
;
: c2-test  ( -- )
   " C2" .idling
   ['] c2-idle  idling
;
: c3-test  ( -- )
   bm-rld-on
   " C3" .idling
   ['] c3-idle  idling
;
: c4-test  ( -- )
   bm-rld-on
   " C4" .idling
   ['] c4-idle idling
;

\ LICENSE_BEGIN
\ Copyright (c) 2009 FirmWorks
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
