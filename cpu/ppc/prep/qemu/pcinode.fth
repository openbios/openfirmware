purpose: System-specific portions of PCI bus package
\ See license at end of file

dev /pci

d# 33,333,333 " clock-frequency"  integer-property

external

h#    1.c000  " bus-master-capable"          integer-property

h# 1c000 encode-int				\ Mask of implemented slots
" Slot1" encode-string encode+
" Slot2" encode-string encode+
" Slot3" encode-string encode+  " slot-names" property

: config-setup  ( config-adr -- vaddr )
   \ Bit 31 ("enable") must be 1, bits 30:24 ("reserved") must be 0,
   \ bits 1:0 must be 0.
   dup h# ff.fffc and  h# 8000.0000 or  h# cf8 pl!  ( config-adr )
   3 and  h# cfc +  \ Merge in the byte selector bits
;

: config-b@  ( config-adr -- b )  config-setup pc@ ;
: config-w@  ( config-adr -- w )  config-setup pw@  ;
: config-l@  ( config-adr -- l )  config-setup pl@ ;
: config-b!  ( b config-adr -- )  config-setup pc! ;
: config-w!  ( w config-adr -- )  config-setup pw! ;
: config-l!  ( l config-adr -- )  config-setup pl! ;


fload ${BP}/dev/pci/intmap.fth		\ Generic interrupt mapping code

device-end

" 2,3,4,5"  dup config-string pci-probe-list

\ LICENSE_BEGIN
\ Copyright (c) 1997 FirmWorks
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

