purpose: Platform-specific device aliases
\ See license at end of file

devalias net /pci/ethernet

devalias scsi  /pci/scsi
devalias disk0 /pci/ide/disk@0,0:1
devalias disk1 /pci/ide/disk@1,0:1
devalias disk3 /pci/ide/disk@3,0:1
devalias cdrom /pci/ide/disk@2,0

devalias a /fdc/disk@0:\
devalias c /pci/ide/disk@0,0:\

devalias disk  /pci/ide/disk@0,0:1

\ devalias mouse /pci/isa/8042/mouse

devalias com1 /pci/isa/serial@i3f8
devalias com2 /pci/isa/serial@i2f8

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

