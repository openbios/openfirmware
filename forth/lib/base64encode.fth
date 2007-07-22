purpose: Encode in base64 (RFC 1341)
\ See license at end of file

variable base64-linelen

defer base64-emit

: base64-putcr  ( -- )
   carret base64-emit  linefeed base64-emit
   base64-linelen off  
;

: base64-putb  ( char -- )
   base64-emit     1 base64-linelen +!
   base64-linelen @ d# 72 =  if  base64-putcr  then
;

: base64-out  ( 6bits -- )
   h# 3f and    ( bits )
   " ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"  ( bits adr len )
   drop + c@    ( char )
   base64-putb  ( )
;

: base64-put=  ( -- )  [char] = base64-putb  debug-me ;

: base64-encbyte   ( adr bits #rshift -- adr' bits' )
   >r                     ( adr bits' r: #rshift )
   8 lshift  over c@ or   ( adr bits' r: #rshift )  \ Get 8 new bits
   swap 1+ swap           ( adr bits' r: #rshift )  \ Increment address
   dup r> rshift  base64-out   ( adr bits' )        \ Output 6 high bits
;

: encode-base64  ( adr len -- )
   base64-linelen off                  ( adr len )
   bounds                              ( endadr adr )
   begin  2dup 3 + >=  while           ( endadr adr )
      0                                ( endadr adr  0bits )
      2 base64-encbyte                 ( endadr adr' 2bits )
      4 base64-encbyte                 ( endadr adr' 4bits )
      6 base64-encbyte                 ( endadr adr' 6bits )
      base64-out                       ( endadr adr )
   repeat                              ( endadr adr )

   tuck -  case                        ( adr )
      1  of                            ( adr )
         0                             ( adr  0bits )
         2 base64-encbyte              ( adr' 2bits )
         4 lshift  base64-out          ( adr )
         base64-put=  base64-put=      ( adr )
      endof

      2  of                            ( adr )
         0                             ( adr  0bits )
         2 base64-encbyte              ( adr' 2bits )
         4 base64-encbyte              ( adr' 4bits )
         2 lshift  base64-out          ( adr )
         base64-put=                   ( adr )
      endof
   endcase                             ( adr )

   drop                                ( )

   base64-linelen @  if  base64-putcr  then       ( )
;

: stream-encode-base64  ( adr len -- )
   ['] emit to base64-emit
   encode-base64
;

\ "where" must have enough space to hold the result
\ 
\ : outlen  ( inlen -- outlen )
\    \ Account for symbol expansion
\    2 + 3 / 4 *                  ( #6bit-symbols )
\    \ Account for CR-LFs
\    d# 72 /mod d# 74 *           ( lastline-symbols fullline-bytes )
\    \ CR-LF on possible short last line
\    swap  ?dup  if  + 2+  then
\ ;

\needs base64-outp  variable base64-outp   \ Output buffer pointer
variable base64-outbase
: base64-memout  ( char -- )  base64-outp @ c!  1 base64-outp +!  ;

: mem-encode-base64  ( adr len where -- outlen )
   dup base64-outp !  base64-outbase !
   ['] base64-memout to base64-emit

   encode-base64

   base64-outp @  base64-outbase @  -
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
