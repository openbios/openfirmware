\ See license at end of file
purpose: Driver for NS16550A UART chip which relies on 16550 package support

\ Please Note:  This driver is NOT suitable for a stand-alone FCode ROM.
\ The code relies on a 16550 package and has a selftest method.

hex
headers

" serial" name			\ Name of device for identification
" serial" device-type		\ Device class
" pnpPNP,501" " compatible" string-property

\ This can be overridden if necessary by redefining this property value
\ after loading this file.
d# 1843200 " clock-frequency" integer-property

\ The UART chip occupies 8 bytes of IO space beginning at its base address

my-address my-space  8 reg	\ Report address space used by device

0 instance value support-ih	\ ihandle of 16550 supprt package
variable refcount  0 refcount !

0 value break?			\ Shared between all instances

external
: $call-support  ( ... $ -- ... )  support-ih $call-method  ;

0 instance value base-adr

: set-break  ( -- )  true to break?  ;
: get-break  ( -- flag )  break?  dup  if  false to break?  then  ;

headers
\ Map the device into virtual address space
: map-uart  ( -- )   my-unit  8  " map-in"  $call-parent to base-adr  ;

\ Release the mapping resources used by the device.
: unmap-uart  ( -- )  base-adr 8  " map-out" $call-parent  ;

external

: rts-dtr-off    ( -- )  " rts-dtr-off"   $call-support  ;
: rts-dtr-on     ( -- )  " rts-dtr-on"    $call-support  ;
: use-irqs       ( -- )  " use-irqs"      $call-support  ;
: use-polling    ( -- )  " use-polling"   $call-support  ;
: install-abort  ( -- )  " install-abort" $call-support  ;
: remove-abort   ( -- )  " remove-abort"  $call-support  ;

: read   ( adr len -- actual )  " read"   $call-support  ;
: write  ( adr len -- actual )  " write"  $call-support  ;

: open  ( -- flag )
   map-uart
   my-args " 16550" $open-package  to support-ih
   support-ih 0=  if  unmap-uart false  exit  then
   refcount @ 1+  refcount !
   true
;

: close  ( -- )
   support-ih close-package
   unmap-uart
   refcount @ 1-  0 max  refcount !
;

: selftest  ( -- 0 )		\ Test device by sending a bunch of characters
   refcount @  if  ." Device in use" cr 0 exit  then
   open 0=  if  ." Device won't open" cr true exit  then
   " selftest" $call-support  close   0
;

headers
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
