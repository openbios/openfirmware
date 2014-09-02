purpose: PR*P-specific NVRAM functions
\ See license at end of file

headerless
[ifndef] nvram-l@
: nvram-l@  ( offset -- l )  dup wa1+ nvram-w@  swap nvram-w@  wljoin  ;
: nvram-l!  ( l offset -- )  >r lwsplit r@ nvram-w!  r> wa1+ nvram-w!  ;
[then]

: crc-loop  ( crc end start -- crc' )  ?do  i nvram-c@ crcgen  loop  ;
: os-area  ( -- offset len )  h# e8 nvram-l@  h# ec nvram-l@  ;
: config-area  ( -- offset len )  h# d4 nvram-l@  h# d8 nvram-l@  ;
: env-range  ( -- offset len )  h# c4 nvram-l@  h# c8 nvram-l@  ;

: prep-env-area  ( -- adr len )  env-range swap config-mem +  swap  ;

\ There is a bug in IBM's early firmware which causes it to omit byte 8.
: crc-base  ( -- offset )  3 nvram-c@ 4 >=  if  8  else  9  then  ;
: crc1  ( -- n )
   h# ffff  4 0  crc-loop              ( crc )
   os-area drop  crc-base  crc-loop    ( crc )
;
: fix-crc1  ( -- )  crc1  4 nvram-w!  4 2 write-range  ;
: fix-crc2  ( -- )
   h# ffff

   \ There is a bug in IBM's early firmware which causes it to omit
   \ the last byte, hence the "1-" below.
   h# d4 nvram-l@  h# d8 nvram-l@ 1-  0 max  bounds  crc-loop  ( crc )
   6 nvram-w!

   6 2 write-range
;

\ True if the intersection between the two ranges in not empty
: overlap?  ( adr1 len1 adr2 len2 -- flag )
   >r >r   over r@ max  -rot       ( max-adr adr1 len1 )
   + r> r> +  min                  ( max-adr min-end-adr )
   swap -  0>
;
: prep-config-checksum?  ( -- okay? )
   os-area  drop  crc-base config-size within  if
      crc1 4 nvram-w@ =
   else
      false
   then
;

: set-prep-env-checksum  ( -- )
   modified-range  0  os-area drop  overlap?  if  fix-crc1  then
   modified-range  config-area      overlap?  if  fix-crc2  then
;

hex
: >bcd  ( binary -- bcd )  d# 10 /mod  4 << +  ;
: set-timestamp  ( offset -- )
   >r
   time&date d# 100 /mod  r@ 7  bounds  do  >bcd i nvram-c!  loop
   r> 7 +  0 swap nvram-c!
;
: init-timestamps  ( -- )  5c 34  do  i set-timestamp  8 +loop  ;
: clear-passwords  ( -- )  " none" " security-mode" $setenv  ;
: prep-layout-config  ( -- )
   config-size d# 1024 /    0 nvram-w!	\ Size in KBytes
   1 2 nvram-c!  2 3 nvram-c!		\ version and revision
   0 3 nvram-c!				\ Last OS (Firmware)
   init-timestamps

    a00 e8 nvram-l!  200 ec nvram-l!	\ OS Area
   1000 d4 nvram-l!    0 d8 nvram-l!	\ ConfigArea (PnP packets)
     f8 c4 nvram-l!  908 c8 nvram-l!	\ Global Environment area

   clear-passwords	 \ Depends on the area descriptors above!
;
: prep-nvram?  ( -- flag )
   2 nvram-c@ 1 =  3 nvram-c@ 2 =  and
   0 nvram-w@  config-size d# 1024 /  =  and
   prep-config-checksum? and
;
headers

\ LICENSE_BEGIN
\ Copyright (c) 1997 FirmWorks
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

