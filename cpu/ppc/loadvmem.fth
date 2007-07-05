purpose: Load file for virtual memory node
\ See license at end of file

headers
false value use-real-mode?
true value in-real-mode?
0 value /rm-tlbmiss

fload ${BP}/ofw/core/allocmor.fth	\ S Allow alloc-mem to use more memory

dev /
new-device
" mmu" device-name
fload ${BP}/ofw/core/virtlist.fth	\ Virtual memory allocator
fload ${BP}/ofw/core/maplist.fth	\ Manage translation list 
fload ${BP}/ofw/core/clntmap.fth	\ OS callbacks for address translation
\ fload ${BP}/arch/prep/memcb.fth		\ Memory allocation callback

fload ${BP}/cpu/ppc/tlb.fth
fload ${BP}/cpu/ppc/tlbmiss.fth
fload ${BP}/cpu/ppc/htabmmu.fth
fload ${BP}/cpu/ppc/batfault.fth
fload ${BP}/cpu/ppc/batmap.fth
[ifdef] exponential
fload ${BP}/cpu/ppc/exptlb.fth
[then]

: .t   translations translation-node .list  ;

fload ${BP}/cpu/ppc/testmmu.fth

' 2drop is ?splice

finish-device
device-end

: map?  ( virtual -- )  " map?" mmu-node @ $call-method  ;
: .t    ( -- )		" .t"   mmu-node @ $call-method  ;


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
