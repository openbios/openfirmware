purpose: Byte-swap the Forth dictionary
\ See license at end of file

\needs bittest  fload ${BP}/forth/lib/bitops.fth

: lbflip  ( n -- n' )
   lbsplit swap 2swap swap bljoin
;
: xlflips  ( adr len -- )
   bounds  ?do  i l@  i la1+ l@  i l!  i la1+ l!  2 /l* +loop
;

h# 20 constant /iheader
0 value /image
0 value /itext
0 value /iuser
0 value /iswap
0 value text-base
0 value user-base
0 value swap-map
0 value buf

: ?lbflips  ( -- )
   /itext 4 /  0  do
      i swap-map bittest  0=  if  text-base i la+ dup  l@ lbflip swap l!  loop
   loop
;

: +buf  ( offset -- adr )  buf +  ;
: little-endian-ify  ( "infile" "outfile" -- )
   reading writing

   ifd @ fsize to /image
   /image 8 round-up  alloc-mem to buf
   buf  /image  ifd @ fgets  drop   ifd @ fclose

   4 +buf be-l@  to /itext
   8 +buf be-l@  to /iuser
   h# 18 +buf be-l@ to /iswap
   /iheader +buf  to text-base
   text-base /itext +  to user-base
   user-base /iuser +  to swap-map

   buf        /iheader  lbflips
   ?lbflips
   user-base  /iuser    lbflips
   buf /image xlflips

   buf /image ofd @ fputs  ofd @ fclose
;

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
