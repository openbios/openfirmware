purpose: Forth floating point package for ARM FPU/FPE
\ See license at end of file

\ Contributed by Hanno Schwalm
\ Implements ths ANS Forth floating and floating extended package.
\ needs Fothmacs V. 3.1/2.12 or higher 
\ All floating point numbers are IEEE double-precision format
\ using a seperate floating stack assigned by a user variable fp.

only forth also  arm-assembler also definitions

: popf0		s" r7 'user fp ldr  f0 r7 popf  r7 'user fp str" evaluate ;
: popf1		s" r7 'user fp ldr  f1 r7 popf  r7 'user fp str" evaluate ;
: popf2		s" r7 'user fp ldr  f2 r7 popf  r7 'user fp str" evaluate ;
: pushf0	s" r7 'user fp ldr  f0 r7 pushf r7 'user fp str" evaluate ;
: pushf1	s" r7 'user fp ldr  f1 r7 pushf r7 'user fp str" evaluate ;
: pushf2	s" r7 'user fp ldr  f2 r7 pushf r7 'user fp str" evaluate ;

only forth also system also definitions hex

code @fs        ( -- n )        \ get the floating status
        top     sp              push
        top                     rfs
        top     top     0f #	and c;
code !fs        ( n -- )        \ set the floating status
        r1      top     0f #	and
        top     sp              pop
        r0                      rfs
        r0      r0	ff00 #	and
        r0      r0      r1      orr
        r0                      wfs c;

