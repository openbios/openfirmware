\ Read blocks from a file and write to internal storage
[ifndef] fs-load
vocabulary fs-load-commands
also fs-load-commands definitions

0 value data-buffer

h# ff a5 00 rgb>565 constant loaded-color        \ orange

: (fs-load-chunk)  ( #bytes -- )
   data-buffer over filefd fgets                 ( #bytes #read )
   over <> " Read failure" ?nand-abort           ( #bytes #read )
   data-buffer swap " write" $call-nand          ( #bytes )
   drop                                          ( )
;

: (fs-load)  ( -- )
   load-base to data-buffer
   " size" $call-nand /nand-block um/mod         ( #left-over-bytes #blocks )
   dup show-init
   0 do
      /nand-block (fs-load-chunk)                ( #left-over-bytes )
      i dup show-eblock# loaded-color show-state ( #left-over-bytes )
   loop                                          ( #left-over-bytes )
   ?dup if                                       ( #left-over-bytes )
      (fs-load-chunk)                            ( )
   then                                          ( )
;

previous definitions

: $fs-load  ( file$ -- )
   open-nand                           ( file$ )
   r/o open-file                       ( fd error? )
   " Can't open file"  ?nand-abort     ( fd )
   to filefd                           ( )
   t-hms(
   [ also fs-load-commands ]
   ['] (fs-load) catch                 ( 0 | x error# )
   [ previous ]
   show-done
   close-nand-ihs
   )t-hms
   throw                               ( )
;

: fs-load  ( "fs.img" -- )  \ read blocks from a file
   safe-parse-word $fs-load
;

[then]
