purpose: System-specific portions of PCI bus package
copyright: Copyright 2001 Firmworks  All Rights Reserved

: init  ( -- )  ;

d# 33,333,333 " clock-frequency"  integer-property

\ Establish limits for address space allocation

pci-mem-pa to first-mem		\ 1400.0000-17ff.ffff
first-mem h# 400.0000 + to mem-space-top

pci-io-pa to first-io		\ 1300.0000-131f.ffff
first-io h# 20.0000 + to io-space-top

\ The phys.hi component of the PCI addresses below indicate the
\ address space type (I/O = 0100.0000, Mem = 0200.0000, etc.)

\ -----------PCI Address---  --Sys Addr--  ------size-----
\  phys.hi     .mid    .low     phys.hi    .hi         .lo

0 0 encode-bytes
   0100.0000 +i 0+i     0+i  pci-io-base  +i  0+i 0020.0000 +i \ PCI I/O
   0200.0000 +i 0+i     0+i  pci-mem-base +i  0+i 0400.0000 +i \ PCI Mem
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
   e c,   2 c,  ff c,  ff c,  ff c,     \ Ethernet
   f c,   1 c,  ff c,  ff c,  ff c,	\ Card bus
  ff c,					\ End of list

also forth definitions
" e,f"  dup config-string pci-probe-list
previous definitions

warning @ warning off
\ The io-base handling really ought to be in the root node, but
\ that would require more changes than I'm willing to do at present.
: map-out  ( vaddr size -- )
   over io-base u>=  if  2drop exit  then  ( vaddr size )
   map-out                                 ( )
;   
warning !

