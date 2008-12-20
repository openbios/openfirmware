purpose: Processor-dependent definitions for breakpoints on ARM
\ See license at end of file

\ Machine-dependent definitions for breakpoints

headerless
defer breakpoint-trap?

\ True if the exception was an undefined instruction
: (breakpoint-trap?  ( -- flag )  exception-psr h# 1f and h# 1b =  ;
' (breakpoint-trap? is breakpoint-trap?

: op@  ( adr -- op )  l@  ;
: op!  ( op adr -- )  instruction!  ;
: bp-address-valid?  ( adr -- flag )  3 and  0=  ;
: at-breakpoint?  ( adr -- flag )  op@  breakpoint-opcode =  ;
: put-breakpoint  ( adr -- )  breakpoint-opcode swap op!  ;

headers
: .instruction  ( -- )
   pc   [ also disassembler ] dis-pc! dis1 [ previous ]
;

headerless
\ Find the places to set the next breakpoint for single stepping.

\ Flag is true if the branch should be followed - we don't follow branches
\ if stepping? is false and the instruction is a "bl"
: >b-target  ( pc -- adr )  dup l@ 8 << 6 >>a + 8 +  ;
: bl?  ( pc -- flag ) l@ h# 0f00.0000 and h# 0b00.0000 =  ;
: b?   ( pc -- flag ) l@ h# 0e00.0000 and h# 0a00.0000 =  ;

: next-instruction  ( stepping? -- next-adr branch-target|0 )
   pc la1+   swap                          ( next-adr stepping? )

   \ If we are hopping (not stepping), then we don't follow
   \ branch-and-link instructions.
   0=  pc bl? and  if  0 exit  then         ( next-adr )

   pc                                       ( next-adr pc )
   dup b?   if  >b-target  exit  then       ( next-adr pc )
   dup bl?  if  >b-target  exit  then       ( next-adr pc )
\ XXX need to handle all sorts of instructions with PC as the destination
   drop 0
;

: bumppc  ( -- )  pc la1+ to pc   ;

alias rpc pc

: return-adr  ( -- adr )  r11 l@  ;
: leaf-return-adr  ( -- adr )  lr  ;

: backward-branch?  ( adr -- flag )  \ True if adr points to a backward branch
   dup b?  if  dup >b-target  u>  exit  then   ( adr )
   drop false
;
: loop-exit-adr  ( -- adr )
   pc  begin  dup backward-branch? 0=  while  la1+  repeat  la1+
;

headers
: set-pc  ( adr -- )  to pc  ;

\ LICENSE_BEGIN
\ Copyright (c) 1994 FirmWorks
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
