purpose: System-specific portions of PCI bus package
copyright: Copyright 2001 Firmworks  All Rights Reserved

: init  ( -- )  ;

d# 33,333,333 " clock-frequency"  integer-property

\ Establish limits for address space allocation

h# 1000.0000 to first-mem	\ 1000.0000 - 1bff.ffff
h# 1c00.0000 to mem-space-top	\ Top of area available for PCI memory

h# 0000.1000 to first-io        \ Avoid on-board ISA I/O devices
h# 0000.f000 to io-space-top    \ And SouthBridge's SMBUS base address

\ The phys.hi component of the PCI addresses below indicate the
\ address space type (I/O = 0100.0000, Mem = 0200.0000, etc.)

\ -----------PCI Address---  --Sys Addr--  ------size-----
\  phys.hi     .mid    .low     phys.hi    .hi         .lo

0 0 encode-bytes
   0000.0000 +i 0+i     0+i  bfe8.0000 +i  0+i    8.0000 +i \ PCI Cfg
   0100.0000 +i 0+i     0+i  bfd0.0000 +i  0+i 0010.0000 +i \ ISA I/O
   0200.0000 +i 0+i     0+i  9000.0000 +i  0+i 0c00.0000 +i \ PCI Mem
" ranges" property

\ These package methods use the global versions of the configuration
\ access words.

: config-l@  ( config-addr -- l )  config-l@  ;
: config-l!  ( l config-addr -- )  config-l!  ;
: config-w@  ( config-addr -- w )  config-w@  ;
: config-w!  ( w config-addr -- )  config-w!  ;
: config-b@  ( config-addr -- c )  config-b@  ;
: config-b!  ( c config-addr -- )  config-b!  ;

fload ${BP}/dev/pci/intmap.fth		\ Generic interrupt mapping code

\ This table describes the wiring of PCI interrupt pins at the PCI slots
\ to ISA IRQs.

create slot-map
\  Dev#  Pin A  Pin B  Pin C  Pin D
  18 c,   0 c,   1 c,   2 c,   3 c,	\ PCI slot 2 (P9)
  19 c,   1 c,   2 c,   3 c,   0 c,	\ PCI slot 3 (P10)
  1a c,   2 c,   3 c,   0 c,   1 c,	\ PCI slot 4 (P11)
  1b c,   2 c,  ff c,  ff c,  ff c,	\ Ethernet
  1c c,   0 c,   1 c,   2 c,   3 c,	\ South Bridge
  1d c,   3 c,   0 c,   1 c,   2 c,	\ PCI slot 1 (P8)
  ff c,					\ End of list

h# f800 encode-int			\ Mask of implemented slots
" PCI1" encode-string encode+
" PCI2" encode-string encode+
" PCI3" encode-string encode+
" PCI4" encode-string encode+
" slot-names" property

also forth definitions
" 1b,1d,18,19,1a"  dup config-string pci-probe-list
previous definitions

warning @ warning off
\ The io-base handling really ought to be in the root node, but
\ that would require more changes than I'm willing to do at present.
: map-out  ( vaddr size -- )
   over io-base u>=  if  2drop exit  then  ( vaddr size )
   map-out                                 ( )
;   
warning !

: bonito-function-present?  ( phys.hi.func -- flag )
   bonito-cfg-pa 6 + dup w@ over w!	\ Clear errors
   swap " config-l@" $call-self drop
   w@ h# 2000 and 0=			\ Return true if not Master-Abort
;
' bonito-function-present? to function-present?

