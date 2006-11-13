purpose: Common USB UART stuff
\ See license at end of file

hex

external
defer rts-dtr-off	' noop to rts-dtr-off
defer rts-dtr-on	' noop to rts-dtr-on
defer inituart		' noop to inituart
defer rpoll		' noop to rpoll

: def-r/w-bytes    ( adr len -- actual )  2drop 0  ;
defer read-bytes   ( adr len -- actual )  ' def-r/w-bytes to read-bytes
defer write-bytes  ( adr len -- actual )  ' def-r/w-bytes to write-bytes

headers

defer init-hook		' noop to init-hook

0 value vid
0 value pid

0 value outbuf
d# 1024 constant /outbuf

0 value inbuf

0 value intrbuf

: init-buf  ( -- )
   outbuf 0=  if  /outbuf       dma-alloc to outbuf  then
   inbuf  0=  if  /bulk-in-pipe dma-alloc to inbuf  then
   /intr-in-pipe intrbuf 0= and  if
      /intr-in-pipe dma-alloc to intrbuf
   then
;
: free-buf  ( -- )
   outbuf   if  outbuf  /outbuf       dma-free  0 to outbuf  then
   inbuf    if  inbuf   /bulk-in-pipe dma-free  0 to inbuf  then
   intrbuf  if  intrbuf /intr-in-pipe dma-free  0 to intrbuf  then
;

: init  ( -- )
   init
   " vendor-id"  get-int-property  to vid
   " device-id"  get-int-property  to pid
;


\ Gritty operational portion of the driver

0 value break?
false value lost-carrier?

: set-address  ( dev -- )  " set-address" $call-parent  ;

: set-break  ( -- )  true to break?  ;
: get-break  ( -- flag )  break?  dup  if  false to break?  then  ;
: poll-tty  ( -- )  get-break  if  user-abort  then  ;

external

\ Queues for collecting received bytes
d# 1024 constant /q

struct
/n field >head
/n field >tail
/q field >qdata
constant /qstruct

/qstruct buffer: read-q

: init-q  ( q -- )  0 over >head !  0 swap >tail !   ;
: inc-q-ptr  ( pointer-addr -- )
   dup @  ca1+  dup /q  =  if  drop 0  then  swap !
;

: enque  ( new-entry q -- )
   over 0=  if  set-break 2drop exit  then
   >r
   r@ >tail @  r@ >head @  2dup >  if  - /q  then  1-     ( entry tail head )
   <>  if  r@ >qdata  r@ >tail @ ca+ c!  r@ >tail inc-q-ptr  else  drop  then
   r> drop
;

\ This is only called for the queue for "port"
: deque?  ( q -- false | entry true )
   >r
   r@ >head @  r@ >tail @  <>  if
      r@ >qdata  r@ >head @  ca+ c@  r@ >head inc-q-ptr  true
   else
      false
   then
   r> drop
;


: generic-rpoll  ( -- )
   bulk-in?  if  drop restart-bulk-in exit  then	\ USB error; restart
   ?dup  if
      0 ?do
         inbuf i ca+ c@ read-q enque
      loop
      restart-bulk-in
   then
;
' generic-rpoll to rpoll

: generic-write-bytes  ( adr len -- actual )
   swap >r			( len )  ( R: adr )
   /outbuf /mod			( rem #loop )
   r> 0 rot 0  ?do		( rem adr act )
      over outbuf /outbuf move	( rem adr act )
      outbuf /outbuf bulk-out-pipe bulk-out
				( rem adr act usberr )
      if  nip nip exit  then
      /outbuf +			( rem adr act' )
      swap /outbuf + swap	( rem adr' act' )
   loop				( rem adr' act' ) 

   -rot swap			( act adr rem )
   tuck outbuf swap move	( act rem )
   outbuf over bulk-out-pipe bulk-out
				( act rem usberr )
   if  drop  else  +  then	( act' )
;
' generic-write-bytes to write-bytes


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
