\ See license at end of file
purpose: After a breakpoint, displays a backtrace of C stack frames.

\ This assumes the "standard" i386 stack frame format implied by
\ the hardware's "leave" instruction, i.e.
\    <high addresses>
\          [arguments ..]
\          return-address
\ %ebp ->  caller's %ebp        (%ebp is the frame pointer)
\          [local variables ..]
\ %esp ->


only forth also hidden also forth definitions

headerless
false value ctrace-more?

defer valid-adr?  ' 0<> to valid-adr?

defer .subname  ( adr -- )
' .x is .subname
: x. . ;

: .fp    ( fp -- )  ."   FP: " .x  ;
: .from  ( call-adr -- )  ." called from " .subname cr  ;

: invalid?  ( adr -- adr flag )
   dup 0<>  if   dup valid-adr?  if  false exit  then   then
   false to ctrace-more?  true
;

: .args  ( fp -- )
   invalid?  if  drop cr  exit  then
   ."  ("                                                       ( fp )
   dup 2 na+ 4 /n* bounds  do  i @ (u.) type ." , "  /n +loop   ( fp )
   ." ...)"  cr                                                 ( fp )
   ."   FP: " push-hex (u.) type pop-base  ." , "
;

: mode-field  ( adr -- mode )  c@  3 rshift  7 and  ;
: indirect?  ( fp ra offset -- true | fp ra false )
   over swap -                      ( fp ra adr' )
   dup c@  h# ff =   if             ( fp ra adr' )
      dup 1+ mode-field  2 =  if    ( fp ra adr' )
         ." <indirect call>"        ( fp ra adr' )
         rot .args                  ( ra adr' )
         .from                      ( )
         drop true  exit            ( true )
      then                          ( fp ra adr' )
   then                             ( fp ra adr' )
   drop false                       ( fp ra false )
;
      
\ Show the subroutine name or address and the call point address
: .subroutine  ( fp return-adr -- )
   invalid?  if  2drop exit  then                             ( fp ra )
   dup 8 - invalid?  if  3drop exit  then  drop               ( fp ra )

   \ Search for one of the various forms of call instruction
   \ at likely places preceding the return address

   dup 5 - c@ h# e8 =  if     \ near, relative displacement   ( fp ra )
      dup   dup 4 - @ + .subname                              ( fp ra )
      swap .args                                              ( ra )
      5 - .from                                               ( )
      exit
   then

   dup 7 - c@ h# 9a =  if     \ immediate far call            ( fp ra )
      dup 2 - w@  x. ." :" dup 6 - l@ .subname                ( fp ra )
      swap .args                                              ( ra )
      7 - .from                                               ( )
      exit
   then

   \ indirect near calls with various operand lengths
   2 indirect?  if  exit  then                                ( fp ra )
   3 indirect?  if  exit  then                                ( fp ra )
   4 indirect?  if  exit  then                                ( fp ra )
   5 indirect?  if  exit  then                                ( fp ra )
   6 indirect?  if  exit  then                                ( fp ra )
   8 indirect?  if  exit  then                                ( fp ra )

   \ Memory indirect far call
   dup 8 - c@ h# ff =  if                                     ( fp ra )
      dup 7 - mode-field  3 =  if                             ( fp ra )
         dup 6 - l@  over 2 - w@ far-l@ .subname              ( fp ra )
         swap .args                                           ( ra )
         8 - .from                                            ( )
         exit
      then
   then                                                       ( fp ra )

   \ Didn't find a call.  We have is probably run off the end of
   \ the call chain, but we display it just in case the above
   \ heuristic missed a valid call.  We depend on the "invalid?"
   \ checks in various places to eventually stop the process.
   ." ???"  swap .args                                        ( ra )
   ." returns to  " .subname cr
;

\ Show the subroutine call for the given frame pointer, with arguments
: .c-call  ( fp -- )
   invalid?  if  drop cr  exit  then
   dup   na1+ @  invalid?  if  2drop cr  exit  then  ( fp ra )
   .subroutine  cr
;

headers

: ctrace  ( -- )   \ C stack backtrace
   state-valid @  0=  if   ." No saved state"  exit  then
   true to ctrace-more?
   cr ." PC: "  %eip .subname    ."  SP: "  %esp .x cr cr
   %ebp
   begin  exit? 0=  ctrace-more? and  while  ( fp )
      dup .c-call
      invalid?  0=  if  @  then
   repeat
   drop
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
