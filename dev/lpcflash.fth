purpose: LPC/FWH FLASH low-level write words for use inside a device node
\ See license at end of file.

\ Typically this file is loaded between flashpkg.fth and flashwritepkg.fth

0 instance value regs-adr

\ The "register space" for an LPC FLASH device is a different address bank,
\ typically differing by the value of A22.  In some devices there are only
\ two registers (chip ID and GPIO), while other devices have write lock
\ registers scattered throughout a large (e.g. 1 MB) address space.

: map-regs  ( -- )
   regs-adr  if  exit  then
   my-address my-space regs-offset +  /device  " map-in" $call-parent  to regs-adr
;

: unmap-regs  ( -- )
   regs-adr  if
      regs-adr /device " map-out" $call-parent
      0 to regs-adr
      write-disable
   then
;

\ This tests for the presence of an LPC/FWH FLASH device by trying to
\ read its ID register.  You can't tell by reading the FLASH data because
\ an erased device is indistinguishable from a device that's not there.
\ ROM emulators that can't be written via the LPC bus will show up as
\ "not present" (unless they emulate the ID register).

: (present?)  ( -- flag )
   regs-adr h# c.0000 +  c@  ( id0 )

   dup 0<>  swap h# ff <>  and   ( id-present? )
;

\ Test for device presence, leaving register space in the same state
\ (mapped or not) as before.  This is intended for use as an "early
\ probe" to see if the device is there.

: present?  ( -- flag )
   regs-adr  if
      (present?)
   else
      map-regs  (present?)  unmap-regs
   then   
;

\ Test for device presence (and thus the ability to write), leaving
\ register space mapped and the device write-enabled if the device is
\ indeed present.  This intended for use in preparation for a sequence
\ of write operations.  When the sequence is finished, closing the
\ device instance will unmap the registers and write-disable .

: writable?  ( -- flag )
   \ This is an optimization so writable? can be called multiple times
   \ quickly.  Theres is no point in leaving register space mapped if
   \ there are no registers.
   regs-adr  if  true exit  then

   map-regs

   (present?)

   dup  if  write-enable  else  unmap-regs  then
;

warning @ warning off  \ Intentional chained definition
: close  ( -- )  unmap-regs  close  ;
warning !

: >lpc-adr  ( offset -- )  device-base +  ;
: jedec!  ( byte -- )  h# 5555 >lpc-adr  c!  ;

\ Some, but not all, devices have block-granularity software locking via
\ register-space addresses.  For example, SST49LF008A (FWH version) has
\ software locking, while SST47LF080A (LPC version) does not.  Writing
\ the lock register addresses is innocuous on the ones without locking.

: (write-enable-block)  ( offset -- )
   h# ffff invert and  2  or         ( we-offset )
   regs-adr +   0 swap c!
;
: write-enable-block  ( offset -- )
   regs-adr  if
      (write-enable-block)
   else
      map-regs  (write-enable-block)  unmap-regs
   then
;

: write-setup  ( -- )  h# aa jedec!  h# 55 h# 2aaa >lpc-adr c!  ;

: lpc!  ( byte offset -- )
   over h# ff =  if  2drop exit  then
   >lpc-adr                          ( byte lpc-adr )
   write-setup   h# a0 jedec!        ( byte lpc-adr )
   2dup c!                           ( byte lpc-adr )
   begin  2dup c@ =  until  2drop    ( )
;

: wait-toggle  ( -- )
   device-base c@   ( value )
   begin  device-base c@ tuck  =  until  ( value )
   drop
;
: erase-sector  ( offset -- )
   dup write-enable-block
   write-setup   h# 80 jedec!
   write-setup   h# 30 swap >lpc-adr c!
   wait-toggle
;
: erase-block  ( offset -- )
   dup write-enable-block
   write-setup   h# 80 jedec!
   write-setup   h# 50 swap >lpc-adr c!
   wait-toggle 
;
: erase-chip  ( -- )
   write-setup   h# 80 jedec!
   write-setup   h# 10 jedec!
   wait-toggle
;

: flash-read  ( adr len offset -- )
   device-base +  -rot  move
;
: flash-verify  ( adr len offset -- )
   device-base +  -rot  comp
   abort" LPC FLASH verify failed"
;

: flash-write  ( adr len offset -- )
   dup write-enable-block      ( adr len offset )
   -rot  bounds  ?do           ( offset )
      i c@ over lpc!   1+      ( offset' )
   loop                        ( offset )
   drop
;
: write-block  ( adr len offset -- )
   dup erase-block       ( adr len offset )
   flash-write
;
: block-size  ( -- u )  /block  ;

\ LICENSE_BEGIN
\ Copyright (c) 2008 FirmWorks
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
