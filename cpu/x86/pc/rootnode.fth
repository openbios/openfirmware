\ See license at end of file
purpose: Root node methods for generic PC, beyond the generic 1-cell ones

: root-map-in  ( phys len -- virt )
[ifdef] virtual-mode
   " /" " map-in" execute-device-method drop
[else]
   drop
[then]
;
: root-map-out  ( virt len -- )
[ifdef] virtual-mode
   " /" " map-out" execute-device-method drop
[else]
   2drop
[then]
;

dev /
extend-package

" Generic PC" encode-string  " banner-name" property

hex

\ Static methods
: decode-unit  ( adr len -- phys )  push-hex  $number  if  0  then  pop-base  ;
: encode-unit  ( phys -- adr len )  push-hex  (u.)  pop-base  ;

\ Not-necessarily-static methods
: open  ( -- true )  true  ;
: close  ( -- )  ;

: map-in   ( phys size -- virt )
[ifdef] virtual-mode
   over  mmu-lowbits +  pagesize round-up >r   ( phys        r: size' )
   r@ pagesize mmu-claim                       ( phys virt   r: size' )
   >r  dup mmu-highbits                        ( phys phys'  r: size' virt )
   r> r>  over >r                 ( phys  phys' virt size    r: virt )
   -1 mmu-map                                  ( phys        r: virt )
   mmu-lowbits r> +                            ( virtual )
[else]
   drop
[then]
;
: map-out  ( virtual size -- )
[ifdef] virtual-mode
   2dup mmu-unmap  mmu-release
[else]
   2drop
[then]
;

: dma-range  ( -- start end )  dma-base   dup dma-size +  ;

0 [if]  \ This is fairly useless since the DMA ranges can be dynamic
\ We hereby establish the convention that the implied "#address-cells"
\ for the (nonexistent) parent of the root node is 0, so the parent
\ address portion of the ranges property is empty.
0 0 encode-bytes
   dma-base encode-int encode+  dma-size encode-int encode+
" dma-ranges" property
[then]

\ x86 caches are coherent
h# 3 constant dma-map-mode		\ Cacheable

\ Used with "find-node" to locate a physical memory node containing
\ enough memory in the DMA range.
\ We first compute the intersection between the memory piece and the
\ range reachable by DMA.  If the regions are disjoint, then ok-high
\ will be (unsigned) less than ok-low.  We then subtract ok-low from
\ ok-high to give the (possibly negative) size of the intersection.
: in-range?  ( size mem-low mem-high range-low range-high -- flag )
   rot umin -rot              ( size min-high mem-low mem-high )
   umax                       ( size min-high max-low )
   - <=                       ( flag )
;

: dma-ok?  ( size node-adr -- size flag )
   node-range				 ( size mem-adr mem-len )
   over +                                ( size mem-adr mem-end )

   3dup dma-range in-range?  if          ( size mem-adr mem-end )
      2drop true exit                    ( size true )
   then                                  ( size mem-adr mem-end )

   2drop false                           ( size false )
;

\ Find an available physical address range suitable for DMA.  This word
\ doesn't actually claim the memory (that is done later), but simply locates
\ a suitable range that can be successfully claimed.
: find-dma-address  ( size -- true | adr false )
   " physavail" memory-node @ $call-method  	( list )
   ['] dma-ok?  find-node is next-node  drop	( size' )
   next-node 0=  if  drop true exit  then	( size' )
   next-end                                     ( size mem-end )
   dma-range                                    ( size mem-end range-l,h )
   nip umin  swap -   false		        ( adr false )
;

headers
: dma-alloc  ( size -- virt )
   pagesize round-up

   \ Locate a suitable physical range
   dup  find-dma-address  throw			( size' phys )

   \ Claim it
   over 0  mem-claim				( size' phys )

[ifdef] virtual-mode
   \ Get a virtual range
   over pagesize  mmu-claim			( size' phys virt )

   \ Map the physical and virtual ranges
   dup >r					( size' phys virt )
   rot dma-map-mode				( phys virt size' mode )
   mmu-map					( )
   r>						( virt )
[else]
   nip
[then]
;
warning off
: dma-free  ( virt size -- )
   pagesize round-up				( virt size' )
[ifdef] virtual-mode
   over mmu-translate 0= abort" Freeing unmapped dma memory"  drop
						( virt size phys )
   -rot tuck                                    ( phys size  virt size )
   2dup mmu-unmap  mmu-release			( phys size )
[then]
   mem-release					( )
;

\ We don't need to flush the cache because we map DMA memory non-cached.
: dma-map-in  ( virt size cache? -- phys )
   2drop    \ We mapped it non-cacheable above	( virt )
[ifdef] virtual-mode
   mmu-translate 0= abort" Invalid DMA address"	( phys mode )
   drop
[then]
;
: dma-map-out  ( virt phys size -- )  3drop  ;
: dma-sync     ( virt phys size -- )  3drop  ;
: dma-push     ( virt phys size -- )  3drop  ;
: dma-pull     ( virt phys size -- )  3drop  ;
warning on
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
