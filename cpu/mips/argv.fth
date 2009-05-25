\ See license at end of file
purpose: Split a command string into an argv array

\ argc,argv  ( command$ name$ -- argv argc )
\  Places a pointer to a null-terminated representation of the "adr len"
\  string "name$" in the first element of a pointer array whose base
\  address is "argv".  Then parses the "adr len" string "command$" into
\  constituent substrings, storing pointers to the null-terminated
\  substrings in subsequent elements of the "argv" array.
\  Returns the number of pointers in the array, including the pointer to
\  name$, as "argc".  An extra null pointer (i.e. the number 0) is stored
\  at the end of the array but is not included in the "argc" count.
\
\  The substrings are delimited by white space, except that
\   a) If a backslash is encountered, it "quotes" the next character;
\      if that character is whitespace, it does not delimit the
\      substring.  To embed the \ character itself, double it.
\   b) If the first character of a substring is either " or ', the
\      substring continues until the next non-quoted occurence of
\      that quote character.  (A " character can be embedded within
\      a quoted string by preceding it with \ .)
\  These quoting rules are intended to be similar to those of Unix shells.

: skipwhite  ( adr len -- adr' len' )
   begin  dup  while
      over c@  bl >  if  exit  then
      1 /string
   repeat
;

: append-char  ( ptr adr len char -- ptr' adr len )
   3 roll  tuck c!  1+  -rot
;

: collect-arg  ( ptr adr len delim -- ptr' adr' len' )
   >r
   begin  dup  while             ( ptr adr len )
      over c@                    ( ptr adr len char )

      \ Exit when delimiter found
      \ If delim is < 0, then parse nonwhite characters.  Otherwise parse
      \ with a specific delimiter.
      dup  r@  dup  0<  if  drop bl <=  else  =  then  if
         r> 2drop  1 /string  0 append-char  exit
      then

      dup  [char] \  =  if       ( ptr adr len char )
         drop                    ( ptr adr len )
         1 /string               ( ptr adr' len' )
         dup 0=  if  0 append-char  r> drop  exit  then
         over c@                 ( ptr adr len char )
      then                       ( ptr adr len char )
      append-char  1 /string     ( ptr' adr' len' )
   repeat
   r> drop
;

: add-arg  ( ptr adr len -- ptr' adr' len' )
   dup 0=  if  exit  then

   2 pick ,                             ( ptr adr len )
   over c@   dup [char] " =
   swap [char] ' =  or  if              ( ptr adr len )
      1 /string  over 1- c@    collect-arg  ( ptr adr len )
   else
      -1 collect-arg
   then
;

: argv,argc  ( command$ name$ -- argv argc )
   align here >r          ( command$ name$ ) ( r: argv )
   $cstr ,                ( command$ )
   dup alloc-mem -rot     ( ptr  command$ )
   begin  dup  while      ( ptr  command$ )
      skipwhite           ( ptr  command$' )
      add-arg             ( ptr' command$' )
   repeat                 ( ptr  command$ )
   3drop                  ( ) ( r: argv )
   r>  here over - /n /   ( argv argc )
   0 ,
;

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
