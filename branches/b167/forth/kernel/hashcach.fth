\ See license at end of file

\ Dictionary cache to speed up "find".  Only the Forth vocabulary is
\ cached; this eliminates a lot of cache flushing and is simpler than
\ caching all vocabularies.

hex

headerless
100 /link * constant /hashcache
/hashcache buffer: hashcache


: link+  ( adr index -- adr' )
\t16 wa+
\t32 la+
;
: vhash  ( adr,len -- cache-adr )
   7 and  swap c@ 1f and  3 <<  +  hashcache swap  link+
;
: match?  ( adr len cache-adr  -- flag )
   another-link?   if     ( adr len acf )
      >name name>string   ( adr len adr2,len2 )
      2swap               ( nameadr,len stradr,len )
      rot                 ( nameadr stradr slen nlen )
      over =  if          ( nadr sadr slen )
	 comp 0=
      else                ( nadr sadr slen )
	 3drop false
      then
   else                   ( adr len )
      2drop false
   then
;

headers
: clear-hashcache  ( -- )
   hashcache  /hashcache bounds  ?do  i !null-link  /link +loop
;
headerless
clear-hashcache
: init  ( -- )  init clear-hashcache  ;

: probe-cache  ( adr len voc-acf -- find-results )
   dup ['] forth =  if               ( adr len voc-acf )
      drop 2dup vhash                ( adr len cache-adr )
      3dup match?  if                ( adr len cache-adr )
	 link@ >link true            ( adr len alf true )
      else                           ( adr len adr2 )
	 >r                          ( adr len )
	 ['] forth >threads  $find-next  if   ( adr len alf )
	    r> over link> swap link!  true    ( adr len alf true)
	 else                                 ( adr len )
	    r> drop false                     ( adr len false )
	 then                            ( adr len false | adr len alf true )
      then
      find-fixup                              ( find-results )
      r> drop exit
   then
   >first                                     ( find-results )
;

: forth?  ( -- flag )  current-voc  ['] forth =  ;

: replace-entry  ( -- )  last @ name>  last @ name>string vhash  link!  ;
: clear-entry  ( -- )  last @ name>string vhash  !null-link  ;

: cached-make  ( adr len voc-acf -- )
   $create-word   forth? if  replace-entry  then
;

: cached-hide  ( -- voc-acf )  forth? if  clear-entry  then  current-voc  ;

: cached-reveal  ( -- )
   hidden-voc get-token?  if  drop forth? if  replace-entry  then  then
   hidden-voc
;

: cached-remove  ( alf acf -- alf prev-link )
   over l>name name>string vhash  !null-link  >threads
;

\ patch cached-hide current-voc hide
' cached-hide ' hide >body token!

\ patch cached-reveal hidden-voc reveal
' cached-reveal ' reveal >body token!

\ patch probe-cache >first find-word
' probe-cache ' $find-word >body token!

\ patch cached-make $create-word ("header)
' cached-make ' ($header) >body /token + token!

\ patch cached-remove >threads remove-word
' cached-remove ' remove-word >body token!

headers
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
