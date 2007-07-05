purpose: After a crash, displays a backtrace of C stack frames.
\ See license at end of file

only forth also hidden also forth definitions
needs (rstrace rstrace.fth
needs >saved savedstk.fth
only forth also hidden also forth definitions

headerless
: imatch?  ( adr match mask -- adr flag )  2 pick l@ and =  ;

: b?      ( adr -- adr flag )  h# 4800.0000 h# fc00.0000 imatch?  ;
: bc?     ( adr -- adr flag )  h# 4000.0000 h# fc00.0000 imatch?  ;
: bclr?   ( adr -- adr flag )  h# 4c00.0020 h# fc00.07fe imatch?  ;
: bcctr?  ( adr -- adr flag )  h# 4c00.0420 h# fc00.07fe imatch?  ;

: >b-target  ( adr -- target-adr )
   dup l@  dup  d# 6 <<  d# 6 >>a  3 invert and        ( adr instr bd )
   swap  2 and  if  nip  else  +  then
;
: >bc-target  ( adr -- target-adr )
   dup l@  dup  d# 16 <<  d# 16 >>a  3 invert and      ( adr instr bd )
   swap  2 and  if  nip  else  +  then
;
: .subroutine  ( call-adr -- )  \ Show subroutine address
   b?      if  >b-target    9 u.r  exit  then
   bc?     if  >bc-target   9 u.r  exit  then
   bclr?   if  drop %lr     9 u.r  exit  then  \ only works in leaf context
   bcctr?  if  drop %ctr    9 u.r  exit  then  \ only works in leaf context
   drop  ."    ??????"
;
: .args  ( -- )  \ Show C subroutine arguments
   ."  ("  %r3 9 u.r   %r4 9 u.r   %r5 9 u.r   %r6 9 u.r  ."  ... )"
;
: .leaf  ( return-adr -- )
   4 -
   base @ >r  hex
   dup .subroutine  .args  ."  called from "  9 u.r  cr
   r> base !
;
: .subr  ( return-adr -- )
   4 -
   base @ >r  hex
   dup .subroutine  ." ( ???? )"  ."  called from "  9 u.r  cr
   r> base !
;
headers
: ctrace  ( -- )   \ C stack backtrace
   ?saved-state
   ." Last Leaf:" cr   %lr .leaf
   %r1  if
      ." On stack:" cr
      %r1     ( leaf-frame-adr )
      begin  @ dup  while   ( frame-adr )  dup 8 + @ .subr  repeat
      drop
   then
;

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
