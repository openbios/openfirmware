purpose: Aligned dma aligned alloc and free
\ See license at end of file

hex
headers

d# 256 constant /align256
d#  16 constant /align16
d#  32 constant /align32

: round-up  ( n align -- n' )  1- tuck + swap invert and  ;

external
: dma-push     ( virt phys size -- )         " dma-push" $call-parent     ;
: dma-pull     ( virt phys size -- )         " dma-pull" $call-parent     ;
: dma-alloc    ( size -- virt )              " dma-alloc" $call-parent    ;
: dma-free     ( virt size -- )              " dma-free" $call-parent     ;
: dma-map-in   ( virt size cache? -- phys )  " dma-map-in" $call-parent   ;
: dma-map-out  ( virt phys size -- )         " dma-map-out" $call-parent  ;

headers

: aligned-alloc  ( size align -- unaligned-virt aligned-virtual )
   dup >r + dma-alloc  dup r> round-up
;
: aligned-free  ( virtual size align -- )  + dma-free  ;

: aligned16-alloc  ( size -- unaligned-virt aligned-virtual )
   /align16 aligned-alloc
;
: aligned16-free  ( virtual size -- )
   /align16 aligned-free
;

: aligned16-alloc-map-in  ( size -- unaligned-virt aligned-virt phys )
   dup >r aligned16-alloc
   dup r> true dma-map-in
;
: aligned16-free-map-out  ( unaligned virt phys size -- )
   dup >r dma-map-out
   r> aligned16-free
;

: aligned32-alloc  ( size -- unaligned-virt aligned-virtual )
   /align32 aligned-alloc
;
: aligned32-free  ( virtual size -- )
   /align32 aligned-free
;

: aligned32-alloc-map-in  ( size -- unaligned-virt aligned-virt phys )
   dup >r aligned32-alloc
   dup r> true dma-map-in
;
: aligned32-free-map-out  ( unaligned virt phys size -- )
   dup >r dma-map-out
   r> aligned32-free
;

: aligned256-alloc  ( size -- unaligned-virt aligned-virtual )
   /align256 aligned-alloc
;
: aligned256-free  ( virtual size -- )
   /align256 aligned-free
;

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
