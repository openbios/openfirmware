purpose: Transport interface for Marvel 8686 wireless ethernet driver
\ See license at end of file

headers
hex

\ =======================================================================
\ Wireless environment variables
\    wlan-fw             e.g., rom:mv8686.bin, disk:\mv8686.bin
\    wlan-helper         e.g., rom:mvhelper.bin, disk:\mvhelper.bin
\ =======================================================================

: wlan-fw  ( -- $ )
   " wlan-fw" " $getenv" evaluate  if  " rom:sd8686.bin"  then  
;
: wlan-helper  ( -- $ )
   " wlan-helper" " $getenv" evaluate  if  " rom:helper_sd.bin"  then
;

\ >fw-type constants
0 constant CMD_TYPE_DATA
1 constant CMD_TYPE_CMD
3 constant CMD_TYPE_EVENT

struct
2 field >fw-plen
2 field >fw-type
constant /fw-transport

: packet-type  ( adr -- type )
   >fw-type le-w@  case
      CMD_TYPE_CMD    of  0  endof
      CMD_TYPE_DATA   of  1  endof
      CMD_TYPE_EVENT  of  2  endof
   endcase
;

: cmd-out  ( adr len -- error? )
   read-poll
   2dup swap >fw-plen le-w!             ( len )
   CMD_TYPE_CMD 2 pick >fw-type le-w!   ( len )

   2dup vdump				( adr len )
   packet-out				( error? )
;

: data-out  ( adr len -- )
   read-poll
   2dup swap >fw-plen le-w!             ( adr len )
   CMD_TYPE_DATA 2 pick >fw-type le-w!  ( adr len )
   packet-out-async
;

: got-packet?  ( -- false | error true | buf len 0 true )
   read-poll            ( )

   get-queued?  if  	( buf len )
      0  true           ( buf len 0 true )
   else                 ( )
      false             ( false )
   then
;
: recycle-packet  ( -- )  recycle-queued  ;

0 value rca   \ Relative card address

: set-parent-channel  ( -- )  rca my-unit set-address  ;

: release-bus-resources  ( -- )  drain-queue detach-card  ;

0 value card-attached?

: ?attach-card  ( -- ok? )
   card-attached?  if  true exit  then
   attach-card  dup to card-attached?   ( ok? )
;

: make-my-properties  ( -- )
   get-address dup to rca
   encode-int " assigned-address" property
;

: setup-bus-io  ( /inbuf /outbuf -- error? )
   2drop
   init-queue
   ?attach-card 0=  if  ." Fail to attach card" cr true exit  then
   make-my-properties
   init-device
   false
;

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
