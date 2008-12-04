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

: #enand  ( channel# -- )
   depth 1 < abort" Usage: channel# enand"
   " rom:mcastnand ether:%d" sprintf boot-load go
;
: #ether-clone  ( channel# -- )
   depth 1 < abort" Usage: channel# ether-clone"
   " rom:cloner ether:%d" sprintf boot-load go
;
: ether-clone1  ( -- )  1 #ether-clone  ;
: ether-clone6  ( -- )  6 #ether-clone  ;
: ether-clone11  ( -- )  d# 11 #ether-clone  ;
: enand1  ( -- )  1 #enand  ;
: enand6  ( -- )  6 #enand  ;
: enand11  ( -- )  d# 11 #enand  ;

: mesh-clone
   use-mesh
   false to already-go?
   " boot rom:cloner 239.255.1.2" eval
;

: meshnand
   use-mesh
   false to already-go?
   " boot rom:mcastnand 239.255.1.2" eval
;

: mcastnand
   false to already-go?
   " boot rom:mcastnand 239.255.1.2" eval
;
: ucastnand
   false to already-go?
   " boot rom:mcastnand 10.20.0.16,,10.20.0.44" eval
;
: nmcastnand  \ Boot from network, for testing
   false to already-go?
   " boot http:\\10.20.0.14\mcastnand 239.255.1.2" eval
;
: dmcastnand  \ Boot from USB disk, for testing
   false to already-go?
   " boot disk:\mcnand 239.255.1.2" eval
;
