purpose: Save the Forth dictionary to a file
\ See license at end of file

\ $save-forth  ( filename$ -- )
\	Saves the Forth dictionary to a file so it may be later used under Unix
\
\ $save-image  ( header-adr header-len filename$ -- )
\	Primitive save routine.  Saves the dictionary image to a file.
\	The header is placed at the start of the file.  The latest definition
\	whose name is the same as the "init-routine-name" argument is
\	installed as the init-io routine.

only forth also hidden also  forth definitions


headerless
: swap-size  ( -- n )  here  >swap-map-size  ;
: be-lput  ( adr -- )
   l@ lbsplit  ofd @ fputc  ofd @ fputc  ofd @ fputc  ofd @ fputc
;
: be-fputs  ( adr len -- )  bounds  ?do  i be-lput  4 +loop  ;
: ?be-fputs  ( adr len -- )
   3 + 2 >>  0  ?do              ( adr )
      dup i la+                  ( adr adr' )
      i swap-map bittest  if     ( adr adr' )
         4 ofd @ fputs           ( adr )
      else                       ( adr adr' )
         be-lput                 ( adr )
      then                       ( adr )
   loop                          ( adr )
   drop
;
: $save-image  ( header header-len filename$ -- )
   ['] ($find-next) is $find-next

   $new-file   ( header header-len )
   in-little-endian?  if
       ( header header-len )  be-fputs		\ Write header
       origin   text-size     ?be-fputs		\ Write dictionary
       up@      user-size     be-fputs		\ Write user area
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
   h# 48000020 h_magic l!	\ This is a   b .+0x20   instruction
   text-size   h_tlen  l!       \ Set the text size in program header
   user-size   h_dlen  l!       \ Set the data size in program header
   growth-size h_blen  l!       \ Set the bss size in program header
   0           h_slen  l!       \ Set the symbol size in program header
   origin      h_entry l!       \ Set the current starting address
   swap-size   h_trlen l!       \ Set the relocation size
   0           h_drlen l!       \ Set the data relocation size
;

\ Save an image of the target system in a file.
: $save-forth  ( name$ -- )
   8 (align)			\ Make sure image is 8 byte aligned

   2>r

   make-bin-header

   " sys-init-io" $find-name is init-io
   " sys-init"  init-save
   bin-header  /bin-header  2r>  $save-image
;

only forth also definitions

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
