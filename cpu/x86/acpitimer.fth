\ See license at end of file
purpose: Timing functions using the ACPI timer

\ The ACPI timer counts at 3.579545 MHz.
\ 3.579545 * 1024 is 3665
: acpi-timer@  ( -- counts )  8 acpi-l@  ;

: acpi-us  ( us -- )
   d# 3664 * d# 10 rshift  acpi-timer@ +  ( end )
   begin   dup acpi-timer@ -  0< until    ( end )
   drop
;
: acpi-ms  ( us -- )
   d# 3580 * acpi-timer@ +  ( end )
   begin   dup acpi-timer@ -  0< until    ( end )
   drop
;

: acpi-calibrate-tsc  ( -- )
   tsc@  d# 100 acpi-ms  tsc@           ( d.start d.end )
   2swap d-                             ( d.delta )
   2dup d# 100 um/mod nip to ms-factor  ( d.delta ms )
   d# 100,000  um/mod nip to us-factor  ( )
;

[ifdef] use-acpi-delays
: us  ( us -- )  acpi-us  ;
' acpi-ms to ms
[then]

[ifdef] use-acpi-timing

\ Timing tools
2variable timestamp
0 value timer-high
: get-timer  ( -- d )
   \ First handle the case where we have aleady rolled over
   0 acpi-w@ 1 and  if           \ Rollover bit changed
      1 0 acpi-w!                \ Clear indication
      acpi-timer@  timer-high    ( timer.low timer.high )
      over  0>=  if              ( timer.low timer.high )
         1+ dup  to timer-high   ( timer.low timer.high' )
      then                       ( timer.low timer.high )
      exit
   then                          ( )

   acpi-timer@ timer-high        ( timer.low timer.high )
   0 acpi-w@ 1 and  0=  if  exit  then   \ We are done if rollover bit didn't change
   1 0 acpi-w!                   ( timer.low timer.high )
   \ Otherwise we must start over, to ensure that low and high are consistent

   2drop                         ( )
   acpi-timer@  timer-high       ( timer.low timer.high )
   over  0>=  if                 ( timer.low timer.high )
      1+ dup  to timer-high      ( timer.low timer.high' )
   then                          ( timer.low timer.high )
;
: du*  ( ud.lo ud.hi u -- res.lo res.mid res.hi )  \ Ignores overflow to third cell
   tuck  um*  2>r           ( ud.lo u      r: res.mid0 res.hi0 )
   um*                      ( res.lo res.mid1  r: res.mid0 res.hi0 )
   0  2r> d+                ( res.lo res.mid res.hi )
;
: acpi-ticks>usecs  ( d.ticks -- usec )
   d# 50 du* drop      ( d.product )  \ The scale factor is 1000/3580 == 50/179
   d# 179 um/mod nip   ( usecs )
;

\ If you are doing a long timing, call this periodically to handle rollover
: t-update  ( -- )  0 acpi-w@ 1 and  if  timer-high 1+ to timer-high  then  ;
: t(  ( -- )  get-timer timestamp 2!  ;
\ Subtracting 10 accounts for the time it takes to read the ACPI timer,
\ which is an I/O port and therefore slow to read
: ))t1  ( -- d.ticks )  get-timer  timestamp 2@  d-  d# 10. d-  0. dmax  ;
: )t  ( -- )
   ))t1  acpi-ticks>usecs   ( microseconds )
   push-decimal
   <#  u# u# u#  [char] , hold  u# u#s u#>  type  ."  uS "
   pop-base
;
: ))t-sec  ( -- sec )  ))t1  d# 3,580,000 um/mod nip  ;
: )t-sec  ( -- )
   ))t-sec  ( seconds )
   push-decimal
   <# u# u#s u#>  type  ." S "
   pop-base
;
: .hms  ( seconds -- )
   d# 60 /mod   d# 60 /mod    ( sec min hrs )
   push-decimal
   <# u# u#s u#> type ." :" <# u# u# u#> type ." :" <# u# u# u#>  type
   pop-base
;
: )t-hms  ( -- )  ))t-sec  .hms  ;
[then]

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
