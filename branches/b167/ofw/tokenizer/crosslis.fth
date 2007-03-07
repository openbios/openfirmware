\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: crosslis.fth
\ 
\ Copyright (c) 2006 Sun Microsystems, Inc. All Rights Reserved.
\ 
\  - Do no alter or remove copyright notices
\ 
\  - Redistribution and use of this software in source and binary forms, with 
\    or without modification, are permitted provided that the following 
\    conditions are met: 
\ 
\  - Redistribution of source code must retain the above copyright notice, 
\    this list of conditions and the following disclaimer.
\ 
\  - Redistribution in binary form must reproduce the above copyright notice,
\    this list of conditions and the following disclaimer in the
\    documentation and/or other materials provided with the distribution. 
\ 
\    Neither the name of Sun Microsystems, Inc. or the names of contributors 
\ may be used to endorse or promote products derived from this software 
\ without specific prior written permission. 
\ 
\     This software is provided "AS IS," without a warranty of any kind. 
\ ALL EXPRESS OR IMPLIED CONDITIONS, REPRESENTATIONS AND WARRANTIES, 
\ INCLUDING ANY IMPLIED WARRANTY OF MERCHANTABILITY, FITNESS FOR A 
\ PARTICULAR PURPOSE OR NON-INFRINGEMENT, ARE HEREBY EXCLUDED. SUN 
\ MICROSYSTEMS, INC. ("SUN") AND ITS LICENSORS SHALL NOT BE LIABLE FOR 
\ ANY DAMAGES SUFFERED BY LICENSEE AS A RESULT OF USING, MODIFYING OR 
\ DISTRIBUTING THIS SOFTWARE OR ITS DERIVATIVES. IN NO EVENT WILL SUN 
\ OR ITS LICENSORS BE LIABLE FOR ANY LOST REVENUE, PROFIT OR DATA, OR 
\ FOR DIRECT, INDIRECT, SPECIAL, CONSEQUENTIAL, INCIDENTAL OR PUNITIVE 
\ DAMAGES, HOWEVER CAUSED AND REGARDLESS OF THE THEORY OF LIABILITY, 
\ ARISING OUT OF THE USE OF OR INABILITY TO USE THIS SOFTWARE, EVEN IF 
\ SUN HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
\ 
\ You acknowledge that this software is not designed, licensed or
\ intended for use in the design, construction, operation or maintenance of
\ any nuclear facility. 
\ 
\ ========== Copyright Header End ============================================
purpose: Tokenizer macros - one word expands to several FCodes
copyright: Copyright 1996-2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ Cross-compiler equivalents for tokenizer system
\ "All accounted for" means that, for this section, all non-primitives
\ are named (and either defined, or at least mentioned.)

\ --- Firmworks extensions ----------------------------------------------
: encode-null		0 0 encode-bytes   ;
: +i			encode-int encode+  ;
: string-property	2swap encode-string 2swap property  ;
: integer-property	rot encode-int 2swap property  ;
: encode-reg		>r encode-phys r> encode-int encode+  ;
: package(		r> my-self >r >r is my-self  ; 
: )package		r> r> is my-self >r  ; 
: push-hex		r> base @ >r hex >r  ;
: pop-base		r> r> base ! >r  ;
\ new-package is begin-package without the initial select
\ : begin-package  select-dev new-package  ;
: new-package		new-device  set-args  ;
: end-package		finish-device   ;

\ --- IEEE 1275 and ANS Forth name changes ------------------------------
v2-compat: << lshift
v2-compat: >> rshift
v2-compat: attribute property
v2-compat: delete-attribute delete-property
v2-compat: get-inherited-attribute get-inherited-property
v2-compat: get-my-attribute get-my-property
v2-compat: get-package-attribute get-package-property
v2-compat: /c*  chars
v2-compat: ca1+ char+
v2-compat: /n*  cells
v2-compat: na1+ cell+
v2-compat: decode-2int parse-2int
v2-compat: eval evaluate
v2-compat: flip wbflip
v2-compat: lflips lwflips
v2-compat: wflips wbflips
v2-compat: is     to
v2-compat: map-sbus map-low
v2-compat: not  invert
v2-compat: u*x  um*
v2-compat: xu/mod um/mod
v2-compat: x+ d+
v2-compat: x- d-
v2-compat: version fcode-revision
v2-compat: xdr+ encode+
v2-compat: xdrbytes encode-bytes
v2-compat: xdrint encode-int
v2-compat: xdrphys encode-phys
v2-compat: xdrstring encode-string
v2-compat: xdrtostring decode-string
v2-compat: xdrtoint decode-int


