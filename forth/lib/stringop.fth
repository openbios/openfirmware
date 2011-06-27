\ See license at end of file
purpose: String tools to manipulate OS file pathnames

\ head$ is the portion of str3 preceding str2, and tail$ is the portion
\ of str3 following str2
: break$  ( str2 str3  -- head$ tail$ )
   2over +  2 pick 2 pick +  over - 2>r  ( str2 str3 ) ( r: tail$ )
   drop nip tuck -   ( head$ )  ( r: tail$ )
   2r>
;
\ str4 is the result of replacing the characters in str2, which must be
\ within str3, with the characters in str1.  str1 need not be the same
\ length as str2.
: $insert  ( str1 str2 str3  -- str4 )
   break$                    ( str1 head$ tail$ )
   4 pick 3 pick 2 pick + +  ( str1 head$ tail$ total-len )
   dup >r alloc-mem >r       ( str1 head$ tail$ )
   2swap tuck r@ swap move   ( str1 tail$ head-len )
   >r 2swap r>               ( tail$ str1 head-len )
   r@ + >r tuck              ( tail$ str1-len str1 ) ( r: len4 adr4 adr' )
   r@ swap move              ( tail$ str1-len ) ( r: len4 adr4 adr' )
   r> + swap move            ( )  ( r: len4 adr4 )
   r> r>
;
: $cat3  ( head$ env$ tail$ -- total$ )
   4 pick 3 pick 2 pick + +          ( head$ env$ tail$ total-len )
   dup >r alloc-mem >r               ( head$ env$ tail$ )  ( r: len adr )
   5 roll 5 roll tuck r@ swap move   ( env$ tail$ head-len ) ( r: len adr )
   >r 2swap r>                       ( tail$ env$ head-len )
   r@ + >r tuck              ( tail$ env-len env-adr ) ( r: len4 adr4 adr' )
   r@ swap move              ( tail$ env-len ) ( r: len4 adr4 adr' )
   r> + swap move            ( )  ( r: len4 adr4 )
   r> r>
;
vocabulary macros

: $set-macro  ( value$ name$ -- )
   warning @ >r  warning off
   also macros definitions  $header create-cf  previous definitions  ( value$ )
   r> warning !
   ",
   does>  ( -- adr len )  count
;
: $get-macro  ( name$ -- true | value$ false )
   ['] macros search-wordlist  if  execute  false  else  true  then
;

: macro:  ( "name" "value" -- )  safe-parse-word  0 parse  2swap  $set-macro  ;

: expansion  ( macro-name$ -- macro-value$ )
   2dup $get-macro  if         ( name$ )
      $getenv  if  " "  then   ( value$ )
   else                        ( name$ value$ )
      2nip                     ( value$ )
   then                        ( value$ )
;

\ Expand references to environment variables within str1
: expand1  ( str1 -- str2 expanded? )
   2dup [char] $ split-string        ( str head$ tail$ )
   dup 1 >  if                       ( str head$ tail$ )
      over 1+ c@ [char] { =  if      ( str head$ tail$ )
         2 /string                   ( str head$ tail$' )
         [char] } split-string       ( str head$ env$ tail$' )
         dup 0>  if                  ( str head$ env$ tail$ )
            1 /string                ( str head$ env$ tail$' )
            2swap expansion          ( str head$ tail$ env$ )
            2swap $cat3              ( str str2 )
            2swap 2drop  true        ( str2 true )
         else                        ( str head$ env$ tail$' )
            4drop 2drop false		( str false )
         then
      else				( str head$ tail$ )
         4drop false			( str false )
      then
   else					( str head$ tail$ )
      4drop false			( str false )
   then
;
: expand$  ( str1 -- str2 )  begin  expand1  0= until  ;

: remove-extension  ( $1 ext$ -- $2 )
   2 pick over <  if  2drop  exit  then   ( $1 ext$ )
   dup >r                                 ( $1 ext$ )
   2over + r@ - r@                        ( $1 ext$ tail$1 )
   $=  if  r@ -  then  r> drop            ( $2 )
;
: $,  ( adr len -- )  here over allot swap move  ;
: #remaining  ( -- n )  source nip >in @ -  ;
: remaining  ( -- adr len )  source >in @ /string  ;
\ The complexity with last-delim is necessary in order to handle the
\ case where files" is at the very end of a line.
variable last-delim
: files"  ( "strings" -- adr len )
   last-delim off
   here
   begin
      #remaining  if
         [char] " parse  ( adr len )  $,
         source drop  >in @  +  1-  c@ last-delim !
      then
      #remaining 0=
   while
      >in @  if  last-delim @  [char] " <>  else  true  then
   while
      bl c,
      refill 0=
   until then then                ( adr )
   here over -
;
\ The result is < = > zero when $1 is < = > $2
: $compare  ( $1 $2 -- -1|0|1 )
   rot                               ( adr1 adr2 len2 len1 )
   2dup =  if                        ( adr1 adr2 len2 len1 )
      \ The strings are the same length, so consider only their contents
      drop comp                 ( -1|0|1 )
   else                              ( adr1 adr2 len2 len1 )
      \ The lengths differ, so consider both contents and length
      \ First consider the contents within the length of the shorter string
      2>r  2r@ min                   ( adr1 adr2 min-len r: len2 len1 )
      comp  ?dup  if            ( -1|1 r: len2 len1 )
         \ The initial substrings differ, determining the answer
	 2r> 2drop                   ( -1|1 )
      else                           ( r: len2 len1 )
         \ The initial substring are the same, so the longer string is ">"
         2r>  swap                   ( len1 len2 )
	 <  if  -1  else  1  then    ( -1|1 )
      then
   then
;
\ The result is < = > zero when $1 is < = > $2
: $caps-compare  ( $1 $2 -- -1|0|1 )
   rot                               ( adr1 adr2 len2 len1 )
   2dup =  if                        ( adr1 adr2 len2 len1 )
      \ The strings are the same length, so consider only their contents
      drop caps-comp                 ( -1|0|1 )
   else                              ( adr1 adr2 len2 len1 )
      \ The lengths differ, so consider both contents and length
      \ First consider the contents within the length of the shorter string
      2>r  2r@ min                   ( adr1 adr2 min-len r: len2 len1 )
      caps-comp  ?dup  if            ( -1|1 r: len2 len1 )
         \ The initial substrings differ, determining the answer
	 2r> 2drop                   ( -1|1 )
      else                           ( r: len2 len1 )
         \ The initial substring are the same, so the longer string is ">"
         2r>  swap                   ( len1 len2 )
	 <  if  -1  else  1  then    ( -1|1 )
      then
   then
;
0 [if] \ Test cases
" "   " "     $compare .
" a"  " a"    $compare .
" a"  " b"    $compare .
" a"  " ab"   $compare .
" b"  " a"    $compare .
" b"  " ab"   $compare .
" a"  " a"    $caps-compare .
" a"  " B"    $caps-compare .
" a"  " Ba"   $caps-compare .
" B"  " a"    $caps-compare .
" B"  " ab"   $caps-compare .
[then]

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
