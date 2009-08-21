\ See license at end of file
\ ATAPI package implementing a "block" device-type interface.
\
\

headers

: waitonbusy  ( -- )
   h# 2000 0 do
      r-csr@ dup 80 and 0=  if  drop leave  then	\ Exit if not busy
      1 and  if  leave  then				\ Exit if error
      1 ms
   loop
;

: atapi-get-drive-parms  ( -- found? )
   h# a1 r-csr!         \ send identify command

   waitonbusy	\ The busy bit can be set even if there's no slave drive

   r-csr@  dup 0=  swap h# ff =  or  if  false exit  then

   true    atapi-drive?!

   scratchbuf d# 512 pio-rblock  if  false exit  then

   scratchbuf 1+ c@  h# 1f and  dup  drive-type!   ( type )
   5 =  if  d# 2048  else  d# 512  then  /block!

[ifdef] notdef
   \ It's possible that the following workaround was caused by a byte-order
   \ dependency, now fixed, that used to exist in the code above.

   \ This is a workaround for ATAPI CD-ROM drives such as the NEC MultiSpin
   \ 2Vi, which do not have the drive-type in the right byte.
   5 drive-type!
[then]
   true
;

: waitfordrq  ( -- timeout? )
   d# 100 0 do
      r-csr@ dup h# 80 and  if	\ Ignore DRQ if BSY is set
         drop
      else
         8 and  if  false unloop exit  then		\ Exit if DRQ is set
      then
      1 ms
   loop
   true
;

: atapi-reset  ( -- )
   8 chip-base 7 + rb!      \ ATAPI soft reset
   d# 100 0  do
      r-csr@ dup 0= swap 1 and 1 = or  if  leave  then
      d# 16 ms
   loop
;

: flushdata  ( -- )
   h# 10000 0  do
      r-csr@ 8 and 0=  if  unloop exit  then  r-data@ drop
   loop

   \ If the sucker won't stop sending us data, bonk him on the head
   atapi-reset atapi-get-drive-parms
;

: r-feature!  ( feature -- )  1 reg!  ;

: sendcmd  ( cmd len -- )  flushdata  0 r-feature!  r-cyl!  r-csr!  ;

d# 12 constant pkt-len

create pkt-buf pkt-len allot

: +c!  ( n addr -- addr' )  tuck c! 1+  ;
: 2c!  ( n addr -- )  >r lbsplit 2drop  r> +c!         c!  ;
: 4c!  ( n addr -- )  >r lbsplit        r> +c! +c! +c! c!  ;

: >pkt-buf  ( byte offset -- )  pkt-buf + c! ;

defer pio-rwblock  ' noop to pio-rwblock
: sendpkt  ( addr len pkt-addr -- count )
   over h# a0 swap sendcmd                         ( addr len pkt-addr )
   wait-until-drq  pkt-len chip-base io-blk-w!     ( addr len )
   waitonbusy                                      ( addr len )
   waitfordrq  if		\ Timeout          ( addr len )
      h# 100 ms  2drop 0                           ( 0 )
   else				\ No timeout       ( addr len )
      tuck  pio-rwblock drop   waitonbusy           ( len )
   then
;

: clear-pkt-buf  ( -- )  pkt-buf pkt-len erase  ;

0 instance value clen
0 instance value cbuf

: retry-command  ( addr len -- false | count true )
   to clen to cbuf
   h# 10 0  do
      cbuf clen pkt-buf sendpkt
      r-csr@ 1 and 0=  if  unloop true exit  then
      drop
   loop
   false
;

: atapi-read  ( addr block# #blocks -- #read )
   ['] pio-rblock to pio-rwblock
   >r  0 -rot  r>		( #read addr block# #blocks )
   0 ?do			( #read addr block# )
      2dup >r >r		( #read addr block# ) ( R: block# addr )
      clear-pkt-buf		( #read addr block# ) ( R: block# addr )
      h# 28 0 >pkt-buf		\ read (10) command
      1 pkt-buf 7 + 2c!		( #read addr block# ) ( R: block# addr )
      pkt-buf 2 + 4c!		( #read addr ) ( R: block# addr )
      /block@ retry-command  0=  if  r> r> leave  then  ( #read count )
      swap 1+ swap		( #read' count )
      r> r> 1+			( #read' count addr block#' )
      -rot + swap		( #read' addr' block#' )
   loop  2drop			( #read )
;

: atapi-write  ( addr block# #blocks -- #write )
   ['] pio-wblock to pio-rwblock
   >r  0 -rot  r>		( #write addr block# #blocks )
   0 ?do			( #write addr block# )
      2dup >r >r		( #write addr block# ) ( R: block# addr )
      clear-pkt-buf		( #write addr block# ) ( R: block# addr )
      h# 2a 0 >pkt-buf		\ write (10) command
      1 pkt-buf 7 + 2c!		( #write addr block# ) ( R: block# addr )
      pkt-buf 2 + 4c!		( #write addr ) ( R: block# addr )
      /block@ retry-command  0=  if  r> r> leave  then  ( #write count )
      swap 1+ swap		( #write' count )
      r> r> 1+			( #write' count addr block#' )
      -rot + swap		( #write' addr' block#' )
   loop  2drop			( #write )
;

: be-l@  ( adr -- l )
   >r  r@ 3 + c@  r@ 2+ c@  r@ 1+ c@  r> c@  bljoin
;

: atapi-capacity  ( -- n )
   ['] pio-rblock to pio-rwblock
   clear-pkt-buf
   h# 25 0 >pkt-buf
   scratchbuf 8 retry-command  if  drop scratchbuf be-l@  else  0  then
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
