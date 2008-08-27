\ Forth Floating point package for i387 floating point coprocessor.
\
\ Implements the Forth Vendors Group proposed Forth Floating Point Standard
\ for a 386/387 or 486 system.
\ Uses the coprocessor's internal floating point stack.
\ All floating point numbers are IEEE double-precision format.

\needs error-output  alias error-output noop
\needs restore-output  alias restore-output noop

also assembler definitions
: fop  ( byte1 byte2 -- )  swap asm8, asm8,  ;
previous definitions

hex
only forth definitions 
vocabulary floating
only forth also hidden also floating also definitions


d# 16 constant f#places
8 constant /f
/f constant f#bytes

\ Clear the task-switched bit.  We really should save and restore
\ the FP environment.

use-postfix-assembler

label fp-ts-handler
\   ax push
\   cr0 ax mov
\   8 # al and
\   ax pop
\   0<> if
      0f 06 fop		\ CLTS
      iret
\   else
\      ax pop
\      7 # push
\      save-state #) jmp
\   then
end-code

\ \ nuser xx
\ label fp-exc-handler
\   ax push
\   ax ax xor
\   df e0 fop		\ FNSTSW AX   
\   ax  'user xx  mov
\   ax pop
\    db e2 fop		\ FNCLEX
\    iret
\ end-code

code (finit)  ( -- )  db e3 fop  c;	\ FNINIT

: finit  ( -- )
[ifdef] pm-vector!
   fp-ts-handler cs@  d#  7 pm-vector!
\   fp-exc-handler d# 16 set-vector
[then]
   (finit)
;
finit



d# 28 buffer: fpenvbuf
code fstenv  ( -- )
   'user fpenvbuf ax mov
   9b d9 fop  0 [ax] /6 mem,
   0 [ax] /5 d9 esc		\ fstcw  0 [ax]   restore cw
c;
: .ftags  ( -- )
   fstenv fpenvbuf 8 + w@
   ??cr ." 01234567" cr
   8 0 do
      dup 3 and  " +0X-" drop + c@ emit
      2 >>
   loop
   drop cr
;

code fcw!  ( cw -- )
   sp ax mov
   wait  0 [ax] /5 d9 esc	\ fstcw  0 [ax]
   ax pop
c;
code fcw@  ( -- cw )
   ax ax xor
   ax push
   sp ax mov
   0 [ax] /7 d9 esc		\ fldcw  0 [ax]
c;
\ \ : +exc  cr0@ h# 20 or cr0!  fcw@ 1 not and fcw!  ;


code (fxam)  ( -- type )
   ax ax xor
   d9 e5 fop		\ FXAM
   9b asm8,  df e0 fop	\ FWAIT  FSTSW AX
   ax push
c;
: fntype  ( -- type sign )
   (fxam)
   \ C3 bit - #14       C2 bit - #10              C0 bit - #8
   dup d# 12 >> 4 and  over d# 9 >> 2 and or  over d# 8 >> 1 and or
   \ C1 bit - #9
   swap h# 20 and 0<>
;
string-array  fntypes
   ," Unsupported"
   ," NAN"
   ," Normal"
   ," Infinity"
   ," Zero"
   ," Empty"
   ," Denormal"
end-string-array
: .ftype  ( -- )
   fntype  if  ." +"  else  ." -"  then
   fntypes ".
;

code fstatus  ( -- n )
   ax ax xor		\ Clear high word
   df e0 fop		\ FNSTSW AX
   ax push
c;
: fdepth  ( -- n )
   fstatus d# 11 >> 7 and  dup  if  8 swap -  then
;

: binaryfop:  ( byte2 -- )
   [compile] code
   [ also assembler ]  de over fop  [compile] c;  [ previous ] drop
;

c1 binaryfop: f+
c9 binaryfop: f*

\ d0 binaryfop: fcom   \ Version that doesn't pop the stack
d9 binaryfop: fcmp

