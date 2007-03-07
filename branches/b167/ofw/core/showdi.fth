\ See license at end of file
purpose: Display a list of dropin drivers

: .di-name  ( adr -- )
   d# 16 +  d# 16  begin  dup  while
      over c@  0=  if           ( adr len )
         0  do  bl emit  loop   ( adr )
         drop exit
      then
      over c@  emit  1 /string
   repeat
   2drop
;
0 value dropin-offset
h# 20 constant /di-header
: dropin?  ( adr len -- flag )
   /di-header <  if  drop false exit  then
   " OBMD"  comp 0=
;
: >di-extent  ( adr -- len )  4 + be-l@  /di-header +  4 round-up  ;
: .dropin  ( base-adr adr len -- base-adr adr' len' flag )
   2dup  dropin?  0=  if                 ( adr len )
      ." The last " .d ." bytes are not in dropin format" cr
      true exit
   then                                  ( base-adr adr len )
   over .di-name  space
   push-hex
      over 3 pick - /di-header +  dropin-offset +  d# 11 u.r
      over     4 + be-l@     d# 11 u.r
      over d# 12 + be-l@     d# 11 u.r
      over     8 + be-l@     d# 11 u.r  cr
   pop-base
   over >di-extent /string
   false
;
: find-first-dropin  ( adr len -- adr' len' )
   " OBMD" 2over  sindex  dup  -1  =  if  ( adr len -1 )
      drop  0 to dropin-offset            ( adr len )
   else                                   ( adr len offset )
      dup to dropin-offset  /string       ( adr' len' )
   then                                   ( adr' len' )
;
: (.dropins)  ( adr len -- )
   find-first-dropin
   ." Name             Data Offset     Length  Expansion   Checksum" cr
   over swap
   begin  .dropin  until
   3drop
;

[ifdef] map-drop-in
: .dropins  ( -- )
   map-drop-in
   2dup (.dropins)
   unmap-drop-in
;
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