nuser fbuff  /float 2* ualloc drop
: @sign         ( -- f) fbuff @ 80000000 and 0<> ;
: @esign        ( -- f) fbuff @ 40000000 and 0<> ;
: !sign         ( f )   0<> 80000000 and  fbuff @ 4fffffff and or fbuff ! ;
: !esign        ( f )   0<> 40000000 and  fbuff @ 8fffffff and or fbuff ! ;
: @nibble       ( #nibb -- n2 )
        8 /mod swap >r cells fbuff + @ 7 r> - 4* rshift  0f and ;
: !nibble       ( #nibb n )
        swap  8 /mod swap >r cells fbuff +      ( n addr        r: n-th )
        f0000000 r@ 4* rshift -1 xor            ( n addr mask   r: n-th )
        over @ and                              ( n addr ncont  R: n-th )
        rot  7 r> - 4* lshift  or  swap ! ;

decimal

: @exp          0 5 1 do 10 *  i @nibble + loop  @esign ?negate 1+ ;
: @dig          5 + @nibble [char] 0 + ;

code !flpd      \ ( addr -- ) 
                 popf0 
        packed  f0      top 3 cells ia stf double
                top     sp      pop c;
\ a packed decimal is read at addr and written to the floating stack
code @flpd      ( addr -- )
        packed  f0      top 3 cells ia ldf double
                 pushf0 
                top     sp      pop c;

: fp-error
        @fs  0 !fs
        dup      2 and  if -42 throw then
        dup     13 and  if -43 throw then
                16 and  if -41 throw then abort ;

arm-assembler definitions
: c;fl  \ ends a floating point code definitions with checking for errors
        r0 rfs   r0 r0 h# 0f # s and   eq next   ip  ['] fp-error >body adr c; ;

forth definitions
: (cold-hook    0 !fs (cold-hook ;  ' (cold-hook is cold-hook

\ often used floating high precision constants
code -.5E0	f0	#0.5	mnf	 pushf0  c;
code -1E0	f0	#1.0	mnf	 pushf0  c;
code -2E0	f0	#2.0	mnf	 pushf0  c;
code -3E0	f0	#3.0	mnf	 pushf0  c;
code -4E0	f0	#4.0	mnf	 pushf0  c;
code -5E0	f0	#5.0	mnf	 pushf0  c;
code -1E1	f0	#10.0	mnf	 pushf0  c;
code 0E0	f0	#0.0	mvf	 pushf0  c;
code .5E0	f0	#0.5	mvf	 pushf0  c;
code 1E0	f0	#1.0	mvf	 pushf0  c;
code 2E0	f0	#2.0	mvf	 pushf0  c;
code 3E0	f0	#3.0	mvf	 pushf0  c;
code 4E0	f0	#4.0	mvf	 pushf0  c;
code 5E0	f0	#5.0	mvf	 pushf0  c;
code 1E1	f0	#10.0	mvf	 pushf0  c;

code f+         ( f1 f2 -- f3 )  popf0 popf1 f0 f1 f0 adf pushf0  c;fl
code f-         ( f1 f2 -- f3 )  popf0 popf1 f0 f1 f0 suf pushf0  c;fl
code f*         ( f1 f2 -- f3 )  popf0 popf1 f0 f1 f0 muf pushf0  c;fl
code f/         ( f1 f2 -- f3 )  popf0 popf1 f0 f1 f0 dvf pushf0  c;fl
code f**        ( f1 f2 -- f3 )  popf0 popf1 f0 f1 f0 pow pushf0  c;fl
code fmod	( f1 f2 -- f3 )	 popf0 popf1 f0 f1 f0 rmf pushf0  c;fl
code fsin       ( f1 -- f2 )     popf0  f0 f0 sin  pushf0  c;fl
code fasin      ( f1 -- f2 )     popf0  f0 f0 asn  pushf0  c;fl
code fcos       ( f1 -- f2 )     popf0  f0 f0 cos  pushf0  c;fl
code fsincos	( f1 -- f2 f3 )	 popf0  f1 f0 sin  f2 f0 cos  pushf0 pushf1  c;fl
code facos      ( f1 -- f2 )     popf0  f0 f0 acs  pushf0  c;fl
code ftan       ( f1 -- f2 )     popf0  f0 f0 tan  pushf0  c;fl
code fatan      ( f1 -- f2 )     popf0  f0 f0 atn  pushf0  c;fl
code fln        ( f1 -- f2 )     popf0  f0 f0 lgn  pushf0  c;fl
code flnp1      ( f1 -- f2 )     popf0  f0 f0 #1.0 adf  f0 f0 lgn  pushf0  c;fl
code flog       ( f1 -- f2 )	 popf0  f0 f0 log  pushf0  c;fl
code falog	( f1 -- f2 )	 popf0  f0 #10.0 f0 pow  pushf0  c;fl
code fsqrt      ( f1 -- f2 )     popf0  f0 f0 sqt  pushf0  c;fl
code fexp       ( f1 -- f2 )     popf0  f0 f0 exp  pushf0  c;fl
code fexpm1	( f1 -- f2 )	 popf0  f0 f0 exp  f0 f0 #1.0 suf pushf0  c;fl
code fabs	( f1 -- absf1 )	 popf0  f0 f0 abs  pushf0  c;fl
code fnegate	( f1 -- -f1 )	 popf0  f0 f0 mnf  pushf0  c;fl
code floor	( f1 -- f2 )	 popf0 -infinity f0 f0 rnd nearest pushf0  c;fl
code fround	( f1 -- f2 )	 popf0  f0 f0 rnd  pushf0  c;fl 
code fhyp	( f1 -- 1/f1)	 popf0  f0 f0 #1.0 rdf pushf0  c;fl
code sf@	( sf-addr ) ( f: --sf )
	single	f0	top	popf
        double			 pushf0 
        	top	sp	pop c;fl
code sf!
	double			 popf0 
	single	f0	top	pushf
	double	top	sp	pop c;fl

: facosh	( f1 -- f2 )	fhyp facos ;
: fasinh	( f1 -- f2 )	fhyp fasin ;
: fatan2	( f1 f2 -- f3 )	f/ fatan ;
: fatanh	( f1 -- f2 )	fhyp fatan ;
: fsinh		( f1 -- f2 )	fsin fhyp ;
: ftanh		( f1 -- f2 )	ftan fhyp ;


code f<         ( f1 f2 -- | f )
                top     sp      push     popf1 popf0 
                f0      f1      cmfe
                top -1 # lt mov		top 0 # ge mov c;fl
code f>         ( f1 f2 -- | f )
                top     sp      push     popf1 popf0 
                f0      f1      cmfe
                top -1 # gt mov		top 0 # le mov c;fl
code f=         ( f1 f2 -- | f)
                top     sp      push     popf1 popf0 
                f0      f1      cmf
                top -1 # eq mov		top 0 # ne mov c;fl
code f<>                ( f1 f2 -- | f)
                top     sp      push     popf1 popf0 
                f0      f1      cmf
                top -1 # ne mov		top 0 # eq mov c;fl
code f0=        top     sp      push     popf0 
                f0      #0.0    cmfe
                top -1 # eq mov		top 0 # ne mov c;fl
code f0<        top     sp      push     popf0 
                f0      #0.0    cmfe
                top -1 # lt mov		top 0 # ge mov c;fl
code f0>        top     sp      push     popf0 
                f0      #0.0    cmfe
                top -1 # gt mov		top 0 # le mov c;fl

code fdup       ( f1 -- f1 f1 )
		r2	'user fp	ldr
                r0 r1 2 	r2 ia	ldm
                r0 r1 2 	r2 db!	stm
                r2	'user fp	str c;
code fdrop      ( f1 -- )
		r0	'user fp	ldr
                r0	2 cells		incr
                r0	'user fp	str c;
code fswap      ( f1 f2 -- f2 f1 )
		r4	'user fp	ldr
                r0 r1 r2 r3 4	r4 ia!	ldm
                r0 r1 2		r4 db!	stm
                r2 r3 2		r4 db!	stm c;
code frot       ( f1 f2 f3 -- f2 f3 f1 )
		r6	'user fp	ldr
		r0 r1 r2 r3 r4 r5 6  r6 ia! ldm
                r2 r3 2 	r6 db!	stm
                r4 r5 2		r6 db!	stm
                r0 r1 2		r6 db!	stm c;
code f-rot	( f1 f2 f3 -- f3 f1 f2 )
		r6	'user fp	ldr
		r0 r1 r2 r3 r4 r5 6 r6 ia! ldm
		r4 r5 2		r6 db!	stm
		r0 r1 r2 r3 4	r6 db!	stm c;
code f2dup      ( f1 f2 -- f1 f2 f1 f2 )
		r6	'user fp	ldr
                r0 r1 r2 r3  4	r6 ia	ldm
                r0 r1 r2 r3  4	r6 db!	stm
                r6	'user fp	str c;
code fover      ( f1 f2 -- f1 f2 f1 )
		r6	'user fp	ldr
                r2	r6 /float #	add
                r0 r1 2		r2 ia	ldm
                r0 r1 2		r6 db!	stm
                r6	'user fp	str c;
code n>f	( n -- ) \ n is converted to a float
                f0      top     flt 
                		 pushf0 
                top     sp      pop c;
code f>n	( -- n ) \ takes a float and converts it to n
                popf0
                top     sp      push
                top     f0      fix c;
code fmin	 popf0 popf1
		f0	f1	cmfe
	0< if	pushf0	else	pushf1 then  c;fl
code fmax	 popf0 popf1
		f0	f1	cmfe
	0> if	pushf0	else	pushf1 then  c;fl

code f~		( f: f1 f2 f3 -- ) ( -- flag )
		popf2 popf1 popf0
		top	sp	push
		top	0 #	mov
		f2	#0.0	cmfe
gt if		f3	f0 f1	suf
		f3	f3	abs
		f3	f2	cmfe
		top	-1 #	lt mov
   else		f2	#0.0	cmf
   eq if	f0	f2	cmf
   		top	-1 #	eq mov
      else	f3	f0	abs
      		f4	f1	abs
      		f3	f3 f4	adf
      		f3	f3 f2	muf
      		f0	f0 f1	suf
      		f0	f0	abs
      		f0	f3	cmfe
      		top	-1 #	lt mov
      then
   then  c;fl

: d>f	( d -- ) ( f: -- f-d )
	dup 0< >r dabs ?dup
	if n>f  [ 2E0 32 n>f f** ] fliteral  f* else 0E0 then
	dup h# 7fffffff and n>f f+
	h# 80000000 and if [ 2E0 31 n>f f** ] fliteral f+ then
	r> if fnegate then ;
: f>d	0 !fs fdup f>n @fs
	if	drop 0 !fs
		fdup f0< >r fabs fdup [ 2E0 32 n>f f** fdup ]
		fliteral fmod f>n  fliteral f/ f>n  r> ?dnegate
	else	fdrop s>d
	then ;
: fdepth        fp0 @  fp@ -  3 rshift ;

: represent     \ ( c-addr cnt -- exponent sign ok? )
        2dup [char] 0 fill
        19 min  fbuff !flpd
        @fs b# 1101 and if drop 0 false exit then
        dup 19 < over 19 min @dig  [char] 4 >  and
        ( c-addr cnt round )
        -rot 1- 0 swap
        do      over i @dig  swap
                if 1+ dup [char] 9 >
                 if drop [char] 0 else rot drop 0 -rot then
                then
                over i + c!
        -1 +loop
        @exp swap
        rot if [char] 1 swap c! 1+ else drop then
        @sign true ;
: >float        \ ( addr u -- flag )
        0 !fs  fbuff 3 cells erase
        over c@ [char] - = dup !sign if next-char then
        over c@ [char] + = if next-char then
        begin over c@ [char] 0 = while  next-char repeat
        over 0  2swap 2dup bounds
        ( c-addr c-len e-addr e-len to-char from-char )
        ?do     next-char  i c@ [char] E <> if 2swap char+ 2swap else leave then
        loop    ( f-addr f-len  e-addr e-len )
	\ now the floating-number string has been split into the digits
	\ and the exponent part
	\ first the exponent is calculated
        over c@ [char] - = dup >r if next-char then
        over c@ [char] + = if next-char then
        0. 2swap >number
        if r> 3drop 3drop false exit else 2drop r> ?negate then >r
	\ exponent is left on the return-stack
	\ skip leading nulls
        begin over c@ [char] 0 = while next-char repeat
	\ look for exponent correction
        2dup -1 -rot bounds  ?do i c@ [char] . = ?leave 1+ loop r> + >r
        over c@ [char] . =	\ skip leading dots or nulls
        if next-char begin over c@ [char] 0 = while r> 1- >r next-char repeat
        then
        r@ 0< !esign r> abs  1 4  do 10 /mod i rot !nibble -1 +loop drop
        ( f-addr f-len )
        5 -rot bounds   ( nibble to from )
        ?do i c@ [char] 0 [char] 9 between if dup i c@ [char] 0 - !nibble 1+ then
        loop drop
        fbuff @flpd @fs 0= 0 !fs ;

: fdigit?       ( char -- flag )
        dup  [char] 0 [char] 9 between  ( char flag )
        over [char] E = or      over [char] . = or
        over [char] + = or      swap [char] - = or ;
: fnumber?      ( string -- string false | f true )
        true over count bounds  ( string true to from )
        ?do i c@ fdigit? 0= if drop false leave then loop
        if      dup count >float if drop true else false then
        else    false
        then ;
: float,	( f -- )	here /float allot f! ;


: fvariable	create /float allot ;
: fconstant	create float,
		;code
		r7			get-link
                r0 r1 2		r7 ia	ldm
		r2	'user fp	ldr
                r0 r1 2		r2 db!	stm
                r2	'user fp	str c;

3 actions" obj. floatval"
	action: f@ ;
	action: f! ;
	action: ;
: floatval	\ ( F: f1 -- )
	create	here /float allot f!
	use-actions ;

alias falign	align
alias faligned	aligned
alias df!       f!
alias df@	f@
alias dfalign	align
alias dfaligned	aligned
alias sfalign	align
alias sfaligned	aligned
alias dfloat+	float+
alias dfloats	floats
alias sfloat+	cell+
alias sfloats	cells

5 constant precision
: set-precision	( n -- )
		1 max  250 min  is precision ;
: fs.		( f: r -- )
		astring dup precision represent	( buffer exponent sign ok? )
		0= if fp-error then
		if ." -" then >r dup c@ emit ." ." char+ precision 1- type
		." E" r> 1- .d ;
: fe.		( f: r -- )
		astring dup precision represent	( buffer exponent sign ok? )
		0= if fp-error then
		if ." -" then 1+ >r
		dup  r@ 1+ 3 mod 1+  dup >r type ." ." r@ + precision r> - type
		." E" r> 1+ 3 / 1- 3 *  .d ;
: f.		( f: r -- )
		astring dup precision represent	( buffer exponent sign ok? )
		0= if fp-error then
		if ." -" then dup 0<=
		if	." 0." abs 0 ?do ." 0" loop precision type
		else    2dup type ." ." tuck + swap  precision - dup 0< ( addr cnt f )
			if  abs type else 2drop ." 0" then
		then ;
: .fs		( -- ) \ displays floating stack
		fp0 @
		begin	/float - dup fp@ >=
		while	dup f@ fs.
		repeat drop ;

: floats-on	['] fnumber? is fliteral? ;
: floats-off	['] false is fliteral? ;

floats-on
environment: floating			true ;
environment: floating-ext		true ;
environment: floating-stack		[ fs-size /float / ] literal ;
environment: max-float			1.79769313486231571E+308 ;
3.1415926535897932384E0 fconstant PI
floats-off


\ floating point decompiler support
[ifdef] see
	only forth also hidden also definitions
	: .finline	(s ip -- ip' )  cell+ dup f@  fs.  cell+ cell+  ;
	: skip-finline	(s ip -- ip' )  cell+ float+ ;
		' (flit)  ' .finline  ' skip-finline  install-decomp
[then]

only forth also definitions

\ LICENSE_BEGIN
\ Copyright (c) 2008 FirmWorks
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
