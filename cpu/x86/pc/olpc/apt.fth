\ See license at end of file
purpose: Common developer utilities

: newrom  enable-serial  " flash! http:\\192.168.200.200\new.rom" eval  ;
: urom  enable-serial " flash! u:\new.rom" eval  ;

: newec  " flash-ec http:\\192.168.200.200\ecimage.bin" eval  ;
: uec   " flash-ec! u:\ecimage.bin" eval  ;

: qz  " qz" $essid  " http:\\qz\" included  ;

: no-usb-delay  " dev /usb  false to delay?  dend"  evaluate  ;

: null-fsdisk  \ for testing fs-update without writing
   " dev /null : size 0 8 ; : write-blocks-start 3drop false ; : write-blocks-end false ; dend" evaluate
   " devalias fsdisk //null" evaluate
;

: .os  " more int:\boot\olpc_build" eval  ;

: boost  .bat  cr  h# 3b ec-cmd  d# 1000 ms  h# 3c ec-cmd  d# 1000 ms  .bat  ;

stand-init: wifi
   " NN" find-tag  if  ?-null  $essid  then  \ network name
   " PP" find-tag  if  ?-null  $wpa    then  \ pass phrase
;

\ LICENSE_BEGIN
\ Copyright (c) 2013 FirmWorks
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
