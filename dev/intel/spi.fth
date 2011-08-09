\ See license at end of file
purpose: Driver for SPI FLASH chips connected via Intel NM10 SPI interface

h# fed1f020 value spi-base
: spi-reg-b!  ( b offset -- )  spi-base + c!  ;
: spi-reg-w!  ( w offset -- )  spi-base + w!  ;
: spi-reg-l!  ( l offset -- )  spi-base + l!  ;
: spi-reg-b@  ( offset -- b )  spi-base + c@  ;
: spi-reg-w@  ( offset -- w )  spi-base + w@  ;
: spi-reg-l@  ( offset -- l )  spi-base + l@  ;

: spi-data     ( -- adr )  spi-base 8 +  ;

: spi-stat@   ( -- w )  0 spi-reg-w@  ;
: spi-stat!   ( w -- )  0 spi-reg-w!  ;
: spi-ctrl!   ( w -- )  2 spi-reg-w!  ;
: spi-addr!   ( l -- )  4 spi-reg-l!  ;
: spi-prefix!  ( n -- )  h# 54 spi-reg-w!  ;
: spi-type!  ( n -- )  h# 56 spi-reg-w!  ;
: spi-opcode!  ( b opcode# -- )  h# 58 + spi-reg-b!  ;

d# 64 constant max-spi-data


\ Commands
\ # t DCOA P Op 
\ 0 0 4102    5 <no address> <1 data in>  read-status
\ 1 2 4n12    3 <ADDR>       <N data in>  read
\ 2 0 4322   9f <no address> <3 data in>  jedec-id
\ 3 2 4232   90 <ADDR=0>     <2 data in>  90-id
\ 4 2 4142   ab <ADDR=0>     <1 data in>  ab-id
\ 5 1 4156 6  1 <no address> <1 data out> write-status
\ 6 3 4n66 6  2 <ADDR>       <N data out> write
\ 7 3 0076 6 d8 <ADDR>       <no data>    erase-block

4 base ! 33122020 hex constant cycle-types
: intel-spi-start  ( -- )
   h# 0406 spi-prefix!  \ Prefix 0 is write-enable, 1 is write-disable
   h# d80201ab h# 5c spi-reg-l!  \ opcodes 7-4
   h# 909f0305 h# 58 spi-reg-l!  \ opcodes 3-0
   cycle-types h# 56 spi-reg-w!
   h# 0c spi-stat!
;
: spi-do-cmd  ( code -- )
   begin  spi-stat@ 1 and  0=  until
   spi-ctrl!
   begin  spi-stat@ 4 and  until
   4 spi-stat!
;
: spi-read-status  ( -- b )
   h# 4002 spi-do-cmd
   spi-data c@
;
: wait-write-done  ( -- )
   d# 100000 0  do
      spi-read-status 1 and 0=  if  unloop exit  then
      d# 10 us
   loop
;
: spi-read-n  ( adr len offset -- )
   spi-addr!                               ( adr len )
   dup 1- 8 lshift h# 4012 or  spi-do-cmd  ( adr len )
   spi-data -rot move                      ( )
;
: jedec-id  ( -- b3b2b1 )
   h# 4222 spi-do-cmd
   spi-data w@  spi-data 2+ c@  wljoin
;
: 90-id  ( -- b2b1 )
   0 spi-addr!
   h# 4132 spi-do-cmd
   spi-data w@
;
: ab-id  ( -- b1 )
   0 spi-addr!
   h# 4042 spi-do-cmd
   spi-data c@
;
: spi-write-status  ( b -- )
   spi-data c!         ( )
   h# 4056 spi-do-cmd  ( )
   wait-write-done     ( )
;
: spi-write-n  ( adr len offset -- )
   spi-addr!            ( adr len )
   tuck                 ( len adr len )
   spi-data swap move   ( len )
   1- 8 lshift h# 4066 or spi-do-cmd  ( )
   wait-write-done                    ( )
;
: erase-spi-block  ( offset -- )
   spi-addr!           ( )
   h# 0076 spi-do-cmd  ( )
   wait-write-done     ( )
;

\ Write within one SPI FLASH page.  Offset + len must not cross a page boundary

: write-spi-page  ( adr len offset -- )
   begin  over  while               ( adr len offset )
      over max-spi-data min >r      ( adr len offset  r: this )
      2 pick r@ 2 pick  spi-write-n ( adr len offset  r: this )
      rot r@ +  rot r@ -  rot r> +  ( adr' len' offset' )
   repeat                           ( adr len offset )
   3drop                            ( )
;

: read-spi-flash  ( adr len offset -- )
   begin  over  while               ( adr len offset )
      over max-spi-data min >r      ( adr len offset  r: this )
      2 pick r@ 2 pick  spi-read-n  ( adr len offset  r: this )
      rot r@ +  rot r@ -  rot r> +  ( adr' len' offset' )
   repeat                           ( adr len offset )
   3drop                            ( )
;

\ Verify the contents of SPI FLASH starting at offset against
\ the memory range adr,len .  Aborts with a message on mismatch.

: verify-spi-flash  ( adr len offset -- mismatch? )
   over alloc-mem >r                  ( adr len offset r: temp-adr )
   r@  2 pick  rot                    ( adr len temp-adr len offset r: temp-adr )
   flash-read                         ( adr len r: temp-adr )
   tuck  r@ swap comp                 ( len mismatch? r: temp-adr )
   r> rot free-mem                    ( mismatch? )
;

h# 10000 constant /spi-eblock   \ Smallest erase block common to all chips
h#   100 constant /spi-page     \ Largest write for page-oriented chips

\ Figures out how many bytes can be written in one transaction,
\ subject to not crossing a 256-byte page boundary.

: left-in-page  ( len offset -- len offset #left )
   \ Determine how many bytes are left in the page containing offset
   /spi-page  over /spi-page 1- and -      ( adr len offset left-in-page )

   \ Determine the number of bytes to write in this transaction
   2 pick  min                  ( adr len offset r: #to-write )
;

\ Adjust address, length, and write offset by the number of
\ bytes transferred in the last action

: adjust  ( adr len offset #transferred -- adr+ len- offset+ )
   tuck +  >r  /string  r>
;

\ Determine if it's worthwhile to write; writing FF's is pointless
: non-blank?  ( adr len -- non-blank? )  h# ff bskip 0<>  ;

\ Write as many bytes as can be done in one operation, limited
\ by page boundaries, and adjust the parameters to reflect the
\ data that was written.  If the data that would be written is
\ all FFs, save time by not actually writing it.

: write-spi-some  ( adr len offset -- adr' len' offset' )
   left-in-page                    ( adr len offset #to-write )

   3 pick  over  non-blank?  if    ( adr len offset #to-write )
      3 pick  over  3 pick         ( adr len offset #to-write  adr #to-write offset )
      write-spi-page               ( adr len offset #to-write )
   then                            ( adr len offset #to-write )

   adjust                          ( adr' len' offset' )
;

\ Write data from the range adr,len to SPI FLASH beginning at offset
\ Does not erase automatically; you have to do that beforehand.

\ This version works for parts that support page writes with
\ multiple data bytes after command 2

: write-spi-flash  ( adr len offset -- )
   begin  over  while    ( adr len offset )
      write-spi-some     ( adr' len' offset' )
   repeat                ( adr 0 offset )
   3drop
;

\ Get the SPI FLASH ID and decode it to the extent that we need.
\ There are several different commands to get ID information,
\ and the various SPI FLASH chips support different subsets of
\ those commands.  The AB command seems to be supported by all
\ of them, so it's a good starting point.

0 value spi-id#
: spi-identify  ( -- )
   ab-id to spi-id#
   spi-id# case
      h# 13  of  endof
      h# 15  of  endof
      h# 34  of  endof
      ( default )  true abort" Unsupported SPI FLASH ID"
   endcase
   0 spi-write-status  \ Turn off write protect bits
;

\ Display a message telling what kind of part was found

: .spi-id  ( -- )
   ." SPI FLASH is "
   spi-id#  case
      h# 13  of  ." type 13 - Spansion, Winbond, or ST"  endof
      h# 15  of  ." type 15 - Macronyx"  endof
      h# 34  of  ." type 34 - Macronyx"  endof
   endcase
;

: spi-flash-open  ( -- )
   \ One retry
   spi-start  ['] spi-identify catch  if
      spi-start  spi-identify
   then
;
: spi-flash-write-enable  ( -- )  flash-open  .spi-id cr  ;

: use-spi-flash-read  ( -- )  ['] read-spi-flash to flash-read  ;

\ Install the SPI FLASH versions as their implementations.
: use-spi-flash  ( -- )
   ['] spi-flash-open          to flash-open
   ['] noop                    to flash-close
   ['] spi-flash-write-enable  to flash-write-enable
   ['] noop                    to flash-write-disable
   ['] write-spi-flash         to flash-write
   ['] verify-spi-flash        to flash-verify
   ['] erase-spi-block         to flash-erase-block
   use-mem-flash-read          \ Might be overridden
   h# 40.0000  to /flash
   /spi-eblock to /flash-block
;
use-spi-flash
' intel-spi-start to spi-start

\ LICENSE_BEGIN
\ Copyright (c) 2011 FirmWorks
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
