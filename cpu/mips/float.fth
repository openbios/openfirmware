purpose: Forth Floating point package for MIPS
\ See license at end of file

\ Has a separate floating point stack.
\ All floating point numbers are IEEE double-precision format.

\ Additional floating point words, including input and output conversion,
\ are in unix/sparc/floatext.fth

hex
only forth definitions vocabulary floating
only forth also hidden also floating also definitions

create float.fth

16 constant f#places
8 constant /f
/f constant f#bytes

: align8  ( adr -- adr' )  7 +  -8 and  ;
h# 20 /f * constant /fstack

/fstack /f +  buffer: fstack		\ Including slack for alignment

/l ualloc user fp0

: fp  ( -- n )  [ assembler ]  s7  ;

code fp!  ( adr -- )  tos fp move  sp tos pop  c;
code fp@  ( adr adr )  tos sp push  fp tos move  c;

: fclear  ( -- )  fp0 l@ fp!  ;
: finit  ( -- )  fstack align8  /fstack + /f -   fp0 l!  fclear  ;

finit
: fdepth  ( -- n )  fp0 l@  fp@  -  /f /  ;

code f+  ( f1 f2 -- f3 )
   fp 0     $f3  lwc1
   fp 4     $f2  lwc1
   fp /f    fp   addiu
   $f0 $f2  $f0  addf .d
c;
code f-  ( f1 f2 -- f3 )
   fp 0     $f3  lwc1
   fp 4     $f2  lwc1
   fp /f    fp   addiu
   $f2 $f0  $f0  subf .d
c;
code f*  ( f1 f2 -- f3 )
   fp 0     $f3  lwc1
   fp 4     $f2  lwc1
   fp /f    fp   addiu
   $f0 $f2  $f0  mulf .d
c;
code f/  ( f1 f2 -- f3 )
   fp 0     $f3  lwc1
   fp 4     $f2  lwc1
   fp /f    fp   addiu
   $f2 $f0  $f0  divf .d
c;

code fsqrt    ( f1 -- f2 )  $f0 $f0 sqrt .d  c;
code fnegate  ( f1 -- f2 )  $f0 $f0 negf .d  c;
code fabs     ( f1 -- f2 )  $f0 $f0 abs  .d  c;

variable cond
: leaveflag  ( -- )
   asm(
      \    CMP.cond.D  $f2,$f0
      cop1 .d   $f2 rd  $f0 rt  h# 30 addbits  cond @ h# f land  addbits

      tos     sp    push
      here h# 0c +  cond @  h# 10 land  [ also forth ]  if  [ previous ]
         bc1f
      [ also forth ]  else  [ previous ]
         bc1t
      [ also forth ]  then  [ previous ]
         $0  -1  tos   addiu	  \ Delay slot, always executed
         $0      tos   move	  \ Executed only if condition is false
      ( then )
      fp /f      $f1   lwc1
      fp /f 4 +  $f0   lwc1
      fp /f      fp    addiu
      c;
   )asm
;
: binaryfcmp: ( extension-field -- )  ( Later:  f1 f2 -- flag )
   cond !
   code

   asm(
      fp 0    $f3   lwc1
      fp 4    $f2   lwc1
      fp /f   fp    addiu
   )asm

   leaveflag
;
: unaryfcmp: ( extension-field -- )  ( Later:  f1 -- flag )
   cond !
   code
   asm(
      $f2  $0    mtc1      bubble
      $f2  $f2   cvt.d .w
   )asm
   leaveflag
;

\ The inverse sense of extension-code for the binary comparisons is
\ because the operands come off the stack in the reverse order

assembler also

 2 binaryfcmp: f=
12 binaryfcmp: f<>
 4 binaryfcmp: f<
1f binaryfcmp: f>
 e binaryfcmp: f<=
1d binaryfcmp: f>=

 2 unaryfcmp: f0=
12 unaryfcmp: f0<>
1e unaryfcmp: f0<
 d unaryfcmp: f0>
1c unaryfcmp: f0<=
 f unaryfcmp: f0>=

previous floating

/f negate constant -/f
code fint  ( f -- l )
   $f0    $f0   cvt.w .d
   tos    sp    push
   $f0    tos   mfc1
   fp 0   $f1   lwc1
   fp 4   $f0   lwc1
   fp /f  fp    addiu
c;

code float  ( l -- f )
   fp -/f  fp    addiu
   $f1     fp 0  swc1
   $f0     fp 4  swc1
   $f0     tos   mtc1
   sp      tos   pop
   $f0     $f0   cvt.d .w
c;
code f!  ( f adr -- )
   $f1    tos 0  swc1	\ Don't require doubleword alignment
   $f0    tos 4  swc1
   sp     tos    pop
   fp 0   $f1    lwc1
   fp 4   $f0    lwc1
   fp /f  fp     addiu
c;
code f@  ( adr -- f )
   fp -/f fp     addiu
   $f1    fp 0   swc1
   $f0    fp 4   swc1
   tos 0  $f1    lwc1	\ Don't require doubleword alignment
   tos 4  $f0    lwc1
   sp     tos    pop
c;
code fdrop  ( f -- )
   fp 0   $f1  lwc1
   fp 4   $f0  lwc1
   fp /f  fp   addiu
c;
code fswap  ( f1 f2 -- f2 f1 )
   fp 0   $f3    lwc1
   fp 4   $f2    lwc1
   bubble
   $f1    fp 0   swc1
   $f0    fp 4   swc1
   $f2    $f0    movf .d
c;
code fover  ( f1 f2 -- f1 f2 f1 )
   fp -/f fp    addiu
   $f1    fp 0  swc1
   $f0    fp 4  swc1
   fp /f      $f1   lwc1
   fp /f 4 +  $f0   lwc1
c;
code fdup  ( f -- f f )
   fp -/f fp    addiu
   $f1    fp 0  swc1
   $f0    fp 4  swc1
c;
code frot  ( f1 f2 f3 -- f2 f3 f1 )
   fp 0   $f3    lwc1
   fp 4   $f2    lwc1
   $f1    fp 0   swc1
   $f0    fp 4   swc1
   fp /f      $f1    lwc1
   fp /f 4 +  $f0    lwc1
   $f3    fp /f      swc1
   $f2    fp /f 4 +  swc1
c;
code fpick  ( n -- ; F: fn ... f0 -- fn ... f0 fn )
   fp -/f fp  addiu		\ Make space on stack
   $f1   fp 0 swc1
   tos $0 <>  if
   $f0   fp 4  swc1		\ Delay slot; push top of stack to memory
      tos 3   tos  sll		\ Index into floating point stack
      fp tos  tos  addu
      tos 0   $f1  lwc1		\ Get n'th item from floating point stack
      tos 4   $f0  lwc1
   then
   sp tos pop
c;

code fpop  ( f -- l l )
   tos    sp     push
   sp -4  sp     addiu
   $f0    sp 0   swc1
   $f1    tos    mfc1
   fp 0   $f1    lwc1
   fp 4   $f0    lwc1
   fp /f  fp     addiu
c;
code fpush  ( l l -- f )
   fp -/f fp     addiu
   $f1    fp 0   swc1
   $f0    fp 4   swc1
   $f1    tos    mtc1
   sp 0   $f0    lwc1
   sp 4   tos    lw
   sp 8   sp     addiu
c;

: fvariable  ( -- )  create /f allot  ;
: fconstant  ( fp -- )
   create  here  /f allot  f!
   does> f@
;
: ifconstant  ( fp-on-p-stack -- )
   create  here  /f allot  dup >r l!  r> /l + l!
   does> f@
;
00000000 3ff00000  ifconstant  1E0
00000000 3fe00000  ifconstant  .5E0

\ XXX We really should round to nearest or even.
: fix  ( -- )  .5E0 f+ fint  ;

code (flit) ( -- fp )
   fp -/f fp    addiu
   $f1    fp 0  swc1
   $f0    fp 4  swc1
   ip 0   $f1   lwc1
   ip 4   $f0   lwc1
   ip /f  ip    addiu
c;


: fliteral  ( fp -- )  compile (flit)  here /f allot  f!  ; immediate

code 10**i  ( i -- fp )  \ Raise 10 to the i'th power

   \ if i < 0, we compute 10**|i|, then take the reciprocal

   fp -/f fp     addiu	\ Prepare to push the floating number
   $f1    fp 0   swc1
   $f0    fp 4   swc1

   1      t0     li
   $f0    t0     mtc1
   d# 10  t0     li	   \ (Load delay)
   $f0    $f0    cvt.d .w  \ 1E0 in $f0

   $f2    t0     mtc1
   bubble
   $f2    $f2    cvt.d .w  \ 10E0 in $f2

   \ Set scr to the absolute value of i

   tos 0<  if
      tos      t0   move	\ t0  = i
      $0  tos  t0   subu	\ t0  = -i
   then

   tos $0 <> if	\ Leave answer at 1 if i=0
      nop
      begin
         $f0 $f2  $f0  mulf .d	\ Multiply current result by 10
	 t0 -1    t0   addiu
      t0 $0 = until
         nop
   then

   \ If the exponent is negative, compute the reciprocal
   tos 0<  if			\ Save i for its sign
      1         t0   li
      $f2       t0   mtc1
      $f2       $f2  cvt.d .w	\ 1E0 in $f2
      $f2 $f0   $f0  divf .d	\ Take the reciprocal
   then

   sp  tos  pop		\ Fix data stack
c;

: >f  ( l -- fscaled )
   float  dpl @ 0>  if  dpl @  10**i  f/  then
;

\ Kludge, kludge
\ Example: 1.3 E 4  puts the floating point number 13000 on the float stack
\ Works inside of colon definitions too.
: E  \ exponent  ( l -- fscaled )
   state @
   if   \ If we're compiling, we have to grab the number from the code stream
      here /l - /token - token@
      ['] (llit) =
      if    here /l - l@   /l /token + negate allot
      else ." E must be preceded by a number containing a decimal point"
           cr abort
      then
   then
   >f bl word number  10**i  f*
   state @  if  [compile] fliteral  then
; immediate

forth definitions
: (cold-hook  ( -- )  (cold-hook  finit  ;
' (cold-hook is cold-hook
only forth floating also forth also definitions

decimal

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
