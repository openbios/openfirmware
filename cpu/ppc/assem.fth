purpose: PowerPC assembler
\ See license at end of file

decimal

\needs $vfind            fload ${BP}/forthlang/lib/strings.fth
\needs left-parse-string fload ${BP}/forthlang/lib/parses1.fth

vocabulary ppc-assembler

also ppc-assembler definitions

headerless
false value disassembling?
variable instruction
variable end-found
headers
variable pc
variable display-offset  0 display-offset !
: +offset  ( adr -- adr' )  display-offset @  +  ;
' ul.  is showaddr

headerless
h#  40 /token      *  constant /op-map  create op-map /op-map allot
h#  10 /token /n + *  constant /19-map  create 19-map /19-map allot
h# 400 /token      *  constant /31-map  create 31-map /31-map allot
h#  20 /token      *  constant /59-map  create 59-map /59-map allot
h#  20 /token /n + *  constant /63-map  create 63-map /63-map allot

: unimp  ( -- )
   end-found on
   ." Not an instruction: "  instruction @ 
   base @ >r hex  9 u.r  r> base !  space
   false is disassembling?
;

: (.name)  ( acf -- )
   dup ['] unimp  =  if  execute  else  >name name>string type  then
;

: find-sparse-entry  ( entry map -- acf )
   begin  dup @ -1  <>  while     ( entry mapp )
      2dup @ =  if              ( entry mapp )
         nip na1+ token@  exit  ( acf )
      then                      ( entry mapp )
      na1+ ta1+
   repeat
   2drop  ['] unimp
;
: find-indexed-entry  ( entry map -- acf )  swap ta+ token@  ;

: init-map  ( adr len -- )  bounds  ?do  ['] unimp  i token!  /token +loop  ;
: init-sparse-map  ( adr len -- )
   bounds  ?do  -1 i !  ['] unimp  i na1+ token!  /token na1+  +loop
;

variable start-column
variable need-comma
: ?,  ( -- )  need-comma @  if  ." ,"  else  need-comma on  then  ;
: to-operand-column  ( -- )  d# 8 start-column @ +  to-column  need-comma off ;
: ibits  ( right-bit# width -- bits )
   tuck - 1+  instruction l@ swap <<  32 rot - >>
;

: init-maps  ( -- )
   op-map  /op-map  init-map
   31-map  /31-map  init-map
   59-map  /59-map  init-map
   19-map  /19-map  init-sparse-map
   63-map  /63-map  init-sparse-map
;   
init-maps

headers
defer here
defer asm-allot
defer asm@
defer asm!

\ Install as a resident assembler
\ : xx see ; immediate
: resident-assembler  ( -- )
   [ forth ] ['] here          [ ppc-assembler ] is here
   [ forth ] ['] allot         [ ppc-assembler ] is asm-allot
   [ forth ] ['] @             [ ppc-assembler ] is asm@
   [ forth ] ['] instruction!  [ ppc-assembler ] is asm!
;
resident-assembler

headerless
2variable operands

: get-field  ( -- adr len )
   operands 2@  ascii ,  left-parse-string  2swap operands 2!  ( adr len )
;
: field-or-number  ( ? -- n true | adr len false )
   disassembling?  if  false exit  then
   get-field
   2dup  " *"  $=  dup  if  nip nip  then
;
\ If adr2,len2 is an initial substring of adr1,len1, return the remainder
\ of the adr1,len1 string following that initial substring.
\ Otherwise, return adr1,len1
: ?remove  ( adr1 len1 adr2 len2 -- adr3 len3 removed? )
   2 pick  over  u<  if  2drop false exit  then      \ len2 too long?
   3 pick  rot  2 pick   ( adr len1 len2  adr1 adr2 len2 )
   caps-comp 0=  if  /string true  else  drop false  then
;
: set-base  ( adr len -- adr' len' )
   " h#" ?remove  if  hex     exit  then
   " 0x" ?remove  if  hex     exit  then
   " d#" ?remove  if  decimal exit  then
   " o#" ?remove  if  octal   exit  then
   " b#" ?remove  if  binary  exit  then
;

headers
\ Define symbolic names for constants in this vocabulary
vocabulary constant-names

headerless
: get-based-number  ( adr len -- true | n false )
   ['] constant-names $vfind  if  execute false exit  then
   base @ >r decimal
   set-base
   $number
   r> base !
;
: number  ( -- n )
   disassembling?  if  ?, exit  then
   field-or-number  if  exit  then
   get-based-number abort" Bad number"
;

: reg-name  ( adr1 len1 adr2 len2 -- n )  \ adr2 len2 is the register prefix
   disassembling?  if  ?,  type exit  then
   ?remove drop
   base @ >r decimal
   $number
   r> base !
   abort" Bad register number"
;

\ The two 5-bit halves of the special register field are interchanged
: flip5  ( n -- n' )  dup h# 1f and  5 <<  swap  5 >>  or  ;

headers
: sp-reg:  ( n -- )  flip5  constant  ;

vocabulary sp-registers
also sp-registers definitions
1011 sp-reg: tbar	\ This is not really a PowerPC register;
			\ I invented it as a way of communicating
			\ the trap base address to the simulator
			\ to avoid slowing the simulator down with
			\ absolute addressing

   0 sp-reg: mq
   1 sp-reg: xer
   4 sp-reg: rtcu  \ mfspr version
   5 sp-reg: rtcl  \ mfspr version
   8 sp-reg: lr
   9 sp-reg: ctr
  18 sp-reg: dsisr
  19 sp-reg: dar
  20 sp-reg: rtcu  \ mtspr version
  21 sp-reg: rtcl  \ mtspr version
  22 sp-reg: dec
  25 sp-reg: sdr1
  26 sp-reg: srr0
  27 sp-reg: srr1
 268 sp-reg: tb		\ For reading
 269 sp-reg: tbu	\ For reading
 272 sp-reg: sprg0
 273 sp-reg: sprg1
 274 sp-reg: sprg2
 275 sp-reg: sprg3
 280 sp-reg: asr	\ 620-specific
 282 sp-reg: ear
 284 sp-reg: tb.w	\ For writing
 285 sp-reg: tbu.w	\ For writing
 287 sp-reg: pvr
 528 sp-reg: ibat0u
 529 sp-reg: ibat0l
 530 sp-reg: ibat1u
 531 sp-reg: ibat1l
 532 sp-reg: ibat2u
 533 sp-reg: ibat2l
 534 sp-reg: ibat3u
 535 sp-reg: ibat3l
 536 sp-reg: dbat0u
 537 sp-reg: dbat0l
 538 sp-reg: dbat1u
 539 sp-reg: dbat1l
 540 sp-reg: dbat2u
 541 sp-reg: dbat2l
 542 sp-reg: dbat3u
 543 sp-reg: dbat3l

1008 sp-reg: check	\ Exponential 704-specific
1008 sp-reg: checkstop  1008 sp-reg: hid0
1009 sp-reg: debug-mode 1009 sp-reg: hid1
1010 sp-reg: iabr       1010 sp-reg: hid2
1013 sp-reg: dabr       1013 sp-reg: hid5
1016 sp-reg: buscsr	\ 620-specific
1017 sp-reg: l2cr	\ 620-specific
1018 sp-reg: l2sr	\ 620-specific
1023 sp-reg: pir        1023 sp-reg: hid15

 \ 603-specific
 976 sp-reg: dmiss
 977 sp-reg: dcmp
 978 sp-reg: hash1
 979 sp-reg: hash2
 980 sp-reg: imiss
 981 sp-reg: icmp
 982 sp-reg: rpa

\ 604-specific
 952 sp-reg: mmcr0	\ 604-specific reg
 953 sp-reg: pmc1	\ 604-specific reg
 954 sp-reg: pmc2	\ 604-specific reg
 955 sp-reg: sia	\ 604-specific reg
 959 sp-reg: sda	\ 604-specific reg

\ Exponential 704-specific: also uses some 603-specific registers
 276 sp-reg: sprg4	\ Exponential 704-specific
 277 sp-reg: sprg5	\ Exponential 704-specific
 278 sp-reg: sprg6	\ Exponential 704-specific
 279 sp-reg: sprg7	\ Exponential 704-specific
 953 sp-reg: event	\ Exponential 704-specific
 954 sp-reg: modes	\ Exponential 704-specific
 977 sp-reg: cmp	\ Similar to 603 dcmp
 982 sp-reg: tlblru0	\ Similar to 603 rpa
 983 sp-reg: tlbmrf	\ Exponential 704-specific
 985 sp-reg: bpctl	\ Exponential 704-specific
 987 sp-reg: tlblru1	\ Exponential 704-specific
 988 sp-reg: misr	\ Exponential 704-specific
 989 sp-reg: mar	\ Exponential 704-specific
1012 sp-reg: l2cdr	\ Exponential 704-specific
1014 sp-reg: xdabr	\ Exponential 704-specific
1019 sp-reg: l2ctl	\ Exponential 704-specific

\ 823-specific
  80 sp-reg: eie
  81 sp-reg: eid
  82 sp-reg: nri
 144 sp-reg: cmpa
 145 sp-reg: cmpb
 146 sp-reg: cmpc
 147 sp-reg: cmpd
 148 sp-reg: icr
 149 sp-reg: der
 150 sp-reg: counta
 151 sp-reg: countb
 152 sp-reg: cmpe
 153 sp-reg: cmpf
 154 sp-reg: cmpg
 155 sp-reg: cmph
 156 sp-reg: lctrl1
 157 sp-reg: lctrl2
 158 sp-reg: ictrl
 159 sp-reg: bar
 560 sp-reg: ic-csr
 561 sp-reg: ic-adr
 562 sp-reg: ic-dat
 568 sp-reg: dc-csr
 569 sp-reg: dc-adr
 570 sp-reg: dc-dat
 630 sp-reg: dpdr
 631 sp-reg: dpir
 638 sp-reg: immr
 784 sp-reg: mi-ctr
 786 sp-reg: mi-ap
 787 sp-reg: mi-epn
 789 sp-reg: mi-twc
 790 sp-reg: mi-rpn
 816 sp-reg: mi-cam
 817 sp-reg: mi-ram0
 818 sp-reg: mi-ram1
 792 sp-reg: md-ctr
 793 sp-reg: m-casid
 794 sp-reg: md-ap
 795 sp-reg: md-epn
 796 sp-reg: m-twb
 797 sp-reg: md-twc
 798 sp-reg: md-rpn
 799 sp-reg: m-tw
 824 sp-reg: md-cam
 825 sp-reg: md-ram0
 826 sp-reg: md-ram1


previous definitions

\ Define symbolic names for registers in this vocabulary
vocabulary register-names

headerless
: r-reg-name  ( adr len -- n )
   disassembling?  0=  if
      ['] register-names $vfind  if  execute exit  then
   then
   " r"   reg-name
;
: r-register    ( -- n )
   field-or-number  if  exit  then
   r-reg-name
;
: crf-register  ( -- n )  field-or-number  if  exit  then  " crf" reg-name  ;
: crb-bit       ( -- n )  field-or-number  if  exit  then  " crb" reg-name  ;
: fr-register   ( -- n )  field-or-number  if  exit  then  " fr"  reg-name  ;
: u.d  ( n -- )  base @ >r decimal  (u.) type  r> base !  ;

\ Nasty hack to handle the RTCU/RTCL SPR encoding difference
\ between mfspr and mtspr
: ?fix-rtc  ( sp-reg# -- sp-reg#' )
   dup h# 280 =  over h# 2a0 =  or  if          \ rtcu or rtcl?
      here /l - asm@ h# 100 and  0=  if   \ mfspr?
         h# 200 -
      then
   then
;

: sp-register   ( -- n )
   disassembling?  if
      ?,
      20 10 ibits               ( n )
      ['] sp-registers  follow
      begin  another?  while
         name>  dup execute                     ( n acf constant )
	 2 pick =  if  (.name) drop exit  then  ( n acf )
         drop
      repeat
      ." spr" flip5 u.d
   else
      field-or-number  if  exit  then
      ['] sp-registers  $vfind 0=  if
         ." Bad special register name: " type cr  abort
      then
      execute
      ?fix-rtc
   then
;
: relative?  ( -- flag )  here 4 -  asm@  2 and  0=  ;
: ?aligned  ( adr -- adr )
   dup 3 and  abort" Misaligned branch target"
;
: convert-target  ( adr -- n )
   ?aligned
   relative?  if  here 4 -  -  then
;
: safe-get-number  ( adr len -- n )
   get-based-number  abort" Bad branch target address"
;
: branch-target  ( -- adr )
   field-or-number  0=  if   ( adr len )
      dup 2 >=  if           ( adr len )
         over " .+" comp  0=  if   ( adr len )
            2 /string  safe-get-number  here /l - +  exit
         then                ( adr len )
         over " .-" comp  0=  if   ( adr len )
            2 /string  safe-get-number  negate  here /l - +  exit
         then
      then
      safe-get-number
   then
;

: add-bits  ( n -- )
   here /l - dup  asm@  rot or  swap asm!
;

: >16-bits?  ( n -- u flag )
   dup h# ffff and  swap  h# -8000  h# 8000 within  0=
;
: ?simm  ( n -- n )
   >16-bits?  abort" Signed immediate value out of range"
;

: high-mask  ( #low-zeroes -- mask )  1 swap << 1- invert  ;
: bit-field  ( n shift width -- )
   disassembling?  if   ibits  u.d  exit  then
   high-mask 2 pick  and  abort" Value too large for bit field"
   31 swap -  << add-bits
;
: 5bit-field   ( -- )  5 bit-field  ;
: rd-field  ( n -- )  10 5bit-field  ;
: ra-field  ( n -- )  15 5bit-field  ;
: rb-field  ( n -- )  20 5bit-field  ;
: rc-bit    ( n -- )  31 1 bit-field  ;
: oe-bit    ( n -- )  21 1 bit-field  ;

: imm-field  ( n -- )  31 16 bit-field  ;
: sign-extend-16  ( n1 -- n2 )  16 << 16 >>a   ;
: h#.x  ( n -- )
   dup -9 9 between  0=  if  ." h#"  then
   base @ >r  hex  (.) type  r> base !
;
: simm  ( n -- )
   disassembling?  if
      ?,  31 16 ibits  sign-extend-16  h#.x
   else
      number ?simm  imm-field
   then
;
: ?uimm  ( u -- u )
   dup h# ffff u>  abort" Unsigned immediate value too large"
;
: uimm  ( u -- )
   disassembling?  if
      ?,  31 16 ibits  h#.x
   else
      number ?uimm
      imm-field
   then
;
\ In principle, this is a signed field, but it makes the code
\ incredibly hard to read if we display it as such.
: simms  ( n -- )
   disassembling?  if
      ?,  31 16 ibits  ( sign-extend-16 )  h#.x  ." ...."
   else
      simm
   then
;
: uimms  ( n -- )
   disassembling?  if
      \ 64-bit: we will need to handle this differently for the 64-bit version
      simms
   else
      uimm
   then
;
: imm  ( -- )  number       19 4 bit-field  ;
: rd   ( -- )  r-register   rd-field  ;
: ra   ( -- )  r-register   ra-field  ;
: rb   ( -- )  r-register   rb-field  ;
: rs   ( -- )  rd  ;
: crfd ( -- )  crf-register  8 3 bit-field  ;
: crfs ( -- )  crf-register 13 3 bit-field  ;
: crbd ( -- )  crb-bit      rd-field  ;
: crba ( -- )  crb-bit      ra-field  ;
: crbb ( -- )  crb-bit      rb-field  ;
: fm   ( -- )  number       14 8 bit-field  ;
: l    ( -- )  number       10 1 bit-field  ;
false value numeric-conditionals?
variable suppress-cond
: bo   ( -- )
   disassembling?  if
      10 5 ibits
      numeric-conditionals?  if  ?, u.d  exit  then
      dup h# 14 and  h# 14 =  if
         ?, ." always" suppress-cond on
      else
         dup h#  4 and  0=  if	\ Decrement and test counter register
            ?, ." ctr"
            dup 2 and  if  ." =0"  then
         then
         dup h# 10 and  if
            suppress-cond on
         else
            suppress-cond off
            dup h#  8 and  0=  if  ?, ." not"  then
         then
      then
      1 and  if  ?,  ." Y"  then
   else
      number       rd-field
   then
;

headers
: set-y  ( -- )  h# 0020.0000 add-bits  ;

headerless
string-array condnames   ," lt"  ," gt"  ," eq"  ," so"  end-string-array
: bi   ( -- )
   disassembling?  if
      15 5 ibits
      numeric-conditionals?  if  ?,  u.d  exit  then
      suppress-cond @  if
         drop
      else
         ?,
         4 /mod  ?dup  if  ." cr" u.d ." +"  then
         condnames ".
      then
   else
      number       ra-field
   then
;
: frd  ( -- )  fr-register  rd-field  ;
: frs  ( -- )  fr-register  rd-field  ;
: fra  ( -- )  fr-register  ra-field  ;
: frb  ( -- )  fr-register  rb-field  ;
: frc  ( -- )  fr-register  25    5bit-field  ;
: spr  ( -- )  sp-register  disassembling?  0=  if  20  10 bit-field  then  ;
: tbr  ( -- )  sp-register  disassembling?  0=  if  20  10 bit-field  then  ;
: sr   ( -- )  number       15      4 bit-field  ;
: crm  ( -- )  number       19      8 bit-field  ;
\ Don't overload the Forth word "to"
: tox  ( -- )  number       rd-field  ;
: mb   ( -- )  number       25 5bit-field  ;
: me   ( -- )  number       30 5bit-field  ;
: md   ( -- )  number   dup h# 1f and 25 5bit-field  5 >> 26 1 bit-field  ;
: sh   ( -- )  number       rb-field  ;
: shd  ( -- )  number   dup h# 1f and rb-field  5 >> 30 1 bit-field  ;
: nb   ( -- )  number       rb-field  ;
: set-bd-field  ( adr -- )  convert-target  ?simm 2 >>   29 14 bit-field  ;
: bd   ( -- )
   disassembling?  if
      ?,  29 14 ibits  2 <<
      30 1 ibits  0=  if  sign-extend-16 pc @  +  then  showaddr
   else
      branch-target  set-bd-field
   then
;
: ?offset-26  ( target -- target-masked )
   dup  h# fe00.0000  h# 200.0000 within  0=
   abort" Branch target out of 26-bit range"
   h# 3ff.ffff and
;
: lif   ( -- )
   disassembling?  if
      ?,  29 24 ibits  8 <<  6 >>a  \ Sign extend
      30 1 ibits  0=  if  pc @  +  then  showaddr
   else
      branch-target
      convert-target
      ?offset-26  2 >>  29  24 bit-field
   then

;
: parse-d(ra)  ( -- disp ra )
   field-or-number  if  exit  then               ( adr len )
   ascii (  left-parse-string                    ( rem-str disp-str )
   dup 0=  if                                    ( rem-str disp-str )
      2drop 0                                    ( rem-str 0 )
   else                                          ( rem-str disp-str )
      get-based-number abort" Bad displacement"  ( rem-str disp )
   then                                          ( rem-str disp )
   -rot  ascii ) left-parse-string               ( disp rem-str reg-str )
   2swap 2drop  r-reg-name                       ( disp ra )
;
: d(ra)  ( -- )
   disassembling?  if
      ?,
      31 16 ibits  sign-extend-16  h#.x
      need-comma off
      15  5 ibits  if  ." (" ra ." )"  then
   else
      parse-d(ra)  ra-field   ?simm  imm-field
   then
;
: ds(ra)  ( -- )
   disassembling?  if
      ?,
      29 14 ibits  2 lshift  sign-extend-16  h#.x
      need-comma off
      15  5 ibits  if  ." (" ra ." )"  then
   else
      parse-d(ra)  ra-field   ?simm
      dup 3 and  abort" offset must be 4-byte aligned"
      imm-field
   then
;

\ Operand formats
: rd,ra  rd ra  ;
: rd,ra,rb  rd,ra rb  ;
: rd,ra,simm   rd,ra simm   ;
: rd,ra,simms  rd,ra simms  ;
: crbd,crba,crbb  crbd crba crbb  ;
: ra,rs     ra rs  ;
: ra,rb     ra rb  ;
: rs,ra,rb  rs ra rb  ;
: rs,rb     rs rb  ;
: ra,rs,rb  ra,rs rb  ;
: ra,rs,uimm   ra,rs uimm   ;
: ra,rs,uimms  ra,rs uimms  ;
: bo,bi     bo bi  end-found on  ;
: bo,bi,bd  bo bi bd  ;
: crfd,l,ra     crfd l ra ;
: crfd,crfs     crfd crfs ;
: crfd,l,ra,rb  crfd,l,ra rb  ;
: frd,frb frd frb ;
: frd,fra,frb frd fra frb ;
: frd,fra,frc frd fra frc ;
: crfd,fra,frb  crfd fra frb ;
: frd,fra,frc,frb  frd fra frc frb  ;
: crfd,imm crfd imm ;
: crfd,l,ra,uimm  crfd,l,ra uimm  ;
: crfd,l,ra,simm  crfd,l,ra simm  ;
: frs,ra,rb  frs ra rb  ;
: frd,ra,rb  frd ra rb  ;
: rd,spr  rd spr  ;
: rd,tbr  rd tbr  ;
: rd,sr  rd sr  ;
: crm,rs  crm rs  ;
: spr,rs  spr rs  ;
: sr,rs  sr rs  ;
: to,ra,rb tox ra rb  ;
: to,ra,simm tox ra simm  ;
: rd,d(ra)  rd d(ra)  ;
: rs,d(ra)  rs d(ra)  ;
: rd,ds(ra)  rd ds(ra)  ;
: rs,ds(ra)  rs ds(ra)  ;
: frd,d(ra)  frd d(ra)  ;
: frs,d(ra)  frs d(ra)  ;
: ra,rs,rb,mb,me  ra rs rb mb me  ;
: ra,rs,sh,mb,me  ra rs sh mb me  ;
: ra,rs,shd,md  ra rs shd md  ;
: ra,rs,rb,md   ra rs rb md  ;
: ra,rs,sh  ra rs sh  ;
: ra,rs,shd  ra rs shd  ;
: fm,frb  fm frb  ;
: rd,ra,nb  rd ra nb  ;
: rs,ra,nb  rs ra nb  ;
: rd,rb  rd rb  ;
: no-args  ;

: no-. ;

alias power noop
\ alias power \

\ alias 64bit \
alias 64bit noop

: >op2-field  ( template -- op2 )  1 >>  h# 3fff and  ;
: find-free  ( map -- entry-adr )
   begin  dup @ -1 <>  while  na1+ ta1+  repeat
;
headers

transient
: set-indexed-map  ( op2 map -- )  swap ta+  lastacf swap token!  ;
: set-sparse-map   ( op2 map -- )
   find-free  tuck !  lastacf  swap na1+  token!
;
: set-map  ( opcode-template -- )
   dup >op2-field  swap 26 >>     ( op2 opcd )
   case
      19  of   19-map  set-sparse-map   endof
      31  of   31-map  set-indexed-map  endof
      59  of   59-map  set-indexed-map  endof
      63  of   63-map  set-sparse-map   endof
   ( default ) op-map  set-indexed-map
   endcase
;
resident

: asm,  ( n -- )  here  /l asm-allot  asm!  ;

headerless
: ?.  ( -- )  31 1 ibits  if  ." ."  then  ;
: dis-operands  ( acf -- )
   dup  ['] unimp  =  if  drop exit  then
   to-operand-column  >body na1+ token@ execute
;
variable op-class   \ Used for handling the "." forms of the rlw... opcodes
: dis-name&operands  ( acf -- )
   dup (.name)
   op-class @ d# 20 d# 23 between  if  ?.  then
   dis-operands
;

: bust  ( n -- )
   base @ >r decimal
   dup 26 >>  2 u.r
   dup 21 >>  h# 1f and  3 u.r
   dup 16 >>  h# 1f and  3 u.r
   dup 11 >>  h# 1f and  3 u.r
   dup  1 >>  h# 3ff and 5 u.r
   1 and 2 u.r ( cr )
   r> base !
;

headers
: ppc-disasm  ( 32b -- )
   dup instruction l!
   true is disassembling?
   26 >>  dup op-class !  op-map  find-indexed-entry  execute
;
also forth definitions
alias disasm ppc-disasm
: dis1  ( -- )
   ??cr
   pc @ showaddr  4 spaces
   #out @  start-column !
   pc @ +offset l@ disasm  cr
   /l pc +!
;
: +dis  ( -- )
   base @ >r  hex
   end-found off
   begin   dis1  end-found @  exit? or  until
   r> base !
;
: dis  ( adr -- )   pc l!   +dis  ;
alias (dis dis
previous definitions

headerless
\ Try to interpret the word with the "." removed, and then with the "o"
\ removed.
: interpreted?  ( adr len -- adr len false | true )
   $find  dup  if  swap execute  then
;
: ?peel  ( adr1 len1 char -- adr2 len2 flag )
   >r 2dup 1- + c@  r> =  if  1- true  else  false  then
;
: $ppc-assem-do-undefined  ( adr len -- )
   ascii .  ?peel  if                         ( adr len )
      interpreted?  if  1 rc-bit exit  then   ( adr len )
      ascii o  ?peel  if                      ( adr len )
            interpreted?  if  1 oe-bit  1 rc-bit exit  then
      then                                    ( adr len )
   else
      ascii o  ?peel  if
         interpreted?  if  1 oe-bit  exit  then
      then
   then                                       ( adr len )
   .not-found  abort
;
: get-operands  ( -- )  parse-word  operands 2!  ;

: op:  ( opcode-template -- )
   create  dup set-map  ,		\ Remember opcode template

   \ Remember argument parsing word
   parse-word $find  0= abort" Missing argument specification"  token,

   does>
      disassembling?  if
         body> dis-name&operands
         false is disassembling?
      else
         dup @  asm,    \ Place opcode
         na1+ token@  dup  ['] no-args <>  if  get-operands  then
         execute               \ Handle arguments
      then
;

[ifdef] notdef
: .binary  ( n -- )
   base @ >r  2 base !
   <#  32 0 do  #  loop  #>  type space
   r> base !
;
[then]

headers
transient
: can-.  ( -- )  ;  \ "." form is available
: can-o  ( -- )  ;  \ "o" form is available

\ Opcode formats
resident
: >op  ( op0 -- )  26 <<  ;

transient
: d:   ( op0 -- )                          >op    op:  ;
: b:   ( op0 aa lk -- )  swap 1 << +  swap >op +  op:  ;
: o:   ( op1 op0 -- )    swap 1 <<    swap >op +  op:  ;

: dl:  ( op0 low -- )                 swap >op +  op:  ;
: rd:  ( low -- )             2 <<      30 >op +  op:  ;
 
: r:   ( op0 -- )  d:  can-.  ;

: xl:  ( op1 -- )  19 o:  ;
: x:   ( op1 -- )  31 o:  ;
: s:   ( op1 -- )  59 o:  can-.  ;
: f:   ( op1 -- )  63 o:  can-.  ;

\ : x:  31 swap  1 <<  swap >op +  .binary  newline word ".  cr  ;

: xc:  ( op1 -- )     x:   can-.  ;
: xo:  ( op1 oe -- )  xc:  can-o  ;
resident

\ Put a branch instruction from high-level Forth code

: offset-26  ( target-address branch-address -- masked-displacement )
   swap ?aligned  swap ?aligned
   - ?offset-26
; 

also forth definitions
: put-branch  ( target-adr branch-adr -- )
   tuck offset-26 h# 4800.0000 + swap asm!	\ b offset
;
previous definitions

: cond  ( bo bi -- )
   swap 5 <<  or  16 <<  create ,  does>  @ 
;
: -cond  ( condition -- not-condition )
   dup  h# 0080.0000 and  0=  if  h# 0040.0000 xor  then  \ CTR condition
   dup  h# 0200.0000 and  0=  if  h# 0100.0000 xor  then  \ CR condition
;

headerless
: offset-16  ( target-address branch-address -- masked-displacement )
   dup 3 and  abort" Unaligned branch displacement"
   -
   >16-bits?  abort" branch displacement out of 16-bit range"
; 

headers
: brif  ( address condition -- )
   h# 4000.0000 or  swap here offset-16 or  asm,
;

: mr  ( -- )  \ rdest,rsrc
   444 1 <<  31 >op +  asm,	\ "or  rdest,rsrc,rsrc"
   get-operands
   ra  r-register  dup rd-field rb-field
;
: li  ( -- )    \ rdest,value
   get-operands
   14 >op  asm,			\ "addi  rdest,r0,value"
   r-register rd-field   0 ra-field   number ?simm  imm-field
;
: lis  ( -- )
   15 >op  asm,			\ "addis  rdest,r0,high(value)"
   get-operands
   r-register rd-field   0 ra-field   number 16 >>a imm-field
;
: set  ( -- )   \ rdest,value
   \ We can't keep rd on the stack because a number might be there,
   \ waiting for a "*" in the number field to pick it up
   get-operands  r-register >r  number   ( value )  ( r: register )
   dup >16-bits?  if                                     ( value val.low )
      swap                                               ( val.low value )
      15 >op  asm,	\ "addis  rdest,r0,high(value)"  ( val.low value )
      r@ rd-field  0 ra-field  16 >> imm-field           ( val.low )
      ?dup  if
         24 >op asm,	\ "ori    rdest,rdest,low(value) ( )
         imm-field  r@ rd-field  r@ ra-field
      then                          ( )
   else                                                  ( value val.low )
      nip
      14 >op  asm,	\ "addi  rdest,r0,value"         ( val.low reg )  
      r@ rd-field  0 ra-field  imm-field                 ( )
   then
   r> drop
;
: countdown  ( adr -- )  16 >op asm,  16 rd-field  0 ra-field  set-bd-field  ;
: nop  ( -- )  24 >op asm,  ;	\ ori  r0,r0,0

      \ 0,1 are unassigned

64bit   2 d: tdi     to,ra,simm
        3 d: twi     to,ra,simm

      \ 4,5,6 are unassigned

        7 d: mulli   rd,ra,simm
        8 d: subfic  rd,ra,simm
power   9 d: dozi    rd,ra,simm
       10 d: cmpli   crfd,l,ra,uimm
       11 d: cmpi    crfd,l,ra,simm
       12 d: addic   rd,ra,simm
       13 d: addic.  rd,ra,simm
       14 d: addi    rd,ra,simm
       15 d: addis   rd,ra,simms
       
     \ 16 is bcX
     \ 17 is sc
     \ 18 is bX
     \ 19 is xl: and bclr,bctr

       20 r: rlwimi  ra,rs,sh,mb,me
       21 r: rlwinm  ra,rs,sh,mb,me
power  22 r: rlmi    ra,rs,rb,mb,me
       23 r: rlwnm   ra,rs,rb,mb,me

       24 d: ori     ra,rs,uimm
       25 d: oris    ra,rs,uimms
       26 d: xori    ra,rs,uimm
       27 d: xoris   ra,rs,uimms
       28 d: andi.   ra,rs,uimm
       29 d: andis.  ra,rs,uimms
       
64bit  0 rd: rldicl ra,rs,shd,md
64bit  1 rd: rldicr ra,rs,shd,md
64bit  2 rd: rldic  ra,rs,shd,md
64bit  3 rd: rldimi ra,rs,shd,md
64bit  8 rd: rldcl  ra,rs,rb,md
64bit  9 rd: rldcr  ra,rs,rb,md

     \ 31 is x:  xc:  xo:

       32 d: lwz     rd,d(ra)
       33 d: lwzu    rd,d(ra)
       34 d: lbz     rd,d(ra)
       35 d: lbzu    rd,d(ra)
       36 d: stw     rs,d(ra)
       37 d: stwu    rs,d(ra)
       38 d: stb     rs,d(ra)
       39 d: stbu    rs,d(ra)
       40 d: lhz     rd,d(ra)
       41 d: lhzu    rd,d(ra)
       42 d: lha     rd,d(ra)
       43 d: lhau    rd,d(ra)
       44 d: sth     rs,d(ra)
       45 d: sthu    rs,d(ra)
       46 d: lmw     rd,d(ra)
       47 d: stmw    rs,d(ra)
       48 d: lfs     frd,d(ra)
       49 d: lfsu    frd,d(ra)
       50 d: lfd     frd,d(ra)
       51 d: lfdu    frd,d(ra)
       52 d: stfs    frs,d(ra)
       53 d: stfsu   frs,d(ra)
       54 d: stfd    frs,d(ra)
       55 d: stfdu   frs,d(ra)

\  56,57 are unassigned

64bit  58 0 dl: ld   rd,ds(ra)
64bit  58 1 dl: ldu  rd,ds(ra)
64bit  58 2 dl: lwa  rd,ds(ra)

\  59 is s: words
\  60,61 are unassigned

64bit  62 0 dl: std  rs,ds(ra)
64bit  62 1 dl: stdu rs,ds(ra)

\  63 is f:

       
       16   0 0 b: bc      bo,bi,bd
       16   0 1 b: bca     bo,bi,bd
       16   1 0 b: bcl     bo,bi,bd
       16   1 1 b: bcla    bo,bi,bd
       
       17   1 0 b: sc      no-args
       
       18   0 0 b: b       lif
       18   0 1 b: bl      lif
       18   1 0 b: ba      lif
       18   1 1 b: bla     lif
       
\ Opcode 19

       19  16 0 b: bclr    bo,bi
       19  16 1 b: bclrl   bo,bi
       
       19 528 0 b: bcctr   bo,bi
       19 528 1 b: bcctrl  bo,bi
       
         0 xl: mcrf    crfd,crfs
       
        50 xl: rfi     no-args
       150 xl: isync   no-args
       
        33 xl: crnor   crbd,crba,crbb
       129 xl: crandc  crbd,crba,crbb
       193 xl: crxor   crbd,crba,crbb
       225 xl: crnand  crbd,crba,crbb
       257 xl: crand   crbd,crba,crbb
       289 xl: creqv   crbd,crba,crbb
       417 xl: crorc   crbd,crba,crbb
       449 xl: cror    crbd,crba,crbb

\ Opcode 31

         8 xo: subfc   rd,ra,rb
        10 xo: addc    rd,ra,rb
        40 xo: subf    rd,ra,rb
       104 xo: neg     rd,ra
power  107 xo: mul     rd,ra,rb
       136 xo: subfe   rd,ra,rb
       138 xo: adde    rd,ra,rb
       200 xo: subfze  rd,ra
       202 xo: addze   rd,ra
       232 xo: subfme  rd,ra
       234 xo: addme   rd,ra
       235 xo: mullw   rd,ra,rb
power  264 xo: doz     rd,ra,rb
       266 xo: add     rd,ra,rb
       331 xo: div     rd,ra,rb
power  360 xo: abs     rd,ra
       363 xo: divs    rd,ra,rb
64bit  457 xo: divdu   rd,ra,rb
       459 xo: divwu   rd,ra,rb
       491 xo: divw    rd,ra,rb
power  488 xo: nabs    rd,ra
64bit  233 xo: mulld   rd,ra,rb
64bit  489 xo: divd    rd,ra,rb
       
        28 xc: and     ra,rs,rb
        60 xc: andc    ra,rs,rb
       124 xc: nor     ra,rs,rb
       284 xc: eqv     ra,rs,rb
       316 xc: xor     ra,rs,rb
       412 xc: orc     ra,rs,rb
       444 xc: or      ra,rs,rb
       476 xc: nand    ra,rs,rb
        
        11 xc: mulhwu  rd,ra,rb
        75 xc: mulhw   rd,ra,rb
64bit    9 xc: mulhdu  rd,ra,rb
64bit   73 xc: mulhd   rd,ra,rb
       922 xc: extsh   ra,rs
       954 xc: extsb   ra,rs
64bit  986 xc: extsw   ra,rs
       
        24 xc: slw     ra,rs,rb
       536 xc: srw     ra,rs,rb
       792 xc: sraw    ra,rs,rb
       824 xc: srawi   ra,rs,sh
64bit   27 xc: sld     ra,rs,rb
64bit  539 xc: srd     ra,rs,rb
64bit  413 xc: sradi   ra,rs,shd
64bit  794 xc: srad    ra,rs,rb
       
        26 xc: cntlzw  ra,rs
64bit   58 xc: cntlzd  ra,rs
       
       150 xc: stwcx   rs,ra,rb   \ XXX the non-dotted form doesn't exist!
64bit  214 xc: stdcx   rs,ra,rb   \ XXX the non-dotted form doesn't exist!
       
power  277 xc: lscbx   rd,ra,rb
       
power   29 xc: maskg   ra,rs,rb
power  541 xc: maskir  ra,rs,rb
power  537 xc: rrib    ra,rs,rb
power  153 xc: sle     ra,rs,rb
power  217 xc: sleq    ra,rs,rb
power  216 xc: sllq    ra,rs,rb
power  152 xc: slq     ra,rs,rb
power  184 xc: sliq    ra,rs,sh
power  248 xc: slliq   ra,rs,sh
power  952 xc: sraiq   ra,rs,sh
power  920 xc: sraq    ra,rs,rb
power  665 xc: sre     ra,rs,rb
power  921 xc: srea    ra,rs,rb
power  729 xc: sreq    ra,rs,rb
power  696 xc: sriq    ra,rs,sh
power  760 xc: srliq   ra,rs,sh
power  728 xc: srlq    ra,rs,rb
power  664 xc: srq     ra,rs,rb
       
       531  x: clcs    rd,ra
       
         0  x: cmp     crfd,l,ra,rb
        32  x: cmpl    crfd,l,ra,rb
       
        86  x: dcbf    ra,rb
       470  x: dcbi    ra,rb
        54  x: dcbst   ra,rb
       278  x: dcbt    ra,rb
       246  x: dcbtst  ra,rb
      1014  x: dcbz    ra,rb
       
       310  x: eciwx   rd,ra,rb
       438  x: ecowx   rs,ra,rb
       854  x: eieio   no-args
       
       982  x: icbi    ra,rb
       
        87  x: lbzx    rd,ra,rb
       119  x: lbzux   rd,ra,rb
       343  x: lhax    rd,ra,rb
       375  x: lhaux   rd,ra,rb
       790  x: lhbrx   rd,ra,rb
       279  x: lhzx    rd,ra,rb
       311  x: lhzux   rd,ra,rb
        23  x: lwzx    rd,ra,rb
        55  x: lwzux   rd,ra,rb
        20  x: lwarx   rd,ra,rb
       534  x: lwbrx   rd,ra,rb
       533  x: lswx    rd,ra,rb
       597  x: lswi    rd,ra,nb

64bit   21  x: ldx     rd,ra,rb
64bit   53  x: ldux    rd,ra,rb
64bit   84  x: ldarx   rd,ra,rb
64bit  341  x: lwax    rd,ra,rb
64bit  373  x: lwaux   rd,ra,rb
       
       542 x: lwdx   rd,ra,rb	\ exponential
       670 x: stwdx  rd,ra,rb	\ exponential

       215  x: stbx    rs,ra,rb
       247  x: stbux   rs,ra,rb
       407  x: sthx    rs,ra,rb
       439  x: sthux   rs,ra,rb
       918  x: sthbrx  rs,ra,rb
       662  x: stwbrx  rs,ra,rb
       151  x: stwx    rs,ra,rb
       183  x: stwux   rs,ra,rb

64bit  149  x: stdx    rs,ra,rb
64bit  181  x: stdux   rs,ra,rb
       
       725  x: stswi   rs,ra,nb
       661  x: stswx   rs,ra,rb
       
       727  x: stfdx   frs,ra,rb
       759  x: stfdux  frs,ra,rb
       663  x: stfsx   frs,ra,rb
       695  x: stfsux  frs,ra,rb

64bit  983  x: stfiwx  frs,ra,rb
       
       631  x: lfdux   frd,ra,rb
       599  x: lfdx    frd,ra,rb
       567  x: lfsux   frd,ra,rb
       535  x: lfsx    frd,ra,rb
       
       512  x: mcrxr   crfd
        19  x: mfcr    rd
       
        83  x: mfmsr   rd
       339  x: mfspr   rd,spr
       595  x: mfsr    rd,sr
       659  x: mfsrin  rd,rb
       144  x: mtcrf   crm,rs
       146  x: mtmsr   rs
       467  x: mtspr   spr,rs
       210  x: mtsr    sr,rs
       242  x: mtsrin  rs,rb
       371  x: mftb    rd,tbr	\ tbr register is tb or tbu
       
64bit  434  x: slbie   no-args
64bit  498  x: slbia   no-args
       566  x: tlbsync no-args
64bit  370  x: tlbia   no-args
       598  x: sync    no-args
       306  x: tlbie   rb
       978  x: tlbld   rb		\ 603-specific
      1010  x: tlbli   rb		\ 603-specific
         4  x: tw      to,ra,rb
64bit   68  x: td      to,ra,rb

\ Opcode 59

        18  s: fdivw   frd,fra,frb
        20  s: fsubs   frd,fra,frb
        21  s: fadds   frd,fra,frb
        25  s: fmuls   frd,fra,frc
        28  s: fmsubs  frd,fra,frc,frb
        29  s: fmadds  frd,fra,frc,frb
        30  s: fnmsubs frd,fra,frc,frb
        31  s: fnmadds frd,fra,frc,frb

\ Opcode 63

        18  f: fdiv    frd,fra,frb
        20  f: fsub    frd,fra,frb
        21  f: fadd    frd,fra,frb
        25  f: fmul    frd,fra,frc
        28  f: fmsub   frd,fra,frc,frb
        29  f: fmadd   frd,fra,frc,frb
        30  f: fnmsub  frd,fra,frc,frb
        31  f: fnmadd  frd,fra,frc,frb
       
        12  f: frsp    frd,frb
        14  f: fctiw   frd,frb
        15  f: fctiwz  frd,frb
64bit   22  f: fsqrt   frd,frb
64bit   23  f: fsel    frd,frb
64bit   24  f: fres    frd,frb
64bit   26  f: fsqrte  frd,frb
        40  f: fneg    frd,frb
        72  f: fmr     frd,frb
       136  f: fnabs   frd,frb
       264  f: fabs    frd,frb
       
64bit  814  f: fctid   frd,frb
64bit  815  f: fctidz  frd,frb
64bit  846  f: fcfid   frd,frb

         0  f: fcmpu   crfd,fra,frb
        32  f: fcmpo   crfd,fra,frb
       
        38  f: mtfsb1  crbd
        64  f: mcrfs   crfd,crfs  ( no-. )
        70  f: mtfsxl  crbd
       134  f: mtfsfi  crfd,imm
       583  f: mffs    frd
       711  f: mtfsf   fm,frb

\ This definition prevents "add." from being parsed as a number.
: add.  ( -- )  add  1 rc-bit  ;

headerless
: dis-16  ( -- )
   31 2 ibits  case
      0  of  ['] bc    endof
      1  of  ['] bcl   endof
      2  of  ['] bca   endof
      3  of  ['] bcla  endof
   endcase
   dis-name&operands
;

16 op-map  set-indexed-map
: dis-18  ( -- )
   31 2 ibits  case
      0  of  ['] b    endof
      1  of  ['] bl   endof
      2  of  ['] ba   endof
      3  of  ['] bla  endof
   endcase
   dis-name&operands
;
18 op-map  set-indexed-map

: dis-19  ( -- )
   30 10 ibits  19-map find-sparse-entry 
   dup (.name)                                       ( acf )
   31 1 ibits  if  ." l"  then
   dis-operands
;
19 op-map  set-indexed-map

: dis-31  ( -- )
   28 3 ibits  2 =  if		\ xo form, with o and . modifiers
      30 9 ibits  31-map  find-indexed-entry   dup (.name)   ( acf )
      21 1 ibits  if  ." o"  then
   else
      30 10 ibits  31-map  find-indexed-entry  dup (.name)   ( acf )
   then                           ( acf )
   ?.  dis-operands
;
31 op-map  set-indexed-map

: dis-59  ( -- )
   30 5 ibits  59-map  find-indexed-entry  dup (.name)  ?.  dis-operands
;
59 op-map  set-indexed-map

: dis-63  ( -- )
   30 10 ibits  63-map  find-sparse-entry  dup (.name)  ?.  dis-operands
;
63 op-map  set-indexed-map


headers
\ Structured conditionals

\ Condition names.  There are more of these near the end of the file.
\ BO bits:    16 no-cond   8 cc bit true   4 no-ctr   2 ctr=0
\ B1 values:   0 lt   1 gt   2 eq

20  0 cond always
12 00 cond lt       04 00 cond ge
12 01 cond gt       04 01 cond le
12 02 cond eq       04 02 cond ne  
12 03 cond vs       04 03 cond vc      

: ctr<>0  ( cond -- cond' )
   h# 0080.0000 invert [ also forth ] and [ previous ]
;
: ctr=0   ( cond -- cond' )
   ctr<>0  h# 0040.0000 [ also forth ] or [ previous ]
;

headerless
: <mark  ( -- <mark )  here  ;
: >mark  ( -- >mark )  here  ;
: >resolve  ( >mark -- )  here   over offset-16 over asm@ +  swap asm!  ;
: <resolve  ( -- )  ;

headers
: but     ( mark1 mark2 -- mark2 mark1 )  swap  ;
: yet     ( mark -- mark mark )  dup  ;

: ahead   ( -- >mark )          >mark  here always brif  ;
: if      ( cond -- >mark )     >mark  here  rot -cond  brif  ;
: then    ( >mark -- )          >resolve  ;
: else    ( >mark -- >mark1 )   ahead  but then  ;
: begin   ( -- <mark )          <mark  ;
: until   ( <mark cond -- )     -cond brif  ;
: again   ( <mark -- )          always brif  ;
: repeat  ( >mark <mark -- )    again  then  ;
: while   ( <mark cond -- >mark <mark )  if  but  ;

\ Define these last to delay overloading of the forth versions

\ There are no explicit condition codes for unsigned comparison;
\ there is a "cmpl" instruction that performs an unsigned ("logical")
\ comparison, setting the regular less-than and greater-than bits.

12 00 cond 0<   04 00 cond 0>=
12 00 cond  <   04 00 cond  >=
12 01 cond 0>   04 01 cond 0<=
12 01 cond  >   04 01 cond  <=
12 02 cond 0=   04 02 cond 0<>
12 02 cond  =   04 02 cond  <>

previous definitions

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
