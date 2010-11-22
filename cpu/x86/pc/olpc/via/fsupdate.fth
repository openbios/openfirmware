purpose: Secure NAND updater
\ See license at end of file

\ Depends on words from security.fth and copynand.fth

: get-hex#  ( -- n )
   safe-parse-word
   push-hex $number pop-base  " Bad number" ?nand-abort
;

0 value last-eblock#
: erase-eblock  ( eblock# -- )
   \ XXX
   to last-eblock#
;

: ?all-written  ( -- )
   last-eblock# 1+ #image-eblocks <>  if
      cr
      red-letters
      ." WARNING: The file specified " #image-eblocks .d
      ." chunks but wrote only " last-eblock# 1+ .d ." chunks" cr
      black-letters
   then
;

0 value secure-fsupdate?
d# 128 constant /spec-maxline

: erase-gap  ( end-block -- )
   dup last-eblock# >  if
      last-eblock# 1+  ?do  i erase-eblock  loop
   else
      drop
   then
;

\ We simultaneously DMA one data buffer onto NAND while unpacking the
\ next block of data into another. The buffers exchange roles after
\ each block.

0 value dma-buffer
0 value data-buffer

: swap-buffers  ( -- )  data-buffer dma-buffer  to data-buffer to dma-buffer  ;

: force-line-delimiter  ( delimiter fd -- )
   file @                      ( delim fd fd' )
   swap file !                 ( delim fd' )
   swap line-delimiter c!      ( fd' )
   file !                      ( )
;

: ?compare-spec-line  ( -- )
   secure-fsupdate?  if
      data-buffer /spec-maxline  filefd read-line         ( len end? error? )
      " Spec line read error" ?nand-abort                 ( len end? )
      0= " Spec line too long" ?nand-abort                ( len )
      data-buffer swap                                    ( adr len )
      source $= 0=  " Spec line mismatch" ?nand-abort     ( )
   then
;

vocabulary nand-commands
also nand-commands definitions

: flash-led  ( -- )
    h# 4c acpi-l@
    h# 400000 xor
    h# 4c acpi-l!
;

: clear-led  ( -- )
    h# 4c acpi-l@
    h# 400000 or
    h# 4c acpi-l!
;

: zblocks:  ( "eblock-size" "#eblocks" ... -- )
   flash-led
   ?compare-spec-line
   get-hex# to /nand-block
   get-hex# to #image-eblocks
   " size" $call-nand  #image-eblocks /nand-block um*  d<
   " Image size is larger than output device" ?nand-abort
   #image-eblocks  show-init
   0 #image-eblocks " erase-blocks" $call-nand
   get-inflater
   \ Separate the two buffers by enough space for both the compressed
   \ and uncompressed copies of the data.  4x is overkill, but there
   \ is plenty of space at load-base
   load-base to dma-buffer
   load-base /nand-block 4 * + to data-buffer
   /nand-block /nand-page / to nand-pages/block
   t-update  \ Handle possible timer rollover
;

: zblocks-end:  ( -- )
\ Asynchronous writes
   " write-blocks-end" $call-nand   ( error? )
   " Write error" ?nand-abort
\   #image-eblocks erase-gap
   clear-led
   release-inflater
   fexit
;

: data:  ( "filename" -- )
   safe-parse-word            ( filename$ )
   nb-zd-#sectors  -1 <>  if  ( filename$ )
      2drop  " /nb-updater"   ( filename$' )
   else                       ( filename$ )
      fn-buf place            ( )
      " ${DN}${PN}\${CN}${FN}" expand$  image-name-buf place
      image-name$             ( filename$' )
   then                       ( filename$ )
   r/o open-file  if          ( fd )
      drop ." Can't open " image-name$ type cr
      true " " ?nand-abort
   then  to filefd            ( )
   linefeed filefd force-line-delimiter
   true to secure-fsupdate?
;

: erase-all  ( -- )
   #image-eblocks  0  ?do  i erase-eblock  loop
   #image-eblocks show-writing
;

: eat-newline  ( ih -- )
   fgetc newline <>                                    ( error? )
   " Missing newline after zdata" ?nand-abort             ( )
;
: skip-zdata  ( comprlen -- )
   ?compare-spec-line                                     ( comprlen )

   secure-fsupdate?  if  filefd  else  source-id  then    ( comprlen ih )

   >r  u>d  r@ dftell                                     ( d.comprlen d.pos r: ih )
   d+  r@ dfseek                                          ( r: ih )

   r> eat-newline
;

: get-zdata  ( comprlen -- )
   ?compare-spec-line                                     ( comprlen )

   secure-fsupdate?  if  filefd  else  source-id  then    ( comprlen ih )

   >r  data-buffer /nand-block +  over  r@  fgets         ( comprlen #read r: ih )
   <>  " Short read of zdata file" ?nand-abort            ( r: ih )

   r> eat-newline

   \ The "2+" skips the Zlib header
   data-buffer /nand-block + 2+  data-buffer true  (inflate)  ( len )
   /nand-block <>  " Wrong expanded data length" ?nand-abort  ( )
;

true value check-hash?

: check-hash  ( -- )
   2>r                                ( eblock# hashname$ r: hash$ )
   data-buffer /nand-block 2swap      ( eblock# data$ hashname$ r: hash$ )
   2dup " sha256" $=  if              ( eblock# hashname$ r: hash$ )
      2drop sha-256                   ( eblock# calc-hash$ r: hash$ )
   else
      crypto-hash                     ( eblock# calc-hash$ r: hash$ )
   then
   2r>  $=  0=  if                    ( eblock# )
      ." Bad hash for eblock# " .x cr cr
      ." Your USB key may be bad.  Please try a different one." cr
      ." See http://wiki.laptop.org/go/Bad_hash" cr cr
      abort
   then                               ( eblock# )
;

0 value have-crc?
0 value my-crc

: ?get-crc  ( -- )
   parse-word  dup  if                   ( eblock# hashname$ crc$ r: comprlen )
      push-hex $number pop-base  if      ( eblock# hashname$ crc$ r: comprlen )
         false to have-crc?              ( eblock# hashname$ r: comprlen )
      else                               ( eblock# hashname$ crc r: comprlen )
         to my-crc                       ( eblock# hashname$ r: comprlen )
         true to have-crc?               ( eblock# hashname$ r: comprlen )
      then                               ( eblock# hashname$ r: comprlen )
   else                                  ( eblock# hashname$ empty$ r: comprlen )
      2drop                              ( eblock# hashname$ r: comprlen )
      false to have-crc?                 ( eblock# hashname$ r: comprlen )
   then                                  ( eblock# hashname$ r: comprlen )
;
: ?check-crc  ( -- )
   have-crc?  if
   then
;

: zblock: ( "eblock#" "comprlen" "hashname" "hash-of-128KiB" -- )
   get-hex#                              ( eblock# )
   get-hex# >r                           ( eblock# r: comprlen )
   safe-parse-word                       ( eblock# hashname$ r: comprlen )
   safe-parse-word hex-decode            ( eblock# hashname$ [ hash$ ] err? r: comprlen )
   " Malformed hash string" ?nand-abort  ( eblock# hashname$ hash$ r: comprlen )

   ?get-crc                              ( eblock# hashname$ hash$ r: comprlen )

\  2dup  " fa43239bcee7b97ca62f007cc68487560a39e19f74f3dde7486db3f98df8e471" $=  if  ( eblock# hashname$ hash$ r: comprlen)
\     r> skip-zdata                         ( eblock# hashname$ hash$ )
\     2drop 2drop                           ( eblock# )
\  else                                     ( eblock# hashname$ hash$ )
      r> get-zdata                          ( eblock# hashname$ hash$ )
      ?check-crc                            ( eblock# hashname$ hash$ )

      check-hash?  if                       ( eblock# hashname$ hash$ )
         check-hash                         ( eblock# )
      else                                  ( eblock# hashname$ hash$ )
         2drop 2drop                        ( eblock# )
      then                                  ( eblock# )

\ Asynchronous writes
      data-buffer over nand-pages/block *  nand-pages/block  " write-blocks-start" $call-nand  ( eblock# error? )
      " Write error" ?nand-abort   ( eblock# )
\   data-buffer over nand-pages/block *  nand-pages/block  " write-blocks" $call-nand  ( eblock# #written )
\   nand-pages/block  <>  " Write error" ?nand-abort   ( eblock# )
      swap-buffers                          ( eblock# )
\  then

   dup to last-eblock#                   ( eblock# )
   show-written                          ( )
   show-temperature
   flash-led
;

previous definitions

: fs-update  ( "devspec" -- )
   load-crypto  abort" Can't load hash routines"

   open-nand                           ( )

   false to secure-fsupdate?           ( )
   safe-parse-word r/o open-file       ( fd error? )
   " Can't open file" ?nand-abort      ( fd )

   linefeed over force-line-delimiter  ( fd )

   t-hms(                              ( fd )
   also nand-commands                  ( fd )
   ['] include-file catch  ?dup  if    ( x error )
      nip .error
   then                                ( )
   previous definitions

   show-done
   ?all-written
   close-nand-ihs
   )t-hms
;

: do-fs-update  ( img$ -- )
   tuck  load-base h# c00000 +  swap move  ( len )
   load-base h# c00000 + swap              ( adr len )

   ['] noop to show-progress               ( adr len )

   open-nand                               ( adr len )

\  clear-context  nand-commands
   t(
   also nand-commands                      ( adr len )

   true to secure-fsupdate?                ( adr len )
   ['] include-buffer  catch  ?dup  if  nip nip  .error  security-failure  then

   previous
\  only forth also definitions

   show-done
   ?all-written
   close-nand-ihs
   )t-hms cr
;

: fs-update-from-list  ( devlist$ -- )
   load-crypto  if  visible  ." Crytpo load failed" cr  show-sad  security-failure   then

   visible                            ( devlist$ )
   begin  dup  while                  ( rem$ )
      bl left-parse-string            ( rem$ dev$ )
      dn-buf place                    ( rem$ )

      null$ pn-buf place              ( rem$ )
      null$ cn-buf place              ( rem$ )
      " fs" bundle-present?  if       ( rem$ )
         " Filesystem image found - " ?lease-debug
         fskey$ to pubkey$            ( rem$ )
         img$  sig$  sha-valid?  if   ( rem$ )
            2drop                     ( )
            show-unlock               ( )
            img$ do-fs-update         ( )
            ." Rebooting in 10 seconds ..." cr
            d# 10,000 ms  bye
            exit
         then                         ( rem$ )
         show-lock                    ( rem$ )
      then                            ( rem$ )
   repeat                             ( rem$ )
   2drop
;
: update-devices  " disk: ext: http:\\172.18.0.1"  ;
: try-fs-update  ( -- )
   ." Searching for a NAND file system update image." cr
   " disk: ext:" fs-update-from-list
   ." Trying NANDblaster" cr
   ['] nandblaster catch  0=  if  exit  then
   " http:\\172.18.0.1" fs-update-from-list
;

: $update-nand  ( devspec$ -- )
   load-crypto abort" Can't load the crypto functions"
   null$ cn-buf place                           ( devspec$ )
   2dup                                         ( devspec$ devspec$ )
   [char] : right-split-string dn-buf place     ( devspec$ path+file$ )
   [char] \ right-split-string                  ( devspec$ file$ path$ )
   dup  if  1-  then  pn-buf place              ( devspec$ file$ )
   2drop                                        ( devspec$ )
   boot-read loaded do-fs-update                ( )
;
: update-nand  ( "devspec" -- )  safe-parse-word  $update-nand  ;

0 0  " "  " /" begin-package
   " nb-updater" device-name
   0. 2value offset
   : size  ( -- d.#bytes )  nb-zd-#sectors h# 200 um*  ;
   : open  ( -- flag )
      nb-zd-#sectors -1 =  if
         ." nb-updater: nb-zd-#sectors is not set" cr
         false exit
      then
      nandih  0=  if
         ." nb-updater: fsdisk device is not open" cr
         false exit
      then
      " size" $call-nand  ( d.size )
      size d- to offset
      true
   ;
   : close  ;
   : seek  ( d.pos -- )  offset d+  " seek" $call-nand  ;
   : read  ( adr len -- actual )  " read" $call-nand  ;
   \ No write method for this
end-package

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
