purpose: USB video class descriptors parsing code
\ See license at end of file

hex
headers

1 value vs-interface              \ Interface id of VS_VIDEO_STREAMING

0 value desc-buf
0 value desc-buf-end
h# 800 value /desc-buf

defer alt-array
defer frame-array

\ Support uncompressed video format only

1 value format-idx
2 value bytes/pixel               \ # bytes per uncompressed pixel
d# 16 buffer: guid                \ Uncompressed frame format

d# 32 constant MAX_ALT_DESC       \ Maximum number of alternate interface descriptors
d# 32 constant MAX_FRAME_DESC     \ Maximum number of frame descriptors/format
0 value #fdesc                    \ Number of uncompressed frame descriptors
0 value #alt                      \ Number of alternate interface descriptors
MAX_FRAME_DESC /n* 2* buffer: frame-array  \ Array of width and height per frame
MAX_ALT_DESC   /n*    buffer: alt-array  \ Array of /payload per alternate interface

: #fdesc!  ( idx -- )  #fdesc max to #fdesc  ;
: #alt!    ( idx -- )  #alt   max to #alt    ;
: alt-array!    ( l idx -- )    /n* alt-array + !  ;
: alt-array@    ( idx -- l )    /n* alt-array + @  ;
: frame-array!  ( w h idx -- )  /n* 2* frame-array + tuck na1+ !  !  ;
: frame-array@  ( idx -- width height )  /n* 2* frame-array + dup @ swap na1+ @  ;

: process-vc  ( idx -- )
   desc-buf swap find-intf-desc dup  0=  if  abort" Failed to find 1st Interface Descriptor"  then
   dup 5 + c@ e =  over 6 + c@ 1 = and  swap 7 + c@ 0=  and
   not  if  abort" Expect SC_VIDEO_CONTROL class"  then
;

: process-vs-desc  ( adr -- adr' )
   frame-array MAX_FRAME_DESC /n* 2* erase
   begin  dup desc-buf-end <>  while            ( adr )
      dup 1+ c@  h# 24 <>  if  exit  then  \ CS_INTERFACE
      dup 2 + c@  case
         4  of  \ VS_FORMAT_UNCOMPRESSED
                dup 5 + guid d# 16 move
                dup d# 21 + c@ 3 >> to bytes/pixel
                dup 3 + c@ to format-idx
                endof
         5  of	\ VS_FRAME_UNCOMPRESSED
                dup 5 + le-w@  over 7 + le-w@  2 pick 3 + c@
                dup #fdesc!  frame-array!
                endof
      endcase
      dup c@ +
   repeat
;

: process-alt-desc  ( idx adr -- )
   alt-array MAX_ALT_DESC /n* erase        ( idx adr )
   begin  dup desc-buf-end <>  while       ( idx adr )
      dup 1+ c@ 4 =  if                    ( idx adr )
         2dup 2 + c@ =  if		   \ Alternate INTERFACE descriptor
            dup 3 + c@ dup #alt!           ( idx adr alt )
            swap dup c@ +                  ( idx alt adr' )
            dup 1+ c@ 5 =  if              \ Endpoint descriptor
               tuck 4 + le-w@ swap alt-array! ( idx adr )
               dup 3 + c@ 1 and 0=  if  abort" Expect isochronous endpoint"  then
               dup 2 + c@ h# f and         ( idx adr pipe )
               over 6 + c@                 ( idx adr pipe interval )
               2 pick 2 + c@ h# 80 and
               if  to iso-in-interval to iso-in-pipe  else  to iso-out-interval to iso-out-pipe  then
            then
         then
      then
      dup c@ +
   repeat  2drop
;

: process-vs  ( idx -- )
   dup to vs-interface
   desc-buf over find-intf-desc dup  0=  if  abort" Failed to find 2nd Interface Descriptor"  then
   dup >r                             ( idx adr )  ( R: adr )
   5 + c@ e =  r@ 6 + c@ 2 = and  r@ 7 + c@ 0=  and  not if  abort" Expect SC_VIDEO_STREAMING class"  then
   r> dup c@ + process-vs-desc        ( idx adr )  ( R: adr )
   #fdesc 0=  if  abort" Failed to find VS_FRAME_UNCOMPRESSED descriptors"  then
   ( idx adr' ) process-alt-desc        ( )
   #alt   0=  if  abort" Failed to find Alternate Interface descriptors"  then
;

: init-params  ( -- )
   /desc-buf dma-alloc to desc-buf
   desc-buf dup 0 get-cfg-desc dup  0=  if  abort" Failed to get-desc"  then
   + to desc-buf-end
   desc-buf INTERFACE_ASSO find-desc dup  0=  if  abort" Failed to find Interface Association Descriptor"  then
   dup 3 + c@ 2 <  if  abort" Expect at least 2 associated interfaces"  then
       2 + c@ dup process-vc     \ Process Video Control Interface
   1+ process-vs                 \ Process Video Streaming Interface
   desc-buf /desc-buf dma-free  0 to desc-buf
;

\ LICENSE_BEGIN
\ Copyright (c) 20011 FirmWorks
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
