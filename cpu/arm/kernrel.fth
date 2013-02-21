purpose: Maintains a bitmap identifying longwords that need to be relocated 
\ See license at end of file

\ h# 8.0000 equ      max-image
h# 20.0000 constant max-image

0 value relocation-map

\ The relocation map has one bit for every 32-bit word, since we assume
\ that relocated longwords must start on a 32-bit boundary

\ If the address is within the new part of the dictionary (between
\ relocation-base  and  relocation-base + max-image), set the corresponding
\ bit in relocation-map.  If the address is within the user area,
\ (between  up@  and  up@ + #user), set the corresponding bit in
\ user-relocation-map

: >relbit  ( adr -- bit# array )  origin - /l /  relocation-map  ;

\ This has to be deferred so it can be turned off until the relocation
\ table has been initialized.

defer set-relocation-bit        ' noop is set-relocation-bit
defer clear-relocation-bits     ' 2drop is clear-relocation-bits
: (set-relocation-bit  ( adr -- adr )
   dup  origin  dup max-image + within  if   ( adr )
      dup >relbit bitset
   then
;
: (clear-relocation-bits  ( adr len -- )
   bounds ?do  i >relbit bitclear  /n +loop
;

: relocation-on  ( -- )
   ['] (set-relocation-bit     ['] set-relocation-bit    (is 
   ['] (clear-relocation-bits  ['] clear-relocation-bits (is
;
: relocation-off  ( -- )
   ['] noop   ['] set-relocation-bit    (is
   ['] 2drop  ['] clear-relocation-bits (is
;

: init-relocation  ( -- )  \ Allocate relocation map
   max-image d# 32 /       ( #map-bytes )
   dup alloc-mem           ( #map-bytes adr )
   is relocation-map       ( #map-bytes )
   relocation-map swap erase
   here  relocation-map
   origin h# 10 + l@   h# 1f +  5 rshift  move

   \ Now that the table is set up, set-relocation-bit may be turned on
   relocation-on
;

: set-swap-bit  ( addr -- )  drop  ;
: note-string ( adr len -- adr len )  ;
decimal

\ LICENSE_BEGIN
\ Copyright (c) 1997 FirmWorks
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
