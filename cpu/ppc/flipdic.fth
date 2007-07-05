purpose: Endian-swap the Forth dictionary for PowerPC
\ See license at end of file

\needs bittest  fload ${BP}/forth/lib/bitops.fth
\needs lbflip   \needs lbsplit  fload ${BP}/forth/lib/split.fth
\needs lbflip   : lbflip  ( l1 -- l2 )  lbsplit swap 2swap swap bljoin  ;
\needs lbflips  : lbflips  ( a l -- )  bounds  ?do  i l@ lbflip i l! /l +loop ;

0 value header
h# 20 constant /header
0 value dict
0 value /dict
0 value ua
0 value /ua
0 value relmap
0 value total-size

: ?lbflips  ( adr len -- )
   3 + 4 /  0  ?do                          ( adr )
      i relmap bittest  0=  if              ( adr )
         dup i la+ dup l@ lbflip swap l!    ( adr )
      then                                  ( adr )
   loop                                     ( adr )
   drop
;

reading fw.dil
ifd @ fsize to total-size
total-size alloc-mem  to header
header  total-size  ifd @ fgets  drop
ifd @ fclose

header /header +  to dict
header 1 la+ l@   to /dict

dict /dict + to ua
header 2 la+ l@   to /ua

ua /ua + to relmap

header /header lbflips
dict /dict ?lbflips
ua /ua lbflips

writing fw.dic
header total-size  ofd @ fputs
ofd @ fclose

\ LICENSE_BEGIN
\ Copyright (c) 2007 FirmWorks
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
