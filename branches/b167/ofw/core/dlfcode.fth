\ See license at end of file
purpose:  Download fcode and binary image files over a serial line.


\  Read in a block of bytes.
: getfcbytes  ( adr len -- adr+len )
   over + tuck swap ?do  diag-key i c!  loop
;

\ Throw out junk until we see the start of the header, but return that byte.
: fcconsume  ( -- found )
   0  begin  drop  diag-key  dup h# f0 h# f4 between over h# fd = or   until
;


struct
1 field >fc.start
1 field >fc.format
2 field >fc.check
4 field >fc.length
constant /fcode-header

: dlfcode  ( -- )
   ." Ready for download.  Send fcode file." cr
   fcconsume  load-base c!
   \ Read the header block.
   load-base 1+  /fcode-header 1-  getfcbytes drop
   \ Now read the rest of the fcode.
   load-base dup dup  >fc.length be-l@ /fcode-header -  getfcbytes
   swap - !load-size

   \  The user does the following line to execute the fcode.
   \  load-base 1 byte-load
;


[ifndef] dlbin                 \  If dlbin is already defined, skip this. 

: timed-diag-key  ( #ms -- true | data false )
   0  do
      diag-key?  if  unloop diag-key false exit  then
      1 ms
   loop
   true
;

: dlbin  ( -- )
   ." Ready for download.  Send file." cr
   \ Wait 20 seconds for the first byte.
   d# 20.000 timed-diag-key  if
      ." Timed out, no data." cr exit
   else
      load-base c!			\ Store the first byte.
      load-base dup 1+ h# 200000 bounds  do
         i d# 5000 timed-diag-key  if
	    \ Timed out after 5 seconds.
	    swap - leave
	 then  swap c!			\ Store each succeeding byte.
      loop
   then
   dup !load-size  .d ." bytes" cr
   " init-program" $find  if  execute  else  loaded sync-cache  then
;

[then]
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
