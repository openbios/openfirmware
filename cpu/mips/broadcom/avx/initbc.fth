purpose: Initialize Broadcom BCM7030RKPB1 for startup
copyright: Copyright 2001 Firmworks  All Rights Reserved

transient
: bcl!  ( data idx -- )
   bc-reg-base + " t0 set" evaluate
   " t1 set" evaluate
   " t1 t0 0 sw" evaluate
;
: bc-cfg!  ( data idx -- )
   pci-reg-base + " t0 set" evaluate
   " t1 set" evaluate
   " t1 t0 0 sw" evaluate
;
: pci-cfg!  ( data adr -- )
   pci-cf8 " t0 set" evaluate
   ( adr ) h# 8000.0000 or " t1 set  t1 t0 0 sw" evaluate
   pci-cfc " t0 set" evaluate
   ( data ) " t1 set  t1 t0 0 sw" evaluate
;
: pci-cfg@  ( adr -- t1: data )
   pci-cf8 " t0 set" evaluate
   ( adr ) h# 8000.0000 or " t1 set  t1 t0 0 sw" evaluate
   pci-cfc " t0 set" evaluate
   " t0 0 t1 lw" evaluate
;
: delay-ms  ( ms -- )
   d# 100.0000 * d# 830 + d# 1660 / " t0 set" evaluate
   " begin  t0 0 = until  t0 -1 t0 addi" evaluate
;

resident

label init-broadcom  ( -- )   \ Destroys: t0 and t1
   pci-reg-base t0 set		\ Enable Broadcom PCI memory and I/O
   t0 0 t1 lw
   t0 4 t1 lw
   t1 7 t1 ori
   t1 t0 4 sw

[ifdef] for-bcm93730
   h# f800.e000 h# 200 bcl!	\ ROM address range
   h# c000.8000 h# 204 bcl!	\ Flash address range
   h# 0400.0000 h# 208 bcl!	\ HPNA address range
   h# 0800.0400 h# 20c bcl!	\ VOIP address range
   h# 0c00.0800 h# 210 bcl!	\ 1394 address range
   h# 1000.0c00 h# 214 bcl!	\ POD address range
   h# 1560.1163 h# 230 bcl!	\ 68K bus I/O termination

   \ Setup Broadcom PCI host bridge
   pci-reg-base t0 set		\ Enable Broadcom PCI memory and I/O
   t0 0 t1 lw
   t0 4 t1 lw
   t1 7 t1 ori
   t1 t0 4 sw
   h# 1400.0000 h# 58 bc-cfg!	\ Setup PCI MEM window BARs. Use only win 0 now.
   h# 1400.0000 h# 5c bc-cfg!
   h# 1400.0000 h# 60 bc-cfg!
   h# 1400.0000 h# 64 bc-cfg!
   h# 1300.0000 h# 68 bc-cfg!	\ Setup PCI IO window BAR. Use only win 0 now.
   h# 0000.0000 h# 10 bc-cfg!	\ Setup PCI SDRAM win 0.
   h# 0000.0006 h# 50 bc-cfg!	\ Setup SDRAM win0 size to 64MB
   h# 0000.0000 h# 74 bc-cfg!	\ Setup SDRAM endianness
   h# bfa0.0000 t0 set
   $0 t0 0 sb

   \ Setup BCM93730 PCI devices
   0 pci-cfg@
   h# 1501.0000 h# 10 pci-cfg!	\ BCM4413
   h# 0000.0006 h# 04 pci-cfg!

   h# 1501.1000 h# 110 pci-cfg!	\ BCM4423 CODEC
   h# 0000.0006 h# 104 pci-cfg!

   h# 1501.2000 h# 210 pci-cfg!	\ BCM4413 ENET
   h# 0000.0006 h# 204 pci-cfg!

   h# 1500.0000 h# 810 pci-cfg!	\ BCM3250
   h# 1400.0000 h# 814 pci-cfg!
   h# 0000.0002 h# 804 pci-cfg!

   \ Setup BCM3250
   h# b500.0000 t0 set
   h# f8 t1 set   t1 t0 h# c6 sb
   h# 05 t1 set   t1 t0 h# ce sb
   t0 h# 43 t1 lbu  t1 h# 1f t1 ori  t1 t0 h# 43 sb
   t0 h# f7 t1 lbu  t1 h# 9f t1 ori  t1 t0 h# f7 sb
   $0 t0 h# 50 sh

   h# 27 t1 set   t1 t0 h# 791 sb	\ LED
   h# 10 t1 set   t1 t0 h# 790 sb
   h# 01 t1 set   t1 t0 h# 797 sb
   h# 04 t1 set   t1 t0 h# 796 sb
   h# 20 t1 set   t1 t0 h# 799 sb
   h# b0 t1 set   t1 t0 h# 794 sb	\ 3730
   h# f8 t1 set   t1 t0 h# 795 sb
   h# b0 t1 set   t1 t0 h# 79a sb
   h# c0 t1 set   t1 t0 h# 79b sb
   $0 t0 h# 798 sb
   $0 t0 h# 79e sb

   h# 17 t1 set   t1 t0 h# 7b0 sb	\ UART
   h# 00 t1 set   t1 t0 h# 7b7 sb
   h# af t1 set   t1 t0 h# 7b6 sb
   h# 17 t1 set   t1 t0 h# 7c0 sb	\ UART
   h# 00 t1 set   t1 t0 h# 7c7 sb
   h# af t1 set   t1 t0 h# 7c6 sb

   1 delay-ms
   d# 12 t0 mfc0 nop nop
   h# 3400.0000 t1 set
   t0 t1 t0 or
   d# 12 t0 mtc0
   1 delay-ms
   h# bfa0.0000 t0 set
   1 t1 set   t1 t0 0 sb
   1 delay-ms
   h# bfa0.0000 t0 set
   2 t1 set   t1 t0 0 sb
   1 delay-ms
   h# bfa0.0000 t0 set
   4 t1 set   t1 t0 0 sb
   1 delay-ms

   h# b500.0000 t0 set
   h# 89 t1 set   t1 t0 h# 794 sb	\ HELP
   h# 86 t1 set   t1 t0 h# 795 sb
   h# c7 t1 set   t1 t0 h# 79a sb
   h# 8c t1 set   t1 t0 h# 79b sb
[else]
   h# f800.e000 h# 200 bcl!	\ ROM address range
   h# 0007.0004 h# 204 bcl!	\ ATMEL uP address range
   h# 000b.0008 h# 208 bcl!	\ COM ports address range
   h# 000c.000c h# 20c bcl!	\ LED address range
   h# 2aa3.3333 h# 230 bcl!	\ 68K bus I/O termination
[then]
   ra jr  nop
end-code

