purpose: Device tree node that accesses a host system file
\ See license at end of file

\ Creates a device node named "/sparsefile", of device-type "block", which
\ accesses an operating system file named by its first argument.  That
\ file contains a verbatim disk image in the following sparse format:
\
\  Images: N block images
\  Map: N integers indicating the block number of the corresponding block image
\  N: integer denoting N
\  Max: integer denoting the maximum block number for the virtual disk
\  BlockSize: integer denoting the length of each block image

\ Backslash (\) characters in the file name are translated to
\ the underlying operating system's directory delimiter.
\   Example:   dir /osfile:\dev\rfd0,\boot\test.fth
\   Example:   dir /osfile:\home\wmb\fs.img,\boot\test.fth
\ As an alternative to supplying the disk image filename in the device
\ specifier, you can set "osfile$" to return the name.  This is
\ helpful for cases where the image filename would interfere with
\ the parsing of later parts of the device specifier.
\   Example:
\      dev /osfile
\      : disk-image$  " /tmp/disk.img" ;
\      ' disk-image$ to osfile$
\      dend
\      dir /osfile:\boot\test.fth
\ When using the "osfile$" method, you can use either backslash (\) or
\ the system's native delimiter in the disk image filename.  When using
\ the device specifier argument method, you must use backslash, because
\ forward slash delimits major device tree components in a device specifier.

dev /
\ : open true ; : close ;

new-device
" sparsefile" device-name
also
defer sparsefile$ ' null$ to sparsefile$
0 value file#

\ The deblocker converts a block/record-oriented interface to a byte-oriented
\ interface, using internal buffering.  Disk and tape devices are usually
\ block or record oriented, but the Open Firmware external interface is
\ byte-oriented, in order to be independent of particular device block sizes.

0 value deblocker
: init-deblocker  ( -- okay? )
   " "  " deblocker"  $open-package  is deblocker
   deblocker if
      true
   else
      ." Can't open deblocker package"  cr  false
   then
;

0 instance value label-package
0 instance value offset-low
0 instance value offset-high

: init-label-package  ( adr len -- okay? )
   0 is offset-high  0 is offset-low
\ iso9660-file-system
   " disk-label"  $open-package is label-package
   label-package  if
      0 0  " offset" label-package $call-method is offset-high is offset-low
      true
   else
      ." Can't open disk label package"  cr  false
   then
;
: convert/  ( filename$ -- )
   bounds  ?do
      i c@ [char] \ =  if  [char] / i c!  then
   loop
;
: $fopen  ( adr len -- fd )  $cstr  2 swap 8 syscall 2drop retval  ;
: do-seek  ( offset whence -- error? )  swap file# _lseek nip  ;
: do-write  ( adr len -- error? )
   file#  ['] _fwrite  catch  if  3drop true  else  drop false  then
;
: do-read  ( adr len -- error? )
   file#  ['] _fread  catch  if  3drop true  else  drop false  then
;

0 value #block-map
0 value block-map
0 value #blocks
0 value #active-blocks
0 value block-size
d# 12 buffer: params
: parse-sparse  ( -- error? )
   3 /n* negate  2 do-seek  if  true exit  then
   params  3 /n*  do-read if  true exit  then
   params @ to #active-blocks
   params na1+ @ to #blocks
   params 2 na+ @ to block-size
   #active-blocks d# 1024 +  to #block-map
   #block-map /n* alloc-mem to block-map
   #active-blocks /n* negate  3 /n* -  2 do-seek  if  true exit  then
   block-map  #active-blocks /n*  do-read  if  true exit  then
   false   
;
: save-block-map  ( -- )
   #active-blocks block-size *  0 do-seek  if  exit  then   ( )
   block-map  #active-blocks /n*  do-write  if  exit  then  ( )
   #active-blocks params !
   #blocks  params na1+ !
   block-size params 2 na+ !
   params  3 /n*  do-write  drop
;

