\ See license at end of file
purpose: File-based "NVRAM" driver package

dev /
new-device

" file-nvram" device-name

h# 1000 constant /nvram

0 instance value nvram-fd
0 instance value nvram-ptr

headerless

: def-name  ( -- filename$ )  " nvram.dat"  ;
defer nv-file  ' def-name to nv-file

: nv-create-file  ( adr len -- flag )
   ['] $create-file catch  if
      2drop false
   else
      close-dev  true
   then
;

: nvopen  ( -- flag )
   nv-file 2dup $file-exists? if  
      r/w open-file if
	 drop false  
      else 
	 to nvram-fd  true 
      then 
   else		\ otherwise make the file
      nv-create-file  if
         nv-file r/w open-file if
            drop false
         else
	    to nvram-fd
            /nvram alloc-mem dup
            /nvram erase   dup /nvram nvram-fd fputs
            /nvram free-mem
	    0 nvram-fd fseek
	    true
         then
      else
         false
      then
   then
;
: update-ptr  ( len' -- len' )  dup nvram-ptr +  to nvram-ptr  ;
: clip-size  ( adr len -- adr len' )	\ data buffer
   nvram-ptr +   /nvram min  nvram-ptr -     ( adr len' )
;

headers

: open  ( -- flag )   true  ;
: close  ( -- )  ;
: seek  ( d.offset -- status )
   0<>  over /nvram u>  or  if
      drop  0 to nvram-ptr  true exit	\ Seek offset too large
   then
   to nvram-ptr   false
;
: read  ( adr len -- actual )
   nvopen if
      clip-size
      nvram-ptr nvram-fd fseek
      nvram-fd fgets
      nvram-fd fclose
      update-ptr
   else
      2drop 0
   then
;
: write  ( adr len -- actual )
   nvopen if
      clip-size
      nvram-ptr nvram-fd fseek
      tuck nvram-fd fputs
      nvram-fd fclose
      update-ptr
   else
      2drop 0
   then
;
: size  ( -- d )  /nvram 0  ;
: nvram@  ( offset -- n )
   0 seek drop   here 1 read if  here c@  else  0  then 
;
: nvram!  ( n offset -- )
   0 seek drop   here c!   here 1 write drop
;

finish-device
device-end

: nvr@   ( offset -- n )   " nvram@" nvram-node $call-method  ;
: nvr!   ( n offset -- )   " nvram!" nvram-node $call-method  ;
' nvr@ to nv-c@
' nvr! to nv-c!
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
