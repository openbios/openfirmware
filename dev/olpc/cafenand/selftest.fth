\ See license at end of file
purpose: Selftest for NAND FLASH section of the OLPC CaFe chip

instance variable rn            \ Random number

: random  ( -- n )
   rn @  d# 1103515245 *  d# 12345 +   h# 7FFFFFFF and  dup rn !
;

0 value cur-eblock                      \ Eblock # under scrutiny
0 value prev-eblock                     \ Last bad eblock #
0 value #fixbbt                         \ Counter of bad eblocks found
false value fixbbt?                     \ Flag to determine whether to mark bad eblocks
false value selftest-err?               \ Selftest result

: /oobbuf  ( -- n )  /oob pages/eblock *  ;

: #fixbbt++  ( -- )  #fixbbt 1+ to #fixbbt  ;
: .#fixbbt  ( -- )
   (cr
   #fixbbt ?dup  if  .d  else  ." No "  then
   ." new bad blocks "
   fixbbt?  if  ." marked"  else  ." found"  then  cr
;
: record-err  ( error? -- )
   noop
   if
      true to selftest-err?
      prev-eblock cur-eblock <>  if
         ." Bad block" cur-eblock .page-byte cr
         cur-eblock to prev-eblock
         #fixbbt++
         fixbbt?  if  cur-eblock mark-bad  then
      then
   then  
;

0 value oobbuf                          \ Original content of OOB
0 value sbuf                            \ Original content of block
0 value obuf                            \ Block data written
0 value ibuf                            \ Block data read
: alloc-test-bufs  ( -- )
   sbuf 0=  if
      /oobbuf    alloc-mem to oobbuf
      erase-size alloc-mem to sbuf
      erase-size alloc-mem to obuf
      erase-size alloc-mem to ibuf
   then
;
: free-test-bufs  ( -- )
   sbuf  if
      oobbuf /oobbuf  free-mem  0 to oobbuf
      sbuf erase-size free-mem  0 to sbuf
      obuf erase-size free-mem  0 to obuf
      ibuf erase-size free-mem  0 to ibuf
   then
;
: read-eblock  ( adr page# -- error? )
   pages/eblock read-blocks pages/eblock <>
   dup  if  ." SAVE" cr  then
;
: write-eblock  ( adr page# -- error? )
   dup (erase-block)  if  2drop true exit  then   ( adr page# )
   over /eblock erased?  if   ( adr page# )
      2drop false
   else                       ( adr page# )
      pages/eblock write-blocks pages/eblock <>
      dup  if  ." RESTORE" cr  then
   then
;

: read-raw-eblock  ( adr page# -- error? )
   pages/eblock bounds  ?do    ( adr )
      dup /dma-buf i 0 dma-write-raw  if   ( adr )
         drop true unloop exit
      then
      /dma-buf +
   loop                        ( adr )
   drop false
;

: save-eblock  ( page# -- error? )
   sbuf over read-eblock dup record-err  if   ( page# )
      drop true exit
   then                                       ( page# )
   oobbuf swap                                ( adr page# )
   pages/eblock bounds  ?do                   ( adr )
      dup /oob i /page pio-read               ( adr )
      /oob +                                  ( adr' )
   loop                                       ( adr )
   drop false
;
: berased?  ( adr len -- flag )
   bounds  ?do
      i c@ h# ff <>  if  false unloop exit  then
   loop
   true
;
: restore-eblock  ( page# -- )
   sbuf over write-eblock  dup record-err  if  ( page# )
      drop exit                                ( page# )
   then                                        ( page# )

   oobbuf /ecc +   swap                        ( adr page# )
   pages/eblock bounds  ?do                    ( adr )
      dup  /oob /ecc -  berased?  0=  if       ( adr )
         dup  /oob /ecc -  i  /page /ecc +     ( adr  adr len page# offset )
         pio-write-raw record-err              ( adr )
      then                                     ( adr )
      /oob +                                   ( adr' )
   loop                                        ( adr )
   drop                                        ( )
;



: write-raw-eblock  ( adr page# -- error? )
   dup (erase-block)  if  2drop true exit  then  ( adr page# )
   pages/eblock bounds  ?do    ( adr )
      dup /dma-buf i 0 dma-write-raw  if   ( adr )
         drop true unloop exit
      then
      /dma-buf +
   loop                        ( adr )
   drop false
;
: test-eblock  ( page# pattern -- error? )
   obuf erase-size 2 pick      fill
   ibuf erase-size rot invert  fill
   obuf over write-eblock  if  ." WRITE " obuf c@ . cr  drop true exit  then
   ibuf swap read-eblock   if  ." READ " obuf c@ . cr true exit  then
   ibuf obuf erase-size comp  dup if  ." COMP " obuf c@ . cr  then
;

\ Destroy content of flash.  No argument.
: erase!  ( subarg$ -- )  2drop  ." Erasing..." cr  wipe  ;

\ Destroy content of flash.  Argument is hex byte pattern value.
: .skip-bad  ( page# -- )  (cr ." Skip bad block" .page-byte cr  ;
: pfill  ( subarg$ -- )
   $number  if  0  else  0 max h# ff min  then
   ." Fill nandflash with h# " dup u. cr

   usable-page-limit 0  ?do
      i block-bad?  if
         i .skip-bad
      else
         i to cur-eblock
         (cr i . i over test-eblock  record-err
      then
   pages/eblock +loop  drop

   .#fixbbt
;

\ Non-destructive.  Argument is number of blocks to test.
: random-page  ( -- n )  random total-pages 1- and  usable-page-limit min  ;
: fast  ( subarg$ -- )
   $number  if  d# 10  else  0 max  usable-page-limit pages/eblock / min  then
   ." Fill " dup .d  ." random blocks with h# 55, h# aa and h# ff" cr

   0  ?do
      i case
         0 of  0                      endof
         1 of  usable-page-limit 1-   endof
         ( default )  random-page swap
      endcase                         ( page# )
      pages/eblock 1- invert and      ( page#' )

      dup block-bad?  if              ( page#' )
         drop                         ( )
      else                            ( page#' )
         dup to cur-eblock            ( page#' )
         (cr dup .                    ( page#' )
         dup save-eblock  if          ( page# )
            drop                      ( )
         else                                   ( page# )
            dup h# 55 test-eblock  record-err   ( page# )
            dup h# aa test-eblock  record-err   ( page# )
            dup h# ff test-eblock  record-err   ( page# )
            restore-eblock                      ( )
         then                         ( )
      then
   loop

   .#fixbbt
;

\ Non-destructive.  Argument is <#blk>,<blk#>
\ <#blk>+1 is number of blocks as a test unit
\ If <#blk> is absent, all blocks are tested.
\ <blk#> is the block to test in the test unit, in range of 0..<#blk>
\ If <blk#> is absent, 0 is assumed.
\ For example: test /nandflash::full      test all blocks
\              test /nandflash::full,1,0  test even blocks
\              test /nandflash::full,1,1  test odd blocks
\              test /nandflash::full,2,<0-2>   test 33%
\              test /nandflash::full,3,<0-3>   test 25%
\              test /nandflash::full,4,<0-4>   test 20%
\              test /nandflash::full,9,<0-9>   test 10%
: parse-full-args  ( subarg$ -- #blk blk# )
   ?dup 0=  if  drop 0 0  exit  then
   ascii , left-parse-string          ( blk#$ #blk$ )
   $number  if  2drop 0 0 exit  then  ( blk#$ #blk )
   0 max usable-page-limit pages/eblock 1- / min
   -rot $number  if  0  else  0 max over min  then  ( #blk blk# )
;
: .full-arg  ( #blk blk# -- )
   ." Test " 
   over 0=  if  2drop ." every block" cr exit  then
   ." block " u. ." every " 1+ u. ." blocks" cr
;
: full  ( subarg$ -- )
   parse-full-args                       ( #blk blk# )
   2dup .full-arg                        ( #blk blk# )

   pages/eblock *  swap 1+ pages/eblock *    ( page# stride )
   usable-page-limit rot  ?do                ( stride )
      i block-bad? 0=  if                    ( stride )
         i to cur-eblock                     ( stride )
         (cr i .                             ( stride )
         i save-eblock  0=  if               ( stride )
            i h# 55 test-eblock  record-err  ( stride )
            i h# aa test-eblock  record-err  ( stride )
            i restore-eblock                 ( stride )
         then                                ( stride )
      then                                   ( stride )
   dup +loop  drop                           ( )

   .#fixbbt
;

\ Non-destructive.  Same as full.  Except failed eblocks are marked as bad.
: fixbbt  ( subarg$ -- )
   true to fixbbt?
   full
   #fixbbt  if  save-bbt  then
   false to selftest-err?  \ Don't say "failed" if asked to fix the table
;

: none  ( subarg$ -- )  2drop exit  ;

: help  ( subarg$ -- )
   2drop
   ." Usage:" cr
   ."   test /nandflash[::<arg>[;<arg>[;<arg>...]]]" cr
   cr
   ." If no <arg> is present, the fast test is performed." cr
   cr
   ." <arg> can be one of the following:" cr
   ."   none           to do nothing" cr
   ."   help           to get this usage guide" cr
   ."   erase!         to erase the flash (destructive)" cr
   ."   pfill[,<data>] to fill the flash with hex byte pattern <data> (destructive)" cr
   ."                  Default <data> is 00" cr
   ."   fast[,<#blk>]  to non-destructively test the specified <#blk> of flash" cr
   ."                  Default <#blk> is decimal 10" cr
   ."   full[,<#blk>[,<blk#>]]" cr
   ."                  to non-destructively test the specified <blk#> every" cr
   ."                  <#blk>+1 number of blocks" cr
   ."                  Default <#blk> and <blk#> are 0" cr
   ."                  E.g., full,1,0 test even blocks" cr
   ."                        full,1,1 test odd blocks" cr
   ."                        full,2,0 test 33% of the flash" cr
   ."   fixbbt[,<#blk>[,<blk#>]]" cr
   ."                  same as full; however, bad blocks found are marked as bad" cr
   cr
;

: selftest-init  ( -- )                     \ Init variables per test
   false to fixbbt?
   0 to #fixbbt
   -1 to prev-eblock
;

: parse-selftest-args  ( arg$ -- )
   begin                                    ( arg$ )
      ascii ; left-parse-string  ?dup  if   ( rem$ arg$' )
         selftest-init                      ( rem$ arg$' )
         ascii , left-parse-string          ( rem$ subarg$ method$ )
         my-self ['] $call-method catch  if ( rem$ x x x x x )
            ." Unknown argument" cr
            3drop 2drop 2drop
            true to selftest-err?
            exit
         then                               ( rem$ )
      else
         drop                               ( rem$ )
      then
   ?dup 0=  until  drop                     ( )
;
: selftest-args  ( -- arg$ )  my-args ascii : left-parse-string 2drop  ;

: (selftest)  ( -- error? )
   false to selftest-err?
   alloc-test-bufs
   selftest-args ?dup  if
      parse-selftest-args
   else
      selftest-init
      drop " " fast
   then
   free-test-bufs
   selftest-err?
;

: selftest  ( -- error? )
   open 0=  if  true exit  then
   get-msecs rn !
   ." Note: a few bad blocks is normal - these are already known:"  cr
   show-bbt cr
   (selftest)
   close
;

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
