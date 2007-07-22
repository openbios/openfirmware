purpose: Decode base64 (RFC 1341)
\ See license at end of file

0 [if]
\ Constructing the map on the fly takes almost as much space as including
\ it verbatim.  The verbatim copy is probably smaller when compressed.

h# 100 buffer: base64-map

: ?make-map  ( -- )
   base64-map c@  h# ff <>  if
      base64-map  h# 100  h# ff  fill
      " ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
      bounds  ?do  i  base64-map  i c@  +  c!  loop
      h# fe  base64-map [char] = +  c!
   then
;

[else]

base @ hex
create base64-map
ff c, ff c, ff c, ff c, ff c, ff c, ff c, ff c,
ff c, ff c, ff c, ff c, ff c, ff c, ff c, ff c,
ff c, ff c, ff c, ff c, ff c, ff c, ff c, ff c,
ff c, ff c, ff c, ff c, ff c, ff c, ff c, ff c,
ff c, ff c, ff c, ff c, ff c, ff c, ff c, ff c,
ff c, ff c, ff c, 3e c, ff c, ff c, ff c, 3f c, \ + /
34 c, 35 c, 36 c, 37 c, 38 c, 39 c, 3a c, 3b c, \ 0-7
3c c, 3d c, ff c, ff c, ff c, fe c, ff c, ff c, \ 89=
ff c,  0 c,  1 c,  2 c,  3 c,  4 c,  5 c,  6 c, \ A-G
 7 c,  8 c,  9 c,  a c,  b c,  c c,  d c,  e c, \ H-O
 f c, 10 c, 11 c, 12 c, 13 c, 14 c, 15 c, 16 c, \ P-W
17 c, 18 c, 19 c, ff c, ff c, ff c, ff c, ff c, \ X-Z
ff c, 1a c, 1b c, 1c c, 1d c, 1e c, 1f c, 20 c, \ a-g
21 c, 22 c, 23 c, 24 c, 25 c, 26 c, 27 c, 28 c, \ h-o
29 c, 2a c, 2b c, 2c c, 2d c, 2e c, 2f c, 30 c, \ p-w
31 c, 32 c, 33 c, ff c, ff c, ff c, ff c, ff c, \ x-z
ff c, ff c, ff c, ff c, ff c, ff c, ff c, ff c,
ff c, ff c, ff c, ff c, ff c, ff c, ff c, ff c,
ff c, ff c, ff c, ff c, ff c, ff c, ff c, ff c,
ff c, ff c, ff c, ff c, ff c, ff c, ff c, ff c,
ff c, ff c, ff c, ff c, ff c, ff c, ff c, ff c,
ff c, ff c, ff c, ff c, ff c, ff c, ff c, ff c,
ff c, ff c, ff c, ff c, ff c, ff c, ff c, ff c,
ff c, ff c, ff c, ff c, ff c, ff c, ff c, ff c,
ff c, ff c, ff c, ff c, ff c, ff c, ff c, ff c,
ff c, ff c, ff c, ff c, ff c, ff c, ff c, ff c,
ff c, ff c, ff c, ff c, ff c, ff c, ff c, ff c,
ff c, ff c, ff c, ff c, ff c, ff c, ff c, ff c,
ff c, ff c, ff c, ff c, ff c, ff c, ff c, ff c,
ff c, ff c, ff c, ff c, ff c, ff c, ff c, ff c,
ff c, ff c, ff c, ff c, ff c, ff c, ff c, ff c,
ff c, ff c, ff c, ff c, ff c, ff c, ff c, ff c,
base !
[then]

variable base64-buf   \ Bit buffer, collects 6-bit groups into 3 bytes
variable base64-nbits \ Number of bits currently in bit buffer
variable base64-trim  \ Number of bytes to trim at the end
\needs base64-outp  variable base64-outp  \ Output buffer pointer

: base64-bits  ( 6bits -- )
   base64-buf @  6 lshift  or  base64-buf !
   6 base64-nbits +!
   base64-nbits @ d# 24 =  if
      base64-buf @  lbsplit drop  ( b2 b1 b0 )
      base64-outp @  tuck c! 1+  tuck c! 1+  tuck c! 1+  ( adr' )
      base64-outp !
      base64-nbits off
   then
;

\ where must be large enough to hold the result including up to 2 padding bytes
\ Trivially,   ( inlen ) 3 + 4 /  3 *  ( outlen )
\ but that ignores the fact that, in practice, the line length is limited to
\ to 76 characters, so some embedded newlines are skipped.  That makes the
\ actual output length smaller than the calculation above, so the above is safe.
\ In-place decoding is possible, since the output pointer can never catch up
\ to the input pointer.

: decode-base64  ( adr len where -- len' )
[ifdef] ?make-map   ?make-map  [then]
   base64-nbits off  0 base64-trim !  ( adr len where )
   dup base64-outp !  -rot            ( where adr len )

   bounds ?do                  ( where )
      i c@ base64-map + c@     ( where sym )
      dup h# ff =  if          ( where sym )
         drop                  ( where )
      else                     ( where sym )
         dup h# fe = if        ( where sym )
            1 base64-trim +!   ( where sym )
            base64-trim @ 2 >  abort" Bad base64 input"
            drop 0 base64-bits ( where )
         else                  ( where sym )
            base64-trim @ 0<>  abort" Bad base64 input"
            base64-bits        ( where )
         then                  ( where )
      then                     ( where )
   loop                        ( where )
   base64-outp @  swap -  base64-trim @ -  ( len )
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
