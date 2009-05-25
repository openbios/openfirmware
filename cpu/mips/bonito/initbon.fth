purpose: Initialize Bonito for startup
copyright: Copyright 2001Firmworks  All Rights Reserved

transient
: bonito!  ( data bonito-adr -- )
   " t0 set" evaluate
   " t1 set" evaluate
   " t1 t0 0 sw" evaluate
;
: bonito-clrbits  ( bits bonito-adr -- )
   " t0 set" evaluate
   " t0 0 t2 lw" evaluate
   invert " t1 set" evaluate
   " t1 t2 t1 and" evaluate
   " t1 t0 0 sw" evaluate
;
: bonito-setbits  ( bits bonito-adr -- )
   " t0 set" evaluate
   " t0 0 t2 lw" evaluate
   " t1 set" evaluate
   " t1 t2 t1 or" evaluate
   " t1 t0 0 sw" evaluate
;
: delay-ms  ( ms -- )
   d# 100.0000 * d# 830 + d# 1660 / " t0 set" evaluate
   " begin  t0 0 = until  t0 -1 t0 addi" evaluate
;
resident

label init-bonito  ( -- )   \ Destroys: t0, t1 and t2
   \ Bonito configuration registers
\   h# 4020 bonponcfg bonito-clrbits  \ little endian, enable cfg
   h# 4000 bonponcfg bonito-clrbits  \ little endian
   h# 4040 bongencfg bonito-clrbits  \ byte swap
   h# 0410 bonponcfg bonito-setbits  \ ROMCS0, arbiter

   \ Bonito PCI configuration registers
   h# 0600.0000 bonito-cfg-pa h# 08 + bonito!  \ class
   h# f900.0000 bonito-cfg-pa h# 04 + bonito!  \ clear status
   h# 0000.0000 bonito-cfg-pa h# 0c + bonito!  \ latency timer
   h# 0000.0000 bonito-cfg-pa h# 10 + bonito!  \ pcibase0
   h# 0000.0000 bonito-cfg-pa h# 14 + bonito!  \ pcibase1
   h# 0000.0000 bonito-cfg-pa h# 18 + bonito!  \ pcibase2
   h# 0000.0000 bonito-cfg-pa h# 30 + bonito!  \ pciexprbase
   h# 0000.0000 bonito-cfg-pa h# 3c + bonito!  \ pciint
   h# 0000.0047 bonito-cfg-pa h# 04 + bonito-setbits  \ enable mem and I/O

   \ Bonito configuration registers
   h# 9302 bongencfg bonito-setbits  \ I/O buffer
   h# 0001 bongencfg bonito-clrbits  \ disable debug

   \ Reset PCI bus
   h# 0000.0020 gpiodata bonito!  \ pio_pcireset
   h# ffff.ffcf gpioie   bonito!  \ pio_ie
   1 delay-ms
   h# 0000.0020 gpiodata bonito-clrbits
   d# 50 delay-ms

   \ Other Bonito registers
   h# 16e0 iodevcfg bonito-setbits  \ cs

   ra jr  nop
end-code

