\ See license at end of file

\ Create and manipulate new stacks.
\
\ 100 stack: foo      Create a new stack called foo with 100 bytes of storage
\ 123 foo push        Push the number 123 on the stack foo
\ foo pop             Pop the top element from the stack foo onto the
\                     parameter stack
\ foo top@            Copy the top element from the stack foo onto the
\                     parameter stack
\ 456 foo top!        Replace the top element of the stack foo with 456
\ foo ?empty          True if the stack foo is empty
\ foo sdepth          Returns the number of items on the stack foo
\ foo clearstack      Empties the stack foo

\ Creates a new stack
: stack:  \ name  ( size -- )
   create  here token, allot ( top, )
;

\ Adds a number to the stack
: push  ( n stack -- )  /n over +! token@ !  ;

\ True if the stack is empty
: ?empty  ( stack -- flag )  dup token@ >=  ;

\ Removes a number from the stack
: pop  ( stack -- n )
   dup ?empty abort" empty user stack"
   dup token@ @ swap /n negate swap +!
;

\ Retrieves the number on top of the stack, without removing it
: top@  ( stack -- n )  dup ?empty abort" Empty user stack" token@ @  ;

\ Replaces the item on top of the stack
: top!  ( n stack -- )  dup pop drop push  ;

\ Empties the stack
: clearstack  ( stack -- )  dup token!  ;

\ Returns the current depth of the stack
: sdepth  ( stack -- depth )  dup token@ swap - /n /  ;
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
