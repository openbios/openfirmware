\ See license at end of file
purpose: NAND FLASH driver for 5536 companion chip

" nandflash" device-name

h# 2000.0000 h# 1000 reg

0 value nand-base

defer lmove

: set-lmove
  " lmove" my-parent ihandle>phandle find-method  0=  if  ['] move  then
  to lmove
;

: nand@  ( reg# -- b )  nand-base + c@  ;
: nand!  ( b reg# -- )  nand-base + c!  ;

h#     800 instance value /page
h#  2.0000 instance value /eblock

8 constant /ecc

: clear-ecc  ( -- )  3 h# 815 nand!  ;
: get-ecc  ( -- )  h# 811 nand@  h# 812 nand@  bwjoin  ;

h# 40 buffer: oob-buf

: wait-ready  ( -- )  0 h# 800 nand!  begin  h# 810 nand@ 8 and  until  ;

: cmd  ( b -- )  2 h# 800 nand!  h# 801 nand!  ;
: adr  ( b -- )  4 h# 800 nand!  h# 801 nand!  ;
: stp  ( -- )  1 h# 800 nand!  ;

: start-io  ( page# offset cmd -- )
   cmd                      ( page# offset )
   wbsplit swap  adr  adr   ( page# )
   dup adr  8 rshift dup adr  8 rshift adr  ( )
;

h# 10 buffer: ecc-buf
h# 40 buffer: oob-buf

: read-oob  ( page# -- adr )
   h# 800  0  start-io  h# 30 cmd      ( )
   wait-ready                          ( )
   nand-base  oob-buf  h# 40  lmove    ( )
   stp
   oob-buf
;

: handle-ecc  ( ecc-buf adr -- )
\  nand-base  oob-buf  h# 10  lmove    ( ecc-buf adr )
\ Here we should compare the calculated and read ECC
\ and perform error correction as necessary
   2drop   
;

\ This is for FLASH chips that use 5 address cycles plus a second command cycle
: page-read  ( adr page# -- )
   0  0  start-io   h# 30 cmd                 ( adr )  \ Command 2

   wait-ready                                 ( adr )
  
   ecc-buf swap                               ( ecc-buf adr )
   h# 800 0  do                               ( ecc-buf adr )
      clear-ecc                               ( ecc-buf adr )
      nand-base i +  over i +  d# 256  lmove  ( ecc-buf adr )  \ Get 256 bytes
      get-ecc 2 pick w!                       ( ecc-buf adr )
      swap wa1+  swap                         ( ecc-buf' adr )
   d# 256 +loop                               ( ecc-buf adr )
   
   handle-ecc
   stp
;

: read-id  ( -- adr )
   h# 90 cmd   \ Read-id command
   0     adr   \ address 0
   wait-ready
   8 0  do  i nand@  oob-buf i +  c!  loop
   oob-buf
;
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
