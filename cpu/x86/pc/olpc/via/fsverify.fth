\ Boot script for post-audit testing
[ifndef] fs-verify
vocabulary fs-verify-commands
also fs-verify-commands definitions

: zblocks:  ( "eblock-size" "#eblocks" ... -- )
   get-hex# to /nand-block
   get-hex# to #image-eblocks
   open-nand
   /nand-block /nand-page / to nand-pages/block
;

: zblocks-end:  ( -- )
;

\ This could be a no-op ...
: data:  ( "filename" -- )
   safe-parse-word fn-buf place
   " ${DN}${PN}\${CN}${FN}" expand$  image-name-buf place
;

: erase-all  ( -- )
;

load-base value data-buffer

: verify-hash  ( hashname$ hash$ -- okay? )
   2swap                              ( hash$ hashname$ )
   data-buffer /nand-block 2swap      ( hash$ data$ hashname$ )
   fast-hash                          ( hash$ calc-hash$ )
   $=                                 ( okay? )
;

: zblock: ( "eblock#" "comprlen" "hashname" "hash-of-128KiB" -- )
   get-hex#                              ( eblock# )

   data-buffer over nand-pages/block *  nand-pages/block  " read-blocks" $call-nand  ( eblock# #read )
   nand-pages/block <>                   ( eblock# err? )
   " Read failure" ?nand-abort           ( eblock# )

   get-hex# drop                         ( eblock# ) \ comprlen not needed for verify
   safe-parse-word                       ( eblock# hashname$ )
   safe-parse-word hex-decode            ( eblock# hashname$ [ hash$ ] err? )
   " Malformed hash string" ?nand-abort  ( eblock# hashname$ hash$ )

   verify-hash                           ( eblock# okay? )
   swap .d  if  (cr  else  cr  then
;

previous definitions

: $fs-verify  ( file$ -- )
   load-crypto  abort" Can't load hash routines"  ( file$ )

   false to secure-fsupdate?                      ( file$ )
   r/o open-file  abort" Can't open file"         ( fd )

   file @                                         ( fd fd' )
   over file !  linefeed line-delimiter c!        ( fd fd' )
   file !                                         ( fd )

   t-hms(
   also fs-verify-commands
   ['] include-file catch  ?dup  if               ( x error )
      nip .error
   then
   previous
   show-done
   close-nand-ihs
   )t-hms
;

: fs-verify  ( "devspec" -- )
   safe-parse-word $fs-verify
;

[then]

\ dev screen  d# 5000 to burnin-time  dend
\ dev /audio  patch 0 -3 mic-test  dend

\ visible
\ test-all
\ fs-verify u:\os30.zsp
