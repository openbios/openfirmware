\ See license at end of file
\ Get/Set/Display Access to Interrupt vectors

defer pm-vector@  ( vector# -- farp )
defer pm-vector!  ( farp vector# -- )

: >vec-adr  ( vector# -- offset sel )  3 <<  idt  rot far+  ;
: get-pm-vector  ( vector# -- v.4 v.0 )  >vec-adr far-x@ swap  ;
: put-pm-vector  ( v.4 v.0 vector# -- )
   >vec-adr  2swap swap 2swap  far-x!
;
h# ef00 constant trap-gate	\ Trap Gate, Present, Priv: 3
h# ee00 constant int-gate	\ Interrupt Gate, Present, Priv: 3
: format-vector  ( adr sel gate-type -- v.4 v.0 )
   rot lwsplit        ( sel gate adr-low adr-high )
   rot swap wljoin    ( sel adr-low v.4 )
   swap rot wljoin    ( v.4 v.0 )
;
: (pm-vector!)  ( adr sel vector# -- )
   >r  int-gate format-vector  r> put-pm-vector
;
: (pm-vector@)  ( vector# -- adr sel )
   get-pm-vector		       ( v.4 v.0 )
   swap lwsplit rot lwsplit            ( flags offset.high offset.low sel )
   >r  swap wljoin nip  r>	       ( adr sel )
;
: .vector  ( v.4 v.0 -- )
   swap lwsplit rot lwsplit            ( flags offset.high offset.low segment )
   base @ >r hex                       ( flags offset.high offset.low segment )
   ." Segment: "  4 u.r                ( flags offset.high offset.low )
   ."   Offset: "   swap wljoin 9 u.r  ( flags ) 
   ."   P: " dup d# 15 >> .            ( flags )
   ."  Priv: " dup d# 13 >> 3 and .    ( flags )
   8 >> h# 1f and case
      h# 5 of  ."  Task"      endof
      h# e of  ."  Interrupt" endof
      h# f of  ."  Trap"      endof
      ( else ) ."  Unknown"
   endcase
   ."  Gate" cr
   r> base !
;

\ This assumes that the Interrupt Descriptor Table is full sized, i.e. the
\ segment descriptor that refers to it has an size field of at least 256*8.
: dv  ( -- )
   base @ >r hex
   h# 100 0  do
      i 2 u.r  2 spaces  i get-pm-vector .vector
      exit? ?leave
   loop
   r> base !
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
