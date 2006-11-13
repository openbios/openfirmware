\ See license at end of file
purpose: File I/O interface using Open Firmware

headerless
\ Closes an open file, freeing its descriptor for reuse.

: _ofclose  ( file# -- )
   bfbase @  bflimit @ over -  free-mem   \ Hack!  Hack!
   close-dev
;

\ Writes "count" bytes from the buffer at address "adr" to a file.
\ Returns the number of bytes actually written.

: _ofwrite  ( adr #bytes file# -- #written )  " write" rot $call-method  ;

\ Reads at most "count" bytes into the buffer at address "adr" from a file.
\ Returns the number of bytes actually read.

: _ofread  ( adr #bytes file# -- #read )  " read" rot $call-method  ;

\ Positions to byte number "l.byte#" in a file

: _ofseek  ( d.byte# file# -- )  " seek" rot $call-method  drop  ;

\ Returns the current size "l.size" of a file

: _ofsize  ( file# -- d.size )  " size" rot $call-method  ;

\ Prepares a file for later access.  Name is the pathname of the file
\ and mode is the mode (0 read, 1 write, 2 modify).  If the operation
\ succeeds, returns the addresses of routines to perform I/O on the
\ open file and true.  If the operation fails, returns false.

: _ofopen
   ( name mode -- [ fid mode sizeop alignop closeop writeop readop ] okay? )
   >r count open-dev
   dup 0=  if  r> 2drop  false exit  then   ( fid )
   r@   ['] _ofsize   ['] _dfalign   ['] _ofclose   ['] _ofseek
   r@ r/o  =  if  ['] nullwrite  else  ['] _ofwrite  then
   r> w/o  =  if  ['] nullread   else  ['] _ofread   then
   true
;

headers

: stand-init  ( -- )  stand-init  ['] _ofopen to do-fopen  ;
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
