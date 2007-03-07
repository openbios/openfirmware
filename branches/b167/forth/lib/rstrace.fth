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
: .last-executed  ( ip -- )
   ip>token token@  ( acf )
   dup reasonable-ip?  if   .name   else   drop ." ??"   then
;
: .traceline  ( ipaddr -- )
   push-hex
   dup reasonable-ip?
   if    dup .last-executed ip>token .caller   else  9 u.r   then   cr
   pop-base
;
: (rstrace  ( bottom-adr top-adr -- )
   do   i @  .traceline  exit? ?leave  /n +loop
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
