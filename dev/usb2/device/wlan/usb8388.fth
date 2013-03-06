purpose: USB transport interface for Marvel USB 8388 wireless ethernet driver
\ See license at end of file

headers
hex

false constant multifunction?

\ Used by cmd-out below and also by firmware download routine
: packet-out  ( adr len -- error? )
   " send-out" $call-parent  ( qtd )
   " wait-out" $call-parent  ( error? )
;
: packet-out-async  ( adr len -- )
   " send-out" $call-parent  ( qtd )
   drop
;

\ =======================================================================
\ Wireless environment variables
\    wlan-fw             e.g., rom:usb8388.bin, disk:\usb8388.bin
\ =======================================================================

" mv8388" encode-string  " module-type" property

\ This really depends on the firmware that we load, but we don't want
\ to load the firmware in advance, so we hardcode this.  It will need
\ to be changed if we bundle thin-capable firmware in OFW.
0 0 encode-bytes  " fullmac" property

: wlan-fw  ( -- $ )
   " wlan-fw" " $getenv" evaluate  if  " rom:usb8388.bin"  then  
;

struct
4 field >fw-transport
constant /fw-transport

\ >fw-transport constants for USB/8388
h# f00d.face constant TYPE_USB_REQUEST
h# bead.c0de constant TYPE_USB_DATA
h# beef.face constant TYPE_USB_INDICATION

: cmd-out  ( adr len -- error? )
   /fw-transport negate /string                 ( adr' len' )
   TYPE_USB_REQUEST 2 pick >fw-transport le-l!	( adr len )
   2dup vdump 					( adr len )
   packet-out					( error? )
;

: data-out  ( adr len -- )
   /fw-transport negate /string                 ( adr' len' )
   TYPE_USB_DATA 2 pick >fw-transport le-l!	( adr len )
   packet-out-async
;

\ Translate the USB/8388 type codes into uniform code numbers
: decode-header  ( buf len -- dadr dlen type )
   over le-l@ >r                   ( buf len  r: usb-type )
   /fw-transport /string           ( dadr dlen  r: usb-type )
   r>  case                        
      TYPE_USB_REQUEST     of  0  endof
      TYPE_USB_DATA        of  1  endof
      TYPE_USB_INDICATION  of  2  endof
   endcase                         ( dadr dlen type )
;

: got-packet?  ( -- false | error true | buf len type 0 true )
   bulk-in-ready?  if           ( error | buf len 0 )
      ?dup 0=   if              ( dadr dlen )
         decode-header  0       ( dadr dlen type 0 )
      then                      ( error | buf len 0 )
      true
   else                         ( )
      false                     ( false )
   then    ( false | error true | buf len 0 true )
;
: recycle-packet  ( -- )  restart-bulk-in  ;

: end-out-ring  ( -- )  " end-out-ring" $call-parent  ;

: set-parent-channel  ( -- )  set-device  device set-target  ;

: setup-bus-io  ( -- error? )
   reset?  if
      configuration set-config  if
         ." Failed to set USB configuration for wireless" cr
         true exit
      then
      bulk-in-pipe bulk-out-pipe reset-bulk-toggles
   then
   d# 2048     4 bulk-out-pipe " begin-out-ring" $call-parent
   d# 2048 h# 40 bulk-in-pipe  " begin-in-ring"  $call-parent
   false
;

: release-bus-resources  ( -- )  end-bulk-in end-out-ring  ;

false value fw-loaded?
: reset-host-bus  ( -- )  " wlan-reset" evaluate  false to fw-loaded?  ;

0 value vid
0 value pid

: init  ( -- )
   init
   " vendor-id"  property-or-abort  to vid
   " device-id"  property-or-abort  to pid
   set-parent-channel
;

init

: open  ( -- okay? )  setup-bus-io 0=  ;
: close  ( -- )  ;
: alloc-buffer  ( len -- adr )  /fw-transport +  dma-alloc  /fw-transport +  ;
: free-buffer  ( adr len -- )  /fw-transport negate /string  dma-free  ;

defer setup-transport  ( -- error? )  ' true to setup-transport

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
