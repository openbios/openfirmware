purpose: Configuration space access using "configuration mechanism 1"
copyright: Copyright 2001 Firmworks  All Rights Reserved

\ Ostensibly this applies to the PCI bus and thus should be in the PCI node.
\ However, many of the host bridge registers are accessed via this mechanism,
\ so it is convenient to make the configuration access words globally-visible.
\ This mechanism works for several different PCI host bridges.

headerless

defer config-map
: config-map-bonito  ( config-adr -- port )
   h# 00ff.ffff and dup >r  h# 1.0000 <  if
      \ Type 0 cycle
      1 r@ h# f800 and d# 11 >> <<	( idsel )
      r> h# 7ff and or			( type0 )
      lwsplit				( lo hi )
   else
      \ Type 1 cycle
      r> lwsplit h# 1.0000 or		( lo hi )
   then
   pcimap_cfg !  pci-cfg-pa +
;
' config-map-bonito to config-map

: config-l@  ( config-addr -- l )  config-map rl@  ;
: config-l!  ( l config-addr -- )  config-map rl!  ;
: config-w@  ( config-addr -- w )  config-map rw@  ;
: config-w!  ( w config-addr -- )  config-map rw!  ;
: config-b@  ( config-addr -- c )  config-map rb@  ;
: config-b!  ( c config-addr -- )  config-map rb!  ;

