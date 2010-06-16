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

hex

\ Static methods
: decode-unit  ( adr len -- phys )  push-hex  $number  if  0  then  pop-base  ;
: encode-unit  ( phys -- adr len )  push-hex  (u.)  pop-base  ;

\ Not-necessarily-static methods
: open  ( -- true )  true  ;
: close  ( -- )  ;

: map-in   ( phys size -- virt )
   drop
;
: map-out  ( virtual size -- )
   2drop
;

: dma-alloc  ( size -- virt )  alloc-mem  ;
: dma-free   ( virt size -- )  free-mem  ;

: dma-map-in   ( virt size cacheable -- devaddr )
   drop   2dup flush-d$-range  drop   ( virt )
;
: dma-map-out  ( virt devaddr size -- )  nip flush-d$-range  ;

: dma-sync  ( virt devaddr size -- )  nip flush-d$-range  ;
: dma-push  ( virt devaddr size -- )  nip flush-d$-range  ;
: dma-pull  ( virt devaddr size -- )  nip flush-d$-range  ;

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
