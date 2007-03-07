\ See license at end of file

\ The dump utility gives you a formatted hex dump with the ascii
\ text corresponding to the bytes on the right hand side of the
\ screen.  In addition you can use the SM word to set a range of
\ memory locations to desired values.  SM displays an address and
\ its contents.  You can go forwards or backwards depending upon
\ which character you type. Entering a hex number changes the
\ contents of the location.  DL can be used to dump a line of
\ text from a screen.

decimal

only forth also hidden also  definitions

headerless
defer dc@ ' c@ is dc@
\ : .2   (s n -- )   <#   u# u#   u#>   type   space   ;
: d.2   (s addr len -- )   bounds ?do   i dc@ .2   loop   ;
: emit.   (s char -- )
   d# 127 and dup printable? 0= if drop ascii . then emit
;
: emit.ln (s addr len -- )
   bounds ?do   i dc@ emit.   loop
;
: dln   (s addr --- )
   ??cr   dup  n->l 8 u.r   2 spaces   8 2dup d.2 space
   over + 8 d.2 space
   16 emit.ln
;

: .n2    (s n -- )  h# f and  3 .r  ;
: .a     (s n -- )  h# f and  1 .r  ;

: .head   (s addr -- )
   ??cr dup d# 16 >> d# 16 >> ?dup  if
      8 u.r space
   else
      9 spaces
   then                                  ( adr )
   8 0 do   dup i + .n2   loop   space   d# 16 8 do   dup i + .n2   loop
   2 spaces   d# 16 0 do  dup i + .a  loop   drop
;
headers

: (dump) ( addr len -- )
   push-hex   over  .head  ( addr len )
   1 max
   bounds do   i dln  exit? ?leave  16 +loop
   pop-base
;
also forth definitions

: dump ( addr len -- )      ['] c@ is dc@ (dump)  ;
: du   ( addr -- addr+64 )  dup d# 64 dump   d# 64 +  ;

only forth also definitions
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
