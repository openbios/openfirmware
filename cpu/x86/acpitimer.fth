\ See license at end of file
purpose: Timing functions using the ACPI timer

: acpi-b@  ( reg# -- b )  acpi-io-base + pc@  ;
: acpi-b!  ( b reg# -- )  acpi-io-base + pc!  ;
: acpi-w@  ( reg# -- w )  acpi-io-base + pw@  ;
: acpi-w!  ( w reg# -- )  acpi-io-base + pw!  ;
: acpi-l@  ( reg# -- l )  acpi-io-base + pl@  ;
: acpi-l!  ( l reg# -- )  acpi-io-base + pl!  ;

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

[ifdef] tsc@
: acpi-calibrate-tsc  ( -- )
   tsc@  d# 100 acpi-ms  tsc@           ( d.start d.end )
   2swap d-                             ( d.delta )
   2dup d# 100 um/mod nip to ms-factor  ( d.delta ms )
   d# 100,000  um/mod nip to us-factor  ( )
;
[else]
: us  ( us -- )  acpi-us  ;
' acpi-ms to ms
\ Timing tools
variable timestamp1
: t(  ( -- )  acpi-timer@ timestamp1 ! ;
: )t  ( -- )
   acpi-timer@  timestamp1 @  -  d# 1000 d# 3580 */  ( microseconds )
   push-decimal
   <#  u# u# u#  [char] , hold  u# u#s u#>  type  ."  uS "
   pop-base
;

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
