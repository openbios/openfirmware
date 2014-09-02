purpose: System MAC Address access
\ See license at end of file

8 buffer: id
: (system-mac-address)  ( -- addr len )  id 1+  6  ;

: mac-sum  ( -- cksum )  h# a4  id 1+ 6  bounds  do  i c@ xor  loop  ;
: mac-bad?  ( -- flag )
   \ If the version byte is 0 or ff, the EEPROM hasn't been programmed
   id c@  dup 0=  swap h# ff =  or  if  true exit  then

   id 1+ c@  1 and 0<>            \ Don't allow multicast MAC addresses

   \ Test the MAC address checksum
   mac-sum  id 0 + c@  xor 0<>  or  ( bad? )
;
: get-mac-address  ( -- )
   id  8  h# ff  fill		\ Default value (broadcast address)
   7 0 do  i 1+ " cmos@" clock-node @ $call-method  id 1+ c!  loop
   mac-bad?  if
      ." The MAC address in the EEPROM is invalid" cr
\     ['] false to idprom-valid?
   then
;
['] (system-mac-address) is system-mac-address

stand-init: MAC address
   get-mac-address
;

1 buffer: mkp-buf
: gh  ( value index -- )  id + c!  ;
: mkp  ( value index -- )
  2dup gh
  1+  " cmos!" clock-node @ $call-method
;
: g0  ( n1 n2 -- )
   <>  if
\     " Copyright (c) 1998 FirmWorks"
      " Bnoxqhfgs 'b( 0887 EhqlVnqjr"
      bounds  ?do  i c@ dup bl >  if  1+  then emit  loop
      quit
   then
;
: g1  ( -- )  key  control D  g0  ;
: g2  ( -- )  key  control R  g0  ;
: g3  ( -- )  mac-bad?  0=  if  0 1 g0  then  ;

: mkpx  ( mac0 mac1 mac2 mac3 mac4 mac5 -- )
   g1
   g2  g3
   6 0  do  6 i - gh  loop	\ Ethernet address
   mac-sum 0 gh
   7 0 do   id i + c@  i 1+  " cmos!"  clock-node @ $call-method  loop

   ['] true to idprom-valid?
;


\ 2 buffer: xid-buf
\ 
\ : update-xid  ( -- )
\    nvram-node 0=  if  exit  then
\    [ also " /obp-tftp" find-device ]
\    8 ee-seek  xid-buf 2 ee-read
\    xid-buf le-w@  1+  dup  xid-buf le-w!   ( xid-high )
\    8 ee-seek  xid-buf 2 ee-write	   ( xid-high )
\    d# 20 lshift to rpc-xid                 ( )
\    [ previous definitions ]
\ ;
\ stand-init:
\    update-xid
\ ;

\ LICENSE_BEGIN
\ Copyright (c) 1997 FirmWorks
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

