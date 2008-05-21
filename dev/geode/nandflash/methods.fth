\ See license at end of file
purpose: Interface methods for AMD CS5536 NAND controller

: $=  ( $1 $2 -- flag )
   rot tuck <>  if  3drop false exit  then
   comp 0=
;

: msr@  ( adr -- d )  " rdmsr" eval  ;

external

: dma-alloc  ( len -- adr )  " dma-alloc" $call-parent  ;

: dma-free  ( adr len -- )  " dma-free" $call-parent  ;

: close  ( -- )  ;

: size  ( -- d )  partition-size /page um*  ;

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
   \ We assume that LinuxBIOS has already set up the address map
   \ and the timing MSRs.
   set-lmove

   h# 51400010 msr@ drop h# 1000 " map-in" $call-parent  to nand-base

   0 to partition#
   0 to partition-start
   configure 0=  if  false exit  then

   get-bbt
   usable-page-limit to partition-size
   read-partmap

   my-args  dup  if   ( arg$ )
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

headers

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