\ The Intel 486 manual would have you believe that these should be e1 and
\ f1 (reverse subtract and reverse divide), but e9 and f9 actually work.
e1 binaryfop: frsub
e9 binaryfop: f-

f1 binaryfop: frdiv
f9 binaryfop: f/

: unaryfop:   ( byte2 -- )
   [compile] code
   [ also assembler ]  d9 over fop  [compile] c;  [ previous ] drop
   
;

alias fcon: unaryfop:   ( byte2 -- )

e0 unaryfop: fnegate
e1 unaryfop: fabs
\ e2 unaryfop: fclex
\ e3 -----  (but finit is db e3)
\ e4 unaryfop: ftst   \ See unaryfcmp
\ e5 unaryfop: fxam   \ See (fxam)
\ e6 -----
\ e7 -----

e8 fcon: 1E0
e9 fcon: log2(10)
ea fcon: log2(e)
eb fcon: pi
ec fcon: log10(2)
ed fcon: ln(2)
ee fcon: 0E0
\ ef -----

f0 unaryfop: f2xm1
f1 unaryfop: fyl2x
f2 unaryfop: fptan	\ Accurate only if |arg| < 2^63
f3 unaryfop: fpatan  ( rnum rdenom -- ratan )

f4 unaryfop: fxtract	( r1 -- rexponent rsignificand )
f5 unaryfop: fprem1
\ f6 unaryfop: fdecstp
\ f7 unaryfop: fincstp
f8 unaryfop: fprem

\ f9 unaryfop: fyl2xp1
fa unaryfop: fsqrt
fb unaryfop: fsincos
fc unaryfop: frndint
fd unaryfop: fscale
fe unaryfop: fsin
ff unaryfop: fcos


   

\ 0c unaryfop: fasin
\ 1c unaryfop: facos

\ 0d unaryfop: fatanh
\ 02 unaryfop: fsinh
\ 19 unaryfop: fcosh
\ 09 unaryfop: ftanh

\ See page 17-5 for information about comparisons
also assembler definitions
: xsetif  ( dest set-cond -- )
   h# 0f asm8,
   ( set-cond )  asm8,  0 r/m,
;
previous definitions
: binaryfcmp: ( extension-field -- )  ( Later:  f1 f2 -- flag )
   [compile] code
   [ also assembler ]
   bx bx xor
   de d9 fop		\ FCOMPP
   9b asm8,  df e0 fop	\ FWAIT  FSTSW AX
   sahf
   bl over xsetif   bx neg   bx push
   [compile] c;
   [ previous ]
   drop	
;

94 binaryfcmp: f=
95 binaryfcmp: f<>
97 binaryfcmp: f<
96 binaryfcmp: f>=
93 binaryfcmp: f<=
92 binaryfcmp: f>

: unaryfcmp: ( extension-field -- )  ( Later:  f1 -- flag )
   [compile] code
   [ also assembler ]
   bx bx xor
   d9 e4 fop		\ FTST
   9b asm8,  df e0 fop	\ FWAIT  FSTSW AX
   sahf
   bl over xsetif   bx neg   bx push
   dd c0 fop  d9 f7 fop		\ FFREE ST   FINCSTP   (fdrop)
   [compile] c;
   [ previous ]
   drop	
;

94 unaryfcmp: f0=
95 unaryfcmp: f0<>
92 unaryfcmp: f0<
93 unaryfcmp: f0>=
96 unaryfcmp: f0<=
97 unaryfcmp: f0>

code fix ( f -- l )
   ax push			\ Make room on stack
   sp ax mov
   0 [ax] /3 db esc		\ fistp  0 [ax]
   wait
c;
code float  ( l -- f )
   sp ax mov
   0 [ax] /0 db esc		\ fild  0 [ax]
   wait
   ax pop			\ Discard top of stack
c;
code f! ( f addr -- )
   ax pop
   0 [ax] /3 dd esc		\ FST 0 [ax].64
   wait
