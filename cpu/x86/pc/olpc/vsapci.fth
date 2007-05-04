\ See license at end of file
purpose: Simulates PCI configuration headers for Geode on-chip devices

\ This modifies OFW's PCI configuration access routines so that some Geode
\ on-chip devices appear to have PCI configuration headers, although they
\ don't really have hardware implementing same.  This makes it possible
\ to discard the elaborate VSA code, which simulates various bits of
\ PC and PCI legacy hardware by trapping access to certain registers and
\ running System Management Mode code to fake their semantics.
\ The code here has the same general effect as the VSA code, but it is
\ much simpler because it hooks in at an appropriate place in the software,
\ instead of having to simulate the hardware register access semantics.

\ see ~/OLPC/vsa/sysmgr/topology.c
\ see ~/OLPC/vsa/sysmgr/pci_pm.c

\ 0: vendor  2: device  4: command  6: status
\ 8.1: rev  9.3: class  c: /cache-line  d: latency  e: header  f: BIST

hex
create nb-hdr  \ All R/O except cmd/stat, cache line size, latency
  fffffffc ,        0 ,        0 ,        0 ,
         0 ,        0 ,        0 ,        0 ,

    28100b ,  2200005 ,  6000021 ,   80f808 ,
      ac1d ,        0 ,        0 ,        0 ,  \ I/O BAR - base of virtual registers
         0 ,        0 ,        0 ,   28100b ,
         0 ,        0 ,        0 ,        0 ,
         0 ,        0 ,        0 ,        0 ,
         0 ,        0 ,        0 ,        0 ,
         0 ,        0 ,        0 ,        0 ,

create gxfb-hdr  \ All R/O except cmd/stat and cache line size
  ff800000 , fffff000 , fffff000 , fffff000 ,
         0 ,        0 ,        0 ,        0 ,

    30100b ,  2200002 ,  3000000 ,        8 ,
  fd000000 , fe000000 , fe004000 , fe008000 , \ FB, GP, VG, DF
         0 ,        0 ,        0 ,   30100b , \ VIP (LX only)
         0 ,        0 ,        0 ,        0 ,
         0 ,        0 ,        0 ,        0 , \ Interrupt goes at 5c for LX
       3d0 ,      3c0 ,    a0000 ,        0 , \ VG IO, VG IO, EGA FB, MONO FB
         0 ,        0 ,        0 ,        0 ,

create isa-hdr
  fffffff8 , ffffff00 , ffffffc0 , ffffffe0 ,
  ffffff80 , ffffffc0 ,        0 ,        0 ,

  20901022 ,  2a00049 ,  6010003 ,   802000 ,
      18b1 ,     1001 ,     1801 ,     1881 , \ SMB-8   GPIO-256  MFGPT-64  IRQ-32
      1401 ,     1841 ,        0 , 20901022 , \ PMS-128 ACPI-64
         0 ,        0 ,        0 ,        0 ,
         0 ,        0 ,        0 ,        0 ,
         0 ,        0 ,        0 ,     aa5b , \ interrupt steering
         0 ,        0 ,        0 ,        0 ,

create aes-hdr  \ LX security block
  ffffc000 ,        0 ,        0 ,        0 ,
         0 ,        0 ,        0 ,        0 ,

  20821022 ,  2a00006 , 10100000 ,        8 ,
  fe010000 ,        0 ,        0 ,        0 ,  \ I/O BAR - base of virtual registers
         0 ,        0 ,        0 , 20821022 ,
         0 ,        0 ,        0 ,      10e ,  \ INTA, IRQ 14
         0 ,        0 ,        0 ,        0 ,
         0 ,        0 ,        0 ,        0 ,
         0 ,        0 ,        0 ,        0 ,

0 [if]  \ Turned off
create nand-hdr  \ Doesn't appear as a PCI device, and kernel doesn't care

create ide-hdr
         0 ,        0 ,        0 ,        0 ,
  fffffff0 ,        0 ,        0 ,        0 , \ Maybe wrong

  209a1022 ,  2a00041 ,  1018001 ,     f800 ,
         0 ,        0 ,        0 ,        0 ,
      18a1 ,        0 ,        0 , 209a1022 ,
         0 ,        0 ,        0 ,        0 ,
         0 ,        0 , a8a8a8a8 , ffff00ff ,
   3030303 ,        0 ,        0 ,        0 ,
         0 ,        0 ,        0 ,        0 ,
[then]

create ac97-hdr
  ffffff80 ,        0 ,        0 ,        0 ,
         0 ,        0 ,        0 ,        0 ,

  20931022 ,  2a00041 ,  4010001 ,        0 ,
      1481 ,        0 ,        0 ,        0 , \ I/O BAR-128
         0 ,        0 ,        0 , 20931022 ,
         0 ,        0 ,        0 ,      205 , \ IntB , IRQ5
         0 ,        0 ,        0 ,        0 ,
         0 ,        0 ,        0 ,        0 ,
         0 ,        0 ,        0 ,        0 ,

