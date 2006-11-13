\ See license at end of file

\ Primitives to concatenate ( "cat ), and print ( ". ) strings.
decimal
headerless

d# 260 buffer: string2
: save-string  ( pstr1 -- pstr2 )  string2 "copy string2  ;

headers
: $number  ( adr len -- true | n false )
   $dnumber?  case
      0 of  true        endof
      1 of  false       endof
      2 of  drop false  endof
   endcase
;

headerless
: $hnumber  ( adr len -- true | n false )  push-hex  $number  pop-base  ;
headers

\ Here is a direct implementation of $number, except that it doesn't handle
\ DPL, and it allows , in addition to . for number punctuation
\ : $number  ( adr len -- n false | true )
\    1 0 2swap                    ( sign n adr len )
\    bounds  ?do                  ( sign n )
\       i c@  base @ digit  if    ( sign n digit )
\        swap base @ ul* +        ( sign n' )
\       else                      ( sign n char )
\          case                   ( sign n )
\             ascii -  of  swap negate swap  endof    ( -sign n )
\             ascii .  of                    endof    ( sign n )
\             ascii ,  of                    endof    ( sign n )
\           ( sign n char ) drop nip 0 swap leave     ( 0 n )
\          endcase
\       then
\    loop                         ( sign|0 n )
\    over  if                     ( sign n )
\       * false                   ( n' false )
\    else                         ( 0 n )
\       2drop true                ( true )
\    then
\ ;

: $cat2  ( $1 $2 -- $3 )
   2 pick over +  dup >r alloc-mem >r
   2swap tuck  r@ swap move           ( $2 $1-len )
   r@ + swap move                     ( )
   r> r>
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
