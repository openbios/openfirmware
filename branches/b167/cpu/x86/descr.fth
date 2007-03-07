\ See license at end of file

\ r - readable
\ w - writeable
\ x - executable
\ s - stack (expand down)
\ c - conforming (assume callers privilege level)
string-array privileges
   ," r--"	
   ," rw-"
   ," r-s"
   ," rws"
   ," -x-"
   ," rx-"
   ," -xc"
   ," rxc"
end-string-array   
string-array sys-types
   ," inv"	
   ,"   1"
   ," LDT"
   ,"   3"
   ,"   4"
   ," TaskGate"
   ,"   6"
   ,"   7"
   ,"   8"	
   ," TSS"
   ,"   a"
   ," TSSBusy"
   ," CallGate"
   ,"   d"
   ," IntrGate"
   ," TrapGate"
end-string-array   

\ : lowmask  ( #bits -- )  0 swap 0 ?do  1 << 1 +  loop  ;
\ : bits  ( n bit# #bits -- bits )  -rot >>  swap lowmask and  ;
\ : bit  ( n bit# -- )  1 bits  ;
decimal
: .descriptor  ( low high -- )
   base @ >r hex
   dup lbsplit nip nip bwjoin                      ( low high base.high )
   rot lwsplit swap >r  swap wljoin                ( high base ) ( R: limit )
   ." Base: " 8 u.r                                ( high ) ( R: limit )
   ."   Limit: " r> over 16 4 bits wljoin          ( high limit )
   over 23 bit if  12 << h# fff or then  8 u.r     ( high )
   ."  Priv: " dup 13 2 bits .                     ( high )

   dup 15 bit if  ."  Present"  then               ( high )
   dup 22 bit if  ."  32"  else  ."  16"  then     ( high )
   dup 12 bit if
      ."  App "
      dup 9 3 bits privileges ".                   ( high )
      dup 8 bit if  ."  Acc"  else  ."     "  then ( high )
   else
      ."  Sys "
      dup 8 4 bits sys-types ".
   then   ( high )
\  dup 20 bit if  ."  Avail"  then
   drop
   r> base !
;
: get-desc  ( desc# -- low high )
   dup 4 and  if  ldt  else  gdt  then     ( desc# farp )
   rot  h# 7 invert and  far+  far-x@         ( offset )
;
: dump-dt  ( high low -- )
   base @ >r hex
   ?do
      i dup  4 u.r space  get-desc .descriptor  cr
      exit? ?leave
   8 +loop
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
