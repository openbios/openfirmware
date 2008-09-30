purpose: Standard interface methods for the LANCE driver
\ See license at end of file

headers

instance variable le-nbytes
instance variable le-buf

0 instance value obp-tftp
: init-obp-tftp  ( -- okay? )
   " obp-tftp" find-package if		( phandle )
      my-args rot open-package		( ihandle )
   else 0
   then
   dup to obp-tftp			( ihandle | 0 )
   dup 0=  if
      ." Can't open OBP standard TFTP package"  cr
   then
;

: le-xmit  ( bufaddr nbytes -- #sent )
   tuck get-buffer                   ( nbytes bufaddr ether-buffer )
   tuck  3 pick  cmove               ( nbytes ether-buffer )
   dup  dup >devaddr  3 pick         ( nbytes eb eb eb_p nbytes )
   dma-sync                          ( nbytes eb )
   over net-send  if  drop 0  then   ( #sent )
;

: le-poll  ( bufaddr nbytes -- #received )
   le-nbytes ! le-buf !

   receive-ready?  0=  if  0 exit  then		\ Bail out if no packet ready
   receive ?dup if		( buffer-handle ether-buffer length )
      over  dup >devaddr  2 pick
      dma-sync			( buffer-handle ether-buffer length )
      dup >r                    ( buffer-handle ether-buffer length )
      le-nbytes @  min          ( buffer-handle ether-buffer length' )
      le-buf @  swap  cmove     ( handle )
      return-buffer  r>
   else
      drop return-buffer 0
   then
;

: (set-vectors  ( -- )
   rmd0 nextrmd !   tmd0 nexttmd !  
   ['] (.error  to .error
   ['] (.transmit-error to .transmit-error
   ['] noop to handle-broadcast-packet
;
instance defer set-vectors  ' (set-vectors to set-vectors

external

\ Access the address ROM area in 16-bit mode to establish the I/O width
: get-mac-address  ( -- b0 b1 b2 b3 b4 b5 )
   la rw@ wbsplit  la 2 + rw@ wbsplit  la 4 + rw@ wbsplit
;

headers

external
: watch-net ( -- )
   map-chips
   map-lance-buffers
   set-vectors
   prom mode !
   lance-verbose? off
   ext-lbt? off
   net-init  if  watch-test net-off  then
   unmap-lance-buffers
   unmap-chips
;

: read  ( buf len -- -2 | actual-len )
   le-poll  ?dup  0=  if  -2  then
;
: write  ( buf len -- actual-len )  le-xmit  ;

: load  ( adr -- len ) " load" obp-tftp $call-method  ;
: close  ( -- )
   obp-tftp ?dup if close-package then
   net-off
   [ifdef] lance-uninit  lance-uninit  [then]
   unmap-lance-buffers
   unmap-chips
;
: open  ( -- okay? )
   map-chips
   set-vectors
   \ routine to allocate memory and fire up device
   mode off  lance-verbose? off
   map-lance-buffers
   net-init 0=  if  unmap-lance-buffers unmap-chips  false exit  then

   mac-address drop macbuf 6 cmove	\ Update macbuf.
   macbuf 6 encode-bytes  " mac-address" property  \ FIXME should be later.

   init-obp-tftp 0=  if  close  false exit  then
   true
;
: reset  ( -- flag )
   tmd0 if unmap-lance-buffers then
   la if net-off unmap-chips then
   true
;
headers

\ LICENSE_BEGIN
\ Copyright (c) 1994 FirmWorks
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
