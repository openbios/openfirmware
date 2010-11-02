purpose: Package for non-memory-mapped FLASH ROM device
\ See license at end of file

headerless
0 value open-count
0 instance value seek-ptr

: clip-size  ( adr len -- len' adr len' )
   seek-ptr +   /device min  seek-ptr -     ( adr len' )
   tuck
;
: update-ptr  ( len' -- len' )  dup seek-ptr +  to seek-ptr  ;

headers
external
: seek  ( d.offset -- status )
   0<>  over /device u>  or  if  drop true  exit  then \ Seek offset too big
   to seek-ptr
   false
;

: open  ( -- flag )
   \ This lets us open the node during compilation
   standalone?  0=  if  true exit  then

   open-count  dup 1+  to open-count   0=  if       ( )
      flash-open                                    ( )
   then                                             ( )
   0 to seek-ptr                                    ( )
   true                                             ( true )
;
: close  ( -- )
   \ This lets us open the node during compilation
   standalone?  0=  if  exit  then

   open-count dup 1- 0 max to open-count  ( old-count )
   1 =  if    then
;
: size  ( -- d.size )  /device u>d  ;
: read  ( adr len -- actual )
   clip-size                        ( len' adr len' )
   seek-ptr  flash-read             ( len' )
   update-ptr                       ( len' )
;

0 [if]
\ Write support is complicated by the need to erase before
\ writing and the possibly-different erase and write granularity.
\
\ For NOR FLASH, where you can write as many times as you want
\ while turning 1's into 0's, the algorithm is:
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
[then]

: left-in-block  ( len offset -- #left )
   \ Determine how many bytes are left in the page containing offset
   /flash-block  swap /flash-block 1- and -  ( len left-in-page )
   min                                       ( #left )
;

0 value /tmp
0 value 'tmp
: must-erase?  ( adr len -- flag )
   dup to /tmp
   /tmp alloc-mem to 'tmp           ( adr len )
   'tmp /tmp seek-ptr flash-read    ( adr len )
   'tmp  swap  0  ?do               ( adr dev-adr )
      over i + c@  over i + c@      ( adr dev-adr new-byte old-byte )
      \ Must erase if a bit in old-byte is 0 and that bit in new-byte is 1
      invert and  if                ( adr dev-adr )
         'tmp /tmp free-mem         ( adr dev-adr )
         2drop true unloop exit     ( -- flag )
      then                          ( adr dev-adr )
   loop                             ( adr dev-adr )
   'tmp /tmp free-mem               ( adr dev-adr )
   2drop false                      ( flag )
;

: erase+write  ( adr len -- )
   dup /flash-block =  if
      \ If we are going to overwrite the entire block, there's no need to
      \ preserve the old data.  This can only happen if we are already
      \ aligned on an erase block boundary.
      seek-ptr flash-erase-block           ( adr len )
      seek-ptr flash-write                 ( )
   else
      \ Allocate a buffer to save the old block contents
      /flash-block alloc-mem  >r                 ( adr len )

      seek-ptr /flash-block round-down           ( adr len block-start )

      \ Copy existing data from FLASH block to the buffer
      r@ /flash-block  2 pick  flash-read        ( adr len block-start )

      \ Merge new bytes into the buffer
      -rot                                       ( block-start adr len )
      seek-ptr /flash-block mod                  ( block-start adr len buf-offset )
      r@ +  swap move                            ( block-start )

      \ Erase the block and rewrite it from the buffer
      dup  flash-erase-block                     ( block-start )
      r@  /flash-block  rot  flash-write         ( )

      \ Release the buffer
      r> /flash-block free-mem
   then
;

: handle-block  ( adr len -- adr' len' )
   dup seek-ptr left-in-block         ( adr len #left )
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
   flash-write-enable
   tuck                                       ( len adr len )
   begin  dup  while  handle-block  repeat    ( len adr' remain' )
   2drop                                      ( len )
   flash-write-disable
;

\ These permit subordinate nodes for subranges of the device, for
\ purposes like dropin driver collections, configuration variables, etc.
1 " #address-cells" integer-property

: decode-unit  ( adr len -- phys )  push-hex  $number  if  0  then  pop-base  ;
: encode-unit  ( phys -- adr len )  push-hex  (u.)  pop-base  ;

\ LICENSE_BEGIN
\ Copyright (c) 2010 FirmWorks
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
