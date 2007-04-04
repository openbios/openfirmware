\ See license at end of file.
purpose: LPC/FWH FLASH writer.  This assumes a 1 MiB device.

: geode-lpc-write-enable  ( -- )
   h# 1808 rdmsr  h# ff.ffff and  h# 2100.0000 or  h# 1808 wrmsr
;

h# 1.0000 constant /lpc-block
h# fff0.0000 constant lpc-flash-base

: ?lpc  ( -- )
   h# ffbc.0000 c@  ( id0 )
   dup 0=  swap h# ff =  or  abort" LPC FLASH not present"
   geode-lpc-write-enable
;


: >lpc-adr  ( offset -- )  lpc-flash-base +  ;
: lpc-jedec!  ( byte -- )  h# 5555 >lpc-adr  c!  ;

\ The write enable for the block at fffx.0000 is at ffbx.0002
: lpc-write-enable-block  ( adr -- )
   >lpc-adr  h# 0040.ffff invert and  2 or  0 swap c!
;

: lpc-write-setup  ( -- )  h# aa lpc-jedec!  h# 55 h# 2aaa >lpc-adr c!  ;

: lpc!  ( byte offset -- )
   over h# ff =  if  2drop exit  then
   >lpc-adr                              ( byte lpc-adr )
   lpc-write-setup   h# a0 lpc-jedec!    ( byte lpc-adr )
   2dup c!                               ( byte lpc-adr )
   begin  2dup c@ =  until  2drop        ( )
;

: lpc-wait-toggle  ( -- )
   lpc-flash-base c@   ( value )
   begin  lpc-flash-base c@ tuck  =  until  ( value )
   drop
;
: lpc-erase-block  ( offset -- )
   dup lpc-write-enable-block
   lpc-write-setup   h# 80 lpc-jedec!
   lpc-write-setup   h# 50 swap >lpc-adr c!
   lpc-wait-toggle
;

: lpc-write-block  ( adr len offset -- )
   dup lpc-erase-block         ( adr len offset )
   -rot  bounds  ?do           ( offset )
      i c@ over lpc!   1+      ( offset' )
   loop                        ( offset )
   drop
;

: lpc-reflash   ( -- )   \ Flash from data already in memory
   ?file

[ifdef] crc2-offset
   \ Insert another CRC, this time including the mfg data
   flash-buf  /flash  crc                  ( crc )
   flash-buf  /flash +  crc2-offset -  l!  ( )
[then]

   ?lpc
   ." Writing" cr

   /flash  0  ?do
      (cr i .
      flash-buf i +  /lpc-block  i  lpc-write-block  ( )
   /lpc-block +loop
;

: lpc-flash  ( ["filename"] -- )  get-file lpc-reflash  ;

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
