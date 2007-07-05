purpose: Patches to allow limited breakpointing of ROM code
\ See license at end of file

[ifndef] iabr!
code iabr!  ( adr -- )
   mtspr  iabr,tos
   lwz    tos,0(sp)
   addi   sp,sp,1cell
c;
[then]
headerless
: rom-op!  ( op adr -- )
   2dup instruction!      ( op adr )
   2dup op@ =  if         ( op adr )
      2drop               ( )
   else                   ( op adr )
      swap breakpoint-opcode  =  if   ( adr )
         2 or  %msr 5 >> 1 and or     ( iabr-val )
      else                            ( adr )
         drop 0                       ( iabr-val=0 )
      then                            ( iabr-val )
      iabr!                           ( )
   then
;
: rom-at-bp?  ( adr -- flag )
   iabr@  2 and  if
      %msr 5 >> 1 and  iabr@ 1 and  =  if
         dup  iabr@ 3 invert and  =  if  drop breakpoint-opcode exit  then
      then
   then
   op@
;
patch rom-op! instruction! op!
patch rom-at-bp? op@ at-breakpoint?

headers

stand-init:
   h# 13 catch-exception
;
\ Hacros
: --bp  --bp 0 iabr!  ;  : ++ ff30.0000 +  ;
: t --bp  ++ till  ; \ till
: s ++ to %pc ;	\ skip


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
