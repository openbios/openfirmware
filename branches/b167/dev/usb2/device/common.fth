purpose: USB device driver common routines
\ See license at end of file

headers
hex

fload ${BP}/dev/usb2/error.fth			\ USB error definitions
fload ${BP}/dev/usb2/pkt-data.fth		\ Packet data definitions
fload ${BP}/dev/usb2/hcd/hcd-call.fth		\ HCD interface

0 value device
0 value configuration

0 value bulk-in-pipe
0 value bulk-out-pipe
0 value /bulk-in-pipe
0 value /bulk-out-pipe

0 value intr-in-pipe
0 value intr-out-pipe
0 value intr-in-interval
0 value intr-out-interval
0 value /intr-in-pipe
0 value /intr-out-pipe

0 value iso-in-pipe
0 value iso-out-pipe
0 value /iso-in-pipe
0 value /iso-out-pipe

false instance value debug?

: debug-on  ( -- )  true to debug?  ;

: get-int-property  ( name$ -- n )
  get-my-property  if  0  else  decode-int nip nip  then
;

: init  ( -- )
   " assigned-address"  get-int-property  to device
   " configuration#"    get-int-property  to configuration
   " bulk-in-pipe"      get-int-property  to bulk-in-pipe
   " bulk-out-pipe"     get-int-property  to bulk-out-pipe
   " bulk-in-size"      get-int-property  to /bulk-in-pipe
   " bulk-out-size"     get-int-property  to /bulk-out-pipe
   " iso-in-pipe"       get-int-property  to iso-in-pipe
   " iso-out-pipe"      get-int-property  to iso-out-pipe
   " iso-in-size"       get-int-property  to /iso-in-pipe
   " iso-out-size"      get-int-property  to /iso-out-pipe
   " intr-in-pipe"      get-int-property  to intr-in-pipe
   " intr-out-pipe"     get-int-property  to intr-out-pipe
   " intr-in-size"      get-int-property  to /intr-in-pipe
   " intr-out-size"     get-int-property  to /intr-out-pipe
   " intr-in-interval"  get-int-property  to intr-in-interval
   " intr-out-interval" get-int-property  to intr-out-interval
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
