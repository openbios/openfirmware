purpose: SDIO interface
\ See license at end of file

hex
headers

0 value ioport
d# 320 constant blksz			\ Block size for data tx/rx
d# 32 constant fw-blksz

: roundup-blksz  ( n -- n' )  blksz 1- + blksz / blksz *  ;

: set-address  ( rca slot -- )  " set-address" $call-parent  ;
: get-address  ( -- rca )       " get-address" $call-parent  ;
: attach-card  ( -- ok?  )  " attach-sdio-card" $call-parent  ;
: detach-card  ( -- )       " detach-sdio-card" $call-parent  ;

\ The following are CMD52 (SDIO) variants
\ Flags: 80:CRC_ERROR  40:ILLEGAL_COMMAND  30:IO_STATE (see spec)
\        08:ERROR  04:reserved  02:INVALID_FUNCTION#  01:OUT_OF_RANGE

h# cf constant SDIO_FLAG_MASK

: .io-state  ( flags & 30 -- )
   case
      h# 00  of  ." card disabled; "  endof
      h# 10  of  ." CMD state; "      endof
      h# 20  of  ." data transfer; "  endof
      h# 30  of  ." reserved; "       endof
   endcase
;
: .sdio-flags  ( flags -- )
   dup SDIO_FLAG_MASK and 0=  if  drop exit  then
   ." IO_RW_DIRECT response = "
   dup h# 80 and  if  ." CRC error; "            then
   dup h# 40 and  if  ." illegal command; "      then
   dup h# 30 and      .io-state
   dup h# 08 and  if  ." error; "                then
   dup h# 02 and  if  ." invalid function; "     then
   dup h# 01 and  if  ." argument out of range"  then
   cr
;

: sdio-reg@  ( reg# function# -- value )
   " io-b@" $call-parent  .sdio-flags
;

: sdio-reg!  ( value reg# function# -- )
   " io-b!" $call-parent  .sdio-flags
;

: sdio-reg!@  ( value reg# function# -- value' )
   " io-b!@" $call-parent  .sdio-flags
;

: sdio-scratch@  ( -- value )
   h# 34 1 sdio-reg@                        ( lo )
   h# 35 1 sdio-reg@                        ( lo hi )
   bwjoin                                   ( value )
;

: sdio-poll-dl-ready  ( -- ready? )
   false d# 100 0  do
      h# 20 1 sdio-reg@                     \ card status register
      h# 9 tuck and =  if  drop true leave  then
      d# 100 usec
   loop
   dup 0=  if  ." sdio-poll-dl-ready failed" cr  then
;

: sdio-blocks@  ( adr len -- actual )
   >r >r
   ioport 1 true  r> r>  blksz true  " r/w-ioblocks" $call-parent  ( actual )
;

: sdio-blocks!  ( adr len -- actual )
   >r >r ioport 1 true r> r> blksz false " r/w-ioblocks" $call-parent
;

: packet-out  ( adr len -- error? )  tuck sdio-blocks! <>  ;
: packet-out-async  ( adr len -- )  sdio-blocks! drop  ;

: sdio-fw!  ( adr len -- actual )
   >r >r ioport 1 true r> r> fw-blksz false " r/w-ioblocks" $call-parent
;

: rx-ready?  ( -- len )
   5 1 sdio-reg@ 				\ Read interrupt status reg
   dup 0=  if  exit  then
   dup invert 3 and 5 1 sdio-reg!               \ Clear UP_LD bit
   1 and  if
      sdio-scratch@ 				\ Read payload length
   else
      0
   then
;

: read-poll  ( -- )
   begin  rx-ready? ?dup  while         ( len )
      new-buffer			( handle adr len )
      sdio-blocks@ drop                 ( handle )
      enque-buffer                      ( )
   repeat
;

: init-device  ( -- )
   3 0  do  i 1 sdio-reg@  loop		\ Read the IO port
   0 bljoin to ioport

   7 0 sdio-reg@  h# 20 or  7 0 sdio-reg!	\ Enable async interrupt mode

   2 2 0 sdio-reg!			\ Enable IO function
   3 4 0 sdio-reg!			\ Enable interrupts
;

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
