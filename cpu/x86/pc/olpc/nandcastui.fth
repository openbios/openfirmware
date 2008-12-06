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
: $file-to-mem  ( filename$ -- adr len )
   $read-open
   ifd @ fsize  dup alloc-mem  swap     ( adr len )
   2dup ifd @ fgets                     ( adr len actual )
   ifd @ fclose                         ( adr len actual )
   over <>  abort" Can't read file" cr  ( adr len )
;
: load-read  ( filename$ -- )
   open-dev  dup 0=  abort" Can't open file"  >r  ( r: ih )
   load-base " load" r@ $call-method  !load-size
   r> close-dev
;

: secure$  ( -- adr len )
   secure?  if  " secure"  else  null$  then
;

d# 20 value redundancy

: #nb  ( channel# -- )
   depth 1 < abort" Usage: channel# #nb"
   secure$ rot
   " rom:nb_rx ether:%d %s" sprintf boot-load go
;
: #nb-clone  ( channel# -- )
   depth 1 < abort" Usage: channel# #nb-clone"
   redundancy swap
   " rom:nb_tx ether:%d nand: %d" sprintf boot-load go
;
: #nb-copy  ( image-filename$ channel# -- )
   depth 3 < abort" #nb-copy - too few arguments"
   >r 2>r                             ( placement-filename$ r: channel# image-filename$ )
   redundancy  2r> r>                 ( redundancy image-filename$ channel# )
   " rom:nb_tx ether:%d %s %d 131072" sprintf boot-load go
;
: #nb-update  ( placement-filename$ image-filename$ channel# -- )
   depth 5 < abort" #nb-update - too few arguments"
   >r 2>r                             ( placement-filename$ r: channel# image-filename$ )
   $file-to-mem                       ( spec$ r: channel# image-filename$ )
   swap  redundancy  2r> r>           ( speclen specadr redundancy image-filename$ channel# )
   " rom:nb_tx ether:%d %s %d 131072 %d %d" sprintf boot-load go
;
: #nb-secure  ( zip-filename$ image-filename$ channel# -- )
   depth 5 < abort" #nb-secure-update - too few arguments"
   >r 2>r                             ( placement-filename$ r: channel# image-filename$ )
   load-read  sig$ ?save-string swap  ( siglen sigadr r: channel# image-filename$ )
   img$ ?save-string swap             ( siglen sigadr speclen specadr r: channel# image-filename$ )
   redundancy  2r> r>                 ( siglen sigadr speclen specadr redundancy image-filename$ channel# )
   " rom:nb_tx ether:%d %s %d 131072 %d %d %d %d" sprintf boot-load go
;

: nb-clone1  ( -- )  1 #nb-clone  ;
: nb-clone6  ( -- )  6 #nb-clone  ;
: nb-clone11  ( -- )  d# 11 #nb-clone  ;

: nb-update1  ( -- )  1 #nb-update  ;
: nb-update6  ( -- )  6 #nb-update  ;
: nb-update11  ( -- )  d# 11 #nb-update  ;

: nb-secure1  ( -- )  1 #nb-secure  ;
: nb-secure6  ( -- )  6 #nb-secure  ;
: nb-secure11  ( -- )  d# 11 #nb-secure  ;

: nb1  ( -- )  1 #nb  ;
: nb6  ( -- )  6 #nb  ;
: nb11  ( -- )  d# 11 #nb  ;

: mesh-clone
   use-mesh
   false to already-go?
   redundancy " boot rom:nb_tx udp:239.255.1.2 nand: %d" sprintf eval
;

: meshnand
   use-mesh
   false to already-go?
   " boot rom:nb_rx 239.255.1.2" eval
;

: nb_rx
   false to already-go?
   " boot rom:nb_rx 239.255.1.2" eval
;
: ucastnand
   false to already-go?
   " boot rom:nb_rx 10.20.0.16,,10.20.0.44" eval
;
