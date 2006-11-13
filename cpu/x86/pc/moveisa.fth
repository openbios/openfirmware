\ See license at end of file
purpose: Set the ISA node's PCI configuration address

\ Find the ISA bridge and set the isa node's reg property to the
\ PCI device number of the actual hardware
: move-isa  ( -- )
   d# 32  0  do
      \ Look for a PCI header with the ISA bus class code
      i h# 800 *  8 +  config-l@  8 rshift  h# 60100  =  if
         \ Patch the "reg" property in the ISA node to that config address
         " /pci/isa" find-package  if
            " reg" rot get-package-property  0=  if  ( adr len )
               drop  i h# 800 *  swap be-l!
            then
         then
         leave
      then
   loop
;
stand-init:
   move-isa
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
