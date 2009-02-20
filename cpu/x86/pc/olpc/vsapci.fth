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

: >bar-info  ( mask-adr -- base-adr size )
   dup l@   swap h# 30 + l@    ( mask bar-value )
   over and                    ( mask base-adr )
   swap negate                 ( base-adr size )
;

hex
: +methods  ( object -- data-adr )  2 ta+  ;
: set-cmd-reg  ( object value -- adr value )
   swap +methods    ( value adr )
   2dup h# 24 + w!  ( value adr )
   swap             ( adr value )
;
: >hdr-value  ( reg# object -- adr )  +methods  h# 20 +  +  ;

: noop-cmd-reg  ( object value -- )  set-cmd-reg 2drop  ;
: noop-bar  ( object value -- )  2drop  ;

\ To support changing the SMI address, change MSR 1000.00e3 and some
\ hardcoded constants in smi.fth

create nb-hdr  \ All R/O except cmd/stat, cache line size, latency
  ' noop-cmd-reg token,    ' >hdr-value token,  
  fffffffc ,        0 ,        0 ,        0 ,
         0 ,        0 ,        0 ,        0 ,

    28100b ,  2200005 ,  6000021 ,   80f808 ,
      ac1d ,        0 ,        0 ,        0 ,  \ I/O BAR - base of virtual registers
         0 ,        0 ,        0 ,   28100b ,
         0 ,        0 ,        0 ,        0 ,
         0 ,        0 ,        0 ,        0 ,
         0 ,        0 ,        0 ,        0 ,
         0 ,        0 ,        0 ,        0 ,

: unmap-gxfb  ( -- )
   h# 1000.0029 p2d-range-off
   h# 4000.002a p2d-range-off
   h#      1820 rconf-off
   0. h# a000.2001 msr!   \ CBASE

   h# 1000.0022  p2d-bm-off
   h# 4000.0022  p2d-bm-off
   h#      1811  rconf-off
   d# 15 ms
   h# 1000.002a  p2d-bm-off
   h# 4000.0024  p2d-bm-off
   h#      1812  rconf-off
   h# 1000.0023  p2d-bm-off
   h# 4000.0025  p2d-bm-off
   h#      1813  rconf-off
   h# 1000.0024  p2d-bm-off
   h# 4000.0026  p2d-bm-off
   h#      1814  rconf-off
;

\ There are registers inside the display controller and the graphics processor
\ that need to know the address routing of the frame buffer
0 value fb-current
0 value gp-current
0 value dc-current
0 value vp-current
: do-fb-fixups  ( -- )
[ifdef] virtual-mode
   gp-current h# 4000 map-v=p
   dc-current h# 4000 map-v=p
[then]

   fb-current  dc-current h# 84 +  l!
   fb-current  gp-current h# 4c +  l!

[ifdef] virtual-mode
   gp-current h# 4000 mmu-unmap
   dc-current h# 4000 mmu-unmap
[then]
;

: gxfb-cmd-reg  ( object value -- )
   set-cmd-reg  2 and  if      ( adr )
      dup h# 30 + l@  h# f invert and  ( adr base-adr )
      dup to fb-current
      ?dup  if       \ FB 910  ( adr base-adr )
         fbsize                ( adr base-adr size )
         2dup  fb-offset   h# 2  h# 1000.0029 set-p2d-range-offset  ( adr base-adr size )
         2dup              h# 2  h# 4000.002a set-p2d-range         ( adr base-adr size )
         2dup            h# 111  h#      1820 set-rconf             ( adr base-adr size )
         + h# 200000 -  4 rshift  0  h# a000.2001 msr!  \ CBASE ( adr )
\ XXX need to set dc_base+88.l
\ See also video-map in chipinit.fth
      then
      la1+                      ( adr' )

      dup >bar-info  \ GP 914   ( adr base-adr size )
      over to gp-current
      over  if
         2dup  h#  a  h# 1000.0022  set-p2d-bm
         2dup  h#  2  h# 4000.0022  set-p2d-bm
              h# 101  h#      1811  set-rconf
      else  2drop  then
      la1+                      ( adr' )

      dup >bar-info   \ DC 918  ( adr base-adr size )
      over to dc-current
      over  if
         2dup  0  h# 8  h# 1000.002a  set-p2d-range-offset
         2dup     h# 2  h# 4000.0024  set-p2d-bm
                h# 101  h#      1812  set-rconf
      else  2drop  then
      la1+                      ( adr' )

      dup >bar-info   \ VP 91c  ( adr base-adr size )
      over to vp-current
      over  if
         2dup  h# 4  h# 1000.0023  set-p2d-bm
         2dup  h# 4  h# 4000.0025  set-p2d-bm
              h# 101  h#      1813  set-rconf
      else  2drop  then
      la1+                      ( adr' )

      dup >bar-info  \ VIP 920  ( adr base-adr size )
      over  if
         2dup  h#  4  h# 1000.0024  set-p2d-bm
         2dup  h#  a  h# 4000.0026  set-p2d-bm
              h# 101  h#      1814  set-rconf
      else  2drop  then         ( adr )

      drop
      do-fb-fixups
   else
      drop

\     Unmapping wrecks the display
\     unmap-gxfb
   then
;

create gxfb-hdr  \ All R/O except cmd/stat and cache line size
  ' gxfb-cmd-reg token,    ' >hdr-value token,  
  ff800000 , ffffc000 , ffffc000 , ffffc000 ,
         0 ,        0 ,        0 ,        0 ,

    30100b ,  2200003 ,  3000000 ,        8 ,
  fb-pci-base , gp-pci-base , dc-pci-base , vp-pci-base , \ FB, GP, DC, VP
         0 ,        0 ,        0 ,   30100b , \ VIP (LX only)
         0 ,        0 ,        0 ,        0 ,
         0 ,        0 ,        0 ,        0 , \ Interrupt goes at 5c for LX
       3d0 ,      3c0 ,    a0000 ,        0 , \ VG IO, VG IO, EGA FB, MONO FB
         0 ,        0 ,        0 ,        0 ,

create isa-hdr
  ' noop-cmd-reg token,    ' >hdr-value token,  

  fffffff8 , ffffff00 , ffffffc0 , ffffffe0 ,
  ffffff80 , ffffffc0 ,        0 ,        0 ,

  20901022 ,  2a00049 ,  6010003 ,   802000 ,
      18b1 ,     1001 ,     1801 ,     1881 , \ SMB-8   GPIO-256  MFGPT-64  IRQ-32
      1401 ,     1841 ,        0 , 20901022 , \ PMS-128 ACPI-64
         0 ,        0 ,        0 ,        0 ,
         0 ,        0 ,        0 ,        0 ,
         0 ,        0 ,        0 ,     aa5b , \ interrupt steering
         0 ,        0 ,        0 ,        0 ,

: aes-cmd-reg  ( object value -- )
   set-cmd-reg  2 and  if
      >bar-info                               ( base-adr size )
      2dup h#   c h# 4000.002b set-p2d-range  ( base-adr size )
      2dup h#   4 h# 1000.0025 set-p2d-bm     ( base-adr size )
           h# 101 h#      1815 set-rconf      
   else
      drop
      h# 1815 rconf-off
      h# 1000.0025 p2d-bm-off
      h# 4000.002b p2d-range-off
   then
;

create aes-hdr  \ LX security block
  ' aes-cmd-reg token,    ' >hdr-value token,  

  ffffc000 ,        0 ,        0 ,        0 ,
         0 ,        0 ,        0 ,        0 ,

  20821022 ,  2a00006 , 10100000 ,        8 ,
  aes-pci-base ,    0 ,        0 ,        0 ,  \ BAR
         0 ,        0 ,        0 , 20821022 ,
         0 ,        0 ,        0 ,      10e ,  \ INTA, IRQ 14
         0 ,        0 ,        0 ,        0 ,
         0 ,        0 ,        0 ,        0 ,
         0 ,        0 ,        0 ,        0 ,

0 [if]  \ Turned off
create nand-hdr  \ Doesn't appear as a PCI device, and kernel doesn't care
[then]

: ide-cmd-reg  ( object value -- )
   set-cmd-reg  1 and  if                  ( adr )
      >bar-info                            ( base-adr size )
      2dup h# 1 h# 5100.002b set-rconf     ( base-adr size )
      drop 0    h# 5130.0008 msr!          ( )
      h# 4002.  h# 5130.0010 msr!          ( )
   else                                    ( adr )
      drop                                 ( )
      h# 5100.002b rconf-off
      h# 0. h# 5130.0010 msr!              ( )
   then                                    ( )
;

create ide-hdr
  ' ide-cmd-reg token,    ' >hdr-value token,  

         0 ,        0 ,        0 ,        0 ,
  fffffff0 ,        0 ,        0 ,        0 , \ Maybe wrong

  209a1022 ,  2a00041 ,  1018001 ,     f800 ,
         0 ,        0 ,        0 ,        0 ,
      18a1 ,        0 ,        0 , 209a1022 ,
         0 ,        0 ,        0 ,        0 ,
         0 ,        0 , a8a8a8a8 , ffff00ff ,
   3030303 ,        0 ,        0 ,        0 ,
         0 ,        0 ,        0 ,        0 ,

: ?bus-master  ( cmd-reg mask -- )
   h# 51010081 2 pick  4 and  if  msr-set  else  msr-clr  then
;
: ac97-cmd-reg  ( object value -- )
   set-cmd-reg
   h# 300 ?bus-master                  ( adr value )
   1 and  if                           ( adr )
      >bar-info                        ( base-adr size )
      2dup 1 h# 5100.0026 set-io-rconf ( base-adr size )
      h# a   h# 5101.00e1 set-iod-bm   ( )
   else                                ( adr )
      drop                             ( )
      h# 5100.0026 rconf-off           ( )
      h# 5101.00e1 iod-bm-off          ( )
   then

   \ The MSRs are:
   \ 5101.00e1  a0000001.480fff80.  IOD_BM
   \ 5100.0026  014f0001.01480001.  io-rconf
   \ 5150.0004  00000000.00000005.  clock gating
   \ 5150.0001  00000000.0008f000.  prefetch policy
;

create ac97-hdr
  ' ac97-cmd-reg token,    ' >hdr-value token,  

  ffffff80 ,        0 ,        0 ,        0 ,
         0 ,        0 ,        0 ,        0 ,

  20931022 ,  2a00041 ,  4010001 ,        0 ,
      1481 ,        0 ,        0 ,        0 , \ I/O BAR-128
         0 ,        0 ,        0 , 20931022 ,
         0 ,        0 ,        0 ,      205 , \ IntB , IRQ5
         0 ,        0 ,        0 ,        0 ,
         0 ,        0 ,        0 ,        0 ,
         0 ,        0 ,        0 ,        0 ,

: ohci-cmd-reg  ( object value -- )
   set-cmd-reg  2 and  if                  ( adr )
      >bar-info                            ( base-adr size )
      2dup h# 5 h# 5101.0023 set-p2d-bm    ( base-adr size )
      2dup h# 1 h# 5100.0027 set-rconf     ( base-adr size )
      2dup h# 1 h# 5140.0009 set-usb-kel   ( base-adr size )
      drop h# e h# 5120.0008 set-usb-base  ( )
   else                                    ( adr )
      drop                                 ( )
      h# 5101.0023 p2d-bm-off
      h# 5100.0027 rconf-off
      h# 5140.0009 usb-kel-off
      h# 5120.0008 usb-base-off
   then                                    ( )
;

create ohci-hdr
  ' ohci-cmd-reg token,    ' >hdr-value token,  

  fffff000 ,        0 ,        0 ,        0 ,
         0 ,        0 ,        0 ,        0 ,

  20941022 ,  2300006 ,  c031002 ,        0 ,
  ohci-pci-base ,   0 ,        0 ,        0 , \ MEMBAR-1000
         0 ,        0 ,        0 , 20941022 ,
         0 ,       40 ,        0 ,      40a , \ CapPtr  INT-D, IRQ A
  c8020001 ,        0 ,        0 ,        0 , \ Capabilities - 40 is R/O, 44 is mask 8103 (power control)
         0 ,        0 ,        0 ,        0 ,
         0 ,        0 ,        0 ,        0 ,

: ehci-cmd-reg  ( object value -- )
   set-cmd-reg  2 and  if                     ( adr )
      >bar-info                               ( base-adr size )
      2dup h#   04 h# 5101.0024 set-p2d-bm    ( base-adr size )
      2dup h#   01 h# 5100.0028 set-rconf     ( base-adr size )
      drop h# 200e h# 5120.0009 set-usb-base  ( )
   else                                       ( adr )
      drop                                    ( )
      h# 5101.0024 p2d-bm-off
      h# 5100.0028 rconf-off
      h# 5120.0009 usb-base-off
   then                                       ( )
;

create ehci-hdr
  ' ehci-cmd-reg token,    ' >hdr-value token,  

  fffff000 ,        0 ,        0 ,        0 ,
         0 ,        0 ,        0 ,        0 ,

  20951022 ,  2300006 ,  c032002 ,        0 ,
  ehci-pci-base ,   0 ,        0 ,        0 , \ MEMBAR-1000
         0 ,        0 ,        0 , 20951022 ,
         0 ,       40 ,        0 ,      40a , \ CapPtr  INT-D, IRQ A
  c8020001 ,        0 ,        0 ,        0 , \ Capabilities - 40 is R/O, 44 is mask 8103 (power control)
\        1 , 40080000 ,        0 ,        0 , \ EECP - see section 2.1.7 of EHCI spec
  01000001 , 00000000 ,        0 ,        0 , \ EECP - see section 2.1.7 of EHCI spec
      2020 ,        0 ,        0 ,        0 , \ (EHCI page 8) 60 SBRN (R/O), 61 FLADJ (R/W), PORTWAKECAP

create ff-loc  -1 ,
create 00-loc   0 ,

: null-cmd-reg  ( object value -- )  2drop  ;
: >00-loc  ( reg# object -- adr )  2drop 00-loc  ;
: >ff-loc  ( reg# object -- adr )  2drop ff-loc  ;

create ff-hdr  ' null-cmd-reg token,   ' >ff-loc token,
create 00-hdr  ' null-cmd-reg token,   ' >00-loc token,

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

: geode-map  ( adr -- offset struct-adr )
   dup h# f0 and  h# 70 >=  if  drop 00-loc exit  then  ( adr )
   dup h# 7f and  swap  h# ff00 and  case    ( offset )
      h# 7800  of  isa-hdr   endof
\     h# 7900  of  nand-hdr  endof
      h# 7a00  of  ide-hdr   endof
      h# 7b00  of  ac97-hdr  endof
      h# 7c00  of  ohci-hdr  endof
      h# 7d00  of  ehci-hdr  endof
      h#  800  of  nb-hdr    endof
      h#  900  of  gxfb-hdr  endof
      h#  a00  of  gx?  if  drop ff-loc exit  else  aes-hdr  then  endof
      ( default )  2drop ff-loc exit
   endcase
;

: case-within  ( val low high+ -- val ~val | offset 0 0 )
   3dup within  if       ( val low high+ )
      drop  -  0 0       ( val low high+ )
   else                  ( val low high+ )
      2drop  dup invert  ( val ~val )
   then
;

: do-bar  ( object value mask bar-offset -- )
   \ Noop if the write size is not 32 bits
   swap  h# ffffffff <>  if  3drop exit  then   ( object value bar-offset )

   rot                                    ( value bar-offset object )
   +methods  +  >r                        ( value r: adr' )

   \ Mask the value with the size mask that says which bits are writeable
   r@ l@                                  ( value size-mask r: adr )
   and                                    ( value' r: adr )

   \ Get the address of the current value
   r>  h# 30 +  >r                        ( value  r: adr' )

   \ Merge in the existing low attribute bits
   \ I/O base registers have 2 low attribute bits -   01
   \ Mem base registers have 4 low attribute bits - xxx0
   r@ l@                                 ( value old-value  r: adr )
\  dup 1 and  if  3  else  h# f  then    ( value old-value lowmask  r: adr )
   dup 1 and  if  3  else  h# 7  then    ( value old-value lowmask  r: adr )
   and  or                               ( value'  r: adr )

   r>  l!
;

\ Write to reg 7.b
: do-status-clear  ( object value mask -- )
   h# ff <>  if   2drop exit   then   \ Bad size  ( object value )

   \ For now we don't implement status bits
   2drop
;

\ Write to reg 6 (possibly including reg 7.b)
: do-status-reg  ( object value mask -- )
   \ Reg 6.b is RO, so we only have to do something if the write also includes 7.b
   h# ffff <>  if  2drop exit  then   ( object value )

   \ Extract the high byte and call the reg 7.b handler
   wbsplit nip  h# ff  do-status-clear
;

: cmd-reg-only  ( object value -- )  over token@ execute  ;

\ Write to reg 4 (possibly including reg 6.w)
: do-command-reg  ( object value mask -- )
   case  ( object value )
      h# ffffffff of    ( object value )
         wbsplit                             ( object value.lo value.hi )
         2 pick swap h# ffff do-status-reg   ( object value.lo )
         cmd-reg-only                        ( )
      endof

      h#     ffff of  cmd-reg-only   endof
      ( default )  nip nip
   endcase
;

: do-cache-line-size  ( object value mask -- )  3drop  ;
: do-latency-timer  ( object value mask -- )  3drop  ;

: vpci!  ( value reg# object mask -- )
   over dup ff-loc =   swap 00-loc =  or  if  4drop exit  then

   rot >r            ( value object mask r: reg# )
   rot swap          ( object value mask r: reg# )
   r> case  
      h#  4 of  do-command-reg      endof
      h#  6 of  do-status-reg       endof
      h#  7 of  do-status-clear     endof
      h#  c of  do-cache-line-size  endof
      h#  d of  do-latency-timer    endof
      h# 10 h# 2c case-within  of  do-bar  endof

      ( default - read-only )  nip nip nip
   endcase
;

: +rhdr  ( reg# object -- adr )  dup ta1+ token@ execute  ;

: >hdr-object  ( adr -- reg# hdr-object )
   dup h# f0 and  h# 70 >=  if  drop 0 00-hdr exit  then  ( adr )
   dup h# 7f and  swap  h# ff00 and  case    ( reg# )
      h# 7800  of  isa-hdr   endof
\     h# 7900  of  nand-hdr  endof
\     h# 7a00  of  ide-hdr   endof

      h# 7b00  of  ac97-hdr  endof
\ h# 7b00  of  ff-hdr  endof
      h# 7c00  of  ohci-hdr  endof
      h# 7d00  of  ehci-hdr  endof
      h#  800  of  nb-hdr    endof
      h#  900  of  gxfb-hdr  endof
      h#  a00  of  gx?  if  drop 0 ff-hdr exit  else  aes-hdr  then  endof
      ( default )  2drop 0 ff-hdr exit
   endcase
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
   drop true
;

: config-setup  ( a1 -- adr false  |  reg# object true )
   dup  virtual-pci-slot?   ( a1 special )
   if  >hdr-object true  else  config-map-m1 false  then
;

: config-b@  ( a -- b )  config-setup  if  +rhdr  then  rb@  ;
: config-w@  ( a -- w )  config-setup  if  +rhdr  then  rw@  ;
: config-l@  ( a -- l )  config-setup  if  +rhdr  then  rl@  ;

: config-b!  ( b a -- )  config-setup  if  h#       ff vpci!  else  rb!  then  ;
: config-w!  ( w a -- )  config-setup  if  h#     ffff vpci!  else  rw!  then  ;
: config-l!  ( l a -- )  config-setup  if  h# ffffffff vpci!  else  rl!  then  ;

: vpci-devices-on  ( -- )
   h# 06  h#  a04 config-w!  \ AES
   h# 49  h# 7804 config-w!  \ ISA
   h# 45  h# 7b04 config-w!  \ AC97
   h# 06  h# 7c04 config-w!  \ OHCI
   h# 06  h# 7d04 config-w!  \ EHCI
;
: assign-cafe  ( -- )
   nand-pci-base    h# 6010 config-l!
   sd-pci-base      h# 6110 config-l!
   camera-pci-base  h# 6210 config-l!
;
warning @ warning off
: stand-init  ( -- )
   stand-init

   lx?  if
      \ Amend the fake PCI headers for the LX settings
      h# 20801022    nb-hdr +methods h# 20 + l!  \ Vendor/device ID - AMD 
      h# 20801022    nb-hdr +methods h# 4c + l!  \ Vendor/device ID - AMD 

      h# ff000008  gxfb-hdr +methods h#  0 + l!  \ BAR0 MASK - FB
      h# ffffc000  gxfb-hdr +methods h# 10 + l!  \ BAR4 MASK - VIP
      h# 20811022  gxfb-hdr +methods h# 20 + l!  \ Vendor/device ID - AMD 
      vip-pci-base gxfb-hdr +methods h# 40 + l!  \ BAR4 address - VIP 
      h# 20811022  gxfb-hdr +methods h# 4c + l!  \ Vendor/device ID - AMD 
      h#      10e  gxfb-hdr +methods h# 5c + w!  \ Interrupt pin and line - INTA, IRQ 14
   then

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
