purpose: Save the metacompiled kernel image into a file
\ See license at end of file

hex
only forth labels also forth also definitions

\ Program header
create header   forth
h# 4800.0020 l,  \ Branch past the header
      0 l,    \ Text size, actual value will be set later
      0 l,    \ Data size, actual value will be set later
      0 l,    \ Bss  size
      0 l,    \ Symbol Table size
      0 l,    \ Entry
      0 l,    \ Text Relocation Size
      0 l,    \ Data Relocation Size
\ End of header.
here header -  constant /header

only forth also meta also forth-h also definitions

\ Save an image of the target system in the file whose name
\ is the argument on the stack.

: doubleword-align  ( n -- n' )  7 + 7 invert and  ;
: text-base  ( -- adr )  origin-t >hostaddr  ;
: text-size  ( -- n )  here-t origin-t -  doubleword-align  ;
: swap-size  ( -- n )  here-t >swap-map-size-t  ;
: user-base  ( -- adr )  userarea-t  ;
: user-size  ( -- n )  user-size-t  doubleword-align  ;
: save-meta ( str -- )

   \ Doubleword alignment is required so that the user area image will
   \ not be in the same doubleword as the end of the dictionary, thus
   \ causing the copy loop to get the wrong value the first time.
   begin  here-t  7 and  while  0 c,-t  repeat

   new-file

   \ Set the text and data sizes in the program header
   h# 4800.0020          header h#  0 + l-t!		\ Branch past the header
   text-size             header h#  4 + l-t!		\ Text size
   user-size             header h#  8 + l-t!		\ Data size
   0                     header h# 10 + l-t!		\ Symbol table size

   0                     header h# 14 + l-t!		\ Entry point
   swap-size             header h# 18 + l-t!		\ Swap map size

   header               /header       ofd @  fputs
   text-base            text-size     ofd @  fputs
   user-base            user-size     ofd @  fputs
   swap-map-t           swap-size     ofd @  fputs	\ Swap map

   ofd @ fclose
;

only forth also meta also definitions

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
