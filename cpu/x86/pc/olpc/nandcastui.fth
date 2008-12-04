purpose: User interface for NAND multicast updater

: mesh-ssids  ( -- $ )
   " olpc-mesh"nolpc-mesh"nolpc-mesh"nolpc-mesh"nolpc-mesh"nolpc-mesh"
;

: use-mesh  ( -- )
   \ Check for already set because re-setting it will force rescanning
   ['] mesh-ssids to default-ssids
   wifi-cfg >wc-ssid pstr@  " olpc-mesh" $=  0=  if
      " olpc-mesh" $essid
   then
;

: ether-clone1
   false to already-go?
   " boot rom:cloner ether: 1 /nandflash" eval
;
: ether-clone6
   false to already-go?
   " boot rom:cloner ether: 6 /nandflash" eval
;
: ether-clone11
   false to already-go?
   " boot rom:cloner ether: 11 /nandflash" eval
;

: enand1
   false to already-go?
   " boot rom:mcastnand ether: 1 /nandflash" eval
;
: enand6
   false to already-go?
   " boot rom:mcastnand ether: 6 /nandflash" eval
;
: enand11
   false to already-go?
   " boot rom:mcastnand ether: 11 /nandflash" eval
;

: mesh-clone
   use-mesh
   false to already-go?
   " boot rom:cloner 239.255.1.2 12345 /nandflash" eval
;

: meshnand
   use-mesh
   false to already-go?
   " boot rom:mcastnand 239.255.1.2 12345 /nandflash" eval
;

: mcastnand
   false to already-go?
   " boot rom:mcastnand 239.255.1.2 12345 /nandflash" eval
;
: ucastnand
   false to already-go?
   " boot rom:mcastnand 10.20.0.16,,10.20.0.44 12345 /nandflash" eval
;
: nmcastnand  \ Boot from network, for testing
   false to already-go?
   " boot http:\\10.20.0.14\mcastnand 239.255.1.2 12345 /nandflash" eval
;
: dmcastnand  \ Boot from USB disk, for testing
   false to already-go?
   " boot disk:\mcnand 239.255.1.2 12345 /nandflash" eval
;