0 value open-count
: open  ( -- flag )
   my-args                                         ( arg$ )
   sparsefile$  dup 0=  if                         ( arg$ null$ )
      2drop                                        ( arg$ )
      ascii , left-parse-string                    ( arg$' img-filename$ )
   then                                            ( arg$ img-filename$ )

   open-count  if                                  ( arg$ img-filename$ )
      2drop                                        ( arg$ )
   else                                            ( arg$ img-filename$ )
      2dup  convert/                               ( arg$ img-filename$ )
      $fopen to file#                              ( arg$ )
      file# 0<  if  2drop false  exit  then        ( arg$ )

      parse-sparse  if  2drop false exit  then     ( arg$ )

      init-deblocker  0=  if  false exit  then     ( arg$ )
   then                                            ( arg$ )

   init-label-package  dup 0=  if                  ( flag )
      open-count 0=  if                            ( flag )
         deblocker close-package                   ( false )
         file# d# 16 syscall  drop                 ( false )
      then                                         ( flag )
   then                                            ( flag )

   dup  if                                         ( flag )
      open-count 1+ to open-count                  ( flag )
   then                                            ( flag )
;
[ifndef] lfind
[ifdef] 386-assembler
   code lfind  ( sought adr len -- false | index true )
      cx pop       ( cx: len )
      bx pop       ( bx: adr )
      dx pop       ( dx: sought )
      si push
      bx si mov    ( si: adr )
      2 # cx shr   ( cx: longword count )
      begin
         ax lods
         ax dx cmp  = if
            bx si sub     
            2 # si shr
            si dec
            si  0 [sp]  xchg

            ax ax xor
            ax dec
            ax push
            next
         then
      loopa
      si pop      \ Restore si
      ax ax xor
      ax push
   c;
[then]
[ifndef] lfind
   : lfind  ( sought adr len -- false | index true )
      over >r              ( sought adr len r: adr )
      over +  search  if   ( loc r: adr )
         r> - /n /  true   ( index true )
      else                 ( r: adr )
         r> drop false     ( false )
      then                 ( false | index true )
   ;
[then]
[then]
: >block-index  ( block# -- )
   block-map #active-blocks /n*  lfind
;
: read-stored-block  ( adr index -- error? )
   block-size *  0 do-seek  if  drop  true exit  then   ( adr )
   block-size do-read  if  true exit  then              ( )
   false
;

: read-block  ( adr block# -- error? )
." R " dup .x
   dup #blocks >=  if  2drop true exit  then

   >block-index  if        ( adr index )
." I " dup . cr
      read-stored-block    ( error? )
   else                    ( adr )
." Z" cr
      block-size erase     ( )
      false                ( error? )
   then
;

: read-blocks  ( adr block# #blocks -- actual#blocks )
   -rot  2 pick                    ( #blocks adr block# )
   0  do                           ( #blocks adr block# )
      2dup read-block  if          ( #blocks adr block# )
         3drop i unloop exit       ( -- actual#blocks )
      then                         ( #blocks adr block# )
      swap block-size +  swap 1+   ( #blocks adr' block#' )
   loop                            ( #blocks adr block# )
   2drop                           ( actual#blocks )
;

: resize-block-map  ( -- error? )
   block-map  #block-map d# 1024 +  /n*  resize  if  ( buf-adr )
      drop  true exit                                ( -- error? )
   then                                              ( buf-adr )
   to block-map                                      ( )
   #block-map d# 1024 +  to #block-map               ( )
   false                                             ( error? )
;
: write-stored-block  ( adr index -- error? )
   block-size *  0 do-seek  if  drop true exit  then   ( adr )
   block-size do-write if  true exit  then             ( )
   false
;

: write-new-block  ( adr block# -- error? )
   #active-blocks #block-map >=  if                  ( adr block# )
      resize-block-map  if  2drop true exit  then    ( adr block# )
   then                                              ( adr block# )
   swap  #active-blocks write-stored-block  if       ( block# )
      drop true exit                                 ( -- error? )
   then                                              ( block# )
   block-map #active-blocks na+  !                   ( )
   #active-blocks 1+ to #active-blocks               ( )
   false                                             ( error? )
;   

: write-block  ( adr block# -- error? )
." W " dup .x 
   dup #blocks >=  if          ( adr block# )
      2drop true exit          ( -- error? )
   then                        ( adr block# )

   dup >block-index  if        ( adr block# index )
." I " dup .x cr
      nip write-stored-block   ( error? )
   else                        ( adr block# )
." N" cr
      write-new-block          ( error? )
   then                        ( error? )
;

: write-blocks  ( adr block# #blocks -- actual#blocks )
   -rot  2 pick                    ( #blocks adr block# )
   0  do                           ( #blocks adr block# )
      2dup write-block  if         ( #blocks adr block# )
         3drop i unloop exit       ( -- actual#blocks )
      then                         ( #blocks adr block# )
      swap block-size +  swap 1+   ( #blocks adr' block#' )
   loop                            ( #blocks adr block# )
   2drop                           ( actual#blocks )
;

: close  ( -- )
   open-count  dup 1-  0 max   to open-count  ( prev-open-count )
   label-package close-package                ( prev-open-count )
   1 =  if                                    ( )
      deblocker close-package                 ( )
      save-block-map                          ( )
      file# d# 16 syscall  drop               ( )
   then                                       ( )
;

: dma-alloc  ( size -- adr )  alloc-mem  ;
: dma-free   ( adr size -- )  free-mem  ;
: max-transfer  ( -- n )   block-size  ;

: seek  ( offset.low offset.high -- okay? )
   offset-low offset-high  d+  " seek"   deblocker $call-method
;
: read  ( addr len -- actual-len )  " read"  deblocker $call-method  ;
: write ( addr len -- actual-len )  " write" deblocker $call-method  ;
finish-device
device-end

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
