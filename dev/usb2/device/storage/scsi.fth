purpose: USB Mass Storage Device Driver
\ See license at end of file

headers
hex

0          value max-lun
0 instance value lun

USB_ERR_STALL constant bus-reset

defer execute-command-hook  ' noop to execute-command-hook
defer init-execute-command  ' noop to init-execute-command


\ Class specific >dr-request constants
h# ff constant DEV_RESET
h# fe constant GET_MAX_LUN

\ Command Block Wrapper
struct
   4 field >cbw-sig
   4 field >cbw-tag
   4 field >cbw-dlen
   1 field >cbw-flag
   1 field >cbw-lun
   1 field >cbw-cblen
h# 10 field >cbw-cb
constant /cbw

\ >cbw-flag definitions
80 constant cbw-flag-in
00 constant cbw-flag-out

\ Command Status Wrapper
struct
   4 field >csw-sig
   4 field >csw-tag
   4 field >csw-dlen
   1 field >csw-stat
constant /csw

h# 43425355 constant cbw-signature	\ little-endian
h# 53425355 constant csw-signature	\ little-endian

0 value cbw-tag
0 value cbw
0 value csw

: init-cbw  ( -- )
   cbw /cbw erase
   cbw-signature cbw >cbw-sig le-l!
   cbw-tag 1+ to cbw-tag
   cbw-tag cbw >cbw-tag le-l!
;
: alloc-bulk  ( -- )
   cbw 0=  if  /cbw dma-alloc to cbw  then
   csw 0=  if  /csw dma-alloc to csw  then
;
: free-bulk  ( -- )
   cbw  if  cbw /cbw dma-free  0 to cbw  then
   csw  if  csw /csw dma-free  0 to csw  then
;

1 buffer: max-lun-buf

: get-max-lun  ( -- )
   max-lun-buf 1 my-address ( interface ) 0 DR_IN DR_CLASS DR_INTERFACE or or
   GET_MAX_LUN control-get  if			( actual usberr )
      drop 0
   else
      ( actual )  if  max-lun-buf c@  else  0  then
   then
   to max-lun
;

: init  ( -- )
   init
   init-execute-command
   alloc-bulk
   device set-target
   configuration set-config  if  ." Failed to set storage configuration" cr  then
   get-max-lun
   free-bulk
;

: transport-reset  ( -- )
   0 0 my-address ( interface ) 0 DR_OUT DR_CLASS DR_INTERFACE or or
   DEV_RESET control-set-nostat  drop
   \ XXX Wait until devices does not NAK anymore
   bulk-in-pipe  h# 80 or unstall-pipe
   bulk-out-pipe          unstall-pipe
;

: wrap-cbw  ( data-len dir cmd-adr,len -- cbw-adr,len )
   init-cbw				( data-len dir cmd-adr,len )
   cbw >r				( data-len dir cmd-adr,len )  ( R: cbw )
   dup r@ >cbw-cblen c!			( data-len dir cmd-adr,len )  ( R: cbw )
   r@ >cbw-cb swap move			( data-len dir )  ( R: cbw )
   if  cbw-flag-in  else  cbw-flag-out  then	( data-len cbw-flag )  ( R: cbw )
   r@ >cbw-flag c!			( data-len )  ( R: cbw )
   r@ >cbw-dlen le-l!			( )  ( R: cbw )
   lun r@ >cbw-lun c!			( )  ( R: cbw )
   r> /cbw				( cbw-adr,len )
;

: (get-csw)  ( -- len usberr )  csw /csw bulk-in-pipe bulk-in  ;
: get-csw  ( -- len usberr )
   (get-csw) dup  if  2drop (get-csw)  then
;

d# 15,000 constant bulk-timeout

: (execute-command)  ( data-adr,len dir cbw-adr,len -- hwresult | statbyte 0 )
   debug?  if
      2dup " dump" evaluate cr
   then

   bulk-out-pipe bulk-out		( data-adr,len dir usberr )
   USB_ERR_CRC invert and		( data-adr,len dir usberr' )
   ?dup  if  nip nip nip  exit  then	( data-adr,len dir )

   over  if
      if				( data-adr,len )
         bulk-in-pipe bulk-in 2drop	( )
      else
         bulk-out-pipe bulk-out drop	( )
      then
   else					( data-adr,len dir )
      drop 2drop			( )
   then

   get-csw				( len usberr )
   ?dup  if  nip exit  then
   debug?  if
      csw /csw " dump" evaluate cr
   then

   drop csw >csw-stat c@		( cswStatus )
   case
      0  of  0 0  endof			\ No error
      1  of  2 0  endof			\ Error, "check condition"
      2  of  transport-reset		\ Phase error, reset recovery
	     USB_ERR_STALL  endof
      ( default )  0 0 rot		\ Reserved error
   endcase
;

external

: execute-command  ( data-adr,len dir cmd-adr,len -- hwresult | statbyte 0 )
   execute-command-hook
   over c@ h# 1b = 2 pick 4 + c@ 1 = and >r	\ Start command?
   2over 2swap wrap-cbw				( data-adr,len dir cbw-adr,len )
   (execute-command)
   r>  if  dup 0=  if  nip 0  then  then	\ Fake ok
;

: set-address  ( lun -- )
   0 max max-lun min  to lun
   device set-target
;
: set-timeout  ( n -- )  bulk-timeout max set-bulk-in-timeout  ;

: reopen-hardware   ( -- ok? )  true  ;
: open-hardware     ( -- ok? )  alloc-bulk  reopen-hardware  ;
: reclose-hardware  ( -- )	;
: close-hardware    ( -- )      free-bulk  ;

: reset  ( -- )  transport-reset  ;

: selftest  ( -- 0 | error-code )  0  ;

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
