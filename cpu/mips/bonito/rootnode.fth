purpose: Methods for the root node using Bonito Kseg address translation
copyright: Copyright 1998-2001 Firmworks  All Rights Reserved

: root-map-in  ( phys len -- virt )
   " /" " map-in" execute-device-method drop
;
: root-map-out  ( virt len -- )
   " /" " map-out" execute-device-method drop
;

dev /
extend-package

1 encode-int  " #address-cells"  property

0 0 encode-bytes
   \  Base address                     size
   h# 8000.0000 encode-int encode+  h# 0200.0000 encode-int encode+
" dma-ranges" property

hex
headers

\ Static methods
: decode-unit  ( adr len -- phys )  push-hex  $number  if  0  then  pop-base  ;
: encode-unit  ( phys -- adr len )  push-hex  (u.)  pop-base  ;

\ Not-necessarily-static methods
: open  ( -- true )  true  ;
: close  ( -- )  ;

: map-in   ( phys size -- virt )
   drop  dup 1000.0000 u<  if
      bfd0.0000  or
   else
      dup 8000.0000 u< if  h# b000.0000 or  then
   then
; 
: map-out  ( virtual size -- )  2drop  ;

headerless
list: dmalist
listnode
   /n field >dma-ua		\ address obtained from alloc-mem, unaligned
   /n field >dma-aa		\ address passed on to caller, cache-line aligned
   /n field >dma-len		\ original length used to alloc-mem
nodetype: dmanode

0 dmalist !
0 dmanode !
0 value dma-aa

: dma-aa=?  ( node -- aa=? )
   >dma-aa @ dma-aa =
;
: find-dmanode?  ( -- prev-node this-node | 0 )
   dmalist ['] dma-aa=?  find-node
;
: alloc-dmanode  ( -- node )
   dmanode allocate-node dup dmalist last-node insert-after
;
: free-dmanode  ( prev -- )
   delete-after dmanode free-node
;

headers

\ DMA memory is accessed via kseg1 on a cache line boundary in integral # of cache lines
: dma-alloc  ( size -- virt )
   /cache-line + /cache-line round-up dup ( size' size' )
   alloc-mem 2dup swap flush-d$-range 	( size ua )
   dup /cache-line round-up kseg1 or	( size ua aa )
   dup >r				( size ua aa ) ( R: aa )
   alloc-dmanode			( size ua aa node ) ( R: aa )
   tuck >dma-aa !			( size ua node ) ( R: aa )
   tuck >dma-ua !			( size node ) ( R: aa )
   >dma-len !				( )  ( R: aa )
   r>
;
: dma-free  ( virt size -- )
   over to dma-aa find-dmanode? ?dup  if
      dup >dma-ua @ swap >dma-len @ free-mem
      free-dmanode  2drop
   else
      free-mem
   then
;
: dma-map-in  ( virt size cacheable -- devaddr )
   drop 2dup pcicache-wbinv
   drop h# 1fff.ffff and
;
: dma-map-out  ( virt devaddr size -- )  pcicache-wbinv drop  ;
: dma-sync  ( virt devaddr size -- )  pcicache-wbinv drop  ;
: dma-push  ( virt devaddr size -- )  pcicache-inv drop  ;
: dma-pull  ( virt devaddr size -- )  pcicache-wbinv drop  ;

finish-device

device-end

headerless
\ Call this after the system-mac-address is determined, which is typically
\ done near the end of the probing process.
: set-system-id  ( -- )
   system-mac-address  dup  if        ( adr 6 )
      " /" find-device                ( adr 6 )

      \ Convert the six bytes of the MAC address into a string of the
      \ form 0NNNNNNNNNN, where N is an uppercase hex digit.
      push-hex                        ( adr 6 )

      <#  bounds  swap 1-  ?do        ( )
         i c@  u# u#  drop            ( )
      -1 +loop                        ( )
      0 u# u#>                        ( adr len )

      2dup upper                      ( adr len )  \ Force upper case

      pop-base                        ( adr len )

      encode-string  " system-id"  property   ( )

      device-end
   else
      2drop
   then
;
headers
