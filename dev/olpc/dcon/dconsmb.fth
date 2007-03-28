\ See license at end of file
purpose: DCON SMB driver for Geode 5536 companion chip

0 value smb-base
: smb@   ( reg# -- b )  smb-base +  pc@   ;
: smb!   ( b reg# -- )  smb-base +  pc!   ;

h# 70 value smb-clock  \ 8 is the shortest period the controller allows

: smb-on  ( -- )
   h# 5140000b rdmsr drop to smb-base
   \ Empirically, it doesn't work if you set reg 6 before reg 5
   \ First set the registers with the enable bit clear
   smb-clock 1 lshift         5 smb!
   smb-clock 7 rshift         6 smb!
   1 ms
   \ Finally turn on the enable
   \ Being extra paranoid because we've had trouble with this bus
   smb-clock 1 lshift  1 or   5 smb!
   h# 20 1 smb!  \ Clear bus error bit
;
: smb-off  ( -- )  0 5 smb!  ;

: smb-stop  ( -- )  2 3 smb!  ;

\ This little dance seemed to help at one point when we were having
\ problems getting the SMBus going reliably.  It might not be
\ necessary now that we have the clock going slower, but I'm not sure.
: smb-init  ( -- )  smb-on  smb-stop  smb-off  smb-on  ;

: smb-status  ( -- b )
   1 smb@  dup 1 smb!
   dup h# 20 and  abort" SMB Bus conflict"
;

: wait-ready  ( -- )
   d# 1000 0  do
      smb-status  h# 40 and  if  unloop exit  then
   loop
   smb-stop
   smb-off
   true abort" SMB wait-ready timed out"
;

: smb-byte-out  ( b -- )
   wait-ready  0 smb!
   smb-status h# 10 and  abort" No ACK"
;

: wait-start  ( -- )
   d# 1000 0  do
      smb-status  2 and  if  unloop exit  then
   loop
   smb-stop
   smb-off
   true abort" SMB start timed out"
;
: smb-start  ( addr-byte -- )
   1 3 smb!  \ Start condition

   wait-start
   
   smb-byte-out  \ Send address and R/W
;


: dcon@  ( reg# -- w )
   h# 1a  smb-start   smb-byte-out  \ Address and reg#
   h# 1b  smb-start   \ Switch to read
   wait-ready
   0 smb@                       ( low-byte )
   h# 10 3 smb!       \ Set NAK for next byte before reading i
   wait-ready  0 smb@   bwjoin  ( w )
   smb-stop
;
: dcon!  ( w reg# -- )
   h# 1a  smb-start  smb-byte-out            ( w )
   wbsplit swap  smb-byte-out  smb-byte-out  ( )
   wait-ready
   smb-stop
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
