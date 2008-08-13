purpose: LPC/FWH FLASH low-level write words for use inside a device node
\ See license at end of file.

\ write-enable and write-disable need to be defined externally
\ Typically you load flashpkg.fth before and flashwritepkg.fth after this

0 instance value regs-adr

: unmap-regs  ( -- )
   regs-adr  if
      regs-adr /device " map-out" $call-parent
      0 to regs-adr
      write-disable
   then
;

: writable?  ( -- flag )
   regs-adr  if  true exit  then

   my-address my-space regs-offset +  /device  " map-in" $call-parent  to regs-adr
   regs-adr h# c.0000 +  c@  ( id0 )

   dup 0<>  swap h# ff <>  and   ( writable? )

   dup  if  write-enable  else  unmap-regs  then
;

warning @ warning off  \ Intentional chained definition
: close  ( -- )  unmap-regs  close  ;
warning !

: >lpc-adr  ( offset -- )  device-base +  ;
: jedec!  ( byte -- )  h# 5555 >lpc-adr  c!  ;

\ The write enable for the block at fffx.0000 is at ffbx.0002
: write-enable-block  ( offset -- )
   h# ffff invert and  2  or         ( we-offset )
   regs-adr +   0 swap c!
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
: erase-block  ( offset -- )
   dup write-enable-block
   write-setup   h# 80 jedec!
   write-setup   h# 50 swap >lpc-adr c!
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
   -rot  bounds  ?do           ( offset )
      i c@ over lpc!   1+      ( offset' )
   loop                        ( offset )
   drop
;
: write-block  ( adr len offset -- )
   dup erase-block       ( adr len offset )
   flash-write
;

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
