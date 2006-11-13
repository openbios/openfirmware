\ See license at end of file
purpose: split and join operators

[ifndef] lowbyte
: lowbyte   h# ff and  ;
[then]

[ifndef] lwsplit
: lwsplit ( l -- w.low w.high )   dup n->w  swap  d# 16 rshift n->w  ;
[then]
[ifndef] wbsplit
: wbsplit ( w -- b.low b.high )   dup lowbyte  swap  d# 8 rshift lowbyte  ;
[then]
[ifndef] bwjoin
: bwjoin  ( b.low b.high -- w )   lowbyte d# 8 lshift swap lowbyte or  ;
[then]
[ifndef] wljoin
: wljoin  ( w.low w.high -- l )   n->w d# 16 lshift swap n->w or  ;
[then]

64\ : xlsplit ( x -- l.low l.high )   dup n->l  swap  d# 32 rshift n->l  ;
64\ : lxjoin  ( l.low l.high -- x )   n->l d# 32 lshift swap n->l or  ;

: lbsplit ( l -- b.low b.lowmid b.highmid b.high )
   lwsplit >r  wbsplit  r>  wbsplit  
;
: bljoin  ( b.low b.lowmid b.highmid b.high -- l )
   bwjoin >r  bwjoin  r>  wljoin
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
