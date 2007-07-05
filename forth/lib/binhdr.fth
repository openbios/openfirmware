purpose: Header for Forth ".exe" file to be executed by the C wrapper program.
\ See license at end of file

hex

only forth also hidden also
forth definitions
headerless

hidden definitions
th 20 buffer: bin-header
: hfield  \ name ( offset size -- offset' )
   create
   over ,  +
   does>     ( struct-base -- field-addr )
   @ bin-header +
;
: long  4 hfield  ;

struct ( Binary header)
 long h_magic	(  0)		\ Magic Number
 long h_tlen    (  4)		\ length of text (code)
 long h_dlen	(  8)		\ length of initialized data
 long h_blen	(  c)		\ length of BSS unitialized data
 long h_slen	( 10)		\ length of symbol table
 long h_entry	( 14)		\ Entry address
 long h_trlen	( 18)		\ Text Relocation Table length
 long h_drlen	( 1c)		\ Data Relocation Table length
constant /bin-header ( 20)

: text-size  ( -- size-of-dictionary )  dictionary-size aligned  ;
headers

only forth also definitions

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
