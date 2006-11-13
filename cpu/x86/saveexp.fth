\ See license at end of file

\ Save an image of the Forth system in a file in Phar Lap ".EXP" format.

hex

0 value code-adr
0 value code-size

h# 200 constant /exp-header
0 value exp-header
: hc!  ( byte offset -- )  exp-header + c!  ;
: hw!  ( word offset -- )  >r wbsplit r@ 1+ hc!  r> hc!  ;
: hl!  ( long offset -- )  >r lwsplit r@ 2+ hw!  r> hw!  ;
: calc-checksum  ( partial-sum adr len -- )
   bounds  ?do   i le-w@ +  h# ffff and  /w +loop
;
: checksum  ( -- )
   \ Zero any dangling byte to make checksum come out right
   code-size  1 and  if  0  code-adr code-size +  c!  then

   0					     ( partial-sum )
   exp-header  /exp-header  calc-checksum    ( partial-sum' )
   code-adr    code-size    calc-checksum    ( sum )
   invert  h# ffff and
;

variable dictionary-size  h# 40000 dictionary-size !

: initial-sp  ( -- )  dictionary-size @ code-size +  3 invert and  ;

: makeheader  ( -- )
   /exp-header alloc-mem is exp-header
   exp-header /exp-header erase
   ascii M 0 hc!   ascii P 1 hc!	\ Signature
   code-size  /exp-header +   ( file-size )
   dup h# 200 mod      2 hw!		\ Number of valid bytes in last block
   h# 200 +  h# 200 /  4 hw!		\ Number of blocks in the file
   0           6 hw!			\ Relocations
   h# 20       8 hw!			\ Size of header in paragraphs
   dictionary-size @  h# 1000 /  0a hw! \ Minimum data size in 4K pages
   dictionary-size @  h# 1000 /  0c hw! \ Maximum data size in 4K pages
   initial-sp 0e hl!			\ Initial stack pointer
   0          14 hl!			\ Initial instruction pointer
   h# 1e      18 hw!			\ First relocation item (after hdr)
   0          1a hw!			\ Overlay number
   1          1c hw!			\ Must be 1
   checksum   12 hw!			\ Checksum
;   

: save-image  ( pstr base-adr len -- )
   is code-size  is code-adr	( pstr )
   makeheader			( pstr )

   new-file

   exp-header  /exp-header  		 ofd @  fputs
   code-adr    code-size    		 ofd @  fputs
   relocation-map code-size h# 0f + 4 >> ofd @  fputs
 		 
   ofd @ fclose
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
