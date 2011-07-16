\ See license at end of file
purpose: FCode source for PCI-PCI bridge driver

headers

: my-b@  ( offset -- b )  my-space +  " config-b@" $call-parent  ;
: my-b!  ( b offset -- )  my-space +  " config-b!" $call-parent  ;
: my-w@  ( offset -- w )  my-space +  " config-w@" $call-parent  ;
: my-w!  ( w offset -- )  my-space +  " config-w!" $call-parent  ;
: my-l@  ( offset -- l )  my-space +  " config-l@" $call-parent  ;
: my-l!  ( l offset -- )  my-space +  " config-l!" $call-parent  ;

0 value my-bus#

defer parent-decode-unit

: reset-bit-w  ( bit adr -- old-bit )
   dup my-w@ -rot my-w!
;

external

\ false: okay; true: either didn't find, or parent didn't find
: clear-propagated-serr#?  ( -- error? )
   1 d# 14 lshift >r
   r@ h# 1e reset-bit-w
   r@ h#  6 reset-bit-w
   and r> and 0=
   " clear-propagated-serr#?" $call-parent
   swap or
;

: allocate-bus#  ( n -- bus# next-mem next-io )
   " allocate-bus#" $call-parent
;
: decode-unit  ( adr len -- phys.lo..hi )
   parent-decode-unit lwsplit drop  my-bus# wljoin
;
defer encode-unit  ( phys.lo..hi -- adr len )

: enable-apple-hack ( -- )
   " enable-apple-hack" $call-parent
;

: mem-space-top  ( -- n )                     " mem-space-top"  $call-parent  ;
: io-space-top   ( -- n )                      " io-space-top"  $call-parent  ;
: prober-xt    ( -- xt )                         " prober-xt"   $call-parent  ;

: map-in       ( phys.low..high len -- vaddr )   " map-in"      $call-parent  ;
: map-out      ( vaddr size -- )                 " map-out"     $call-parent  ;

: config-b@    ( offset -- b )                   " config-b@"   $call-parent  ;
: config-b!    ( b -- offset )                   " config-b!"   $call-parent  ;
: config-w@    ( offset -- w )                   " config-w@"   $call-parent  ;
: config-w!    ( w -- offset )                   " config-w!"   $call-parent  ;
: config-l@    ( offset -- l )                   " config-l@"   $call-parent  ;
: config-l!    ( l -- offset )                   " config-l!"   $call-parent  ;

headers

: parent-phandle  ( -- phandle )  my-parent ihandle>phandle  ;

d# 9  constant /int-mapb-entry-cells   \ size of int-mapb-entry in cells
d# 16 constant #int-mapb-entries       \ same as # of slots prober-xt uses
#int-mapb-entries /int-mapb-entry-cells cells * constant /int-mapb  \ tot bytes

\ int-mapb holds the accumulation " interrupt-map " property
0 value  int-mapb                    \ Holds address of interrupt-map array
0 value  int-mapc                    \ Holds # of filled components in int-mapb

: start-interrupt-map  ( -- )
   /int-mapb alloc-mem               \ allocate memory for holding array
   to int-mapb 0 to int-mapc
;

: +int  ( adr len n -- adr' len' )  encode-int encode+  ;
: 0+int  ( adr len -- adr' len' )  0 +int  ;

: finish-interrupt-map  ( -- )
   0 0 encode-bytes
   int-mapc /int-mapb-entry-cells * 0 ?do
      int-mapb i cells + @ +int
   loop
   ?dup if
      " interrupt-map" property
      1 encode-int  " #interrupt-cells" property
      h# f800 encode-int  0+int  0+int  7 +int  " interrupt-map-mask" property
   else
      drop
   then
   int-mapb /int-mapb free-mem
;

: int-mapb-adr+  ( -- adr )
   int-mapc #int-mapb-entries >= if ." int-mapb overflow" cr abort then
   int-mapb int-mapc /int-mapb-entry-cells cells * +
;
: +int-ent  ( addr entry -- addr )  over ! cell+  ;

