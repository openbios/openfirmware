\ See license at end of file

\ Transient vocabulary disposal
\
\ This file (and also headless.fth) may be compiled within 'transient'
\ in order to save space.  If this is done, however, only ONE 'dispose'
\ is possible.
\
\ Multiple 'start-module' - 'end-module' cycles are still allowed.
\ Nested modules are allowed.
\
\ dispose   ( -- )	Throw away the transient dictionary and
\	reclaim its space.  Names are saved in the 'headers' file.
\
\ start-module  ( -- here there magic# )    Mark the start of a module.
\
\ end-module  ( oldhere oldthere magic# -- ) The end of a module.  The heads
\	of all headerless words within the module are immediately tossed.

decimal

\ File output primitives
variable header:?   \ If true, output 'header:' else output 'headerless:'
: ftype  ( adr len -- )  ofd @ fputs  ;
: f.acf  ( anf acf  -- )
   " h# " ftype
   origin-  (.)   ( adr len )
   5 over - 0 max  0 ?do  ascii 0 ofd @ fputc loop  ( adr len )
   ftype
   header:? @  if  "  header: "  else  "  headerless: "  then
   ftype
;
: fcr  ( -- )  linefeed ofd @ fputc  ;

: open-headerfile  ( -- )  " headers" $append-open  ;
: close-headerfile ( -- )  fcr fcr ofd @ fclose  ;

: alias?  ( anf -- alias? )  n>flags c@  32 and  ;
: new-name>  ( anf -- acf )     \ Handles alias properly
   dup name>  swap   ( acf anf )
   alias?  if  token@  then
;

: f.immediate ( anf -- )  n>flags c@  64 and  if  "  immediate" ftype  then  ;

: f.name  ( anf acf -- )  fcr  f.acf  dup name>string ftype f.immediate  ;

: ..name  ( acf -- )  \ Print acf and name
   dup >name swap  f.name
;

defer link.  ( link -- )  \ Different links are printed differently
: showit  ( alf -- )
   link.  #out @ 65 >  if  cr  2 spaces  then
;

defer item@  ( this-item -- next-item )
defer item!  ( data-item addr-item -- )
\ ITEMS are alf's for word (thread searches)
\ ITEMS are links for buffer: and vocab
\ ITEMS are acf's for (cold

0 value resboundary   \ Lower boundary of region to dispose
0 value tranboundary

: transient-item?  ( item -- transient? )
   tranboundary there within
;
: resident-item?  ( item -- resident? )
   origin >link resboundary within
;
: safe-transient-item?  ( item -- safe-transient? )
   transtart tranboundary within
;

\ relink removes transients from any linked list. It must be called
\ with a known good first link, as it doesn't know how to reset
\ the head of the list, which is usually a global variable.
: relink  ( first-link -- )
   begin       ( good-link )  
      \ Skip over all consecutive words in the transient vocabulary
      dup
      begin   ( prev-item this-item )
         item@  dup transient-item? ( prev-item next-item tran? )
         dup if  over showit  then
      0= until       ( prev-item next-kept-item )
      \ Link the next non-transient word to the previous non-transient one
      dup rot  item!             ( next-kept-item )
      dup resident-item?         ( next-kept-item resident? )
      over safe-transient-item?  ( next-kept-item resident? safe-transient? )
      or
   until   drop
;

: word.  ( alf -- )  l>name ( anf ) dup new-name> f.name  ;
: word-link@ ( alf -- alf' )  link@ >link  ;
: word-link! ( alf1 alf2 -- ) swap link> swap link!  ;
: relink-voc  ( voc-acf -- )  \ Follow and relink threads in this vocab.
   >threads  #threads /link *  bounds  do  i relink  /link +loop
;
: relink-words  ( -- )
   ['] word-link@ is item@  ['] word-link! is item!  ['] word. is link.
   voc-link  begin  another-link?   while  dup voc> relink-voc >voc-link repeat
;

: buffer:.  ( acf -- )  \ buffer: pfa = user#, size, link-to-prev-buffer:
   ..name  "  ( buffer: )" ftype
;
: buf-link! ( link adr -- )  >buffer-link link!  ;
: buf-link@ ( adr -- link )  >buffer-link link@  ;
: relink-buffer:s  ( -- )
   ['] buf-link@ is item@  ['] buf-link! is item!  ['] buffer:. is link.
   buffer-link begin			\ Check for transient at head
      link@ dup transient-item?
   while
      dup showit  >buffer-link
   repeat  buffer-link link!
   buffer-link link@  relink
;

: vocab.  ( voclink -- )  \ vocab pfa = user#, link-to-prev-vocab
   ..name   "  ( vocabulary )" ftype
;
: voc-link! ( link adr -- )  >voc-link link!  ;
: voc-link@ ( adr -- link )  >voc-link link@  ;
: relink-voc-list  ( -- )
   ['] voc-link@ is item@  ['] voc-link! is item!  ['] vocab. is link.
   voc-link begin			\ Check for transient at head
      link@ dup transient-item?
   while
      dup showit  >voc-link
   repeat  voc-link link!
   voc-link link@ relink
;

: (cold.  ( acf -- )  \ (cold pfa = prev-(cold-cfa, content-cfa, ...
\    ."  initialization word containing: "  >body  /token +  token@  ..name
\    dup ..name  "  ( containing: " ftype
\    >body  /token +  token@  ..name  "  )" ftype
   ..name
;
: cold@  ( acf -- next-acf )  >body token@  ;
: cold!  ( next-acf acf -- )  >body token!  ;

: relink-init-chain  ( str -- )  $find  if  relink  else  2drop  then  ;
: relink-init-chains  ( -- )
   ['] (cold. is link.   ['] cold@ is item@   ['] cold! is item!
   " init"              relink-init-chain
\  " unix-init"         relink-init-chain
\  " unix-init-io"      relink-init-chain
\  " stand-init"        relink-init-chain
\  " stand-init-io"     relink-init-chain
   " (cold-hook"        relink-init-chain
;

defer relink-hook  ' noop is relink-hook

: unlink-all  ( resboundary tranboundary -- )
   is tranboundary   is resboundary
   header:? off      \ Dump using 'headerless:', not 'header:'
   resident    \ Just to be sure

   base @ >r hex
   open-headerfile
   relink-buffer:s
   relink-voc-list
   relink-init-chains
   relink-words
   relink-hook
   close-headerfile
   r> base !

   tranboundary is there
;

: dispose  ( -- )  \ Dispose transient, and save names of words tossed
\ Lower res. bound is start of 'transien.fth' package
   ['] there transtart unlink-all
;

hex fe1f constant magic#
decimal

: start-module  ( -- here there magic# )  here there magic#  ;

: end-module  ( oldhere oldthere magic# -- )
   magic# <> abort" illegal stack for end-module"
\ module debugging (can't use [ifdef] here because it's not defined yet)
\   base @ >r hex
\   ." here=" here .  ." there=" there . cr
\   ." transtart=" transtart . ." transize=" transize . cr
\   ." oldhere=" over .  ." oldthere=" dup .  cr
\   r> base !
   ( oldhere oldthere ) unlink-all
;

[ifdef] delete-file  " headers" delete-file  drop  [then]
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
