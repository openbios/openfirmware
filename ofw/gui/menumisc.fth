\ See license at end of file
purpose: Support routines for icon menu items

headerless
\ Implementation factors used by show-pages
\ Split the first page from a batch of text containing embedded line
\ delimiters.  A page contains one fewer lines than the number of lines
\ on the screen, to leave room for a "more" prompt or other interaction.
: split-page  ( adr len -- rem$ 1page$ )
   over 0   lines/page 1  ?do           ( rem$ head$ )
      2 pick  0=  if  leave  then       ( rem$ head$ )
      2>r  split-line                   ( rem$' line$ )  ( r: head$ )
      nip 2r> rot +                     ( rem$' head$' )
   loop
;
: clear-screen  ( -- )  " "(9b)1;1H"(9b)J" type  ;
: clear-line    ( -- )  " "(9b)K" type  ;

headers
\ Paginate a long string of text containing embedded line delimiters,
\ repainting the screen for each new page instead of scrolling (which
\ can be relatively slow).
: show-pages  ( adr len -- )
   begin  dup  while                   ( adr len )
      split-page clear-screen type     ( adr' len' )
      begin
         dup 0=  if  2drop exit  then  ( adr len )
         ." More [<space>,<cr>,q] ? "
         key upc  case
            ascii Q  of  (cr clear-line  2drop exit  endof
            carret   of  true  endof
            ( default )  false swap
         endcase                       ( adr len 1line? )
      while
         (cr clear-line  split-line type
      repeat
   repeat
;

\ Attempt to boot with the indicated string arguments.  Returning cleanly
\ if the attempt aborts.
: guarded-boot  ( adr len -- )
   ['] $boot  catch  ?dup  if  ( x x )  .error  2drop  then
;

\ Defining word for byte arrays containing a batch of text from a file
: text:  ( "name" "filename" -- ) ( child: -- adr len )
   create  here  0 ,  here  parse-word $file,   ( apf adr )
   here swap -  swap !                          ( )
   does> dup na1+ swap @   ( adr len )
;

\ Defining word for icon images
: icon:  ( "name" "devicename" -- ) ( child: -- adr )
   create  parse-word ",
;

icon: exit.icon            ${BP}/ofw/gui/exeunt.icx
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