c;
code f@  ( addr -- f )
   ax pop
   0 [ax] /0 dd esc		\ FLD 0 [ax].64
   wait
c;

code fdrop  ( f -- )
   dd c0 fop  d9 f7 fop		\ FFREE ST   FINCSTP   (fdrop)
c;
code fswap  ( f1 f2 -- f2 f1 )
   d9 c9 fop			\ FXCH ST(1)
c;

code fover  ( f1 f2 -- f1 f2 f1 )
   d9 c1 fop			\ FLD ST(1)
c;
code fdup  ( f -- f f )
   d9 c0 fop			\ FLD ST(0)
c;

\ Gack! This will be hard to implement if we let the stack spill into memory!
code fpick  ( f x x x n -- f x x x f )
   ax pop
   h# c1 asm8, ax /4 r/m, 8 asm8,	\ SHL AX,#8
   h# c3c0d9 # ax add			\ Create  FLD ST(n) , RET instruction
   ax push				\ Put it on the stack
   sp call				\ Execute it
   ax pop
c;

code frot  ( f1 f2 f3 -- f2 f3 f1 )
   d9 c9 fop		\ FXCH ST(1)	f1 f2 f3 -> f1 f3 f2
   d9 ca fop		\ FXCH ST(2)	f1 f3 f2 -> f2 f3 f1
c;

code f-rot  ( f1 f2 f3 -- f3 f1 f2 )
   d9 ca fop		\ FXCH ST(2)	f1 f2 f3 -> f3 f2 f1
   d9 c9 fop		\ FXCH ST(1)	f3 f2 f1 -> f3 f1 f2
c;

code fpop  ( f -- l l )
   ax push
   ax push
   sp ax mov
   0 [ax] /3 dd esc		\ FST 0 [ax].64
   wait
c;

code fpush  ( l l -- f )
   sp ax mov
   0 [ax] /0 dd esc		\ FLD 0 [ax].64
   wait
   ax pop
   ax pop
c;

: ftan   ( r1 -- r2 )  fptan fdrop  ;
: fatan  ( r1 -- r2 )  1E0 fpatan  ;

\ We could do this without increasing the stack depth if we used a
\ memory location for the constant "1E0"
: 1/f  ( r1 -- r2 )  1E0 frdiv  ;

: flog2  ( r1 -- r2 )  1E0 fswap fyl2x  ;
: flog   ( r1 -- r2 )  log2(10) 1/f fswap fyl2x  ;
: fln    ( r1 -- r2 )  log2(e)  1/f fswap fyl2x  ;

code ftrunc  ( r1 -- r2 )
   ax push			\ Make room on stack
   sp ax mov
   0 [ax] /7 d9 esc		\ fnstcw  0 [ax]
   op: 0 [ax] bx mov		\ Get cw into bx
   h# c00 # bx or		\ Truncate mode
   op: bx 2 [ax] mov		\ Get cw into ax
   2 [ax] /5 d9 esc		\ fnldcw  2 [ax]   truncate toward 0 mode
   d9 fc fop			\ frndint
   0 [ax] /5 d9 esc		\ fnldcw  0 [ax]   restore previous mode
   ax pop			\ Clean up stack
c;
code ffceil  ( r1 -- r2 )
   ax push			\ Make room on stack
   sp ax mov
   0 [ax] /7 d9 esc		\ fnstcw  0 [ax]
   op: 0 [ax] bx mov		\ Get cw into bx
   h# 800 # bx or		\ Truncate mode
   op: bx 2 [ax] mov		\ Get cw into ax
   2 [ax] /5 d9 esc		\ fnldcw  2 [ax]   truncate toward 0 mode
   d9 fc fop			\ frndint
   0 [ax] /5 d9 esc		\ fnldcw  0 [ax]   restore previous mode
   ax pop			\ Clean up stack
