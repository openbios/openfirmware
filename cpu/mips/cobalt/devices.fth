purpose: Load file for I/O devices
\ See license at end of file

fload ${BP}/dev/flashpkg.fth

0 0  " 1c80.03f8"  " /"  begin-package	\ UART 0
  alias enable-interrupt drop
  alias disable-interrupt drop
  alias interrupt-handler@ 0
  alias interrupt-handler! drop
  fload ${BP}/dev/ns16550a.fth
  d# 18432000 to clock-frequency  \ 10 times the normal PC clock frequency!
  d# 115200 to default-baudrate
end-package


0 0  " "  " /"  begin-package	\ Access to FLASH
  " dropins" device-name

  create eprom-va  " dropins.img" $file,
  here eprom-va - constant /device
  /device constant /device-phys

  " rom" encode-string
  " compatible" property

  fload ${BP}/cpu/mips/cobalt/flashpkg.fth
end-package

\ The first sector in the ROM is a FLASH burner program
\ Define these words outside of the PCI bus node for convenience in debugging
h# b400.0000 constant io-base
: pl!  ( l offset -- )  io-base + rl!  ;
fload ${BP}/dev/pci/configm1.fth

0 0  " "  " /"  begin-package
   \ Redefine these words inside the PCI bus node so they can be accessed
   \ as device methods
   alias config-l@ config-l@  alias config-l! config-l!
   alias config-w@ config-w@  alias config-w! config-w!
   alias config-b@ config-b@  alias config-b! config-b!

   fload ${BP}/cpu/mips/cobalt/mappci.fth	\ Map PCI to root
   fload ${BP}/dev/pcibus.fth		\ Generic PCI bus package

   fload ${BP}/cpu/mips/cobalt/pciinit.fth

end-package
stand-init: PCI host bridge
   " /pci" " init" execute-device-method drop
;

fload ${BP}/dev/pciprobe.fth		\ PCI probing
fload ${BP}/dev/scsi/probscsi.fth	\ SCSI probing

0 0  " "  " /"  begin-package
   " clock" device-name
   : open true ;
   : close ;
   : get-time  ( -- s m h d m y )  0 0  d# 12  d# 27 d# 11  d# 2001  ;
end-package
stand-init: Clock node
   " /clock" open-dev clock-node !
;

\ LICENSE_BEGIN
\ Copyright (c) 2009 FirmWorks
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
