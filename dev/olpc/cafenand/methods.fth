\ See license at end of file
purpose: interface methods for CaFe NAND controller

: $=  ( $1 $2 -- flag )
   rot tuck <>  if  3drop false exit  then
   comp 0=
;

: configure-all  ( -- error? )
   0 to total-pages

   \ Set boundary to 0 to look for chip on CE1#
   \ If one is found, the number of pages will be added to total-pages
   0 to chip-boundary  configure  drop

   \ Set boundary to 1 to look for chip on CE0#  (configure uses page# 0)
   1 to chip-boundary  configure  if
      pages/chip  \ Chip present at CE0#, set boundary above it
   else
      0           \ No chip at CE0, set boundary at 0 to use CE1# chip
   then
   to chip-boundary

   total-pages 0=   \ Error if there are no chips
;

: open-args  ( -- arg$ )
   \ If the argument string starts with :, discard the rest, because
   \ it is intended for the selftest function.
   my-args  dup  0>  if    ( arg$ )
      over c@  ascii :  =  if  drop 0  then
   then
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
;

: size  ( -- d )  partition-size /page  um*  ;

: $set-partition  ( $ -- error? )
   dup 0=  if  2drop false exit  then      ( $ )
   over c@  ascii 0 ascii 9 between  if    ( $ )  \ number
      base @ >r decimal  $number  r> base !  if  true exit  then   ( )
      set-partition-number                 ( error? )
   else                                    ( $ )  \ name
      set-partition-name                   ( error? )
   then                                    ( error? )
   dup  if                                 ( error? )
      ." NAND: No such partition" cr       ( error? )
   then
;

: open  ( -- okay? )
   map-regs
   init
   0 to partition#
   0 to partition-start
   configure-all  if  false exit  then

   /dma-buf dma-alloc to dma-buf-va
   dma-buf-va /dma-buf false " dma-map-in" $call-parent to dma-buf-pa

   " lmove" $find  0=  if  ['] move  then  to do-lmove

   get-bbt
   usable-page-limit to partition-size
   read-partmap

   open-args  dup  if   ( arg$ )
      ascii , left-parse-string    ( arg2$ arg1$ )

      \ Handle partitions                                 ( arg2$ arg1$ )
      2dup 1 min  " \"  $=  if                            ( arg2$ arg1$ )
         2swap 2drop                                      ( arg1$ )
         \ If there is no "mtd" specifier and there is a partition map,
         \ select the boot partition.
         #partitions 0>=  if                              ( arg1$ )
            " boot" $set-partition  if  2drop false exit  then
         then                                             ( arg2$ arg1$ )
      else                                                ( arg2$ arg1$ )
         \ The argument is not a file so it must be a partition spec
         #partitions 0<  if  2drop 2drop  false exit  then  ( arg2$ arg1$ )
         $set-partition  if  2drop false exit  then         ( arg2$ )
      then                                                  ( arg$ )

      dup 0=  if  2drop  true exit  then                    ( arg$ )

      " jffs2-file-system" find-package  if                 ( arg$ xt )
         interpose  true   ( okay? )
      else                 ( arg$ )
         ." Can't find jffs2-file-system package" cr
         2drop  false      ( okay? )
      then                 ( okay? )
   else                    ( arg$ )
      2drop  true          ( okay? )
   then                    ( okay? )
;

: selftest  ( -- error? )
   map-regs
   read-id 1+ c@ h# dc <>
   unmap-regs
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
