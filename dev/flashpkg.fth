purpose: Package for FLASH ROM device
\ See license at end of file

headerless
0 value device-base
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
[ifdef] eprom-va
      eprom-va
[else]
      my-address my-space /device  " map-in" $call-parent
[then]
      to device-base
   then                                             ( )
   0 to seek-ptr                                    ( )
   true                                             ( true )
;
: close  ( -- )
   \ This lets us open the node during compilation
   standalone?  0=  if  exit  then

   open-count dup 1- 0 max to open-count  ( old-count )
[ifdef] eprom-va
   drop
[else]
   1 =  if  device-base /device " map-out" $call-parent  then
[then]
;
: size  ( -- d.size )  /device u>d  ;
: read  ( adr len -- actual )
   clip-size                        ( len' adr len' )
   seek-ptr device-base +  -rot     ( len' device-adr adr len' )
   move                             ( len' )
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

\ These permit subordinate nodes for subranges of the device, for
\ purposes like dropin driver collections, configuration variables, etc.
1 " #address-cells" integer-property

: decode-unit  ( adr len -- phys )  push-hex  $number  if  0  then  pop-base  ;
: encode-unit  ( phys -- adr len )  push-hex  (u.)  pop-base  ;
: map-in   ( offset size -- virt )  drop  device-base +  ;
: map-out  ( virt size -- virt )  2drop  ;

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
