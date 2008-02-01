purpose: High level implementations of string scanning words
\ See license at end of file

: skipwhite  ( adr1 len1 -- adr2 len2  )
   begin  dup 0>  while       ( adr len )
      over c@  bl >  if  exit  then
      1 /string
   repeat                     ( adr' 0 )
;

\ Adr2 points to the delimiter or to the end of the buffer
\ Adr3 points to the character after the delimiter or to the end of the buffer
: scantowhite  ( adr1 len1 -- adr1 adr2 adr3 )
   over swap                       ( adr1 adr1 len1 )
   begin  dup 0>  while            ( adr1 adr len )
      over c@  bl <=  if  drop dup 1+  exit  then
      1 /string                    ( adr1 adr' len' )
   repeat                          ( adr1 adr2 0 )
   drop dup                        ( adr1 adr2 adr2 )
;

: skipchar  ( adr1 len1 delim -- adr2 len2 )
   >r                         ( adr1 len1 )  ( r: delim )
   begin  dup 0>  while       ( adr len )
      over c@  r@ <>  if      ( adr len )
         r> drop exit         ( adr2 len2 )
      then                    ( adr len )
      1 /string               ( adr' len' )
   repeat                     ( adr' 0 )
   r> drop                    ( adr2 0 )
;

\ Adr2 points to the delimiter or to the end of the buffer
\ Adr3 points to the character after the delimiter or to the end of the buffer
: scantochar  ( adr1 len1 char -- adr1 adr2 adr3 )
   >r                              ( adr1 len1 )   ( r: delim )
   over swap                       ( adr1 adr1 len1 )
   begin  dup 0>  while            ( adr1 adr len )
      over c@  r@ =  if            ( adr1 adr len )
         r> 2drop dup 1+  exit     ( adr1 adr2 adr3 )
      then                         ( adr1 adr len )
      1 /string                    ( adr1 adr' len' )
   repeat                          ( adr1 adr2 0 )
   r> 2drop dup                    ( adr1 adr2 adr2 )
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
