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

vocabulary nand-commands
also nand-commands definitions

: zblocks:  ( "eblock-size" "#eblocks" ... -- )
   get-hex# to /nand-block
   get-hex# to #image-eblocks
   open-nand
   #image-eblocks  show-init
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
   " write-blocks-finish" $call-nand  drop
   #image-eblocks erase-gap
;

: data:  ( "filename" -- )
   safe-parse-word fn-buf place
   " ${DN}${PN}\${CN}${FN}" expand$  image-name-buf place
   image-name$ r/o open-file  if
      drop ." Can't open " image-name$ type cr
      true " " ?nand-abort
   then  to filefd
   linefeed filefd force-line-delimiter
   \ Eat the initial "zblocks:" line
   load-base /spec-maxline  filefd read-line     ( len not-eof? error? )  
   " Read error on .zd file" ?nand-abort         ( len not-eof? )
   0= " Premature EOF on .zd file" ?nand-abort   ( len )
   drop                                          ( )
   true to secure-fsupdate?
;

: erase-all  ( -- )
   #image-eblocks  0  ?do  i erase-eblock  loop
   #image-eblocks show-writing
;

: get-zdata  ( comprlen -- )
   secure-fsupdate?  if
      data-buffer /spec-maxline  filefd read-line         ( len end? error? )
      " Spec line read error" ?nand-abort                 ( len end? )
      0= " Spec line too long" ?nand-abort                ( len )
      data-buffer swap                                    ( adr len )
      source $= 0=  " Spec line mismatch" ?nand-abort     ( )

      filefd                                              ( ih )
   else                                                   ( )
      source-id                                           ( ih )
   then                                                   ( ih )

   >r  data-buffer /nand-block +  over  r@  fgets         ( comprlen #read r: ih )
   <>  " Short read of zdata file" ?nand-abort            ( r: ih )

   r> fgetc newline <>                                    ( error? )
   " Missing newline after zdata" ?nand-abort             ( )

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
   r> get-zdata                          ( eblock# hashname$ hash$ )
   ?check-crc                            ( eblock# hashname$ hash$ )

   check-hash?  if                       ( eblock# hashname$ hash$ )
      check-hash                         ( eblock# )
   else                                  ( eblock# hashname$ hash$ )
      2drop 2drop                        ( eblock# )
   then
   
   ( eblock# )
\ Asynchronous writes
   data-buffer over nand-pages/block *  nand-pages/block  " write-blocks-start" $call-nand  ( eblock# )
\   data-buffer over nand-pages/block *  nand-pages/block  " write-blocks" $call-nand  ( eblock# #written )
\   nand-pages/block  <>  " Write error" ?nand-abort   ( eblock# )
   swap-buffers                          ( eblock# )

   dup to last-eblock#                   ( eblock# )
   show-written                          ( )
   show-temperature
;

previous definitions

: fs-update  ( "devspec" -- )
   load-crypto  abort" Can't load hash routines"

   false to secure-fsupdate?
   safe-parse-word r/o open-file       ( fd )
   abort" Can't open file"             ( fd )

   linefeed over force-line-delimiter  ( fd )

   t(                                  ( fd )
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

   ['] noop to show-progress

\  clear-context  nand-commands
   t(
   also nand-commands
   
   true to secure-fsupdate?
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
[ifdef] Later
   ." Trying NANDblaster" cr
   ['] nandblaster catch  0=  if  exit  then
   " http:\\172.18.0.1" fs-update-from-list
[then]
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
