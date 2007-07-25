\ See license at end of file
purpose: Package for FLASH ROM device

headerless
0 instance value base-adr
0 instance value image-size
0 value device-base
0 value open-count
false value written?
0 instance value seek-ptr

: clip-size  ( adr len -- len' adr len' )
   seek-ptr +   image-size min  seek-ptr -     ( adr len' )
   tuck
;
: update-ptr  ( len' -- len' )  dup seek-ptr +  to seek-ptr  ;
: 'base-adr  ( -- adr )
   seek-ptr
[ifdef] select-flash
   /device-phys /mod select-flash
[then]
   base-adr +
;

headers
external
: seek  ( d.offset -- status )
   0<>  over image-size u>  or  if  drop true  exit  then \ Seek offset too big
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
      my-address my-space /device-phys  " map-in" $call-parent
[then]
      to device-base
   then                                             ( )
   0 to seek-ptr                                    ( )
   my-args  dup  if                                 ( adr len )
      2dup  " \"  $=  0=  if                        ( adr len )
         over c@  [char] \  =  if  1 /string  then  ( adr' len' )
         find-drop-in  dup  if                      ( di-adr di-len true )
            -rot  to image-size  to base-adr        ( true )
         then                                       ( flag )
         exit                                       ( flag )
      then                                          ( adr len )
   then                                             ( adr len )
   2drop                                            ( )
   /device to image-size                            ( )
   device-base to base-adr                          ( )
   true                                             ( true )
;
: close  ( -- )
   \ This lets us open the node during compilation
   standalone?  0=  if  exit  then

   base-adr device-base <>  if  base-adr image-size release-dropin  then
   open-count dup 1- 0 max to open-count  ( old-count )
[ifdef] eprom-va
   drop
[else]
   1 =  if  device-base /device-phys " map-out" $call-parent  then
[then]
;
: size  ( -- d.size )
   base-adr device-base <>  if  image-size  else  /device  then  0
;
: read  ( adr len -- actual )
   clip-size tuck			( len' len' adr len' )
   begin
      /device-phys seek-ptr /device-phys mod - min	( len' len' adr len'' )
      2dup 'base-adr -rot move		( len' len' adr len'' )
      update-ptr			( len' len' adr len'' )
      rot over - -rot + over		( len' len'-len'' adr+len'' len'-len'' )
   ?dup 0=  until			( len' len'-len'' adr+len'' len'-len'' )
   2drop
;
: load  ( adr -- len )
   0 0 seek drop     ( adr )
   image-size  read  ( len )
;
: next-file-info  ( id -- false | id' s m h d m y len attributes name$ true )
   ?dup 0=  if  open-drop-in  then      ( id )
   another-dropin?  if                  ( id )
      " built-time-int" $find  if       ( id s m h xt )
         execute                        ( id s m h packed-date )
         d# 100 /mod  d# 100 /mod       ( id s m h d m y )
      else                              ( id s m h adr len )
         2drop  0 0 0                   ( id s m h d m y )
      then                              ( id s m h d m y )
      " built-date-int" $find  if       ( id s m h xt )
         execute                        ( id s m h packed-date )
         d# 100 /mod  d# 100 /mod       ( id s m h d m y )
      else                              ( id s m h adr len )
         2drop  0 0 0                   ( id s m h d m y )
      then                              ( id s m h d m y )
      di-expansion be-l@                ( id s m h d m y size )
      ?dup 0=  if  di-size be-l@  then  ( id s m h d m y size )
      o# 100444                         ( id s m h d m y size attributes )
      di-name$				( id s m h d m y size attr name$ )
      true                              ( id s m h d m y size attr name$ true )
   else                                 ( )
      close-drop-in  false              ( false )
   then
;

: free-bytes  ( -- d.#bytes )
   open-drop-in  0                    ( high-water )
   0  begin  another-dropin?  while   ( high-water id )
      nip  di-size be-l@ 4 round-up   ( id size )
      over +  swap                    ( high-water' id )
   repeat                             ( high-water )
   size  rot 0  d-                    ( d.#bytes )
;

[ifdef] flash-is-parent
\ These allow us to sub-address the FLASH device to access the PROMICE AI port
1 " #address-cells" integer-property

: decode-unit  ( adr len -- phys )  push-hex  $number  if  0  then  pop-base  ;
: encode-unit  ( phys -- adr len )  push-hex  (u.)  pop-base  ;
: map-in   ( offset size -- virt )  drop  device-base +  ;
: map-out  ( virt size -- virt )  2drop  ;
[then]

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
