\ See license at end of file
purpose: Access to GPIO registers

\ GPIO registers
h# 00 constant GPIOx_OUT_VAL 
h# 20 constant GPIOx_IN_EN 
h# 04 constant GPIOx_OUT_EN  
h# 10 constant GPIOx_OUT_AUX1
h# 14 constant GPIOx_OUT_AUX2
h# 24 constant GPIOx_INV_EN 
h# 28 constant GPIOx_IN_FLTR_EN 
h# 2c constant GPIOx_EVNTCNT_EN 
h# 30 constant GPIOx_READ_BACK 
h# 38 constant GPIOx_EVNT_EN 

h# 1000 value gpio-base  \ stand-init sets this from an MSR
: gpio@  ( offset -- 0 )  gpio-base +  pl@  ;
: gpio!  ( l offset -- )  gpio-base +  pl!  ;

alias >set noop   ( mask -- mask' )  
: >clr    ( mask -- mask' )  d# 16 lshift  ;

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
