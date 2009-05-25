purpose: Methods for the root node using MIPS Kseg address translation
\ See license at end of file

: root-map-in  ( phys len -- virt )
   " /" " map-in" execute-device-method drop
;
: root-map-out  ( virt len -- )
   " /" " map-out" execute-device-method drop
;

dev /
extend-package

[ifdef] 2-cell-rootnode  2  [else]  1  [then]
encode-int  " #address-cells"  property

0 0 encode-bytes
   h# 8000.0000 encode-int encode+	\ Base address
[ifdef] 2-cell-rootnode
   0 encode-int encode+
[then]
   h# 0200.0000 encode-int encode+	\ Size
" dma-ranges" property

hex
headers

\ Static methods
: decode-unit  ( adr len -- phys )
   push-hex
[ifdef] 2-cell-rootnode
   $dnumber?  case
      0  of  0.  endof
      1  of  0   endof
      2  of      endof
   endcase
[else]
   $number  if  0  then
[then]
   pop-base
;
: encode-unit  ( phys -- adr len )
   push-hex
[ifdef] 2-cell-rootnode
   <# #s #>
[else]
   (u.)
[then]
   pop-base
;

\ Not-necessarily-static methods
: open  ( -- true )  true  ;
: close  ( -- )  ;

: map-in   ( phys size -- virt )
   drop                                 ( phys.low phys.high )
[ifdef] 2-cell-rootnode
   0= over h# 2000.0000 u>=  or
[else]
   dup h# 2000.0000 u>=
[then]
   abort" Can't map addresses > (hex) 2000.0000"
   kseg1 or
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
: find-dmanode?  ( -- prev-node this-node|0 )
   dmalist ['] dma-aa=?  find-node
;
: alloc-dmanode  ( -- node )
   dmanode allocate-node dup dmalist last-node insert-after
;
: free-dmanode  ( prev -- )
   delete-after dmanode free-node
;

headers

[ifndef] prepare-dma-range
\ This is the default version, appropriate for systems without hardware
\ cache coherency between the CPU and DMA
: prepare-dma-range  ( size ua aa -- size ua dma-aa )
   over  3 pick  flush-d$-range     ( size ua aa )  \ Remove from cache
   kseg1 or
;
[then]

\ Many MIPS systems require, or at least prefer, that DMA memory is
\ aligned on cache line boundaries.
: dma-alloc  ( size -- virt )
   /cache-line + /cache-line round-up dup ( size' size' )
   alloc-mem                              ( size ua )
   dup /cache-line round-up               ( size ua aa )
   prepare-dma-range                      ( size ua dma-aa )
   dup >r				  ( size ua aa ) ( R: aa )
   alloc-dmanode			  ( size ua aa node ) ( R: aa )
   tuck >dma-aa !			  ( size ua node ) ( R: aa )
   tuck >dma-ua !			  ( size node ) ( R: aa )
   >dma-len !				  ( )  ( R: aa )
   r>
;
: dma-free  ( virt size -- )
   over to dma-aa find-dmanode? dup  if
      dup >dma-ua @ swap >dma-len @ free-mem
      free-dmanode  2drop
   else
      2drop free-mem
   then
;
: dma-map-in  ( virt size cacheable -- devaddr )
   drop  2dup pcicache-wbinv
   drop h# 1fff.ffff and
   [ifdef] 2-cell-rootnode  0  [then]
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

\ LICENSE_BEGIN
\ Copyright (c) 2009 FirmWorks
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
