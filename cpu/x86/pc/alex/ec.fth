\ See license at end of file
purpose: Access to platform functions controlled by the Embedded Controller

[ifdef] notdef
\ The following is an alternative interface to EC internals.  It seems to
\ accomplish the same thing as the standard port 66/62 ACPI interface.
: ec-i@  ( index -- b )  h# a00 pc! h# a01 pc@  ;
: ec-i!  ( b index -- )  h# a00 pc! h# a01 pc!  ;
: ec-rdy?  ( -- flag )  h# 82 ec-i@  0=  ;
: wait-ec-rdy  ( -- )
   h# 800  0  do  ec-rdy?  if  unloop exit  then  d# 10 us  loop
   true abort" EC timeout"
;
: ec-cmd  ( cmd -- )  wait-ec-rdy  h# 82 ec-i!  wait-ec-rdy  ;
: ec-cmd-data  ( data cmd -- )  wait-ec-rdy swap h# 84 ec-i!  h# 82 ec-i!  wait-ec-rdy  ;

: ec-b@  ( adr -- b )  h# 88 ec-cmd-data  h# 84 ec-i@  ;
: ec-b!  ( b adr -- )  h# 84 ec-i! h# 85 ec-i! h# 89 h# 82 ec-i!  ;

: ec-w@  ( adr -- b )  dup ec-b@  swap 1+ ec-b@  bwjoin  ;
: ec-w!  ( w adr -- b )  >r wbsplit  r@ 1+ ec-b!  r> ec-b!  ;
[then]

\ Alex has one fan, but it appears that the EC supports up to 5 fans.
\ Alex's fan goes on if you turn on either of EC fans 0,1, or 2
: fan-on?  ( -- flag )  h# ca ec-b@ 7 and 0<>  ;
: fan-on   ( -- )  h# 81 h# ca ec-b!  ;
: fan-off  ( -- )  h# 80 h# ca ec-b!  ;

: battery-remaining-capacity  ( -- w )  h# a2 ec-w@  ;
: battery-present-rate        ( -- w )  h# a4 ec-w@  ;
: battery-present-voltage     ( -- w )  h# a6 ec-w@  ;

: battery-design-capacity  ( -- w )  h# b0 ec-w@  ;
: battery-last-charge      ( -- w )  h# b2 ec-w@  ;
: battery-design-voltage   ( -- w )  h# b4 ec-w@  ;
: battery-design-full      ( -- w )  h# b6 ec-w@  ;

: cpu-temperature  ( -- degrees-c )  h# c0 ec-b@  ;

: battery-state  ( -- b )  h# 84 ec-b@  ;  \ 0:discharging 1:charging 2:critical
: lid-open?  ( -- flag )  h# 83 ec-b@  1 and  0<>  ;
: ac?  ( -- flag )  h# 80 ec-b@  4 and  0<>  ;
: battery?  ( -- flag )  h# 80 ec-b@  1 and  0<>  ;

\ LICENSE_BEGIN
\ Copyright (c) 2011 FirmWorks
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
