purpose: USB HID mouse driver using the mouse boot protocol
\ See license at end of file

hex
headers

\ >dr-request constants specific to HID
h# 0b constant SET_PROTOCOL

\ Report buffer
8 constant /report-buf
0 value report-buf

: init-buf  ( -- )
   report-buf 0=  if
      /report-buf dma-alloc
      to report-buf
   then
;
: free-buf  ( -- )
   report-buf  if
      report-buf /report-buf dma-free
      0 to report-buf
   then
;

: set-boot-protocol  ( -- error? )
   0 0 my-address ( interface ) 0 DR_HIDD DR_OUT or SET_PROTOCOL
   control-set
;

\ Retrieve report data.

: begin-scan  ( -- )
   report-buf /report-buf intr-in-pipe intr-in-interval  begin-intr-in
;
: end-scan  ( -- )  end-intr-in  ;

: get-data?  ( adr len -- actual )
   intr-in?  if  nip nip restart-intr-in exit  then	\ USB error; restart
   ?dup  if				( adr len actual )
      min tuck report-buf -rot move	( actual )
      restart-intr-in			( actual )
   else
      2drop 0				( actual )
   then
;
: b>n  ( b -- n )  dup h# 80 and  if  h# ff invert or  then  ;
8 buffer: pkt-buf
: stream-poll?  ( -- false | x y buttons true )
   pkt-buf 8  get-data?  0=  if  false exit  then
   pkt-buf c@ h# 42 =  if  false exit  then
   pkt-buf 1+ c@ b>n         ( x )
   pkt-buf 2+ c@ b>n negate  ( x y )
   pkt-buf c@ 7 and          ( x y buttons )
   true
;

variable refcount  0 refcount !
: +refcount  ( n -- )  refcount +!  ;

\ report-buf must have been allocated
: setup-hardware?  ( -- error? )
   set-device?  if  true exit  then
   device set-target
   reset?  if
      configuration set-config  if
         ." Failed to set USB mouse configuration" cr
         true exit
      then
   then
   set-boot-protocol  if  ." Failed to set USB mouse boot protocol" cr  then
   false
;

: open  ( -- flag )
   refcount @  if  1 +refcount  true exit  then
   init-buf
   setup-hardware?  if  free-buf  false exit  then
   begin-scan
   1 +refcount
   true
;
: close  ( -- )
   -1 +refcount  refcount @  if  exit  then
   free-buf
;

init

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
