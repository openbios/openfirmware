\ See license at end of file
purpose: Selftest for NAND FLASH section of the OLPC CaFe chip

0 value test-block#
0 value sbuf				\ Original content of block
0 value obuf				\ Block data written
0 value ibuf				\ Block data read
: test-page#  ( -- n )  test-block# pages/eblock *  ;
: alloc-test-bufs  ( -- )
   sbuf 0=  if
      erase-size alloc-mem to sbuf
      erase-size alloc-mem to obuf
      erase-size alloc-mem to ibuf
   then
;
: free-test-bufs  ( -- )
   sbuf  if
      sbuf erase-size free-mem  0 to sbuf
      obuf erase-size free-mem  0 to obuf
      ibuf erase-size free-mem  0 to ibuf
   then
;
: determine-test-block#  ( -- error? )
   -1 to test-block#
   size erase-size um/mod nip 1-	( block# )
   begin  dup 0> test-block# -1 = and   while
      dup pages/eblock * block-bad? not  if  dup to test-block#  then
      1-				( block#' )
   repeat  drop
   test-block# -1 =
;
: read-eblock  ( adr -- error? )
   test-page# pages/eblock read-blocks pages/eblock <>
;
: write-eblock  ( adr -- error? )
   test-page# erase-block
   test-page# pages/eblock write-blocks pages/eblock <>
;
: test-eblock  ( pattern -- error? )
   obuf erase-size 2 pick     fill  obuf write-eblock  if  true exit  then
   ibuf erase-size rot invert fill  ibuf read-eblock   if  true exit  then
   ibuf obuf erase-size comp
;
: write-test  ( -- error? )
   determine-test-block#  if  true exit  then
   alloc-test-bufs
   sbuf read-eblock   if  free-test-bufs true exit  then
   h# 5a test-eblock  if  free-test-bufs true exit  then
   h# a5 test-eblock  if  free-test-bufs true exit  then
   sbuf write-eblock			 \ Restore original content
   free-test-bufs
;
: selftest  ( -- error? )
   open 0=  if  true exit  then
   read-id 1+ c@ h# dc <>  if  close true exit  then
   show-bbt
   write-test
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
