\ See license at end of file
purpose: Interface methods for AMD CS5536 NAND controller

external

: msr@  ( adr -- d )  " rdmsr" eval  ;
: open  ( -- okay? )
   \ We assume that LinuxBIOS has already set up the address map
   \ and the timing MSRs.
   set-lmove
   h# 51400010 msr@ drop to nand-base
   configure 0=  if  false exit  then

   my-args  dup  if   ( arg$ )
      " jffs2-file-system" find-package  if  ( arg$ xt )
         interpose  true   ( okay? )
      else                 ( arg$ )
         ." Can't find jffs2-file-system package" cr
         2drop  false      ( okay? )
      then                 ( okay? )
   else                    ( arg$ )
      2drop  true          ( okay? )
   then                    ( okay? )
;
: close  ( -- )  ;

: size  ( -- d )  pages/chip /page um*  ;

: dma-alloc  ( len -- adr )  " dma-alloc" $call-parent  ;

: dma-free  ( adr len -- )  " dma-free" $call-parent  ;

: read-blocks  ( adr page# #pages -- #read )
   dup >r          ( adr page# #pages r: #pages )
   bounds  ?do                  ( adr )
      dup i page-read           ( adr )
      /page +                   ( adr' )
   loop                         ( adr )
   drop  r>
;

[ifdef] notdef
: write-blocks  ( adr page# #pages -- #read )
   dup >r          ( adr page# #pages r: #pages )
   bounds  ?do                          ( adr )
      \ XXX need some error handling
      dup i page-write                  ( adr )
      /page +                           ( adr' )
   loop                                 ( adr )
   drop  r>
;
[then]

[ifdef] notdef
: erase-blocks  ( page# #pages -- #pages )
   tuck  bounds  ?do  i erase-block  pages/eblock +loop
;
[then]

: block-size    ( -- n )  /page  ;

: erase-size    ( -- n )  /eblock  ;

: max-transfer  ( -- n )  /eblock  ;

headers

[ifdef] notdef
variable temp
0 instance value copy-page#
: +copy-page  ( -- )  copy-page# pages/eblock +  to copy-page#  ;

: find-good-block  ( -- )
   begin
      copy-page#    read-oob  h# 3c + @  0=
      copy-page# 1+ read-oob  h# 3c + @  0=
   or  while
      +copy-page
   repeat
;

external

\ These methods are used for copying a verbatim file system image
\ onto the NAND FLASH, automatically skipping bad blocks.

: start-copy  ( -- )  0 to copy-page#  ;

: copy-block  ( adr -- )
   find-good-block
   copy-page# erase-block
   copy-page#  pages/eblock  bounds  ?do  ( adr )
      dup i page-write                    ( adr )
      /page +                             ( adr' )
   loop                                   ( adr )
   drop                                   ( )
   +copy-page
;
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
