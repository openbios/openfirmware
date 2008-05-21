\ See license at end of file
purpose: Access to GPIO registers

\ GPIO registers
h# 00 constant OUT_VAL 
h# 04 constant OUT_EN  
h# 08 constant OUT_OD_EN  
h# 0c constant OUT_INVRT_EN  
h# 10 constant OUT_AUX1
h# 14 constant OUT_AUX2
h# 18 constant PU_EN
h# 1c constant PD_EN
h# 20 constant IN_EN 
h# 24 constant INV_EN 
h# 28 constant IN_FLTR_EN 
h# 2c constant EVNTCNT_EN 
h# 30 constant READ_BACK 
h# 38 constant EVNT_EN 

h# 1000 value gpio-base  \ stand-init sets this from an MSR
: gpio@  ( offset -- 0 )  gpio-base +  pl@  ;
: gpio!  ( l offset -- )  gpio-base +  pl!  ;

alias >set noop   ( mask -- mask' )  
: >clr    ( mask -- mask' )  d# 16 lshift  ;

: >hi     ( reg# -- reg#' )  h# 80 +  ;   \ High bank for GPIO bits 16..31

: gpio-data@  ( -- l )  h# 30 gpio@  ;


h# 5140000C constant MSR_LBAR_GPIO

stand-init: gpio
   MSR_LBAR_GPIO rdmsr  ( lo hi )
   h# 0000f001 <>  abort" GPIO not enabled"
   h# ff00 and  to gpio-base
;
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
