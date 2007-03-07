\ See license at end of file
\ Relocation table.  
\ Keeps a bitmap identifying longwords that need to be relocated
\ if they are saved to a file.

hex
: max-image  ( -- #bytes )  memtop @  origin -  ;

nuser 'relocation-map
: relocation-map  ( -- adr )  'relocation-map @  ;

\ The relocation map has one bit for every 16-bit word, since we assume
\ that relocated longwords must start on a 16-bit boundary

\ If the address is within the new part of the dictionary (between
\ relocation-base  and  relocation-base + max-image), set the corresponding
\ bit in relocation-map.  If the address is within the user area,
\ (between  up@  and  up@ + #user), set the corresponding bit in
\ user-relocation-map

: >relbit  ( addr -- bit# array )   origin - 2/  relocation-map  ;

\ This has to be deferred so it can be turned off until the relocation
\ table has been initialized.
defer set-relocation-bit
defer clear-relocation-bits
' noop is set-relocation-bit
' 2drop is clear-relocation-bits
: (set-relocation-bit ( addr -- addr )
   dup  origin  dup max-image + within   ( addr relocatable? )
   if  dup  >relbit  bitset   then
;
: (clear-relocation-bits  ( adr len -- )
   bounds ?do  i >relbit bitclear  /w +loop
;
hex

: relocation-on  ( -- )
   ['] (set-relocation-bit     ['] set-relocation-bit    (is 
   ['] (clear-relocation-bits  ['] clear-relocation-bits (is 
;
: init-relocation  ( -- )		\ Allocate relocation map

\   max-image 2/ 8 /			( #map-bytes )
\   dup alloc-mem			( #map-bytes addr )
   memtop @ 1c + 		\ the loader has copied the relocation map
   'relocation-map !			( #map-bytes )
\   relocation-map swap 0 fill

   \ Copy in the initial relocation map
\   here  relocation-map  ( origin 20 - 18 + l@ )
\   over origin - 0f + 4 >>  move

   \ Now that the table is set up, set-relocation-bit may be turned on
   relocation-on
;
: relocation-off  ( -- )
   ['] noop  ['] set-relocation-bit  >body >user
   !	\ XX version-dependent
   ['] 2drop  ['] clear-relocation-bits  >body >user
   !	\ XX version-dependent
;
decimal

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
