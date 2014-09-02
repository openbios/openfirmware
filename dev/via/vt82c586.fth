purpose: Device nodes for VIA Technologies PCI-to-ISA bridge chip
\ See license at end of file

" VIA,82C586" encode-string  " model"  property
" pci1106,586" encode-string
" pnpPNP,a00"  encode-string encode+
" compatible"  property

fload ${BP}/dev/pci/isa.fth

fload ${BP}/dev/pci/isamisc.fth

\ Amend various device nodes
my-self  0 to my-self   \ Force the properties to be created in the child nodes

" dma-controller" find-device
   " pci1106,586-dma-controller" +compatible
   " chrp,dma" +compatible
   " VIA,82C586" model
pop-device

" interrupt-controller" find-device
   " pci8086,484-interrupt-controller" +compatible
   " pci10ad,105-interrupt-controller" +compatible
   " chrp,iic" +compatible
   " WINB,83C553" model
pop-device

" timer" find-device
   " pci10ad,105-timer" +compatible
   " WINB,83C553" model
pop-device

to my-self
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
