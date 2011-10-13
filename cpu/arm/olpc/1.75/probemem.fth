purpose: Memory probing
copyright: Copyright 1994 FirmWorks  All Rights Reserved

" /memory" find-device

: (memory?)  ( phys -- flag )  fb-mem-va >physical  u<  ;
' (memory?) to memory?

headerless

h# ffff.ffff value low
h#         0 value high

: log&release  ( adr len -- )
   over    low  umin to low   ( adr len )
   2dup +  high umax to high  ( adr len )
   release
;

headers
: probe  ( -- )
   0  fb-mem-va >physical   /fb-mem +  log&release

   0 0 encode-bytes                                   ( adr 0 )
   physavail  ['] make-phys-memlist  find-node        ( adr len  prev 0 )
   2drop  " reg" property

   \ Claim the memory already in use
   fb-mem-va    >physical   /fb-mem     0 claim  drop
   fw-mem-va    >physical   /fw-mem     0 claim  drop
   extra-mem-va >physical   /extra-mem  0 claim  drop

   0 pagesize  0 claim  drop       \ Vector table
;

\ The parameters depend on CPU-specific cache parameters
: flush-entire-dcache  ( -- )
   \ Flush L1 dcache
   
   h# 1000 0  do     \ Loop over sets - h# 1000 is L1 #sets
      0 0  do        \ Loop over ways
	 i j + clean&flush-d$-entry-way  \ Operate on L1 cache
      h# 2000.0000 +loop  \ h# 2000.0000 depends on L1 #ways
   h# 20 +loop       \ h# 20 is L1 line size

   h# 10000 0  do    \ Loop over sets - h# 10000 is L2 #sets
      0 0  do        \ Loop over ways
	 i j + 2+ clean&flush-d$-entry-way  \ Operate on L2 cache (2+)
      h# 2000.0000 +loop  \ h# 2000.0000 depends on L2 #ways
   h# 20 +loop       \ h# 20 is L2 line size
;
' flush-entire-dcache to memtest-flush-cache

0 value p-adr
0 value v-adr

false value mem-fail?

: show-line  ( adr len -- )  (cr type  3 spaces  kill-line  ;
' show-line to show-status

[ifndef] 8u.h
: 8u.h  ( n -- )  push-hex (.8) type pop-base  ;
[then]
: .chunk  ( adr len -- )  ." Testing address 0x" swap 8u.h ."  length 0x" 8u.h cr  ;

defer test-s3  ( -- error? )  ' false is test-s3

: test-mem  ( adr len -- )	\ Test a chunk 'o memory
   2>r
   2r@ 0 mem-claim to p-adr		( ) ( r: adr len )
[ifdef] virtual-mode
   2r@ nip 1 mmu-claim to v-adr		( ) ( r: adr len )
   2r@ v-adr swap h# c00 mmu-map	( ) ( r: adr len ) \ c00 = non-cached
   v-adr				( adr )
[else]
   p-adr				( adr )
[then]

   2r@ nip memory-test-suite		( status ) ( r: adr len )
   0<>  if  true to mem-fail?  then

[ifdef] virtual-mode
   v-adr 2r@ nip mmu-unmap		( ) ( r: adr len )
   v-adr 2r@ nip mmu-release		( ) ( r: adr len )
[then]
   p-adr 2r> nip mem-release		( )

   mem-fail?  if                        ( )
      "     !!Failed!!" show-status  cr ( )
   else                                 ( )
      "     Succeeded" show-status  cr  ( )
   then                                 ( )
;

: map-dma  ( -- )
   dma-mem-va >physical dup  /dma-mem map-sections
;
: selftest  ( -- error? )
   map-dma

   false to mem-fail?

   " available" get-my-property  if
      ." No available property in memory node" cr
      true exit
   then                                ( adr len )

   begin  dup  while                   ( adr len )
      2 decode-ints swap               ( adr len this-len r: this-padr )
      2dup .chunk                      ( adr len this-len r: this-padr )
      test-mem                         ( adr len )
      mem-fail?  if                    ( adr len )
         2drop true exit               ( -- error? )
      then                             ( adr len )
   repeat                              ( adr len )
   2drop                               ( )

   test-s3                             ( error? )
;

device-end

: memtest  ( -- )
   true to diag-switch?
   1  begin                       ( pass# )
      ." Pass " dup .d  cr  1+    ( pass# )
      " /memory" test-dev         ( pass# )
   key? until                     ( pass# )
   key drop                       ( pass# )
   drop                           ( )
;
