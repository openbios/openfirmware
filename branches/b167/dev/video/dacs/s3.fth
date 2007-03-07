\ See license at end of file
purpose: Initialize S3 RAMDAC

hex 
headerless

\ Init code for S3 RAMDAC. This DAC has indexed registers that
\ are accessed by setting RS2 high and writing to the windex and 
\ palette adressess. 

\ : s3-dac-setup 55 crt@ 1 or 55 crt! ;	\ set cr[55]:0 to 1 for indexed writes
\ : s3-dac-close 55 crt@ fe and 55 crt! ;	\ set cr[55]:0 to 0 

: init-s3-dac  ( -- )			\ Setup S3 DAC
\   s3-dac-setup
\   2 windex! 2a plt! 43 plt!
\   3 windex! 77 plt! 4a plt!
\   4 windex! 79 plt! 49 plt!
\   5 windex! 62 plt! 46 plt!
\   6 windex! 6b plt! 2a plt!
\   7 windex! 52 plt! 26 plt!
\   a windex! 63 plt! 44 plt!
\   e windex! 0 plt!
\   s3-dac-close

   2 4 rs! 2a plt! 43 plt!
   3 4 rs! 77 plt! 4a plt!
   4 4 rs! 79 plt! 49 plt!
   5 4 rs! 62 plt! 46 plt!
   6 4 rs! 6b plt! 2a plt!
   7 4 rs! 52 plt! 26 plt!
   a 4 rs! 63 plt! 44 plt!
   e 4 rs! 0 plt!

   0 2 rs!			\ Reset address latches

   ff rmr!
   true to 6-bit-primaries?		\ the LUT in this beastie only has 6bpp
;

: use-s3-dac  ( -- )
   ['] init-s3-dac to init-dac
;
\ LICENSE_BEGIN
\ Copyright (c) 2006 FirmWorks
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
