\ Write blocks to a file
[ifndef] fs-save
vocabulary fs-save-commands
also fs-save-commands definitions

0 value data-buffer

h# ff 0 0 rgb>565 constant saved-color          \ red

: (fs-save-chunk)  ( #bytes -- )
   data-buffer over " read" $call-nand          ( #bytes #read )
   over <> " Read failure" ?nand-abort          ( #bytes )
   data-buffer swap filefd fputs                ( )
;

: (fs-save)  ( -- )
   load-base to data-buffer
   " size" $call-nand /nand-block um/mod        ( #left-over-bytes #blocks )
   dup show-init
   0 do
      /nand-block (fs-save-chunk)               ( #left-over-bytes )
      i dup show-eblock# saved-color show-state ( #left-over-bytes )
   loop                                         ( #left-over-bytes )
   ?dup if                                      ( #left-over-bytes )
      (fs-save-chunk)                           ( )
   then                                         ( )
;

previous definitions

: $fs-save  ( file$ -- )
   open-nand                           ( file$ )
   r/w open-file                       ( fd error? )
   " Can't open file"  ?nand-abort     ( fd )
   to filefd                           ( )
   t-hms(
   [ also fs-save-commands ]
   ['] (fs-save) catch                 ( 0 | x error# )
   [ previous ]
   show-done
   close-nand-ihs
   )t-hms
   throw                               ( )
;

: fs-save  ( "fs.img" -- )  \ write blocks to a file
   safe-parse-word $fs-save
;

[then]
