\ See license at end of file
purpose: Create a device node for a TWSI device based on stack arguments

\ Put the following on the stack prior to floading this file:
\     ( phys-addr     clk irq  mux? fast? linux-unit# )
\ E.g:  h# d4011000     1   7 false true     2

root-device
new-device

" linux,unit#" integer-property                    ( baseadr clock# irq# muxed-irq? fast? )
" i2c" name                                        ( baseadr clock# irq# muxed-irq? fast? )
" mrvl,mmp-twsi" +compatible                       ( baseadr clock# irq# muxed-irq? fast? )
[if]  0 0  " mrvl,i2c-fast-mode" property  [then]  ( baseadr clock# irq# muxed-irq? )
[if]
   " /interrupt-controller/interrupt-controller@158" encode-phandle " interrupt-parent" property
[then]                                             ( baseadr clock# irq# )
" interrupts" integer-property                     ( baseadr clock# )

" /apbc" encode-phandle rot  encode-int encode+  " clocks" property
h# 1000 reg                                        ( )

1 " #address-cells" integer-property
1 " #size-cells" integer-property

: decode-unit  ( adr len -- n )  parse-int  ;
: encode-unit  ( n -- adr len )  push-hex (u.) pop-base  ;

0 instance value twsi
0 instance value my-va

: $call-twsi  ( ? -- ? )  twsi $call-method  ;

: open  ( -- okay? )
   my-clock-on

   " "  " twsi" $open-package  to twsi
   twsi 0=  if  false exit  then

   my-unit  h# 40  " map-in" $call-parent to my-va

   true
;
: close  ( -- )
   my-va  h# 40  " map-out" $call-parent

   twsi close-package
   my-clock-off
;

1 " #address-cells" integer-property
1 " #size-cells" integer-property

: set-address  ( target -- )  my-va " set-address" $call-twsi  ;

: bytes-out-in  ( out ... #outs #ins -- in ... )  " bytes-out-in" $call-twsi   ;

: get  ( #bytes -- bytes ... )  0 swap  bytes-out-in  ;

: byte@  ( -- )  " byte@" $call-twsi  ;
: byte!  ( -- )  " byte!" $call-twsi  ;
: bytes-out  ( byte .. #bytes -- )  " bytes-out" $call-twsi  ;

\ Useful range is 25K .. 400K - 100K and 400K are typical
: set-bus-speed  ( hz -- )  " set-bus-speed" $call-twsi  ;

finish-device
device-end

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
