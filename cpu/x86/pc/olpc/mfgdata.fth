purpose: Manufacturing data reader
\ See license at end of file

\ The manufacturing data format is specified by
\ http://wiki.laptop.org/go/Manufacturing_Data

: hibit?  ( adr offset -- adr flag )  over +  c@  h# 80 and  ;

: invalid-tag?  ( adr -- data-adr flag )
   -1 hibit?  if  true exit  then  \ Name char must be 7-bit ASCII
   -2 hibit?  if  true exit  then  \ Name char must be 7-bit ASCII
   -3 hibit?  if  \ Long (5-byte tag) format   ( adr )
      dup  4 - c@  dup h# 80 and  if  drop true exit  then   ( adr low )
      over 5 - c@  dup h# 80 and  if  2drop true exit  then  ( adr low high )
      2dup xor h# ff xor                                     ( adr low high check )
      3 pick 3 - c@ <>  if  2drop true exit  then            ( adr low high )
      7 << +                                                 ( adr length )
      - 5 -                                                  ( data-adr )
   else           \ Short (4-byte tag) format
      dup  3 - c@                          ( adr len )
      over 4 - c@                          ( adr len ~len )
      xor  h# ff <>  if  true exit  then   ( adr )
      dup  3 - c@  - 4 -                   ( data-adr )
   then

   false
;

: last-mfg-data  ( top-adr -- adr )  begin  invalid-tag?  until  ;

: another-tag?  ( adr -- adr false |  adr' data$ name-adr true )
   dup invalid-tag?  if       ( adr data-adr )
      drop false exit
   then                       ( adr data-adr )
   >r  2-                     ( name-adr r: data-adr )
   dup 1- c@ h# 80 and  if    ( name-adr r: data-adr )   \ 5-byte format
      dup 2- c@               ( name-adr lowlen r: data-adr )
      over 3 - c@  7 lshift + ( name-adr len r: data-adr )
   else                       ( name-adr r: data-adr )   \ 4-byte format
      dup 1- c@               ( name-adr len r: data-adr )
   then                       ( name-adr len r: data-adr )
   r> rot >r                  ( len data-adr r: name-adr )
   dup rot  r>                ( adr data$ name-adr )
   true                       ( adr data$ name-adr true )
;

: (find-tag)  ( name$ top-adr -- false | data$ true )
   -rot  drop >r                ( adr r: name-adr )
   begin  another-tag?  while   ( adr' data$ tname-adr r: name-adr )
      r@ 2 comp 0=  if          ( adr' data$ r: name-adr )
         r> drop  rot drop      ( data$ )
         true exit              ( -- data$ true )
      then                      ( adr' data$ r: name-adr )
      2drop                     ( adr' r: name-adr )
   repeat                       ( adr' r: name-adr )
   r> 2drop false
;
: find-tag  ( name$ -- false | data$ true )
   mfg-data-top  (find-tag)
;

\ Remove bogus null characters from the end of mfg data tags (old machines
\ have malformed tags)
: ?-null  ( adr len -- adr' len' )
   dup  if
      2dup + 1- c@  0=  if  1-  then        ( adr len' )
   then
;

: ?erased  ( adr len -- )
   bounds  ?do  i c@  h# ff <> abort" Not erased"  loop
;

: $tag-printable?  ( adr len -- flag )
   ?-null   \ Ignore trailing null
   bounds  ?do  i c@  bl h# 7f within 0=  if  false unloop exit  then  loop
   true
;

: wrapped-cdump  ( adr len -- )
   lmargin @ >r  rmargin @ >r  tabstops @ >r
   4 lmargin !  d# 71 rmargin !  3 tabstops !
   dup >r
   blue-letters
   bounds ?do
      #out @ 3 +  rmargin @  >  if  exit? ?leave  then
      3 .tab  i c@  <# u# u# u#> type
   loop
   black-letters
   r> d# 10 >  if  cr  then
   r> tabstops !  r> rmargin !  r> lmargin !
;

: .mfg-data  ( -- )
   0 lmargin !  d# 78 rmargin !  d# 42 tabstops !
   ??cr
   mfg-data-top        ( adr )
   begin  another-tag?  while   ( adr' data$ tname-adr )
      over 4 + .tab
      2 type 2 spaces           ( adr' data$ )
      2dup $tag-printable?  if  ?-null type  else  wrapped-cdump  then
      exit?  if  drop exit  then
   repeat
   drop
;

[ifdef] notdef
: put-mfg-data  ( value$ name$ -- )
   drop  over invert here c!  over here 1+ c!  ( value$ name-adr )
   here 2+ 2 move                              ( value$ )
   flash-base /ec +  last-mfg-data             ( value$ mfg-adr )
   over - 4 -                                  ( value$ new-adr )
   2dup swap  ?erased                          ( value$ new-adr )
   flash-base -                                ( value$ offset )
   2>r 2r@                                     ( value$ offset r: len offset )
   spi-start spi-identify                      ( value$ r: len offset )
   write-spi-flash                             ( r: len offset )
   here 4  2r> +  write-spi-flash              ( )
;
[then]

\ LICENSE_BEGIN
\ Copyright (c) 2007 FirmWorks
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
