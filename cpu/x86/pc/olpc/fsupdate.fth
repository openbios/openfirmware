purpose: Secure NAND updater

\ Depends on words from security.fth and copynand.fth

: get-hex#  ( -- n )
   safe-parse-word
   push-hex
   $number  " Bad number" ?nand-abort
   pop-base
;

\ XXX implement this
: map-eblock# ( block# -- block#' )  ;


vocabulary nand-commands
also nand-commands definitions

: data:  ( "filename" -- )
   safe-parse-word fn-buf place
   bundle-name$ image-name-buf place
   open-img
;

: erase-all  ( -- )
   #nand-pages >eblock#  show-erasing
   ['] show-bad  ['] show-erased  ['] show-bbt-block " (wipe)" $call-nand
   #image-eblocks show-writing
;

: eblock: ( "eblock#" "hashname" "hash-of-128KiB" -- )
   get-hex#                                    ( eblock# )
   read-image-block
   load-base /nand-block    safe-parse-word    ( eblock# data$ hashname$ )
   hash                                        ( eblock# result$ )
   safe-parse-word hex-decode  " Malformed hash string" ?nand-abort
   $=  if                                      ( eblock# )
      drop 
   else                                        ( eblock# )
      ." Bad hash for eblock# " .x cr
      abort
   then                                        ( )

   load-base " copy-block" $call-nand          ( page# error? )
   " Error writing to NAND FLASH" ?nand-abort  ( page# )
   >eblock# show-written                       ( )
;

: bytes:  ( "eblock#" "page#" "offset" "length" "data" -- )
   get-hex#  get-hex#  2>r                 ( r: eblock# page# )
   get-hex#  get-hex#                      ( offset length r: eblock# page# )
   2dup +  h# 840 >= abort" Offset + length exceeds page + OOB size"
   safe-parse-word hex-decode              ( offset length data$ )
   rot over <> abort" Length mismatch"     ( offset data$ )
   r> r> map-eblock# nand-pages/block * +  ( offset data$ page#')
   -rot 2swap swap                         ( data$ page# offset )
   " pio-write-raw" $call-nand abort" NAND write error"
;

: cleanmarkers  ( -- )
   show-cleaning
   ['] show-clean " put-cleanmarkers" $call-nand
;   

: mark-pending:  ( "eblock#" -- )
   get-hex# map-eblock# nand-pages/block *   ( page# )
   " COMP" rot h# 838 
   " pio-write-raw" $call-nand abort" NAND write error"
;

: mark-complete:  ( "eblock#" -- )
   get-hex# map-eblock# nand-pages/block *
   " LETE" rot h# 83c
   " pio-write-raw" $call-nand abort" NAND write error"
;

previous definitions

: do-fs-update  ( img$ -- )
   tuck  load-base h# 100000 +  swap move  ( len )
   load-base h# 100000 + swap
   open-nand
   ['] noop to show-progress
   #nand-pages >eblock#  show-init

\    clear-context  nand-commands
also nand-commands
   
   ['] include-buffer  catch  if  nip nip  .error  security-failure  then

previous
\    only forth also definitions

   show-done
   close-nand-ihs
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
            exit
         then                         ( rem$ )
         show-lock                    ( rem$ )
      then                            ( rem$ )
   repeat                             ( rem$ )
   2drop
;
: try-fs-update  ( -- )
   ." Searching for a NAND file system update image." cr
   all-devices$ fs-update-from-list
;
