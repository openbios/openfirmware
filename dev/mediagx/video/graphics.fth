\ See license at end of file
purpose: Define higher-level DAC methods

\ Common graphics methods for all video drivers

hex 
headers

0 instance value graph-ver
warning @ warning off
: .driver-info  ( -- )
   .driver-info
   graph-ver . ." Graphics Code Version" cr
;
warning !

external

: default-colors  ( -- adr index #indices )
   " "(00 00 00  00 00 aa  00 aa 00  00 aa aa  aa 00 00  aa 00 aa  aa 55 00  aa aa aa  55 55 55  55 55 ff  55 ff 55  55 ff ff  ff 55 55  ff 55 ff  ff ff 55  ff ff ff)"
   0 swap 3 /
;

headerless

\ For 6-to-8 conversion, we set the low bits to the same as the high bits,
\ so that the colors are spread out evenly
: 6to8  ( 6-bit-color -- 8-bit-color )  3f and dup 2 lshift  swap 4 rshift or  ;

\ For 8-to-6 conversion, we round to nearest
: 8to6  ( 8-bit-color -- 6-bit-color )  dup 2 rshift  swap 1 rshift 1 and or  ;

external

: color>rgb  ( color -- r g b )
   dup d# 12 >> 6to8 swap
   dup d# 6  >> 6to8 swap
   6to8
;
: (color@)  ( index -- r g b )
   rindex!  plt@  color>rgb
;

: color@  ( index -- r g b )
   map-io-regs
   (color@)
   unmap-io-regs
;

: rgb>color  ( r g b -- color )
   8to6
   swap 8to6 d# 6  << or
   swap 8to6 d# 12 << or
;
: (color!)  ( r g b index -- )
   windex! rgb>color plt!
;

: color! ( r g b index -- )
   map-io-regs
   (color!)
   unmap-io-regs
;

: (set-colors)  ( adr index #indices -- )
   swap windex!
   3 *  bounds  ?do
      i c@ i 1+ c@ i 2+ c@
      rgb>color plt!
   3 +loop
;

: set-colors  ( adr index #indices -- )
   map-io-regs
   (set-colors)
   unmap-io-regs
;

: get-colors  ( adr index #indices -- )
   map-io-regs
   swap rindex!
   3 *  bounds  ?do
      plt@ color>rgb
      i 2+ c! i 1+ c! i c!
   3 +loop
   unmap-io-regs
;

headers

: set-dac-colors  ( -- )	\ Sets the DAC colors
   default-colors		\ Pull up colors
   set-colors			\ Stuff LUT in DAC
   0f (color@) ff (color!)	\ Set color ff to white (same as 15)
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