create ohci-hdr
  fffff000 ,        0 ,        0 ,        0 ,
         0 ,        0 ,        0 ,        0 ,

  20941022 ,  2300006 ,  c031002 ,        0 ,
  fe01a000 ,        0 ,        0 ,        0 , \ MEMBAR-1000
         0 ,        0 ,        0 , 20941022 ,
         0 ,       40 ,        0 ,      40a , \ CapPtr  INT-D, IRQ A
  c8020001 ,        0 ,        0 ,        0 , \ Capabilities - 40 is R/O, 44 is mask 8103 (power control)
         0 ,        0 ,        0 ,        0 ,
         0 ,        0 ,        0 ,        0 ,

create ehci-hdr
  fffff000 ,        0 ,        0 ,        0 ,
         0 ,        0 ,        0 ,        0 ,

  20951022 ,  2300000 ,  c032002 ,        0 ,
  fe01b000 ,        0 ,        0 ,        0 , \ MEMBAR-1000
         0 ,        0 ,        0 , 20951022 ,
         0 ,       40 ,        0 ,      40a , \ CapPtr  INT-D, IRQ A
  c8020001 ,        0 ,        0 ,        0 , \ Capabilities - 40 is R/O, 44 is mask 8103 (power control)
\        1 , 40080000 ,        0 ,        0 , \ EECP - see section 2.1.7 of EHCI spec
  01000001 , 00000000 ,        0 ,        0 , \ EECP - see section 2.1.7 of EHCI spec
      2020 ,        0 ,        0 ,        0 , \ (EHCI page 8) 60 SBRN (R/O), 61 FLADJ (R/W), PORTWAKECAP

create ff-loc  -1 ,
create 00-loc   0 ,

variable hdr-offset
variable bar-probing

: do-special  ( value adr -- )
   drop   ( value )
   -1 =   ( probing? )
   hdr-offset @  h# 10  h# 2c  within  and   bar-probing !
   \ XXX need to decode EHCI power management stuff
;

: +hdr  ( offset hdr-adr -- adr )
   over hdr-offset !   ( offset hdr-adr )  \ Save for writing
   bar-probing @  if   ( offset hdr-adr )
      h# 10 -  +       \ Index into bar sizes part
   else
      h# 20 +  +       \ Index into values part
   then
   bar-probing off
;
: geode-map  ( adr -- data-adr )
   dup h# f0 and  h# 70 >=  if  drop 00-loc exit  then  ( adr )
   dup h# 7f and  swap  h# ff00 and  case    ( offset )
      h# 7800  of  isa-hdr   endof
\     h# 7900  of  nand-hdr  endof
\     h# 7a00  of  ide-loc   endof
      h# 7b00  of  ac97-hdr  endof
      h# 7c00  of  ohci-hdr  endof
      h# 7d00  of  ehci-hdr  endof
      h#  800  of  nb-hdr    endof
      h#  900  of  gxfb-hdr  endof
      h#  a00  of  gx?  if  ff-loc  else  aes-hdr  then  endof
      ( default )  2drop ff-loc exit
   endcase
   +hdr
;

\ The standard cf8/cfc dance
: config-map-m1  ( config-adr -- port )
   dup  3 invert and  h# 8000.0000 or  h# cf8 pl!  ( config-adr )
   3 and  h# cfc or  io-base +
;

: virtual-pci-slot?  ( config-adr -- flag )
   d# 11 rshift  h# 1fff and  dup h# f =  swap 1 =  or
;

: preassigned-pci-slot?  ( config-adr -- flag )
[ifdef] lx-devel  virtual-pci-slot? exit  [then]
   drop true
;

: config-setup  ( a1 -- a2 special? )
   dup  virtual-pci-slot?   ( a1 special )
   if  geode-map true  else  config-map-m1 false  then
;

: config-b@  ( a -- b )  config-setup  drop  rb@  ;
: config-w@  ( a -- w )  config-setup  drop  rw@  ;
: config-l@  ( a -- l )  config-setup  drop  rl@  ;

: config-b!  ( b a -- )  config-setup  if  do-special  else  rb!  then   ;
: config-w!  ( w a -- )  config-setup  if  do-special  else  rw!  then   ;
: config-l!  ( l a -- )  config-setup  if  do-special  else  rl!  then   ;

: assign-cafe  ( -- )
   h# fe020000  h# 6010 config-l!
   h# fe024000  h# 6110 config-l!
   h# fe028000  h# 6210 config-l!
;
warning @ warning off
: stand-init  ( -- )
   stand-init

   lx?  if
      \ Amend the fake PCI headers for the LX settings
      h# 20801022   nb-hdr h# 20 + l!  \ Vendor/device ID - AMD 
      h# 20801022   nb-hdr h# 4c + l!  \ Vendor/device ID - AMD 

      h# ff000008 gxfb-hdr h#  0 + l!  \ BAR0 MASK - FB
      h# ffffc000 gxfb-hdr h# 10 + l!  \ BAR4 MASK - VIP
      h# 20811022 gxfb-hdr h# 20 + l!  \ Vendor/device ID - AMD 
      h# fe00c000 gxfb-hdr h# 40 + l!  \ BAR4 address - VIP 
      h# 20811022 gxfb-hdr h# 4c + l!  \ Vendor/device ID - AMD 
      h#      10e gxfb-hdr h# 5c + w!  \ Interrupt pin and line - INTA, IRQ 14
   then

[ifdef] lx-devel  exit  [then]
   assign-cafe
   \ FIXME - we really should fixup the NB and FB headers to use the
   \ AMD device IDs, add the AES device, and insert the VIP BAR.
;
warning !

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
