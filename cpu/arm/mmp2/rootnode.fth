purpose: Methods for root node
\ See license at end of file

: root-map-in  ( phys len -- virt )
   " /" " map-in" execute-device-method drop
;
: root-map-out  ( virt len -- )
   " /" " map-out" execute-device-method drop
;

dev /
extend-package

1 encode-int  " #address-cells"  property
1 encode-int  " #size-cells"  property

hex

\ Static methods
: decode-unit  ( adr len -- phys )  push-hex  $number  if  0  then  pop-base  ;
: encode-unit  ( phys -- adr len )  push-hex  (u.)  pop-base  ;

\ Not-necessarily-static methods
: open  ( -- true )  true  ;
: close  ( -- )  ;

: map-in   ( phys size -- virt )
   drop                        ( phys )
   \ The display driver uses fb-mem-va directly instead of calling map-in
   \ dup fb-mem-va >physical =  if  drop fb-mem-va exit  then   ( phys )
   dup io2-pa u>=  if          ( phys )
      io2-pa -  io2-va +       ( virt )
      exit
   then                        ( phys )
   dup io-pa u>=  if           ( phys )
      io-pa -  io-va +         ( virt )
      exit
   then                        ( phys )
   \ Fall through to return virt == phys
;
: map-out  ( virtual size -- )
   2drop
;

[ifdef] virtual-mode
h# 0 constant dma-map-mode		\ XXX what should this be?
[then]

headers
: dma-alloc  ( size -- virt )
   \ Allocate the physical memory
   dup " allocate-dma-phys" $call-mem-method	( size' phys )

[ifdef] virtual-mode
   \ Get a virtual range
   over pagesize  mmu-claim			( size' phys virt )

   \ Map the physical and virtual ranges
   dup >r					( size' phys virt )
   rot dma-map-mode				( phys virt size' mode )
   mmu-map					( )
   r>						( virt )
[else]
   nip                                          ( phys )
[ifdef] dma-mem-va
   dma-mem-va >physical -  dma-mem-va +         ( virt )
[then]
[then]
;
: dma-free  ( virt size -- )
   pagesize round-up				( virt size' )
[ifdef] virtual-mode
   over mmu-translate 0= abort" Freeing unmapped dma memory"  drop
						( virt size phys )
   -rot tuck                                    ( phys size  virt size )
   2dup mmu-unmap  mmu-release			( phys size )
[else]
[ifdef] >physical
   swap >physical swap                          ( virt )
[then]
[then]
   " free-dma-phys" $call-mem-method		( )
;

: dma-map-in   ( virt size cacheable -- devaddr )
   drop                 ( virt size )
   2dup flush-d$-range  ( virt size )
   drop                 ( virt )
[ifdef] >physical
   >physical            ( phys )
[then]
;
: dma-map-out  ( virt devaddr size -- )  nip flush-d$-range  ;

\ : dma-sync  ( virt devaddr size -- )  nip flush-d$-range  ;
\ : dma-push  ( virt devaddr size -- )  nip flush-d$-range  ;
\ : dma-pull  ( virt devaddr size -- )  nip flush-d$-range  ;
: dma-sync  ( virt devaddr size -- )  3drop  d# 30 us  ;
: dma-push  ( virt devaddr size -- )  3drop  ;
: dma-pull  ( virt devaddr size -- )  3drop  d# 30 us  ;

finish-device

device-end

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
\ Copyright (c) 2007 FirmWorks
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
