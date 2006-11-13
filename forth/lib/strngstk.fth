\ See license at end of file
purpose: Stack for strings

\ $stack:   ( "name" -- ) Defining word - creates an empty string stack word:
\     <name>  ( -- $stack )
\ $empty?   ( $stack -- flag )     True if the string stack is empty
\ $empty    ( $stack -- )          Discards everything on the string stack
\ $push     ( adr len $stack -- )  Adds the data in adr,len to the string stack
\ $top      ( $stack -- adr len )  Returns the value on top of the string stack
\ $drop     ( $stack -- )          Discards the data on top of the string stack
\
\ The reason that there is no word like  "$pop  ( $stack -- adr len )" is
\ because string stack elements are stored in dynamically-allocated memory,
\ and the act of discarding the top element releases the storage for that
\ element.  The hypothetical word "$pop" would have no safe place to store
\ its data.

\ This defining word creates a variable that points to a linked list
\ of dynamically-allocated structures.  Each structure consists of:
\    link (1 cell) , length (1 cell) , "length" bytes of data

: $stack:  ( "name" -- )  variable  lastacf execute !null-link  ;

: $empty?  ( $stack -- empty? )  link@ origin =  ;

\ Pushes "adr len" on the string stack
: $push  ( adr len $stack -- )
   >r
   dup 2 na+ alloc-mem    ( adr len adr' )
   r@ link@  over link!   ( adr len adr' )  \ Link to previous
   dup r> link!           ( adr len adr' )  \ Set head pointer
   2dup na1+ !            ( adr len adr' )  \ Set length
   2 na+ swap move        ( )               \ Store string data
;
: $errchk  ( adr -- adr )  dup $empty?  abort" String stack empty"  ;

\ Returns the top element of the string stack
: $top  ( $stack -- adr len )
   $errchk link@             ( struct-adr )
   na1+ dup na1+ swap @      ( adr len )
;

\ Discards the top element of the string stack
: $drop  ( $stack -- )
   $errchk
   dup link@                      ( $stack struct-adr )
   tuck link@ swap link!          ( struct-adr )
   dup na1+ @  2 na+ free-mem     ( )
;

: $empty  ( $stack -- )
   begin  dup $empty? 0=  while  dup $drop  repeat  drop
;

[ifdef] testcase
ok showstack
ok $stack: bar
ok bar $empty? .
-1 
ok " foo" bar $push    
ok bar $empty? .
0 
ok bar $top type 
foo
ok " goofy" bar $push
ok bar $top type     
goofy
ok bar $empty? .     
0 
ok " stuff" bar $push
ok bar $top type     
stuff
ok bar $drop    
ok bar $top type
goofy
ok bar $empty
ok bar $empty? .
-1 
ok 
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
