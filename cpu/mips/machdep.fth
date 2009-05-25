purpose: Breakpoint support words for MIPS
\ See license at end of file

: op@  ( adr -- op )  >vmem l@  ;
: op!  ( op adr -- )  >vmem instruction!  ;
: at-breakpoint?  ( adr -- flag )  op@  breakpoint-opcode =  ;
: put-breakpoint  ( adr -- )  breakpoint-opcode swap op!  ;

: j?   ( adr -- adr flag )  h# 0800.0000 h# fc00.0000 imatch?  ;
: jr?  ( adr -- adr flag )  h# 0000.0008 h# fc00.003f imatch?  ;
: branch?  ( adr -- flag )
   h# 1000.0000  h# b000.0000  imatch?  >r  \ beq(l),bne(l),blez(l),bgtz(l)
   h# 0400.0000  h# fc1c.0000  imatch?      \ bltz,bgez,bltzl,bgezl
   r>  or
;

: delayed?  ( adr -- flag )
   j? swap  jr? swap  jal? swap  jalr? swap  bal? swap  branch? swap
   drop  or or or or or
;
: .instruction  ( -- )
   $pc 
   [ also disassembler ] pc ! dis1 [ previous ]
   $pc delayed?  if
      $pc la1+ [ also disassembler ] pc ! dis1 [ previous ]
   then
;

\ Find the places to set the next breakpoint for single stepping.
\ Usually the right place is at nPC .  However, for annulled branch
\ instructions, we have to cope with the possibility that the delay
\ instruction, which is where nPC points, won't be executed.  Annulled
\ unconditional branches never execute the delay instruction, so we have
\ to put the breakpoint at the branch target.  Annulled conditional
\ branches will either execute the delay instruction or the one right
\ after it.

: >after-delay  ( adr -- adr' )  2 la+  ;
variable step?
: next-instruction  ( stepping? -- next-adr branch-target|0 )
   step? !
   $pc
   j?    if  >j-target   0 exit  then
   jr?   if  >jr-target  0 exit  then
   jal?  if  step? @  if  >j-target   else  >after-delay  then  0  exit  then
   jalr? if  step? @  if  >jr-target  else  >after-delay  then  0  exit  then
   bal?  if
      step? @  if  dup >after-delay swap >br-target  else  >after-delay 0  then
      exit
   then
   branch?  if  dup >after-delay  swap >br-target  exit  then
   la1+  0
;
: bumppc  ( -- )  $pc la1+ to $pc   ;
alias rpc $pc

code goto  ( adr -- )
   tos       t0   move
   sp        tos  get
   t0             jr
   sp /n     sp   add
end-code

: return-adr  ( -- adr )  $ra  ;
: leaf-return-adr  ( -- adr )  $ra  ;
: backward-branch?  ( adr -- flag )  \ True if adr points to a backward branch
   l@                                        ( instruction )
   dup branch?                               ( instruction branch? )
   swap  h# 0000.8000 and  0<>               ( branch? backward? )
   and
;
: loop-exit-adr  ( -- adr )
   \ Start at PC-4 in case we're sitting on a delay instruction at the loop end
   $pc 4 -  begin  dup backward-branch? 0=  while  4 +  repeat  8 +
;

headers
: set-pc  ( adr -- )  to $pc  ;

\ LICENSE_BEGIN
\ Copyright (c) 2009 FirmWorks
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
