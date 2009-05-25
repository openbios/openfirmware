purpose: Memory probing
\ See license at end of file

: (memory?)  ( adr -- flag )  /ram-bank u<  ;
' (memory?) to memory?

" /memory" find-device

headerless

h# ffff.ffff value low
h#         0 value high

: log&release  ( adr len -- )
   over    low  umin to low   ( adr len )
   2dup +  high umax to high  ( adr len )
   release
;

: scan-banks  ( base mask -- )
   d# 32 0  do                          ( base mask )
      dup 1 and  if                     ( base mask )
         over /ram-bank  log&release    ( base mask )
      then                              ( base mask )
      swap /ram-bank +  swap 1 rshift   ( base' mask' )
   loop                                 ( base mask )
   2drop
;
0 value membanks
headers
: claim  ( [ phys ] size align -- kseg0-adr )  claim kseg0 +  ;

: probe  ( -- )
   ram-pa      bank-mask @  scan-banks

   0 0 encode-bytes                                   ( adr 0 )
   physavail  ['] make-phys-memlist  find-node        ( adr len  prev 0 )
   2drop  " reg" property

   \ Claim the megabyte used for the trap vectors, Forth, and the section table
[ifdef] ram-image
   0                  rom-base /rom + 0 claim  drop
[else]
   0                  /resetjmp       0 claim  drop
[then]
   high h# 10.0000 -  h# 10.0000      0 claim  drop
;

device-end

\ LICENSE_BEGIN
\ Copyright (c) 2009 FirmWorks
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