c;
code fffloor  ( -- )
   ax push			\ Make room on stack
   sp ax mov
   0 [ax] /7 d9 esc		\ fnstcw  0 [ax]
   op: 0 [ax] bx mov		\ Get cw into bx
   h# 400 # bx or		\ Truncate mode
   op: bx 2 [ax] mov		\ Get cw into ax
   2 [ax] /5 d9 esc		\ fnldcw  2 [ax]   truncate toward 0 mode
   d9 fc fop			\ frndint
   0 [ax] /5 d9 esc		\ fnldcw  0 [ax]   restore previous mode
   ax pop			\ Clean up stack
c;
: int     ( r -- l )  ftrunc  fix  ;
: fceil   ( r -- l )  ffceil  fix  ;
: ffloor  ( r -- l )  fffloor fix  ;

h# 3f800000 constant ione

code falog2  ( r1 -- r2 )
   \ fdup
   d9 c0 fop			\ FLD ST(0)	( fdup )

   \ ftrunc
   ax push			\ Make room on stack
   sp ax mov
   0 [ax] /7 d9 esc		\ fnstcw  0 [ax]
   op: 0 [ax] bx mov		\ Get cw into bx
   h# c00 # bx or		\ Truncate mode
   op: bx 2 [ax] mov		\ Get cw into ax
   2 [ax] /5 d9 esc		\ fnldcw  2 [ax]   truncate toward 0 mode
   d9 fc fop			\ frndint
   0 [ax] /5 d9 esc		\ fnldcw  0 [ax]   restore previous mode
   ax pop			\ Clean up stack

   \ fswap
   d9 c9 fop  			\ FXCH ST(1)   ( integer-part r1 )

   \ fover f-
   d8 e1 fop			\ FSUB ST, ST(i)  ( integer fraction )

   \ f2xm1
   d9 f0 fop			\ F2XM1		( integer alog-1 )

   \ 1E0 f+
   d8 asm8, 'body ione #) /0 r/m,	\ FADD m32real ione

   \ fscale
   d9 fd fop			\ FSCALE

   \ fswap fdrop
   dd d9 fop			\ FSTP ST(1)
c;

\ : falog2  ( r1 -- r2 )
\    fdup ftrunc fswap fover f-   ( integer-part fractional-part )
\    f2xm1 1E0 f+  fscale         ( integer-part result )
\    fswap fdrop
\ ;
: falog   ( r1 -- r2 )  log2(10) f* falog2  ;
: faln    ( r1 -- r2 )  log2(e)  f* falog2  ;

: f**  ( r1 r2 -- r3 )  fswap fyl2x falog2  ;

: f,  ( f -- )  here /f allot  f!  ;

: fvariable  create /f allot  ;

: fconstant  ( fp -- )
   create  here /f allot  f!
   ;code  [apf]  /0 dd esc	\ FLD  [apf].64
c;


1E0 fdup f+ pi  f*  1/f  fconstant 1/twopi
log2(e) falog2 fconstant (e)

code (flit)  ( -- fp )
   0 [ip]  /0 dd esc		\ FLD  0 [ip].64   
   wait
   /f #  ip  add
c;

: fliteral ( fp -- )  compile (flit)  f,  ; immediate

