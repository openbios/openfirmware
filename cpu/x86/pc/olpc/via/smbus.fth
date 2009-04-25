purpose: Driver for SMBUS controller in Via chipset
\ See license at end of file

: smb-reg@  ( reg# -- value )  smbus-io-base + pc@  ;
: smb-reg!  ( value reg# -- )  smbus-io-base + pc!  ;

0 value smbus-target

\ Register 1 is slave status; we don't use it
: smb-hoststat@   ( -- byte )  0 smb-reg@  ; \ Various status bits - busy bit is bit 0
: smb-hoststat!   ( byte -- )  0 smb-reg!  ; \ Lots of Write 1 to Clear bits herein
: smb-hostctl!    ( byte -- )  2 smb-reg!  ; \ Write this register to start the transaction
: smb-hostcmd@    ( -- byte )  2 smb-reg@  ; \ Reads reset the block data counter
: smb-hostcmd!    ( byte -- )  3 smb-reg!  ; \ Send in protocol Command Field
: smb-xmitadr!    ( byte -- )  4 smb-reg!  ; \ Target address
: smb-hostdata0!  ( byte -- )  5 smb-reg!  ; \ Data0 out
: smb-hostdata0@  ( -- byte )  5 smb-reg@  ; \ Data0 in
: smb-hostdata1!  ( byte -- )  6 smb-reg!  ; \ Data1 out
: smb-hostdata1@  ( -- byte )  6 smb-reg@  ; \ Data1 in
: smb-blockdata!  ( byte -- )  7 smb-reg!  ; \ Block data out
: smb-blockdata@  ( -- byte )  7 smb-reg@  ; \ Block data in
: smbus-delay  ( -- )  1 us  ;
: smbus-wait  ( -- )
   d# 1,000,000 0  do
      smbus-delay
      0 smb-reg@ 1 and 0=  if  unloop exit  then
   loop
   ." SMBUS timeout" cr
;

: smbus-cmd  ( cmd -- )
   h# 40 or smb-hostctl!  ( )  \ 40 is go bit
   smbus-wait             ( )
   smb-hoststat@          ( stat )
   dup h# 9c and  if      ( stat )
      ." SMBUS error:"    ( stat )
      dup h# 80 and  if  ."  PEC"                   then
      dup h# 10 and  if  ."  FailedBusTransaction"  then
      dup h# 08 and  if  ."  Collision"             then
      dup h# 04 and  if  ."  DeviceError"           then
      cr                  ( stat )
   then                   ( stat )
   drop                   ( )
   h# 9e smb-hoststat!    ( )  \ Clear all status bits
;

\ Bracket groups of SMBUS usage with  smbus-acquire ... smbus-release
: smbus-acquire  ( target -- )
   2* to smbus-target

   \ We don't do the real semaphore thing because we "own" the machine exclusively
   h# ff smb-hoststat!   \ Clear all errors, plus the ownership semaphore
   smbus-wait  
;

\ Release semaphore so it will read back as 0 the next time someone looks
: smbus-release  ( -- )  h# 40 smb-hoststat!  ;

: smbus-write  ( adr len offset -- )  \ Up to 32 bytes
   smbus-target smb-xmitadr!      ( adr len offset )
   smb-hostcmd!                   ( adr len )      \ Starting offset
   dup smb-hostdata0!             ( adr len )      \ Length
   smb-hoststat@ drop             ( adr len )      \ Reset block transfer counter
   bounds  ?do  i c@ smb-blockdata!  loop  ( )     \ Copy data to chip
   h# 34 smbus-cmd                ( )              \ I2C block command
;
: smbus-read  ( adr maxlen offset -- actlen )  \ Up to 32 bytes
   smbus-target 1 or smb-xmitadr! ( adr maxlen offset )
   smb-hostcmd!                   ( adr maxlen )   \ Starting offset
   h# 34 smbus-cmd                ( adr maxlen )   \ I2C block command
   smb-hostdata0@ min             ( adr actlen )   \ Number of bytes returned
   smb-hoststat@ drop             ( adr actlen )   \ Reset block transfer counter
   tuck  bounds  ?do  smb-blockdata@  i c!   loop  ( actlen )  \ Copy data from chip
;

: smbus-b!  ( byte offset -- )
   smbus-target smb-xmitadr!  ( byte offset )
   smb-hostcmd!               ( byte )
   smb-hostdata0!             ( )
   h# 8 smbus-cmd             ( )
;
: smbus-b@  ( offset -- byte )
   smbus-target 1 or smb-xmitadr!  ( offset )
   smb-hostcmd!                    ( )
\  0 smb-hostdata0!                ( )  \ Clear host data port
   8 smbus-cmd                     ( )  \ byte data command
   smb-hostdata0@                  ( byte )
;

: smbus-w!  ( word offset -- )
   smbus-target smb-xmitadr!   ( word offset )
   smb-hostcmd!                ( word )
   wbsplit                     ( low high )
   smb-hostdata1!              ( low )
   smb-hostdata0!              ( )
   h# c smbus-cmd              ( )   \ Word data command
;
: smbus-w@  ( offset -- word )
   smbus-target 1 or smb-xmitadr!  ( offset )
   smb-hostcmd!                    ( )
\  0 smb-hostdata0!                ( )  \ Clear host data port
   h# c smbus-cmd                  ( )  \ Word data command
   smb-hostdata0@                  ( low )
   smb-hostdata1@                  ( high )
   bwjoin                          ( word )
;

: enable-smbus  ( -- )
   h# 8894 config-b@  h# 80 invert and  h# 8894 config-b!  \ Clock from 14 MHz divider
   smbus-io-base 1 or  h# 88d0 config-w!
   5 h# 88d2 config-b!   \ Clock source (bit meaning is unclear), enable SMBUS HC
   3 h# 8804 config-w!   \ Enable in PCI command register
   smbus-release
;

: get-spd-data  ( offset dimm -- byte )
   7 and h# 50 or  smbus-acquire    ( offset )  \ DIMMs are IDs 50-57
   smbus-b@
   smbus-release
;

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
