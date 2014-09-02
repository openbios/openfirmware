purpose: Driver for NVRAM portion of DS1385 
\ See license at end of file

" nvram" device-name
" nvram" device-type
" pnpPNP,8" " compatible" string-property

d# 4096 value /nvram

nv-adr-low 1+ nv-adr-high =  [if]
   nv-adr-low    my-space encode-phys          2 encode-int encode+
   nv-data       my-space encode-phys encode+  1 encode-int encode+
[else]
   nv-adr-low    my-space encode-phys          1 encode-int encode+
   nv-adr-high   my-space encode-phys encode+  1 encode-int encode+
   nv-data       my-space encode-phys encode+  1 encode-int encode+
[then]

" reg" property

nv-data     global value data-adr
nv-adr-low  global value as0-adr
nv-adr-high global value as1-adr

0 instance value nvram-ptr

\ Writing to the as1 address latches the high 4 bits of the address,
\ writing to the as0 address latches the low  8 bits of the address,
\ and reading or writing the data address reads or writes the data.
: nvram-set-adr  ( offset -- data-adr )
   wbsplit  as1-adr pc!  as0-adr pc!  data-adr
;
: nvram@  ( offset -- n )  nvram-set-adr pc@  ;
: nvram!  ( n offset -- )  nvram-set-adr pc!  ;
' nvram@ to nv-c@
' nvram! to nv-c!

\ headers
: clip-size  ( adr len -- len' adr len' )
   nvram-ptr +   /nvram min  nvram-ptr -     ( adr len' )
   tuck
;
: update-ptr  ( len' adr -- len' )
   drop  dup nvram-ptr +  to nvram-ptr
;

\ external
: seek  ( d.offset -- status )
   0<>  over /nvram u>  or  if  drop true  exit	 then  \ Seek offset too large
   to nvram-ptr
   false
;
: read  ( adr len -- actual )
   clip-size  0  ?do           ( len' adr )
      i nvram-ptr +  nvram@    ( len' adr value )
      over i + c!              ( len' adr )
   loop                        ( len' adr )
   update-ptr                  
;
: write  ( adr len -- actual )
   clip-size  0  ?do           ( len' adr )
      dup i + c@               ( len' adr value )
      i nvram-ptr +  nvram!    ( len' adr )
   loop                        ( len' adr )
   update-ptr                  ( len' )
;
: size  ( -- d )  /nvram 0  ;

\ external
: open  ( -- flag )  true  ;
: close  ( -- )  ;
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