\ --- Stack operators - All accounted for -------------------------------
\ : clear ( ??? -- ) depth 0 ?do drop loop  ;		not supported
\ : 4dup  ( a b c d -- a b c d  a b c d ) 2over 2over ; not supported
: 3dup  ( a b c   -- a b c    a b c   ) 2 pick  2 pick  2 pick ;
: 3drop ( a b c   -- ) drop 2drop ;


\ --- Memory operators - All accounted for ------------------------------
\   caps-comp						not supported
\   compare						not supported
\   creset						not supported
\   csearch						not supported
\   cset						not supported
\   ctoggle						not supported
\   du							not supported
\   dump						not supported
\   search						not supported
\   toggle						not supported
\   token!						not supported
\   token@						not supported
\   tsearch						not supported
\   wsearch						not supported
: blank ( addr count -- ) bl fill ;
: cmove	( source dest count -- ) move ;
: cmove> ( source dest count -- ) move ;
: erase	( addr count -- ) 0 fill ;
: allot  ( #bytes -- ) 0 max 0 ?do 0 c, loop ;


\ --- Arithmetic - All accounted for ------------------------------------
\   4*							not supported
\   8*							not supported
\   cnot						not supported
\ : even  aligned ;					not supported
\ : lobyte  h# ff  and  ;				not supported
\ : ?negate  ( n1 n2 -- n1 | -n1 ) 0< if negate then ;	not supported
\   u*							not supported
\   umax						not supported
\   umin						not supported
: 1+    1 + ;
: 1-    1 - ;
: 2+    2 + ;
: 2-    2 - ;
: <<a   << ;
: */mod  >r * r> /mod ;
: */     >r * r> /    ;
: xu>l        ( ux -- ul ) drop   ;                    \       64 -> 32
: lu>x        ( ul -- ux ) 0      ;                    \ 32 -> 64


\ --- Stack operators - All accounted for -------------------------------
  : false  0 ;
  : true  -1 ;


\ --- TextInput - Only a subset is supported ----------------------------
\   (					included in main program
\   \					included in main program
\ : ok  ;						not supported
\   (s					included in main program
: accept ( addr len1 -- len2 )  span @ -rot expect  span @ swap span !  ;


\ --- Ascii - All accounted for -----------------------------------------
\   ascii  				included in main program
\   control 				included in main program
\   eof 						not needed
\ : printable?  ( char -- flag ) 			not supported
\    dup bl  h# 7f  within swap  h# 80  h# ff  between or ;
: carret    d# 13  emit-number ;
: linefeed  d# 10  emit-number ;
: newline   d# 10  emit-number ;


\ --- Numeric Input - All accounted for ---------------------------------
\   b#  				included in main program
\   convert  						not supported
\   d#  				included in main program
\   dpl   						not supported
\   h#  				included in main program
\   literal? 						not supported
\   long? 						not supported
\   number 						not supported
\   number? 						not supported
\   o#  				included in main program
\   td					included in main program
\   th					included in main program
: m-binary  ( -- )  2 base !  ;
: m-decimal ( -- )  d# 10 emit-number  base !  ;
: m-hex     ( -- )  d# 16 emit-number  base !  ;
: m-octal   ( -- )  8 emit-number  base !  ;


\ --- Numeric Output - All accounted for --------------------------------
: (.)  ( n -- addr len )  dup abs n->l <# u#s swap sign u#>  ;
: ?    ( addr -- )  @ .  ;
: .d   ( n -- )  base @ swap  m-decimal .  base !  ;
: .h   ( n -- )  base @ swap  m-hex     .  base !  ;
: s.   ( n -- )  (.) type  bl emit  ;
: (u.) ( n -- addr len )  n->l <# u#s u#>  ;
: .x   .h  ;  		\ Becoming obsolete


\ --- General Output - All accounted for --------------------------------
\ : backspaces  0 max 0 ?do  bs emit  loop  ; 		not supported
\ : beep  bell emit  ; 					not supported
\   crlf 						not supported
\   exit? 						not supported
\   lf 							not supported
\   (lf 						not supported
\   prompt 						not supported
: space  bl emit  ; 
: spaces  0 max  0 ?do  space  loop  ;


\ --- Formatted output - All accounted for ------------------------------
\ : ??cr ( -- )  #out @  if cr then  ; 			not supported


\ --- Control - Most are in body of main program ------------------------
\ : perform  @ execute  ;				not supported


\ --- Strings - Only a subset is supported ------------------------------
\   "   				included in main program
\   .(  				included in main program
\   ."  				included in main program
\ : lower  ( addr len -- ) 				not supported
\    bounds ?do  i dup c@  lcc  swap c! loop ;

\ : upper  ( addr len -- ) 				not supported
\    bounds ?do  i dup c@  upc  swap c! loop ;

\ : sindex  ( addr1 len1 addr2 len2 -- n )  \ Find array1 within array2
\                                       		not supported
\    >r over r>  swap -    ( addr1 len1 addr2 len2-len1 )
\    dup 0<  if  2drop 2drop  -1  else
\       -1 swap  1+  0 do        ( addr1 len1 start2 found# )
\          2over 2over drop  swap comp  ( addr1 len1 start2 found# n )
\          0= if  drop i  leave  else  swap 1+ swap  then
\       loop                     ( addr1 len1 start2 found# )
\       >r 2drop drop r>
\    then ;

\ : -trailing  ( addr n1 -- addr n2 )
\    dup 0 do   2dup +  1- c@  bl <>  ?leave  1- loop ;
 

\ --- 32-Bit compatibility - All accounted for --------------------------
\   16\  included in main program  		not supported
\ : 32\  ;  					not supported
\ : 16-bit  abort" Not a 16-bit forth"  ;  	not supported
\ : 32-bit  ;  					not supported
\ : l!    !     ;				not supported
\ : l*    *     ; 				not supported
\ : l+    +     ; 				not supported
\ : l+!   +!    ; 				not supported
\ : l-    -     ; 				not supported
\ : l->n        ; 				not supported
\ : l->w  h# ffff and  ; 			not supported
\   l. 						not supported
\   (l.) 					not supported
\   l.r 					not supported
\ : l0=   0=    ; 				not supported
\ : l2/   2/    ; 				not supported
\ : l2dup 2dup  ; 				not supported
\ : l<    <     ; 				not supported
\ : l<<   <<    ; 				not supported
\ : l<<a  <<    ;				not supported
\ : l<=   <=    ; 				not supported
\ : l=    =     ; 				not supported
\ : l>    >     ; 				not supported
\ : l>=   >=    ; 				not supported
\ : l>>   >>    ; 				not supported
\ : l>>a  >>a   ; 				not supported
\   l>r  					not supported
\ : labs  abs   ; 				not supported
\ : land  and   ; 				not supported
\ : lbetween between ; 				not supported
\   lconstant 					not supported
\ : ldrop drop  ; 				not supported
\ : ldup  dup   ; 				not supported
\   lliteral 					not supported
\ : lmax  max   ; 				not supported
\ : lmin  min   ; 				not supported
\ : lnegate negate ; 				not supported
\ : ?lnegate ?negate ; 				not supported
\ : lnot  not   ; 				not supported
\ : lnover over ; 				not supported
\ : lnswap swap ; 				not supported
\ : lor   or    ; 				not supported
\   lr> 					not supported
\ : lswap  swap ; 				not supported
\   lvariable 					not supported
\ : lwithin within ; 				not supported
\ : m/mod  /mod ; 				not supported
\ : mu/mod u/mod ; 				not supported
\ : n->a        ; 				not supported
\ : n->l        ; 				not supported
\ : n->w  l->w  ; 				not supported
\ : nlover over ; 				not supported
\ : nlswap swap ; 				not supported
\ : s->l        ; 				not supported
\   ul*						not supported
\   ul.						not supported
\   (ul.)					not supported
\   ul.r					not supported
\   um*						not supported
\ : um/mod u/mod ;				not supported
\ : w->l        ;				not supported
\   wvariable					not supported
: wflip  lwsplit swap wljoin  ;

: version1? ( -- flag )   \ True if version 1.x 
   version h# 20000 emit-number <
;

: version2? ( -- flag )   \ True if version 2
   version h# 20000 emit-number >=
   version h# 30000 emit-number < and
   
;
: version2.0? ( -- flag )   \ True if version 2.0
   h# 20000 emit-number version =
;

: version2.1? ( -- flag )   \ True if version 2.1
   version h# 20001 emit-number =
;

: version2.2? ( -- flag )   \ True if version 2.2
   version h# 20002 emit-number =
;

: version2.3? ( -- flag )   \ True if version 2.3
   version h# 20003 emit-number =
;

: version3? ( -- flag )   \ True if version 3
   version h# 30000 emit-number =
;
