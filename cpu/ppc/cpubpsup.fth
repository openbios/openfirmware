purpose: Machine-dependent definitions for breakpoints
\ See license at end of file

headerless
0 value breakpoint-opcode
defer breakpoint-trap?
' true is breakpoint-trap?  \ XXX until arcbpsup is installed...

: op@  ( adr -- op )  l@  ;
: op!  ( op adr -- )  instruction!  ;
: bp-address-valid?  ( adr -- flag )  3 and  0=  ;
: at-breakpoint?  ( adr -- flag )  op@  breakpoint-opcode =  ;
: put-breakpoint  ( adr -- )  breakpoint-opcode swap op!  ;

headers
: .instruction  ( -- )
   %pc   [ also assembler ] pc ! dis1 [ previous ]
;

headerless
\ Find the places to set the next breakpoint for single stepping.

\ Flag is true if the branch should be followed - we don't follow branches
\ if stepping? is false and the instruction modifies the link register.
: -hop?  ( stepping? pc -- stepping? pc flag )  2dup 1 and 0=  or  ;
: next-instruction  ( stepping? -- next-adr branch-target|0 )
   %pc la1+   swap                          ( next-adr stepping? )

   \ If we are hopping (not stepping), then we don't follow subroutine
   \ calls (branches that have the link bit set).  We needn't bother
   \ checking whether or not the instruction is a branch, because if
   \ it isn't, we want to do the same thing as for a branch with link.
   0=  %pc l@ 1 and  and  if  0 exit  then  ( next-adr )

   %pc                                      ( next-adr pc )
   bclr?   if  drop %lr    exit  then       ( next-adr pc )
   bcctr?  if  drop %ctr   exit  then       ( next-adr pc )
   bc?     if  >bc-target  exit  then       ( next-adr pc )
   b?      if  >b-target   exit  then       ( next-adr pc )
   drop 0
;

: bumppc  ( -- )  %pc la1+ to %pc   ;

alias rpc %pc

code goto  ( adr -- )
   mtspr  lr,tos
   lwz    tos,0(sp)
   addi   sp,sp,4
   bclr   20,0
end-code

: return-adr  ( -- adr )  %r1 @ 8 + @  ;
: leaf-return-adr  ( -- adr )  %lr  ;

: backward-branch?  ( adr -- flag )  \ True if adr points to a backward branch
   b?   if  dup  >b-target  u>  exit  then   ( adr )
   bc?  if  dup  >bc-target u>  exit  then   ( adr )
   drop false
;
: loop-exit-adr  ( -- adr )
   %pc  begin  dup backward-branch? 0=  while  la1+  repeat  la1+
;

headers
: set-pc  ( adr -- )  to %pc  ;

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
