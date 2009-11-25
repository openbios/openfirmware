purpose: Driver for SMBUS controller in Via chipset
\ See license at end of file

0 value smbus-port

: smb-reg@  ( reg# -- value )  smbus-port + pc@  ;
: smb-reg!  ( value reg# -- )  smbus-port + pc!  ;

0 value smbus-target

\ Register 1 is slave status; we don't use it
: smb-hoststat@   ( -- byte )  0 smb-reg@  ; \ Various status bits - busy bit is bit 0
: smb-hoststat!   ( byte -- )  0 smb-reg!  ; \ Lots of Write 1 to Clear bits herein
: smb-hostctl!    ( byte -- )  2 smb-reg!  ; \ Write this register to start the transaction
: smb-hostctl@    ( -- byte )  2 smb-reg@  ; \ Reads reset the block data counter
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
   h# 9e smb-hoststat!    ( )  \ Clear all status bits
   dup h# 9c and  if      ( stat )
      dup h# 80 and  abort" SMBUS error: PEC"                   
      dup h# 10 and  abort" SMBUS error: FailedBusTransaction"
      dup h# 08 and  abort" SMBUS error: Collision"
      dup h# 04 and  abort" SMBUS error: DeviceError"
      drop
   then                   ( stat )
   drop                   ( )
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

: i2c-write  ( adr len offset -- )  \ Up to 32 bytes
   smbus-target smb-xmitadr!      ( adr len offset )
   smb-hostcmd!                   ( adr len )      \ Starting offset
   dup smb-hostdata0!             ( adr len )      \ Length
   smb-hostctl@ drop              ( adr len )      \ Reset block transfer counter
   bounds  ?do  i c@ smb-blockdata!  loop  ( )     \ Copy data to chip
   h# 34 smbus-cmd                ( )              \ I2C block command
;
: i2c-read  ( adr maxlen offset -- actlen )  \ Up to 32 bytes
   smbus-target 1 or smb-xmitadr! ( adr maxlen offset )
   smb-hostcmd!                   ( adr maxlen )   \ Starting offset
   h# 34 smbus-cmd                ( adr maxlen )   \ I2C block command
   smb-hostdata0@ min             ( adr actlen )   \ Number of bytes returned
   smb-hostctl@ drop              ( adr actlen )   \ Reset block transfer counter
   tuck  bounds  ?do  smb-blockdata@  i c!   loop  ( actlen )  \ Copy data from chip
;

: smbus-write  ( adr len offset -- )  \ Up to 32 bytes
   smbus-target smb-xmitadr!      ( adr len offset )
   smb-hostcmd!                   ( adr len )      \ Starting offset
   dup smb-hostdata0!             ( adr len )      \ Length
   smb-hostctl@ drop              ( adr len )      \ Reset block transfer counter
   bounds  ?do  i c@ smb-blockdata!  loop  ( )     \ Copy data to chip
   h# 14 smbus-cmd                ( )              \ SMBus block command
;
: smbus-read  ( adr maxlen offset -- actlen )  \ Up to 32 bytes
   smbus-target 1 or smb-xmitadr! ( adr maxlen offset )
   smb-hostcmd!                   ( adr maxlen )   \ Starting offset
   h# 14 smbus-cmd                ( adr maxlen )   \ SMBus block command
   smb-hostdata0@ min             ( adr actlen )   \ Number of bytes returned
   smb-hostctl@ drop              ( adr actlen )   \ Reset block transfer counter
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
\  smbus-io-base 1 or  h# 88d0 config-w!  \ Assume already set up
   5 h# 88d2 config-b!   \ Clock source (bit meaning is unclear), enable SMBUS HC
   3 h# 8804 config-w!   \ Enable in PCI command register
   smbus-release
;

: get-spd-data  ( offset dimm -- byte )
   7 and h# 50 or  smbus-acquire    ( offset )  \ DIMMs are IDs 50-57
   smbus-b@
   smbus-release
;
: dump-dimm  ( dimm# -- )
   h# 80 0  do
     i 2 u.r  ." : "
     i 10 bounds do
        i over get-spd-data 3 u.r
     loop
     cr
   h# 10 +loop
;
: dump-dimms  ( -- )
   2 0 do
      0 i ['] get-spd-data catch  if  ( x x )
         2drop
      else    ( byte )
         drop
         ." DIMM# " i . cr
         i dump-dimm
      then
   loop
;

stand-init: SMBUS
   enable-smbus
   h# 88d0 config-w@ h# fff0 and  to smbus-port
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
