purpose: Support routines for NOR FLASH writing
\ See license at end of file.

\ This defines a "write" method for NOR FLASH than handles the
\ problems that you have to erase a block before writing and
\ the erase granularity may be larger than the write granularity.
\ This is intended to be part of the implementation of a FLASH
\ device node, where lower level erase-block and flash-write
\ routines are already defined.

\ On NOR FLASH, you can write as many times as you want as long as
\ you keep turning 1's into 0's.  You only have to erase when you
\ want to make some bits go from 0 to 1.  An efficient algorithm is:
\
\ Break the entire write range into pieces each contained in one
\ erase unit.  For each piece:
\
\   Compare the existing and new contents to see if the unit needs erasing
\
\   If no bits need to go from 0 to 1, erase is unnecessary, so just write.
\   (It's a little more complicated if the write granularity is >1 byte.)
\
\   Otherwise, copy the existing contents of the erase unit to a buffer,
\   merge in the new data, erase, then write back the buffer.

0 instance value /chunk

: set-chunk-size  ( len -- )
   dup /device =  if                           ( len )
      seek-ptr 0=  if  to /chunk  exit  then   ( len )
   then                                        ( len )
   /block >=  if  /block  else  /sector  then  to /chunk
;

: erase-chunk  ( offset -- )
   /chunk case                  ( offset )
      /sector  of  erase-sector     endof
      /block   of  erase-block      endof
      /device  of  drop erase-chip  endof
      true abort" flashwritepkg: Internal error - bad value for /chunk"
   endcase
;

: left-in-chunk  ( len offset -- #left )
   \ Determine how many bytes are left in the page containing offset
   /chunk  swap /chunk 1- and -  ( len left-in-page )
   min                                   ( #left )
;

: must-erase?  ( adr len -- flag )
   device-base seek-ptr +         ( adr len dev-adr )
   swap  0  ?do                   ( adr dev-adr )
      over i + c@  over i + c@    ( adr dev-adr new-byte old-byte )
      \ Must erase if a bit in old-byte is 0 and that bit in new-byte is 1
      invert and  if              ( adr dev-adr )
         2drop true unloop exit
      then                        ( adr dev-adr )
   loop                           ( adr dev-adr )
   2drop false
;

: erase+write  ( adr len -- )
   dup /chunk =  if                         ( adr len )
      \ If we are going to overwrite the entire block, there's no need to
      \ preserve the old data.  This can only happen if we are already
      \ aligned on an erase block boundary.
      seek-ptr erase-chunk                  ( adr len )
      seek-ptr flash-write                  ( )
   else
      \ Allocate a buffer to save the old block contents
      /chunk alloc-mem  >r                  ( adr len )

      seek-ptr /chunk round-down            ( adr len block-start )

      \ Copy existing data from FLASH block to the buffer
      dup device-base +  r@  /chunk lmove   ( adr len block-start )

      \ Merge new bytes into the buffer
      -rot                                  ( block-start adr len )
      seek-ptr /chunk mod                   ( block-start adr len buf-offset )
      r@ +  swap move                       ( block-start )

      \ Erase the block and rewrite it from the buffer
      dup  erase-chunk                      ( block-start )
      r@  /chunk  rot  flash-write          ( )

      \ Release the buffer
      r> /chunk free-mem
   then
;

: handle-block  ( adr len -- adr' len' )
   dup seek-ptr left-in-chunk         ( adr len #left )
   >r                                 ( adr len r: #left )
   over r@ must-erase?  if            ( adr len r: #left )
      over r@ erase+write             ( adr len r: #left )
   else                               ( adr len r: #left )
      over r@ seek-ptr flash-write    ( adr len r: #left )
   then                               ( adr len r: #left )
   seek-ptr r@ + to seek-ptr          ( adr len r: #left )
   r> /string                         ( adr' len' )
;

: write  ( adr len -- #written )
   writable?  0=  if  2drop 0 exit  then
   dup set-chunk-size                         ( adr len )
   tuck                                       ( len adr len )
   begin  dup  while  handle-block  repeat    ( len adr' remain' )
   2drop                                      ( len )
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
