purpose: PCI physical address mapping to root node
\ See license at end of file

headerless
: map-pci-phys  ( paddr io? phys.hi size -- vaddr )
   >r  drop                    ( paddr io? R: size )
   chrp?  if                   ( paddr io? R: size )
      if  h# fe00.0000  else   ( paddr R: size )
         \ PCI addresses below 2G are really for ISA memory space, and
         \ must be translated up to the "peripheral memory alias" space
         \ so as not to look like system memory addresses.
         dup h# 8000.0000 u<  if  h# fd00.0000  else  h# 0000.0000  then
      then
   else
      if  h# 8000.0000  else  h# c000.0000  then
   then
   or  r>  " map-in" $call-parent
;
: >pci-devaddr  ( root-devaddr -- pci-devaddr )
   chrp?  0=  if  h# 8000.0000  +  then
;
: pci-devaddr>  ( pci-devaddr -- root-devaddr )
   chrp?  0=  if  h# 8000.0000  -  then
;
headers

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

