\ See license at end of file

\ Forth stack backtrace
\ Implements:
\ (rstrace  ( low-adr high-adr -- )
\    Shows the calling sequence that is stored in memory between the
\    two addresses.  This is assumed to be a saved return stack image.
\ \ rstrace  ( -- )
\ \    Shows the calling sequence that is stored on the return stack,
\ \    without destroying the return stack.

decimal
only forth also hidden also definitions
headerless
: @+  ( adr -- adr' n )  dup na1+ swap @  ; 
: .last-executed  ( ip -- )
   ip>token token@  ( acf )
   dup reasonable-ip?  if   .name   else   drop ." ??"   then
;
: in-catch?  ( ip -- flag )  find-cfa  ['] catch =  ;
: .catch  ( rs-adr -- rs-adr' )
   ."    Catch frame - SP: " @+ .  ."   my-self: "  @+ .  ."   handler: "  @+ .
;
1 bits/cell 1- lshift constant minus0
: .do-or-n  ( rs-adr n -- rs-adr' )
   over @ reasonable-ip?  0=  if              ( rs-adr n )
      \ The second number is not an IP so it could be a do loop frame
      over na1+ @  reasonable-ip?  if         ( rs-adr n )
         \ The third entry is a reasonable IP so it could be a do loop frame
         \ Make sure it points just past a loop end
         over na1+ @                          ( rs-adr n n2 )
         ip>token  -1 na+  token@             ( rs-adr n xt )
         dup ['] (loop) =  swap ['] (+loop) =  or  if  ( rs-adr n )
            \ The two numbers span the +- boundary, so probably a do loop
            ."    Do loop frame inside "
            over na1+ @ ip>token .current-word ( rs-adr n )
            over @                             ( rs-adr n n1 )
            ."   i: "  tuck + .                ( rs-adr n1 )
            ."   limit: "  minus0  + .         ( rs-adr )
            2 na+ exit
         then                                  ( rs-adr n )
      then                                     ( rs-adr n )
   then                                        ( rs-adr n )
   9 u.r
;
: .traceline  ( ipaddr -- )
   push-hex
   dup reasonable-ip?
   if    dup .last-executed ip>token .caller   else  9 u.r   then   cr
   pop-base
;
\ Heuristic display of return stack items, recognizing Forth word nesting,
\ catch frames, and do loop frames.
\ For later: It would also be nice to recognize input stream nesting frames.
: rtraceline  ( rs-adr -- rs-adr' )
   push-hex                    ( rs-adr )
   @+                          ( rs-adr' ip )
   dup reasonable-ip?  if      ( rs-adr ip )
      dup in-catch?  if        ( rs-adr ip )
         drop .catch           ( rs-adr' )
      else                     ( rs-adr ip )
         dup .last-executed ip>token .caller  ( rs-adr )
      then                     ( rs-adr )
   else                        ( rs-adr ip )
      .do-or-n                 ( rs-adr )
   then   cr                   ( rs-adr )
   pop-base
;
: (rstrace  ( end-adr start-adr -- )
    begin  2dup u>  while           ( end-adr adr )
       rtraceline                   ( end-adr adr' )
       exit?  if  2drop exit  then  ( end-adr adr )
    repeat                          ( end-adr adr )
    2drop
;
headers
forth definitions
: rstrace  ( -- )  \ Return stack backtrace
   rp@ rp0 @ u>  if
      ." Return Stack Underflow" rp0 @ rp!
   else
      rp0 @ rp@ (rstrace
   then
;
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
