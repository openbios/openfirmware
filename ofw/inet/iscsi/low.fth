purpose: iSCSI low level routines
\ See license at end of file

hex

d# 3260 value is_port
0 value use_port	\ remember which port we used, for re-connect

\ parent routines
: connect   ( port -- connected? )
   debug?  if  ." connecting to port " dup .d cr  then
   " connect" $call-parent
   debug? if  dup 0=  if  ." not " then ." connected" cr  then
;
: disconnect   ( -- )
   " disconnect" $call-parent
;
: tcp-read   ( adr len -- actual )  " read"  $call-parent  ;
: tcp-write  ( adr len -- )  	    " write" $call-parent drop  ;
: set-server  ( server$ -- )
   dup  if  " $set-host" $call-parent  else  2drop  then
;


\ we do not have a parent physical device, so get memory directly
: dma-alloc  ( size -- adr )  alloc-mem  ;
: dma-free   ( adr size -- )  free-mem  ;
: dma-map-in   ( vaddr n cache? -- devaddr )  2drop  ;
: dma-map-out  ( vaddr devaddr n -- )  3drop  ;

0 [if]
\ tcp input 

variable rah	\ read ahead buffer
: rah0   ( -- )   0 rah !  ;
: rahlen@   ( -- n )  rah 1+ c@  ;
: rahlen!   ( n -- )  rah 1+ c!  ;

: rah?  ( -- any? )  
   rahlen@ dup 0>  if  exit  then  drop
   rah 1 tcp-read  dup rahlen!  0>
;
: rah@   ( -- c )   rah c@  rah0  ;

: tcp-rd   ( adr len -- actual )
   rah? if
      over rah@ swap c!  1 /string	( adr' len' )
      1 -rot
   then
   tcp-read dup 0> if		( rahl actual' )
      +
   else
      drop
   then
;
[then]

\ timeout
1 [if]
\ XXX for debugging
instance variable endtime
: set-interval  ( interval -- )
   dup  if  get-msecs  +  then  endtime !
;
: timeout?  ( -- flag )
   endtime @  if  get-msecs  endtime @ >=  else  true  then
;
[then]

\ read up to len characters into buffer at adr
\ returns -1 if the connection is closed
: wait-read  ( adr len -- actual )
   d# 60000 set-interval		\ try for up to 60 seconds
   begin
      2dup  tcp-read   dup -2 =        ( adr len actual flag )
   while                               ( adr len actual )
      drop                             ( adr len )
      timeout?  if
         debug?  if  ." wait-read timed out " cr  then
         2drop 0 exit
      then
   repeat                              ( adr len actual )
   nip nip                             ( actual )
;

: (.12)   ( d -- a n )
   <#  d# 12 0 do # loop  #>
;

\ return the mac address as a string
: (mac-address)   ( -- a n )
    mac-address drop dup 2+ be-l@ swap be-w@ (.12)
;

\ convert a decimal string to an integer
: $dnumber  ( adr len -- true | n false )  push-decimal  $number  pop-base  ;

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
