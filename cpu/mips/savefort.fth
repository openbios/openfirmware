purpose: Save dictionary to a file for MIPS
\ See license at end of file

\ save-forth  ( filename -- )
\	Saves the Forth dictionary to a file so it may be later used under Unix
\
\ save-image  ( header-adr header-len init-routine-name filename -- )
\	Primitive save routine.  Saves the dictionary image to a file.
\	The header is placed at the start of the file.  The latest definition
\	whose name is the same as the "init-routine-name" argument is
\	installed as the init-io routine.

only forth also hidden also  forth definitions

headerless
: swap-size  ( -- n )  here  >swap-map-size  ;

\needs lbflip   : lbflip  ( l1 -- l2 )  lbsplit swap 2swap swap bljoin  ;
variable swap-temp
: swap-lput  ( adr -- )
   l@ lbflip swap-temp l!
   swap-temp  4 ofd @ fputs
;
: swap-fputs  ( adr len -- )  bounds  ?do  i swap-lput  4 +loop  ;
: ?swap-fputs  ( adr len -- )
   3 + 2 >>  0  ?do              ( adr )
      dup i la+                  ( adr adr' )
      i swap-map bittest  if     ( adr adr' )
         4 ofd @ fputs           ( adr )
      else                       ( adr adr' )
         swap-lput               ( adr )
      then                       ( adr )
   loop                          ( adr )
   drop
;

false value swapped-save?
: save-image  ( header header-len init-routine-name filename -- )
   $new-file

   ( header header-len init-routine-name )

   init-save

   swapped-save?  if
      ( header header-len )  swap-fputs		\ Write header
      origin   text-size     ?swap-fputs	\ Write dictionary
      up@      user-size     swap-fputs		\ Write user area
   else
      ( header header-len )  ofd @  fputs	\ Write header
      origin   text-size     ofd @  fputs	\ Write dictionary
      up@      user-size     ofd @  fputs	\ Write user area
   then
   swap-map swap-size     ofd @  fputs		\ Write swap map
   ofd @ fclose
;
headers

0 value growth-size

: make-bin-header  ( -- )
   10000007    h_magic l!	\ This is a   ba,a .+0x20   instruction
   text-size   h_tlen  l!       \ Set the text size in program header
   user-size   h_dlen  l!       \ Set the data size in program header
   growth-size h_blen  l!       \ Set the bss size in program header
   0           h_slen  l!       \ Set the symbol size in program header
   origin      h_entry l!       \ Set the current starting address
   swap-size   h_trlen l!       \ Set the relocation size
;

\ Save an image of the target system in a file.
: $save-forth  ( str -- )
   8 (align)			\ Make sure image is 8 byte aligned

   2>r

   make-bin-header

   bin-header  /bin-header  " sys-init" 2r>  save-image
;
: $save-forth-swapped  ( str -- )
   true to swapped-save?
   $save-forth
   false to swapped-save?
;
: save-forth  ( str -- )  count $save-forth  ;

only forth also definitions

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
