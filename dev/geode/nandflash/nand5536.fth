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

create ff-buf
   h# ffffffff l,  h# ffffffff l,  h# ffffffff l,  h# ffffffff l, 
   h# ffffffff l,  h# ffffffff l,  h# ffffffff l,  h# ffffffff l, 
   h# ffffffff l,  h# ffffffff l,

h# 40 constant /oob

h#  8 constant bb-offset
h# 28 constant ecc-offset

h# 18 constant /ecc     \ 3 parity bytes for each of 8 256-byte chunks

: clear-ecc  ( -- )  7 h# 815 nand!  ;

h# 40 buffer: oob-buf

: cmd  ( b -- )  2 h# 800 nand!  h# 801 nand!  ;
: adr  ( b -- )  4 h# 800 nand!  h# 801 nand!  ;
: stp  ( -- )  1 h# 800 nand!  ;
: data  ( -- )  0 h# 800 nand!  ;
: wait-ready  ( -- )  data  begin  h# 810 nand@ 8 and  until  ;


: page-adr  ( page# -- )  dup adr  8 rshift dup adr  8 rshift adr  ;
: start-io  ( page# offset cmd -- )
   cmd                      ( page# offset )
   wbsplit swap  adr  adr   ( page# )
   page-adr                 ( )
;

h# 10 buffer: ecc-buf
h# 40 buffer: oob-buf

: read-oob  ( page# -- adr )
   h# 800  0  start-io  h# 30 cmd      ( )
   wait-ready                          ( )
   nand-base  oob-buf  /oob  lmove    ( )
   stp
   oob-buf
;

: c!+  ( adr b -- adr' )  over c! 1+  ;
: +ecc  ( adr -- adr' )  h# 812 nand@ c!+  h# 811 nand@ c!+  h# 813 nand@ c!+  ;

: handle-ecc  ( adr -- )
   \ Read the oob data...
   nand-base oob-buf  h# 40 lmove

   \ Compare read ECC to calculated ECC
   ecc-buf  oob-buf ecc-offset +  /ecc  comp  if   ( adr )
      \ If it doesn't match, also check for a fully-erased page
      ff-buf  oob-buf ecc-offset +  /ecc comp  if
         \ Bad ECC, and not fully erased
         \ XXX should try to correct
         ." ECC error" cr
      then
   then                                            ( adr )

   drop
;

\ This is for FLASH chips that use 5 address cycles plus a second command cycle
: read-page  ( adr page# -- )
   0  0  start-io   h# 30 cmd                 ( adr )  \ Command 2

   wait-ready                                 ( adr )
  
   ecc-buf                                    ( adr ecc-buf )
   h# 800 0  do                               ( adr ecc-buf )
      clear-ecc                               ( adr ecc-buf )
      nand-base  2 pick i +  d# 256  lmove    ( adr ecc-buf )  \ Get 256 bytes
      +ecc                                    ( adr ecc-buf' )
   d# 256 +loop                               ( adr ecc-buf )
   drop                                       ( adr )
   handle-ecc                                 ( )
   stp
;
h# 800 buffer: page-buf
: get-page  ( page# -- adr )  page-buf swap read-page  page-buf  ;

: read-id  ( -- adr )
   h# 90 cmd   \ Read-id command
   0     adr   \ address 0
   wait-ready
   nand-base  oob-buf  8  lmove
   oob-buf
;

: read-status  ( -- n )
   h# 70 cmd  data            \ Send cmd then turn off CLE
   0 nand@  h# ff and         \ Read response
   stp                        \ Disable CE#
;

: wait-write-done  ( -- )
   0               ( status )
   begin           ( status )
     drop          ( )
     read-status   ( status )
     dup h# 40 and ( status flag )
   until           ( status )
   \ If the value is completely 0 I think it means write protect     
   1 and  if  ." NAND write error" cr  then
;

: write-bytes   ( adr len page# offset -- )
   h# 80  start-io  data       ( adr len )
   nand-base swap lmove        ( )
   h# 10 cmd   stp             ( )
   wait-ready
   wait-write-done
;

: write-page  ( adr page# -- )
   0  h# 80  start-io   data                  ( adr )

   ecc-buf                                    ( adr ecc-buf )
   h# 800 0  do                               ( adr ecc-buf )
      clear-ecc                               ( adr ecc-buf )
      over i +  nand-base  d# 256  lmove      ( adr ecc-buf )  \ Put 256 bytes
      +ecc                                    ( adr ecc-buf' )
   d# 256 +loop                               ( adr ecc-buf )
   2drop                                      ( )

   ff-buf  nand-base  ecc-offset  lmove       ( )
   ecc-buf nand-base /ecc lmove               ( )

   h# 10 cmd                                  \ Command 2
   stp
   wait-ready
   wait-write-done
;

: erase-block  ( page# -- )
   h# 60 cmd  page-adr  h# d0 cmd  ( )
   stp
   wait-ready
   wait-write-done
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
