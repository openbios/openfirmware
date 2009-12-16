purpose: SD disk (MMC) driver
\ See license at end of file

" disk" device-name
" sdmmc" " iconname" string-property
" block" device-type

0 instance value label-package

0 instance value offset-low     \ Offset to start of partition
0 instance value offset-high

\ The deblocker converts a block/record-oriented interface to a byte-oriented
\ interface, using internal buffering.  Disk and tape devices are usually
\ block or record oriented, but the OBP external interface is byte-oriented,
\ in order to be independent of particular device block sizes.

0 instance value deblocker

external

\ For deblocker

\ Must agree with init-dma - the high bits of register 4.
: max-transfer  ( -- n )   h# 10000   ; 

: read-blocks   ( adr block# #blocks -- #read )
   true  " r/w-blocks" $call-parent
;
: write-blocks  ( adr block# #blocks -- #written )
   false  " r/w-blocks" $call-parent
;

\ Asynchronous write. Completes on the next call to
\ write-blocks-start, write-blocks-finish, or close.
\ (Don't do other read/write operations in between.)
: write-blocks-start  ( adr block# #blocks -- error? )
   false  " r/w-blocks-start" $call-parent
;
: write-blocks-end  ( -- error? )
   false  " r/w-blocks-end" $call-parent
;

: dma-alloc   ( size -- vadr )  " dma-alloc"  $call-parent  ;
: dma-free    ( vadr size -- )  " dma-free"   $call-parent  ;

: set-unit  ( -- )  0 my-unit " set-address" $call-parent  ;
: open  ( -- )
   set-unit
   " attach-card" $call-parent  0=  if  false exit  then

   " "  " deblocker"  $open-package  ?dup  if
      to deblocker
   else
      ." Can't open deblocker package"  cr
      false exit
   then

   my-args  " disk-label"  $open-package  ?dup  if   ( ihandle )
      to label-package 
      0 0  " offset" label-package $call-method  to offset-high  to offset-low
   else
      ." Can't open disk label package"  cr
      deblocker close-package  false exit
   then

   true
;

: close  ( -- )
   label-package close-package
   deblocker close-package
   \ Close packages first in case of delayed write flush
   " detach-card" $call-parent
;

: block-size  ( -- n )  h# 200  ;

: #blocks  ( -- n )
   " size" $call-parent  block-size um/mod  nip
;
: seek  ( offset.low offset.high -- okay? )
   offset-low offset-high d+  " seek"   deblocker $call-method
;

: read  ( addr len -- actual-len )  " read"  deblocker $call-method  ;
: write ( addr len -- actual-len )  " write" deblocker $call-method  ;
: load  ( addr -- size )            " load"  label-package $call-method  ;

: size  ( -- d.size )  " size" label-package $call-method  ;
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
