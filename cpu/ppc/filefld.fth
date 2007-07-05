purpose: Code words to support the file system interface
\ See license at end of file

nuser file

:-h struct ( -- 0 )  00  ;-h

\ Run-time action for fields
code dofield
   lwz   tos,0(tos)	   \ Get the structure member offset
   'user file  lwz  t0,*   \ Get the structure base address
   add   tos,tos,t0	   \ Return the structure member address
c;

\ Assembles the code field when metacompiling a field
:-h file-field-cf   ( -- )
   dodoes token,-t  
   " dofield" $sfind drop resolution@  token,-t	\ code field
;-h

\ Metacompiler defining word for creating fields
:-h file-field  \ name  ( offset size -- offset' )
   " file-field-cf" header-t	\ name field and code field
   over ,-t +   ?debug		\ parameter field
;-h


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
