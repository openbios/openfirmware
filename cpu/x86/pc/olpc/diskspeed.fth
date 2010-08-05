\ See license at end of file
purpose: Disk raw read/write speed test

\ Example:  ok .speed ext:0
\
\ The test is non-destructive unless a write failure occurs.
\ It reads first, then writes the same data back.

0 value disk-ih
0 value disk-speed-transfer
0 value disk-speed-#blocks
0 value disk-speed-/block
0 value disk-speed-total-blocks
h# 200.0000 constant disk-speed-len  \ 32 MB

: .mb/sec  ( usecs -- )
   disk-speed-len d# 20 rot */   ( 20*mb/sec )
   1+ 2/                         ( 10*mb/sec-rounded )
   push-decimal
   <# u# [char] . hold  u#s u#> type
   pop-base
   ."  MB/sec"
;
: .speed  ( "devname" -- )
   safe-parse-word  open-dev to disk-ih
   disk-ih 0=  abort" Can't open device"
   " block-size" disk-ih $call-method to disk-speed-/block

   " max-transfer" disk-ih $call-method to disk-speed-transfer
   disk-speed-transfer disk-speed-/block /  to disk-speed-#blocks
   
   disk-speed-len disk-speed-/block / to disk-speed-total-blocks

   ." Read speed: "
   t(
   disk-speed-total-blocks  0  do
      load-base i disk-speed-/block * +   ( adr )
      i  disk-speed-#blocks  " read-blocks"  disk-ih  $call-method  drop
   disk-speed-#blocks +loop      
   ))t-usecs    ( usecs )
   .mb/sec space
   
   ." Write speed: "
   t(
   disk-speed-total-blocks  0  do
      load-base i disk-speed-/block * +   ( adr )
      i  disk-speed-#blocks  " write-blocks"  disk-ih  $call-method  drop
   disk-speed-#blocks +loop      
   ))t-usecs    ( usecs )
   .mb/sec cr

   disk-ih close-dev
;

\ LICENSE_BEGIN
\ Copyright (c) 2010 FirmWorks
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
