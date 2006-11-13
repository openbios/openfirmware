\ See license at end of file
purpose: MIF interface to PHY

hex

0 value phyadr

\ Use the mii-delay and set-idle methodology as employed by Linux driver.

: mii-delay  ( -- )  srom e@ drop  ;
: mii!  ( flag bitmask -- )
   srom e@  swap  rot  if  or  else  invert and  then  srom e!  mii-delay
;
: mif-data@ ( -- )  srom e@  d# 19 rshift  1 and  ;
: mif-data! ( -- )  h# 2.0000  mii!  ;
: bb-oe!   ( out? -- )  0=  h# 4.0000  mii!  ;
: bb-clock!  ( high? -- )  h# 1.0000 mii!  ;

d# 16 constant #data-bits

: bb-data@  ( -- bit )  0 bb-clock!  mif-data@  1 bb-clock!  ;
: bb-data!  ( bit -- )  mif-data!  0 bb-clock!  1 bb-clock!  ;

: write-sbits  ( data #bits -- )	\ Write data using bit banging
   1 bb-oe!
   dup 1- swap  0  ?do		( n #bits-1 )
      2dup i - rshift 1 and 	( n #bits-1 bit)
      bb-data!			( n #bits-1 )
   loop  2drop			( )
   0 bb-oe!			( )
;

: read-sbits  ( #bits -- data )		\ Read data using bit banging
   0 bb-oe!  0  swap 0  ?do   1 lshift  bb-data@  or  loop
;

: set-idle  ( -- )
   d# 32 0 do
      h# 2.0000 srom e!  mii-delay
      h# 3.0000 srom e!  mii-delay
   loop
;

: mii-setup  ( reg op -- )
   set-idle
   1 2 write-sbits       ( reg op )
     2 write-sbits       ( reg )
   phyadr 5 write-sbits  ( reg )
     5 write-sbits       ( )
;

\ The following words are used outside this file
: mii-read  ( reg -- data )
   2 mii-setup
   bb-data@ drop  bb-data@ drop   #data-bits read-sbits
   \ 1 ms			\ need to wait before sending idle
   set-idle
;
: mii-write  ( data reg -- )
   1 mii-setup
   2 2 write-sbits  #data-bits write-sbits
   \ 1 ms			\ need to wait before sending idle
   set-idle
;

true value xcvr-present?  ( -- present? )

0 value andv	\ Debug
0 value dsdv	\ Debug

0 value hm-timeout
: set-hm-timeout  ( #ms -- )   get-msecs + to hm-timeout  ;
: hm-timeout?  ( -- flag )  get-msecs hm-timeout - 0>=  ;

0 value an-timeout
: set-an-timeout  ( #ms -- )   get-msecs + to an-timeout  ;
: an-timeout?  ( -- flag )  get-msecs an-timeout - 0>=  ;

fload ${BP}/dev/dec21140/transcvr.fth

: phy-present?  ( -- flag )
   h# 20 0  do
      i to phyadr
      2 mii-read  dup h# ffff <>  swap 0<>  and  if  true unloop exit  then
   loop
   0 to phyadr
   false exit
;

: set-mac-interface  ( -- )
   \ Select the MII port for half- or full-duplex modes.
   ctl e@  h# 4.0000 invert and ctl e!
   0 csr13 e!
   0 csr14 e!

   \ Select the MII port (4.0000 bit) and set the FIFO threshold
   \ (40.0000 bit) according to the link speed.
   ctl e@  h# 4.4000 or h# 48.0200 invert and
\   phy-control-reg@ phy-speed-100 and 0=  
\   if  h# 40.0000  else  h# 8.0000  then  or
\   phy-control-reg@ phy-duplex and  if  h# 200 or  then	\ full-duplex
   h# 14 mii-read h# 800 and 0=  if  h# 40.0000  else  h# 8.0000  then  or
   h# 14 mii-read h# 1000 and  if  h# 200  or  then
   ctl e!
;

: auto-set-interface  ( -- )
   phy-present?  if
      phy-status-reg@ phy-link-up and 0=  if  setup-mii?  else  0  then
      0=  if  set-mac-interface exit  then
   then
   tp
;
' auto-set-interface to set-interface
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