\ Intermediate steps in the development of floating point I/O
\ These words aren't needed after fliteral? is working
\
\ : >f  ( l -- fscaled )
\    float  dpl @ 0>  if  td 10 float dpl @ float f** f/  then
\ ;
\ 
\ Example: 1.3 E 4  puts the floating point number 13000 on the float stack
\ Works inside of colon definitions too.
\ : E  \ exponent  ( l -- fscaled )
\    state @  if
\       \ If we're compiling, we have to grab the number from the code stream
\       here /l - /token - token@
\       ['] (llit) =  if
\          here /l - l@   /l /token + negate allot
\       else
\          ." E must be preceded by a number containing a decimal point"
\          cr abort
\       then
\    then
\    >f bl word number float falog  f*
\    state @  if  [compile] fliteral  then
\ ; immediate

variable #places
: places  ( n -- )  f#places min #places !  ;
2 places

d# 10 buffer: fstrbuf	\ BCD buffer used for floating to ASCII conversion

\ Read a nibble from the BCD conversion buffer
: bcd@  ( offset -- )
   2 /mod fstrbuf +    ( offset adr )
   c@                  ( offset byte )
   swap  if  4 >>  then  h# f and
;

\ Write a nibble into the BCD conversion buffer
: bcd!  ( digit offset -- )
   swap h# 0f and swap
   2 /mod fstrbuf +    ( digit offset adr )
   dup >r c@           ( digit offset byte )  ( r: adr )

   \ Merge the new digit into the appropriate nibble
   swap  if            ( digit byte )
      h# 0f and  swap 4 <<
   else
      h# f0 and
   then
   or  r> c!
;

\ Simple non-destructive printing of top of stack for debugging
\ : f..
\    fdup d# 100 float f* fint
\    dup abs <# # # ascii . hold #s nlswap sign #>
\    type space
\ ;

code fbstp  ( r adr -- )  ax pop  0 [ax] /6 df esc  c;
code fbld   ( adr -- r )  ax pop  0 [ax] /4 df esc  c;

: fpack  ( #places r -- )  float falog f* fstrbuf fbstp  ;  \ Scale by 10^#places

\ Number of digits to the left of the decimal point
: #idigits  ( r -- n )
   fdup f0= if  0  else  fabs flog ffloor 1+  then
;

fvariable fnum

code fsave     ( -- )
   d# 108 # rp sub
   wait dd asm8, 0 [rp] /6 mem,
c;
code frestore  ( -- )
   wait dd asm8, 0 [rp] /4 mem,  wait
   d# 108 # rp add
c;
\ Append a decimal digit, or a '?' if the result is indefinite
: fdigit  ( index -- )
   d# 19 bcd@ 1 and  if  drop ascii ?  else  bcd@ ascii 0 +  then  hold
;
: ?-  ( -- )  d# 19 bcd@ h# 8 and  if  ascii - hold  then  ;
\ Convert floating point number to a string in exponential notation
: (e.)  ( r -- adr len )
   fpop fsave  fpush
   base @ >r decimal
   fdup #idigits
   #places @ over -  fpack
   dup abs <# #s nlswap sign ascii E hold
      #places @ 1 max  0  do  i fdigit   loop
      ascii . hold
      ?-
   #>
   r> base !
   frestore
;	

: e.  ( r -- )  (e.) type space  ;	\ Display in exponential notation

\ Convert floating point number to a string in floating point notation
: (f.)  ( r -- adr len )
\   fdup #idigits #places @ negate d# 18 over +  within  if
   fpop  fsave  fpush
   fdup #idigits  d# 18 #places @ - <  if
      #places @ fpack
      frestore
      0 <#
         #places @ 0 ?do  i fdigit  loop
         ascii . hold
         \ Find leading nonzero digit
         d# 19 bcd@ 1 and  if
	    #places @
         else
            #places @  dup  d# 17 min  d# 17  do
               i bcd@ 0<>  if  drop i  leave  then
            -1 +loop     ( nonzero-digit )
         then
         1+ #places @  do  i fdigit  loop
         ?-
      u#>
   else
      fpop  frestore  fpush
      (e.)
   then
;

: f.  ( f -- )  (f.) type space  ;	\ Display in floating point notation

: fclear  ( -- )  fdepth 0  ?do  fdrop  loop  ;

: (f.s)  ( -- )
   0  fdepth 1-  do  i fpick f.  -1 +loop 
;

: f.s  ( -- )
   fdepth  0=  if  ." Empty" exit  then
   (f.s)
;

\ Floating point input conversion

hidden definitions

\ Variables used by the number scanner
variable exponent
variable point-seen
variable #digits

: getexponent  ( adr len -- adr 0 )
   dup  if                           ( adr len )
      push-decimal
      0. 2swap >number               ( d adr' len' )
      pop-base
      nip  or  abort" bad exponent"  ( n )
   else                              ( adr len )
      nip                            ( 0 )
   then                              ( exponent )
   exponent @ -  exponent !
   exponent @ d# -4932 d# 4932 between 0=  abort" Exponent out of range"
   0 0
;

: nextdigit  ( adr -- adr' char )  1- dup c@  ascii 0 -  ;

\ Store digits of input number in the conversion buffer, from right to left
: putdigits  ( adr -- )
   1-      \ Back up over 'E'                           ( adr' )

   \ Post-decimal digits

   exponent @          0  ?do  nextdigit  i bcd!  loop  ( adr' )

   point-seen @  if  1-  then	\ Skip decimal point

   \ Pre-decimal digits

   #digits @  exponent @  ?do  nextdigit  i bcd!  loop  ( adr' )
   drop
;
         
\ Convert a string to a floating point number
: $scanfloat  ( $ -- r )
   fsave
   fstrbuf d# 10 erase
   point-seen off   0 exponent !  #digits off
   begin  dup  while                    ( adr len )
      over 1+ swap 1-                   ( adr adr' len' )
      rot c@  case
         ascii - of  d# 19 bcd@  8 or  d# 19 bcd!  endof
	 ascii + of                                endof
	 ascii . of  point-seen on                 endof
	 ascii , of  point-seen on                 endof
	 ascii E of  over putdigits  getexponent   endof
	 ( digit )   1 #digits +!
                     point-seen @  if  1 exponent +!  then
      endcase
   repeat                               ( adr len )
   2drop

   \ The digits have been packed into the BCD buffer, and "exponent"
   \ contains the base 10 exponent.  Finish the conversion.

   fstrbuf fbld  exponent @ float falog f*
   fpop  frestore  fpush
;

: fdigit?  ( char -- flag )	\ True if char is a valid floating point digit
   dup ascii 0 ascii 9 between  ( char flag )
   over ascii E = or
   over ascii . = or
   over ascii , = or
   over ascii + = or
   swap ascii - = or
;

forth definitions

: $fnumber?  ( $ -- false | f true )
   base @ d# 10 <>  if  2drop false exit  then
   2dup  bounds  ?do       ( $ )
      i c@ fdigit?  0=  if  2drop false unloop exit  then
   loop                    ( $ )
   $scanfloat true
;

hidden definitions
: ?fstack  ( -- )
   fdepth 0<  if
      ." Floating Point Stack Underflow"
      fclear
   then
   fdepth h# 20 >=  if
      ." Floating Point Stack Overflow"
      fclear
   then
   prompt
;

: $fhandle-literal?  ( $ -- handled? )
   2>r 2r@ $dnumber?  ?dup  if  ( n 1 | d 2 )
      (do-literal)              ( n | d | )
      2r> 2drop  true exit
   then                         ( r: $ )
   2r> $fnumber?  if            ( f )
      state @  if               ( f )
         [compile] fliteral     ( )
      then                      ( f | )
      true exit
   then
   false
;
: .flit      ( ip -- ip' )  ta1+ dup f@ f. /f +  ;
: skip-flit  ( ip -- ip' )  ta1+ /f +  ;
: install-fliteral  ( -- )
   ['] ?fstack                ['] prompt      ['] do-prompt     (patch

   ['] $fhandle-literal?      is $handle-literal?

   ['] (flit)  ['] .flit  ['] skip-flit  install-decomp
   [compile] [
;
: remove-fliteral  ( -- )
   ['] prompt                 ['] ?fstack     ['] do-prompt    (patch
   ['] ($handle-literal?)     is $handle-literal?
   [compile] [
;

forth definitions
decimal 
install-fliteral

forth definitions
warning @ warning off
: (cold-hook  ( -- )
   (cold-hook  finit
   only forth floating also forth also definitions
;
warning !
' (cold-hook is cold-hook
only forth floating also forth also definitions

[ifdef] use-prefix-assembler  use-prefix-assembler  [then]
decimal
