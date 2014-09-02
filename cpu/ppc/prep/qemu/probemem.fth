purpose: Create memory node properties and lists
\ See license at end of file

" /memory" find-device

headerless

: scrub&release  ( bottom top -- )
   2dup =  if  2drop exit  then
   over -  2dup  berase
   release
;

headers

: probe  ( -- )
   0 memsize  reg       \ Put all memory in the "reg" property value
   1 encode-int  " #simm-slots" property \ 1 SIMM should be enough for everyone

   \ NT and MacOS have different ideas about the reporting of low pages
   in-little-endian?  if  h# 4000  else  h# 3000  then
   origin pagesize round-down  virt-phys -  scrub&release

   memtop @       memsize                    scrub&release
;

\ mkresid.fth needs #simm-slots and simm-size. Let's give it one SIMM
: simm-size ( simm# -- size )
   0<> if 0 exit  then
   memsize
;

device-end

also forth definitions
stand-init: Memory node
   " probe" memory-node @ $call-method
;
previous definitions


\ LICENSE_BEGIN
\ Copyright (c) 1997 FirmWorks
\ Copyright (c) 2014 Artyom Tarasenko
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

