\ See license at end of file
\ CS5536 ACPI and Power Management Registers

0 value acpi-base
0 value pm-base

: acpi-w@  ( offset -- w )  acpi-base +  pw@ ;
: acpi-w!  ( w offset -- )  acpi-base +  pw! ;
: acpi-l@  ( offset -- l )  acpi-base +  pl@ ;
: acpi-l!  ( l offset -- )  acpi-base +  pl! ;

: pm@  ( offset -- n )  pm-base +  pl@ ;
: pm!  ( n offset -- )  pm-base +  pl! ;

h# 4000.0000 constant pm-enable
: gx-power-off  ( -- )
   \ If the keyboard controller is off (after "flash"), power off doesn't work.
   \ I suspect that is because the EC doesn't notice the deassertion
   \ of main_on and sus_on from the 5536.
   kbc-on

   \ Recipe from AMD; no way I would have figured this out from manual
   5 d# 10 <<  1 or  8 acpi-w!   \ S5 - power off
   
   \ Enable all of these controls with 0 delay
   pm-enable   h# 10 pm!             \ PM_SCLK
   pm-enable   h# 20 pm!             \ PM_IN_SLPCTL
   pm-enable   h# 34 pm!             \ PM_WKXD
   pm-enable   h# 30 pm!             \ PM_WKD

   2 acpi-w@  h# 100 or  2 acpi-w!   \ Enable button wakeup in PM1_EN
   h# 2ffff h# 54 pm!                \ Clear status bits i PM_SSC
   h# 1301 rdmsr  swap 2 or swap  h# 1301 wrmsr  \ Set SMM_SUSP_EN
   h# ffff.ffff h# 18 acpi-l!        \ Clear status bits in PM_GPE0_STS
   8 acpi-w@  h# 2000 or  8 acpi-w!  \ SLP_EN in PM1_CNT - Down we go
;
' gx-power-off is power-off

warning @ warning off
: stand-init
   stand-init
   h# 5140.000e rdmsr drop  h# fff0 and  to acpi-base
   h# 5140.000f rdmsr drop  h# fff0 and  to pm-base
   d# 32768 pm-enable or  h# 40 pm!  \ Shorten off delay to .5 sec
;
warning !
\ LICENSE_BEGIN
\ Copyright (c) 2006 FirmWorks
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
