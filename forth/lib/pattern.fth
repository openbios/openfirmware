\ See license at end of file
purpose: Filename pattern matching

headerless
\ Pattern matching with wildcards as in Unix filenames.

\ * matches anything, ? matches any individual character

: third   ( n5 n4 n3 n2 n1 -- n5 n4 n3 n2 n1 n3 )  2 pick  ;
: fourth  ( n5 n4 n3 n2 n1 -- n5 n4 n3 n2 n1 n4 )  3 pick  ;
: fifth   ( n5 n4 n3 n2 n1 -- n5 n4 n3 n2 n1 n4 )  4 pick  ;
\needs 5drop  : 5drop   ( n5 n4 n3 n2 n1 -- )  2drop 3drop  ;
\needs /string  : /string  ( adr len cnt -- adr' len' )  tuck - -rot + swap  ;

: -initial-match  ( case-insensitive? pat-str test-str -- ... )
                  ( ... -- case-insensitive? pat-str' test-str' )
   begin                                ( case pat-str test-str )
      third 0<>  over 0<>  and          ( case pat-str test-str flag )
   while                                ( case pat-str test-str )
      fourth c@  ascii ?  <>  if        ( case pat-str test-str )
         fifth  if
            fourth c@ upc  third c@ upc ( case pat-str test-str char1 char2 )
         else
            fourth c@  third c@         ( case pat-str test-str char1 char2 )
         then
         <>  if  exit  then             ( case pat-str test-str )
      then                              ( case pat-str test-str )
      2swap 1 /string  2swap 1 /string  ( case pat-str' test-str' )
   repeat                               ( case pat-str test-str )
;

headers
: pattern-match?  ( case-insensitive? pat-str test-str -- flag )  recursive
   -initial-match                       ( case pat-str' test-str' )

   \ If the pattern string is empty, we can decide the question right now;
   \ it's a match iff the test string is also empty.
   third 0=  if                         ( case pat-str test-str )
      nip nip nip nip 0=  exit
   then                                 ( case pat-str test-str )

   \ If the first remaining character in the pattern string is not a '*',
   \ then the strings don't match.

   fourth c@  ascii *  <>  if           ( case pat-str test-str )
      5drop false  exit                 \ Lose
   then                                 ( case pat-str test-str )

   \ The pattern string begins with an *; remove it and try to
   \ match the remaining pattern with all possible trailing substrings
   \ of the test pattern.

   2swap 1 /string 2swap                ( case pat-str test-str )

   \ If the pattern is now empty, we win, because a trailing "*" matches
   \ any possible remaining string.
   third 0=  if  5drop true  exit  then ( case pat-str test-str )

   begin  dup  while                    ( case pat-str test-str )
      fifth fifth fifth fifth fifth     ( case pat-str test-str case .. test$ )
      pattern-match?  if                ( case pat-str test-str )
         5drop true  exit               \ We have a winner!
      then                              ( case pat-str test-str )
      1 /string                         ( case pat-str test-str' )
   repeat                               ( case pat-str test-str )

   \ Having exhausted all possible matches for the '*', we admit defeat.

   5drop false
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
