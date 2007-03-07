\ See license at end of file

\  Patch utility.  Allows you to make patches to already-defined words.
\   Usage:
\     PATCH new old word-to-patch
\         In the definition of "word-to-patch", replaces the first
\         occurence of "old" with "new".  "new" may be either a word
\         or a number.  "old" may be either a word or a number.
\
\     n-new  n-old  NPATCH  word-to-patch
\         In the definition of "word-to-patch", replaces the first
\         compiled instance of the number "n-old" with the number
\         "n-new".
\
\     n-new  n-old  start-adr  end-adr  (NPATCH
\         replaces the first occurrence of "n-old" in the word "acf"
\         with "n-new"
\
\     acf-new  acf-old  acf  (PATCH
\         replaces the first occurrence of "acf-old" in the word "acf"
\         with "acf-new"
\
\     new new-type   old old-type  acf  (PATCH)
\         replaces the first occurrence of "old" in the word "acf" with "new".
\         If "new-type" is true, "new" is a number, otherwise "new" is an acf.
\         If "old-type" is true, "old" is a number, otherwise "old" is an acf.
\
\     n  start-adr end-adr   SEARCH
\         searches for an occurrence of "n" between start-adr and
\         end-adr.  Leaves the adress where found and a success flag.
\
\     c  start-adr end-adr   CSEARCH
\         searches for a byte between start-adr and end-adr
\
\     w  start-adr end-adr   WSEARCH
\         searches for a 16-bit word between start-adr and end-adr
\
\     acf  start-adr end-adr TSEARCH
\         searches for a compiled adress between start-adr and end-adr
\
\

decimal

: csearch ( c start end -- loc true | false )
   false -rot swap  ?do			( c false )
      over i c@ = if
	 drop i swap true leave
      then
   /c +loop  nip
;
: wsearch  ( w start end -- loc true | false )
   rot n->w		\ strip off any high bits
   false 2swap  swap  ?do		( w false )
      over i w@ = if
	 drop i swap true leave
      then
   /w +loop  nip
;
: tsearch  ( adr start end -- loc true | false )
   false -rot  swap  ?do			( targ false )
      over i token@ = if
	 drop i swap true leave
      then
      \ Can't use /token because tokens could be 32-bits, aligned on 16-bit
      \ boundaries, with 16-bit branch offsets realigning the token list.
   #talign +loop  nip
;
: search  ( n start end -- loc true | false )
   false -rot  swap  ?do		( n false )
      over i @ = if
	 drop i swap true leave
      then
   #talign +loop  nip
;

headerless

: next-token  ( adr -- adr token )
   dup token@                 ( n adr token )
   dup ['] unnest =  abort" Can't find word to replace"   ( n adr token )
;

\ Can't use ta1+ because tokens could be 32-bits, aligned on 16-bit
\ boundaries, with 16-bit branch offsets realigning the token list.
: talign+  ( adr -- adr' )  #talign +  ;

: find-lit  ( n acf -- adr )
   >body
   begin
      next-token                 ( n adr token )
\t16  dup  ['] (wlit)  =  if     ( n adr token )
\t16     drop                    ( n adr )
\t16     2dup ta1+ w@ 1-  =  if  ( n adr )
\t16        nip exit             ( adr )
\t16     else                    ( n adr )
\t16        ta1+ wa1+            ( n adr' )
\t16     then                    ( n adr )
\t16  else                       ( n adr token )
       dup  ['] (lit) =  if      ( n adr token )
	  drop                   ( n adr )
	  2dup ta1+ @  =  if     ( n adr )
	     nip exit            ( adr )
	  else                   ( n adr )
	     ta1+ na1+           ( n adr' )
	  then                   ( n adr )
       else                      ( n adr token )
	  ['] (llit) =  if       ( n adr )
	     2dup ta1+ l@ 1-  =  if  ( n adr )
		nip exit             ( adr )
	     else                    ( n adr )
		ta1+ la1+            ( n adr' )
	     then                    ( n adr' )
	  else                       ( n adr )
	     talign+                 ( n adr' )
	  then                       ( n adr' )
       then                          ( n adr' )
\t16 then
   again
;

: find-token  ( n acf -- adr )
   >body
   begin
      next-token                    ( n adr token )
      2 pick =  if  nip exit  then  ( n adr )
      talign+                       ( n adr' )
   again
;

: make-name  ( n digit -- adr len )
   >r  <# u#s ascii # hold  r> hold u#>   ( adr len )
;

: put-constant  ( n adr -- )
   over
   base @  d# 16 =  if
      ascii h make-name
   else
      push-decimal
      ascii d make-name
      pop-base
   then                           ( n adr name-adr name-len )

   \ We don't use  "create .. does> @  because we want this word
   \ to decompile as 'constant'

   warning @ >r  warning off
   $header       ( n adr )
   constant-cf swap ,             ( adr )
   r> warning !

   lastacf swap token!
;

: put-noop  ( adr -- )  ta1+  ['] noop swap token!  ;

\t16 : short-number?  ( n -- flag )  -1  h# fffe  between  ;
\t32 : long-number?  ( n -- flag )  -1  h# ffff.fffe n->l between  ;

headers
: (patch)  ( new number?  old number?  word -- )
   swap  if                         ( new number? old acf )  \ Dest. is num
      find-lit                      ( new number? adr )

\t16  dup token@ ['] (wlit) =  if   ( new number? old )  \ Dest. slot is wlit
\t16     swap  if                   ( new adr )   \ replacement is a number
\t16        over short-number?  if  ( new adr )   \ replacement is short num
\t16           ta1+ swap 1+ swap w! ( )
\t16           exit
\t16        then                    ( new adr )   \ Replacement is long num
\t16        tuck put-constant       ( adr )
\t16        put-noop                ( )
\t16        exit
\t16     then                       ( new adr )  \ replacement is a word
\t16     tuck token!  put-noop      ( )
\t16     exit
\t16  then                          ( new number? adr )  \ Dest. slot is lit

\t32  dup token@ ['] (llit) =  if   ( new number? old )  \ Dest. slot is wlit
\t32     swap  if                   ( new adr )   \ replacement is a number
\t32        over long-number?  if   ( new adr )   \ replacement is short num
64\ \t32       ta1+ swap 1+ swap l! ( )
32\ \t32       ta1+ l!              ( )
\t32           exit
\t32        then                    ( new adr )   \ Replacement is long num
\t32        tuck put-constant       ( adr )
\t32        put-noop                ( )
\t32        exit
\t32     then                       ( new adr )  \ replacement is a word
\t32     tuck token!  put-noop      ( )
\t32     exit
\t32  then                          ( new number? adr )  \ Dest. slot is lit

      swap  if  ta1+ !  exit  then  ( new adr )  \ replacement is a word

      tuck token!                   ( adr )
32\ \t16  dup put-noop  ta1+               ( )
64\ \t16  dup put-noop  ta1+ dup put-noop  dup put-noop  ta1+  ( )
64\ \t32  dup put-noop  ta1+
      put-noop                             ( )
      exit
   then                             ( new number? old acf )  \ Dest. is token

   find-token                       ( new number? adr )
   swap if  put-constant exit  then ( new adr )  \ replacement is a number
   token!
;

headerless
: get-word-type  \ word  ( -- val number? )
   parse-word  $find  if  false exit  then  ( adr len )
   $dnumber?  1 <> abort" ?"  true
;

headers
: (npatch  ( newn oldn acf -- )  >r true tuck  r>  (patch)  ;

: (patch  ( new-acf old-acf acf -- )  >r false tuck r>  (patch)  ;

\ substitute new for first occurrence of old in word "name"
: npatch  \ name  ( new old -- )
   true tuck  '  ( new true old true acf )  (patch)
;

: patch  \ new old word  ( -- )
   get-word-type   get-word-type  '  (patch)
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
