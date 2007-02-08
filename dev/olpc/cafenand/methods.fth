\ See license at end of file
purpose: interface methods for CaFe NAND controller

: $=  ( $1 $2 -- flag )
   rot tuck <>  if  3drop false exit  then
   comp 0=
;

external

: dma-alloc  ( len -- adr )  " dma-alloc" $call-parent  ;

: dma-free  ( adr len -- )  " dma-free" $call-parent  ;

: close  ( -- )
   \ Leave the timing registers set so the OS driver can get the
   \ right values from them.
   soft-reset timing-configure unmap-regs
   dma-buf-va  ?dup  if
      dma-buf-va dma-buf-pa /dma-buf  " dma-map-out" $call-parent
      /dma-buf dma-free
   then
   ?free-resmap
;

: size  ( -- d )
   resmap  if
      #reserved-eblocks /eblock
   else
      pages/chip /page
   then
   um*
;

: open  ( -- okay? )
   map-regs
   init
   configure 0=  if  false exit  then

   /dma-buf dma-alloc to dma-buf-va
   dma-buf-va /dma-buf false " dma-map-in" $call-parent to dma-buf-pa

   " lmove" $find  0=  if  ['] move  then  to do-lmove

   get-bbt

   my-args  dup  if   ( arg$ )
      ascii , left-parse-string    ( arg2$ arg1$ )
      2dup " zip" $=  if           ( arg2$ arg1$ )
         2drop                         ( arg2$ )
         map-reserved                  ( arg2$ )
         init-deblocker  0=  if  2drop ?free-resmap false exit  then  ( arg2$ )

         \ If no file is specified, open the raw archive
         dup 0=  if  2drop true exit  then                ( arg2$ )
      
         \ Otherwise interpose the filesystem handler
         " zip-file-system" find-package  if              ( arg2$ xt )
            interpose true                                ( true )
         else                                             ( arg2$ )
            ." Can't find zip-file-system package" cr     ( arg2$ )
            2drop  deblocker close-package  ?free-resmap  ( )
            false                                         ( false )
         then
         exit
      then                                                ( arg2$ arg1$ )

      \ Accept either "path" or "jffs2,path"
      2dup " jffs2" $=  if                                ( arg2$ arg1$ )
         2drop                                            ( arg2$ )
      else                                                ( arg2$ arg1$ )
         \ XXX probably should check that arg$2 is empty...
         2swap 2drop                                      ( arg1$ )
      then                                                ( arg$ )

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

\ Establish the NAND timings regardless of whether the device is
\ ever opened, so the OS driver doesn't have to worry about it.
\ Fortunately, for all the NAND chips we have considered so far,
\ the same timing set is appropriate.

: probe  ( -- )  map-regs  timing-configure  unmap-regs  ;
probe

headers

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
