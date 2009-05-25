purpose: Initialize SouthBridge for startup messages
copyright: Copyright 2001 Firmworks  All Rights Reserved

h# 1000 constant sb-pci-addr
transient
: config-map  ( reg -- )
   pcimap_cfg " t0 set" evaluate
   sb-pci-addr " t1 set" evaluate
   " t1 t0 0 sw" evaluate
   ( reg )   pci-cfg-pa + " t0 set" evaluate
;
: config-l!  ( value reg -- )
   config-map
   ( value ) " t1 set" evaluate
   " t1 t0 0 sw" evaluate
;
: config-w!  ( value reg -- )
   config-map
   ( value ) " t1 set" evaluate
   " t1 t0 0 sh" evaluate
;
: config-b!  ( value reg -- )
   config-map
   ( value ) " t1 set" evaluate
   " t1 t0 0 sb" evaluate
;
: pc@  ( reg -- )	\ t0: isa-io-base
   ( reg ) " t0 swap t1 lbu" evaluate
;
: pc!  ( data reg -- )	\ t0: isa-io-base
   swap " t1 set" evaluate
   ( reg ) " t1 t0 rot sb" evaluate
;
resident

label init-southbridge  ( -- )   \ Destroys: t0 and t1
   h# fbfe.c001 h# 0b0 config-l!	\ Set ISA mode
   h# 0000.0000 h# 04e config-w!	\ Disable RTC & KBD chip selects
   h# 0000.000d h# 082 config-b!	\ Enable PCI 2.1 timing support
   h# 0000.00fe h# 069 config-b!	\ Set top of memory to 16MB
   h# 0000.0000 h# 0cb config-b!	\ Disable internal RTC

   smbus-base 1 + h# 390 config-l!	\ Set SMB base address
   h# 0000.0001 h# 3d2 config-b!	\ Enable host controller
   h# 0000.0001 h# 304 config-b!	\ Enable I/O

   isa-io-base d# 16 >> t0 lui

[ifdef] notyet
   \ Program ISA refresh counter
   h# 43 pc@		\ Don't know why pmon code read this write-only reg
   h# 74 h# 43 pc!	\ Counter 1, r/w 0-7, 8-15, mode 1, binary
   h# d6 h# 41 pc!	\ Refresh timer
   h# 00 h# 41 pc!
[then]

   ra jr  nop
end-code