\ Add one full entry to int-mapb
: add-interrupt-map-entry  ( p-pin# c-pin# c-space -- )
   h# f800 and                                 ( p-pin# c-pin# c-space')
   int-mapb-adr+                               ( p-pin# c-pin# c-space' addr )
   swap +int-ent                               ( p-pin# c-pin# addr )
   0 +int-ent  0 +int-ent  swap +int-ent       ( p-pin# addr )
   parent-phandle +int-ent                     ( p-pin# addr )
   my-space h# f800 and +int-ent               ( p-pin# addr )
   0 +int-ent  0 +int-ent  swap +int-ent       ( addr )
   drop  int-mapc 1+ to int-mapc               ( )
;

external

: assign-int-line  ( child-space child-int-pin# -- false | irq true )
   over d# 11 rshift h# 1f and     ( c-space c-pin# child-slot# )
   over + 1- 4 mod 1+              ( c-space c-pin# my-int-pin# )
   dup 2swap swap                  ( my-int-pin# my-int-pin# c-pin# c-space )
   add-interrupt-map-entry         ( my-int-pin# )
   my-space swap                   ( my-phys.hi.func my-int-pin# )
   " assign-int-line" $call-parent
;

: assign-pci-addr  ( phys.lo phys.mid phys.hi len -- phys.hi paddr actual-len )
   " assign-pci-addr" $call-parent
;

: dma-alloc    ( size -- vaddr )                 " dma-alloc"   $call-parent  ;
: dma-free     ( vaddr size -- )                 " dma-free"    $call-parent  ;
: dma-map-in   ( vaddr size cache? -- devaddr )  " dma-map-in"  $call-parent  ;
: dma-map-out  ( vaddr devaddr size -- )         " dma-map-out" $call-parent  ;
: dma-push     ( vaddr devaddr size -- )         " dma-push"    $call-parent  ;
: dma-pull     ( vaddr devaddr size -- )         " dma-pull"    $call-parent  ;
: dma-sync     ( vaddr devaddr size -- )         " dma-sync"    $call-parent  ;

: make-function-properties  ( child-ihandle -- )
   " make-function-properties" $call-parent
;

: open  ( -- okay? )  true  ;
: close  ( -- )  ;

headers

: +range-entry  ( adr len base limit type -- adr' len' )
   swap >r 2swap                             ( base type adr  len  r: limit )
   2over 0 swap encode-phys encode+          ( base type adr' len' r: limit )
   2over 0 swap encode-phys encode+          ( base type adr' len' r: limit )
   0 encode-int encode+                      ( base type adr' len' r: limit )
   2swap drop  r> swap - encode-int encode+  ( adr' len' )
;

\ decode-unit and encode-unit must be static methods, so they can't use
\ $call-parent at run-time

" decode-unit" parent-phandle find-method drop  ( xt ) to parent-decode-unit
" encode-unit" parent-phandle find-method drop  ( xt ) to encode-unit

: assign-addresses?  ( -- flag )
\   " addresses-preassigned"  my-parent ihandle>phandle get-package-property  if
   " addresses-preassigned"  get-inherited-property  if
      \ Property not present
      true
   else                ( propval$ )
      \ Property present
      2drop false
   then
;
: prefetch-ranges-off  ( -- )
   \ Turn off prefetchable memory forwarding range
   h# 0000ffff  h# 24 my-l!	\ Prefetchable Limit,Base
   h# ffffffff  h# 28 my-l!	\ Prefetchable Base upper 32 bits
   h#        0  h# 2c my-l!	\ Prefetchable Limit upper 32 bits
;
: io-base@  ( -- base )
   0 h# 1c my-b@  bwjoin  h# 30 my-w@  wljoin
;
: io-base!  ( base -- )
   lwsplit  h# 30 my-w!  wbsplit  h# 1c my-b!  drop
;
: io-limit@  ( -- limit+1 )
   0 h# 1d my-b@  bwjoin  h# 32 my-w@  wljoin  1+
;
: io-limit!  ( limit+1 -- )
   1- lwsplit  h# 32 my-w!  wbsplit  h# 1d my-b!  drop
;
: mem-base@  ( -- base )  0  h# 20 my-w@ wljoin  ;
: mem-base!  ( base -- )  lwsplit  h# 20 my-w!  drop  ;
: mem-limit@  ( -- limit+1 )   0  h# 22 my-w@ wljoin  1+  ;
: mem-limit!  ( limit+1 -- )   1- lwsplit  h# 22 my-w!  drop  ;
: pri-bus!  ( bus# -- )  h# 18 my-b!  ;
: pri-bus@  ( -- bus# )  h# 18 my-b@  ;
: sec-bus!  ( bus# -- )  h# 19 my-b!  ;
: sec-bus@  ( -- bus# )  h# 19 my-b@  ;
: bus-limit!  ( bus# -- )  h# 1a my-b!  ;
: bus-limit@  ( -- bus# )  h# 1a my-b@  ;

: make-ranges-property  ( -- )
   0 0 encode-bytes
   io-base@  io-limit@  h# 8100.0000 +range-entry
   mem-base@ mem-limit@ h# 8200.0000 +range-entry
   " ranges" property
;

\ Paranoia, perhaps justified
: disable-children  ( -- )
   my-bus# d# 16 lshift  4 +   ( template )
   h# 8000 bounds  do  0 i  " config-w!" $call-parent  h# 800 +loop
;

7 value my-bridge-modes

: set-bridge-registers  ( -- )
   \ Turn off memory and I/O response and bus mastership while setting up
   0 4 my-w!

   \ Reset secondary bus
   h# 3e my-b@  dup h# 40 or  h# 3e my-b!
   h# 40 invert and  h# 3e my-b! 

   my-space  d# 16 rshift h# ff and         pri-bus!  \ Primary bus#
   1 " allocate-bus#" $call-parent  rot dup sec-bus!  \ Secondary bus#
   to my-bus#
   ( next-mem next-io )

   \ Set the subordinate bus number to ff in order to pass through any
   \ type 1 cycle with a bus number higher then the secondary bus#
   h# ff bus-limit!               ( next-mem next-io )
   disable-children               ( next-mem next-io )
   over mem-base!  dup io-base!   ( next-mem next-io )

   \ Initially set the limits to encompassing the rest of the address space
   2drop  mem-space-top mem-limit!  io-space-top io-limit!

   \ Clear status bits
   h# ffff  h# 1e my-w!      ( )

   prefetch-ranges-off

   \ Enable memory, IO, and bus mastership
   \ To enable parity, SERR#, fast back-to-back, and address stepping
   \ rebind the (global) value bridge-modes.
   " bridge-modes" $find  if  execute  else  2drop my-bridge-modes  then
   4 my-w@  or  4 my-w!     ( )
;
: reduce-bridge-limits  ( -- )
   \ Reduce the subordinate bus# to the maximum bus number of any of
   \ our children, and the memory and IO forwarding limits to the
   \ limits of the address space actually allocated.
   0 " allocate-bus#" $call-parent  rot bus-limit!   ( final-mem final-io )
   io-limit!  mem-limit!
;
: setup-bridge  ( -- )
   " pci" device-name

   " pci" encode-string  " device_type"  property

   0 0 my-space  encode-phys  0 encode-int encode+  0 encode-int encode+
   " reg" property

   2 encode-int " #size-cells" property
   3 encode-int " #address-cells" property

   start-interrupt-map

   assign-addresses?  if
      set-bridge-registers
   else
      sec-bus@ to my-bus#
      0 0 " addresses-preassigned" property
   then

\ [ifdef] firepower
\ \ The IBM bridge is somewhat funny
\ 0 my-l@ h# 221014 =  if  h# 22 h# 3e my-b!  then
\ [then]

   \ XXX set cache line size in the register at 0c
   \ XXX latency timer in the register at 0d
   \ XXX set secondary latency timer in the register at 1b

   " 0,1,2,3,4,5,6,7,8,9,a,b,c,d,e,f" prober-xt execute

   assign-addresses?  if  reduce-bridge-limits  then

   make-ranges-property

   finish-interrupt-map

   my-bus#  encode-int  bus-limit@  encode-int encode+
   " bus-range"  property
;
setup-bridge

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
