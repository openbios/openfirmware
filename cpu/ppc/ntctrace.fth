purpose: Stack backtrace for Microsoft/Motorola compiler
\ See license at end of file

headerless
\ Search forward for a "bclr" instruction, then search backward for
\ "lwz r0,XXX(r1), then get the contents of that effective address.
: pc>caller  ( fp pc -- call-point-adr )
   \ XXX we need to determine where we are in the function - if we are
   \ before the place where the frame pointer is updated, or after the
   \ place where it is restored, we must treat the function as a leaf
   \ routine and get the caller address directly from LR.  It is probably
   \ a good idea to first check to see if the function is a pure leaf
   \ routine, by searching for a "stwu r1,XX(r1)" instruction between
   \ the beginning and the bclr.  Hmmm...  I wonder if the beginning
   \ address of a leaf routine can be determined?  It might not begin
   \ with a "mfspr r0,lr".

   begin  dup l@ h# 4e800020 <>  while  la1+  repeat  ( fp end-adr )
   begin  -1 la+  dup l@  d# 16 >>  h# 8001 =  until  ( fp lwz-adr )
   l@ h# ffff and  + l@ -1 la+
;
\ Search forward for an "mfspr r0,lr" instruction
: pc>function  ( pc -- entry-adr )
   begin  dup l@  h# 7c0802a6 <> while  -1 la+  repeat  ( mfspr-r0,lr-adr )
;

\ Determine the stack frame size of the function containing the given PC
\ by finding the first "stwu r1,XXX(r1)" instruction in the function.
: pc>framesize  ( pc -- /frame )
   pc>function
   begin  dup l@ d# 16 >>  h# 9421 <>  while  la1+  repeat   ( stwu-adr )

   \ The offset is negative, so merge in the sign bits and negate it
   l@ h# ffff invert or  negate
;

: .adr  base @ >r hex 9 u.r r> base !  ;

: .call  ( fp caller function -- )
   .adr  ." ()  called from" .adr ."   FP: " .x cr
;

\ This must agree with the stack initialization jointly established by
\ init-pe-program and (init-program).
: pe-stack-top  ( -- adr )  pe-image-base h# 20 -  ;

headers
\ XXX show TOC too
: ms-ctrace  ( -- )
   ?saved-state
   %r1  %pc                                     ( frame-ptr pc )
   begin                                        ( frame-ptr pc )
      over  pe-stack-top <>                     ( frame-ptr pc )
   while                                        ( frame-ptr pc )
      dup pc>function >r                        ( frame-ptr pc )
      2dup pc>caller  >r  over r> r> .call      ( frame-ptr pc )
      2dup pc>caller -rot pc>framesize +  swap  ( frame-ptr' pc' )
      exit?  if  2drop exit  then               ( frame-ptr' pc' )
   repeat                                       ( frame-ptr' pc' )
   2drop 0 pe-image-base .call                  ( )
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
