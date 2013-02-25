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
   " wlan-fw" " $getenv" evaluate  if  default-fw$  then
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

: bt-packet-len&type  ( adr -- len type )
   /fw-transport -  dup le-l@  h# ffffff and  /fw-transport -   swap 3 + c@
;

: cmd-out  ( adr len -- error? )
   /fw-transport negate /string         ( adr' len' )
   read-poll                            ( len )
   2dup swap >fw-plen le-w!             ( len )
   CMD_TYPE_CMD 2 pick >fw-type le-w!   ( len )
   packet-out				( error? )
;

: data-out  ( adr len -- )
   /fw-transport negate /string         ( adr' len' )
   read-poll                            ( adr len )
   2dup swap >fw-plen le-w!             ( adr len )
   CMD_TYPE_DATA 2 pick >fw-type le-w!  ( adr len )
   packet-out-async
;

: decode-header  ( buf len -- dadr dlen 8686-type )
   drop                              ( buf )
   dup /fw-transport + swap          ( dadr buf )
   dup >fw-plen le-w@  swap          ( dadr dlen )
   >fw-type le-w@  case
      CMD_TYPE_CMD    of  0  endof
      CMD_TYPE_DATA   of  1  endof
      CMD_TYPE_EVENT  of  2  endof
   endcase                           ( dadr dlen 8686-type )
;
: got-packet?  ( -- false | error true | buf len type 0 true )
   read-poll                 ( )

   get-queued?  if  	     ( buf len )
      decode-header          ( dadr dlen type )
      0  true                ( buf len 0 true )
   else                      ( )
      false                  ( false )
   then
;
: decode-bt-header  ( buf len -- dadr dlen type )
   drop                      ( buf )
   \ SDIO specific header - length: byte[2:0], type: byte[3]
   \ (HCI_COMMAND = 1, ACL_DATA = 2, SCO_DATA = 3, EVENT=4, 0xFE = Vendor)
   dup /fw-transport + swap       ( dadr buf )
   dup le-l@  h# ffffff and swap  ( dadr dlen buf )
   3 + c@                         ( dadr dlen type )
;

: got-bt-packet?  ( -- false | dadr dlen type true )
   read-poll                    ( )

   get-queued?  if  	        ( buf len )
      decode-bt-header true     ( dadr dlen type true )
   else                         ( )
      false                     ( false )
   then
;
: recycle-packet  ( -- )  recycle-queued  ;

0 value rca   \ Relative card address

: set-parent-channel  ( -- )  rca my-unit " set-address" $call-parent  ;

: release-bus-resources  ( -- )  drain-queue detach-card  ;

: ?attach-card  ( -- ok? )
   attach-card  if  set-version 0=  else  false  then
;

: make-my-properties  ( -- )
   " get-address" $call-parent dup to rca
   encode-int " assigned-address" property
;

: setup-bus-io  ( -- error? )
   init-queue
   ?attach-card 0=  if  ." Failed to attach card" cr true exit  then
   make-my-properties
   false
;

: alloc-buffer  ( len -- adr )  /fw-transport +  dma-alloc  ;
: free-buffer  ( adr len -- )  /fw-transport negate /string  dma-free  ;

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
