\ See license at end of file
\ Intel 21143 FCode Ethernet driver

hex

" Intel,21143" model

\ Read the 21143 serial ROM
: delay   ( -- )  1 ms  ;
: s!  ( value -- )  srom e!  delay  ;
: 1bit!  ( 0|1 -- )
   2 lshift  2801 or  dup  s!  dup  2 or  s!  srom e!
;
: 1bit@  ( -- 0|1 )  2803 s!  srom e@  3 rshift 1 and  2801 s!  ;
: setup  ( index -- )
   1 1bit!  1 1bit!  0 1bit!
   0 5  do  dup  i rshift 1 and 1bit!  -1 +loop  drop
;
: setdown  ( -- )  2800 s!  ;
: serial@  ( index -- w )
   setup
   0  10 0  do  1 lshift  1bit@ or  loop
   setdown
;

: subsystem-id?  ( vid -- flag )
   dup 0=  if  drop false exit  then                      ( vid )
   " subsystem-vendor-id" get-my-property  if  drop false exit  then  ( vid $ )
   decode-int nip nip <>  if  false exit  then            ( )
   " subsystem-id" get-my-property  if  false exit  then  ( $ )
   decode-int nip nip                                     ( sid )
   1 serial@ =
;

: get-srom   ( -- 6 5 4 3 2 1 )
   \ Workaround: the first read often doesn't work correctly
   0 serial@ drop     0 serial@ drop

   \ Determine the starting index of the MAC address.
   \ The old standard is the DEC UID format, in which the MAC address is
   \ stored at indices 0..2 with a checksum at 3; the whole thing is
   \ duplicated at 8..b and a byte-reversed version is at f..4 .
   \ (See arch/decnc/uid.fth:check-id for more info.)

   \ The modern standard appears to be that the MAC address starts at index
   \ 0xa, with the subsystem vendor ID at index 0 and the subsystem ID at
   \ index 1.

   0 serial@  subsystem-id?  if  h# a  else  0  then       ( srom-index )

   dup 2 +  do  i serial@ wbsplit swap  -1 +loop
;

external
: tp  ( -- )
   ctl e@  h# 4000 or  ctl e!
   ctl e@  h# 0004.0000 invert and  ctl e!
   0 csr13 e!					\ SIA reset, 10Base-T
   0 csr14 e!					\ enable
   8 csr15 e!					\ enable external transceiver
   ctl e@  h# 0004.0000 or  ctl e!		\ port select, half-duplex
;
: coax  ( -- )
;
: aui  ( -- )
;
: 100bt  ( -- )
   \ XXX implement me
;
' tp to set-interface	\ Default to 10BaseT for now

headers

: init-21143  ( -- )
   0 40 my-space + " config-l!" $call-parent	\ exit sleep mode
;

init-21143
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
