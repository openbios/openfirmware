\ See license at end of file
purpose: 386 disassembler.

\ TODO: disassembler floating point opcodes
\       Try to reduce the size
\         a) try optimizing string arrays
\         b) Use a single dispatch table for opcodes 80-ff
\         c) eliminate some "op-col" calls by moving it into common factors

also forth definitions
vocabulary disassembler
also disassembler also definitions

nuser instruction
variable end-found
nuser pc
nuser branch-target
nuser dis-offset

: op8@   ( -- b )  pc @  dis-offset @ +  c@  1 pc +!  ;
: op16@  ( -- w )  op8@   op8@   bwjoin  ;
: op32@  ( -- l )  op16@  op16@  wljoin  ;

: bext  ( b -- l )  d# 24 <<  d# 24 >>a  ;
: wext  ( w -- l )  d# 16 <<  d# 16 >>a  ;

\ change size of data
true value op32?
: opv@  ( -- l | w )  op32?  if  op32@  else  op16@  then  ;
true value ad32?
: adv@  ( -- l | w )  ad32?  if  op32@  else  op16@   then  ;
: dis16  ( -- )  false is op32?  false is ad32?  ;
: dis32  ( -- )  true  is op32?  true  is ad32?  ;
\ XXX We should also change the register names e.g. from "eax" to "ax"
\ and handle renamed regs, prefix operators,

: get-op  ( -- )  op8@ instruction !  ;

: ibits  ( right-bit #bits -- field )
   instruction @ -rot bits
;
0 value wbit
: lowbits  ( -- n )  0 3 ibits  ;
: low4bits ( -- n )  0 4 ibits  ;
: midbits  ( -- n )  3 3 ibits  ;
: hibits   ( -- n )  6 2 ibits  ;

hex

: .,  ( -- )  ." ,"  ;

d# 32 buffer: ea-text
: $add-text  ( adr len -- )  ea-text $cat  ;

d# 34 buffer: disp-buf
: ?+  ( -- )
   ea-text c@ 1 >  if  " +" $add-text  then
;
: ?-  ( disp -- )
   ea-text c@ 1 >  if  " -" $add-text  negate  then
;
: get-disp  ( mod -- adr len )
   case
   0  of  " "  exit    endof
   1  of  op8@ bext     endof
   2  of  adv@  ad32? 0=  if  wext  then  endof
   endcase
   dup 0>=  if  ?+  else  ?-  then  
   (u.) disp-buf pack  count
;
\ Used when "w" field contains 0
string-array >reg8
," al" ," cl" ," dl" ," bl" ," ah" ," ch" ," dh" ," bh"
end-string-array

\ Used when the instruction implies a 16-bit register
string-array >reg16
," ax" ," cx" ," dx" ," bx" ," sp" ," bp" ," si" ," di"
end-string-array

\ Used when "w" field contains 1, and when there is no "w" field
string-array >regw
\    0       1       2       3       4       5       6       7
," eax" ," ecx" ," edx" ," ebx" ," esp" ," ebp" ," esi" ," edi"
end-string-array

: >reg  ( -- adr len )  >regw count  op32? 0=  if  1 /string  then  ;
: >areg  ( -- adr len )  >regw count  ad32? 0=  if  1 /string  then  ;

: >greg  ( -- adr len )  wbit  if  >reg  else  >reg8 count  then  ;

: .reg   ( reg -- )  >reg  type  ;
: .reg8  ( reg -- )  >reg8 type  ;

string-array  >scale
   ," "  ," *2"  ," *4"  ," *8"
end-string-array

: get-scaled  ( -- )
   hibits  midbits                       ( scale index-reg )
   dup 4 =  if                           ( scale index-reg )
      drop                               ( scale )
      if  ?+  " UNDEF" $add-text  then   ( )
   else                                  ( scale index-reg )
      ?+  >areg $add-text                ( scale )
      >scale count  $add-text            ( )
   then                                  ( )
;
: .[ " ["  $add-text ;
: .] " ]"  $add-text ;
: add-disp  ( sib? reg mod -- )
   .[                            ( sib? reg mod )
   2dup 0<>  swap 5 <>  or  if   ( sib? reg mod )   \ D32
      swap >areg $add-text       ( sib? mod )
   else                          ( sib? reg mod )
      2drop 2                    ( sib? mod=2 )
   then                          ( sib? mod )
   swap  if  get-scaled  then    ( mod )
   get-disp  $add-text           ( )
   .]                            ( )
;

: .ea32  ( reg mod -- )
   >r                                    ( reg r: mod )
   dup 4 =  if                           ( reg )     \ s-i-b
      drop  get-op  true  lowbits        ( true reg )
   else                                  ( reg )     \ displaced
      false swap                         ( false reg )
   then                                  ( sib? reg )
   r> add-disp
;

string-array modes16
   ," [bx+si]"
   ," [bx+di]"
   ," [bp+si]"
   ," [bp+di]"
   ," [si]"
   ," [di]"
   ," [bp]"
   ," [bx]"
end-string-array

: add-disp16  ( disp -- )
   h# ffff and  (u.) disp-buf pack count  $add-text
;
: +disp16  ( disp -- )
   dup 0<  if
      " -" $add-text  negate
   else
      " +" $add-text
   then
   add-disp16
;

: .ea16  ( reg mod -- )
   over 6 =  over 0= and  if             ( reg mod )
      \ disp16 only, takes the place of the [bp] mode
      2drop op16@ .[ add-disp16 .] exit
   then                                  ( reg mod )
   swap modes16 count $add-text          ( mod )
   case
      1 of  op8@  bext +disp16  endof
      2 of  op16@ wext +disp16  endof
   endcase
;
: .ea  ( -- )
   " "  ea-text  place
   lowbits  hibits >r                    ( reg ) ( r: mod )
   r@  3 =  if                           ( reg )     \ register direct
      >greg $add-text                    ( )
      r> drop  ea-text ". exit
   then                                  ( reg )
   r> ad32?  if  .ea32  else  .ea16  then
   ea-text ".
;
: ,ea  ( -- )  .,  .ea  ;


\ Display formatting
variable start-column
: op-col  ( -- )  start-column @  d# 9 +  #out @  -  1 max  spaces  ;

string-array >segment
   ," es"  ," cs"  ," ss"  ," ds"  ," fs"  ," gs"
end-string-array

string-array >binop
   ," add"  ," or"  ," adc"  ," sbb"  ," and"  ," sub"  ," xor"  ," cmp"   
end-string-array

: .binop  ( n -- )  >binop ". op-col  ;

string-array >unop
   ," inc"  ," dec"  ," push"  ," pop"
end-string-array

: .segment  ( -- )  3 2 ibits  >segment ".  ;

string-array >adjust
   ," daa"  ," das"  ," aaa"  ," aas"
end-string-array
: .fescape  ( -- )  ." Later, dude"  ;

0 value reg-field
: get-ea  ( -- )  get-op  midbits  is reg-field  ;

: sreg  ( -- )  reg-field  >segment ".  ;
: .mm   ( reg# -- )  ." mm" (.) type  ;
: mreg  ( -- )  reg-field  .mm  ;
: .mea  ( -- )  hibits 3 =  if  lowbits .mm  else  .ea  then  ;

: gb/v  ( -- )  reg-field  >greg type  ;
: ib    ( -- )  op8@ bext  (.) type  ;
: ,ib  ( -- )  .,  ib  ;
: iub   ( -- )  op8@       (.) type  ;
: iw    ( -- )  op16@ (.) type  ;
: iv    ( -- )  opv@ (.) type  ;
: iuv   ( -- )  adv@ (u.) type  ;
: ,ib/v ( -- )  .,  wbit  if  opv@  else  op8@  then  (u.) type  ;
: al/x  ( -- )  wbit  if  ." eax"  else  ." al"  then  ;
: ,al/x ( -- )  .,  al/x  ;
: ,cl  ( -- )  .,  ." cl"  ;

: .mode  ( mode -- )
   1 >>
   case
      0  of  get-ea  .ea   .,  gb/v  endof
      1  of  get-ea  gb/v  ,ea       endof
      2  of          al/x  ,ib/v     endof
   endcase
;
: .push  ( -- )  ." push" op-col  ;
: .pop   ( -- )  ." pop"  op-col  ;

string-array >cond
   ," o"  ," no"  ," b"  ," ae"  ," e"  ," ne"  ," be"  ," a"
   ," s"  ," ns"  ," pe" ," po"  ," l"  ," ge"  ," le"  ," g"
end-string-array

: showbranch  ( offset -- )
   pc @  op32?  if  ( offset pc )
      +                    ( pc' )
   else                    ( offset pc )
      lwsplit  -rot        ( pc.high offset pc.low )
      + h# ffff and        ( pc.high pc.low' )
      swap wljoin          ( pc' )
   then                    ( pc' )
   dup branch-target !  showaddr
;
: jb  ( -- )  op8@ bext  showbranch  ;
: jv  ( -- )  opv@  showbranch  ;

: .jcc  ( -- )  ." j"  low4bits >cond ".  op-col jb  ;
: ea,g  ( -- )  get-ea  .ea ., gb/v  ;
: g,ea  ( -- )  get-ea  gb/v ,ea  ;

: decode-op  ( -- high4bits )  get-op   0 1 ibits  is wbit  4 4 ibits   ;

string-array >grp6
   ," sldt"  ," str"  ," lldt"  ," ltr"  ," verr"  ," verw"
end-string-array
string-array >grp7
   ," sgdt" ," sidt" ," lgdt" ," lidt" ," smsw" ," Unimp" ," lmsw" ," invlpg"
end-string-array
string-array >grp8
   ," "  ," "  ," "  ," "  ," bt"  ," bts"  ," btr"  ," btc"
end-string-array

: .unimp  ( -- )  ." Unimp"  ;

: ew  ( -- )  .ea  ;  \ XXX should print, e.g. BX not eBX
: 2b0op  ( -- )
   low4bits  case
      0 of  get-ea  midbits >grp6 ".  op-col  ew  endof
      1 of  get-ea  midbits >grp7 ".  op-col  ew  endof
      2 of  ." lar"  op-col  1 is wbit  g,ea  endof
      3 of  ." lsr"  op-col  1 is wbit  g,ea  endof
      6 of  ." clts"  endof
      8 of  ." invd"  endof
      9 of  ." wbinvd"  endof
         .unimp
   endcase
;   
: .mov  ( -- )  ." mov"  op-col  ;
: .byte  ( -- )  ." byte ptr "  ;
\ Don't bother to say "byte" for register direct addressing mode
: ?.byte  ( -- )  hibits 3 <>  wbit 0=  and  if  .byte  then  ;

: .r#  ( -- )  reg-field (.) type  ;
: movspec  ( -- )
   .mov
   1 is wbit		\ These are always 32 bits
   low4bits  get-ea  case
      \ XXX Warning - the 386 and 486 books disagree about the
      \ operand order of these instructions.
      2 of   ." cr" .r#  ,ea       endof
      3 of   ." dr" .r#  ,ea       endof
      6 of   ." tr" .r#  ,ea       endof
      0 of   .ea  .,  ." cr" .r#   endof
      1 of   .ea  .,  ." dr" .r#   endof
      4 of   .ea  .,  ." tr" .r#   endof
         .unimp
   endcase
;
: 2baop  ( -- )
   low4bits  case
      0 of  .push  ." fs"  endof
      1 of  .pop   ." fs"  endof
      2 of  ." cpuid"      endof
      3 of  ." bt"   op-col             ea,g  endof
      4 of  ." shld" op-col  1 is wbit  ea,g  ,ib  endof
      5 of  ." shld" op-col  1 is wbit  ea,g  ,cl  endof
      6 of  ." cmpxchg" op-col          ea,g  endof
      7 of  ." cmpxchg" op-col          ea,g  endof
      8 of  .push  ." gs"  endof
      9 of  .pop   ." gs"  endof
      a of  ." rsm"  end-found on  endof
      b of  ." bt"   op-col             ea,g  endof
      c of  ." shrd" op-col  1 is wbit  ea,g  ,ib  endof
      d of  ." shrd" op-col  1 is wbit  ea,g  ,cl  endof
      f of  ." imul" op-col  g,ea  endof
         .unimp
   endcase
;
\ Decode operands for lds,..,lgs,lss instructions
: .lfp  ( -- )  op-col get-ea midbits .reg  ,ea   ;

: reg,  ( -- )  op-col  get-ea reg-field .reg  .,  ;
: ?.b/w  ( -- )
   hibits 3 <>  if
      wbit  if  ." word ptr "  else  .byte  then
   then
;
: 2bbop  ( -- )
   low4bits  case
      2 of  ." lss"    .lfp               endof
      3 of  ." btr"    op-col  ea,g       endof
      4 of  ." lfs"    .lfp               endof
      5 of  ." lgs"    .lfp               endof
      6 of  ." movzx"  reg,  ?.b/w  .ea   endof
      7 of  ." movzx"  reg,         .ea   endof
      a of  get-ea midbits >grp8 ".  1 is wbit  op-col .ea ,ib    endof
      b of  ." btc"    op-col  ea,g       endof
      c of  ." bsf"    reg,         .ea   endof
      d of  ." bsr"    reg,         .ea   endof
      e of  ." movsx"  reg,  ?.b/w  .ea   endof
      f of  ." movsx"  reg,         .ea   endof
         .unimp
   endcase
;
: 2bcop  ( -- )
   low4bits  case
      0 of  ." xadd"  op-col  ea,g  endof
      1 of  ." xadd"  op-col  ea,g  endof
         dup 8 <  if
            .unimp
         else
            ." bswap" op-col  dup 8 - .reg
         then
   endcase
;
: 2b6op  ( -- )
   low4bits  case
      e of  ." movd"  op-col get-ea  1 is wbit  mreg ., .ea  endof
      f of  ." movq"  op-col get-ea  1 is wbit  mreg ., .mea endof
      .unimp
   endcase
;
: 2b7op  ( -- )
   low4bits  case
      7 of  ." emms"  endof
      8 of  ." svdc"  op-col get-ea  1 is wbit  .ea  ., sreg endof
      9 of  ." rsdc"  op-col get-ea  1 is wbit  sreg ., .ea  endof
      e of  ." movd"  op-col get-ea  1 is wbit  .ea  ., mreg endof
      f of  ." movq"  op-col get-ea  1 is wbit  .mea ., mreg endof
      .unimp
   endcase
;
: msrop  ( -- )
   low4bits case
      0 of  ." wrmsr"  endof
      1 of  ." rdtsc"  endof
      2 of  ." rdmsr"  endof
      8 of  ." smint"  endof
      .unimp
   endcase
;

: .2byte  ( -- )
   decode-op  case
      0 of  2b0op  endof
      2 of  movspec  endof
      3 of  msrop    endof
      6 of  2b6op    endof
      7 of  2b7op    endof
      8 of  ." j"   low4bits >cond ".  op-col  jv  endof
      9 of  ." set" low4bits >cond ".  op-col  0 is wbit  get-ea  .ea  endof
      a of  2baop  endof
      b of  2bbop  endof
      c of  2bcop  endof
         .unimp
   endcase
;
: .wierd  ( -- )
   instruction @  f =  if  .2byte  exit then
   instruction @  h# 21 and  case
      0  of  .push    .segment   endof
      1  of  .pop     .segment   endof
     20  of           .segment  ." :"   endof
     21  of  3 2 ibits >adjust  ". endof
   endcase
;
: .2op  ( -- )
   lowbits 5 >  if
      .wierd
   else
      midbits .binop  lowbits .mode
   then
;
: .1op  ( -- )
   3 2 ibits  >unop ".  op-col  lowbits .reg
;

defer dis-body
: dis-op:  ( -- )
   op32? 0=  is op32?
   ['] dis-body catch  ( error? )
   op32? 0=  is op32?
   throw
;
: dis-ad:  ( -- )
   ad32? 0=  is ad32?
   ['] dis-body catch  ( error? )
   ad32? 0=  is ad32?
   throw
;

: .op6  ( -- )
   low4bits case
      0 of  ." pushad" endof
      1 of  ." popad"  endof
      2 of  ." bound"  op-col   get-ea reg-field .reg ,ea  endof
      3 of  ." arpl"   op-col   ea,g  endof  \ XXX should be w-reg, not d-reg
      4 of  ." fs:"  endof
      5 of  ." gs:"  endof
      6 of  ." op: "  dis-op:  endof
      7 of  ." ad: "  dis-ad:  endof
      8 of  .push    iv  endof
      9 of  ." imul" op-col g,ea ., iv  endof
      a of  .push    ib  endof
      b of  ." imul" op-col g,ea ,ib    endof
      c of  ." insb"  endof
      d of  ." insd"  endof
      e of  ." outsb" endof
      f of  ." outsd" endof
   endcase
;

: grp1op  ( -- )  get-ea  midbits .binop  ;
: .test  ( -- )  ." test" op-col  ;

: .op8  ( -- )
   low4bits  case
      0 of  grp1op    .byte .ea ., iub  endof
      1 of  grp1op          .ea ., iv   endof
\ The opcode map in the Intel manual says 82 is "movb", but it actually
\ appears to be the same as "80" - the sign extension of the immediate
\ byte is irrelevant to a byte-width operation
\     2 of  ." movb"       al/x ,ib   endof
      2 of  grp1op    .byte .ea ,ib   endof \ Opcode maps says "movb"
      3 of  grp1op          .ea ,ib   endof
      4 of  .test           ea,g  endof
      5 of  .test           ea,g  endof
      6 of  ." xchg" op-col ea,g  endof
      7 of  ." xchg" op-col ea,g  endof
      8 of  .mov            ea,g  endof
      9 of  .mov            ea,g  endof
      a of  .mov            g,ea  endof
      b of  .mov            g,ea  endof
      c of  .mov  get-ea  1 is wbit  .ea  ., sreg  endof
      e of  .mov  get-ea  1 is wbit  sreg ,ea   endof
      d of  ." lea" op-col  g,ea         endof
      f of  .pop  get-ea  .ea  endof
   endcase
;

: .4x  ( n -- )  push-hex <# u# u# u# u# u#> type pop-base  ;
: ap  ( -- )
   opv@ ." far "
   op16@ push-hex (.) type pop-base
   ." :"  op32?  if  showaddr  else  .4x  then
   end-found on
;

string-array >8line-ops
  ," cwde"  ," cdq"  ," call"  ," wait"  ," pushfd" ," popfd" ," sahf" ," lahf"
end-string-array

: .op9  ( -- )
   low4bits                                                       ( low4bits )
   dup  8 <  if  ." xchg"  op-col  .reg  ., ." eax"  exit  then   ( low4bits )
   dup 8 -  >8line-ops ".   a =  if  op-col ap  then
;

: .opa  ( -- )
   low4bits case
      0 of  .mov  al/x ., ." [" iuv ." ]"  endof
      1 of  .mov  al/x ., ." [" iuv ." ]"  endof
      2 of  .mov  ." [" iuv ." ]" ,al/x  endof
      3 of  .mov  ." [" iuv ." ]" ,al/x  endof
      4 of  ." movsb"  endof
      5 of  ." movsd"  endof
      6 of  ." cmpsb"  endof
      7 of  ." cmpsd"  endof
      8 of  .test  al/x ,ib/v  endof
      9 of  .test  al/x ,ib/v  endof
      a of  ." stosb"  endof
      b of  ." stosd"  endof
      c of  ." lodsb"  endof
      d of  ." lodsd"  endof
      e of  ." scasb"  endof
      f of  ." scasd"  endof
   endcase
;
string-array >grp2-op
   ," rol"   ," ror"  ," rcl"  ," rcr"  ," shl"  ," shr"  ," sal"  ," sar"
end-string-array
: grp2op  ( -- )  get-ea  midbits >grp2-op ". op-col  ;
: .ret   ( -- )  ." ret"  op-col  end-found on  ;
: .near  ( -- )  ." near "  ;
: .far   ( -- )  ." far "  ;

: .opc  ( -- )
   low4bits case
      0 of  grp2op        ?.byte .ea ,ib    endof
      1 of  grp2op               .ea ,ib    endof
      2 of  .ret           .near iw         endof
      3 of  .ret           .near            endof
      4 of  ." les"        .lfp             endof
      5 of  ." lds"        .lfp             endof
      6 of  .mov           get-ea  ?.byte .ea  ,ib/v  endof
      7 of  .mov           get-ea         .ea  ,ib/v  endof
      8 of  ." enter" op-col  iw ,ib        endof
      9 of  ." leave"                       endof
      a of  .ret             .far  iw       endof
      b of  .ret             .far           endof
      c of  ." int"   op-col ." 3"          endof
      d of  ." int"   op-col iub            endof
      e of  ." into"                        endof
      f of  ." iretd"  end-found on         endof
   endcase
;

defer .esc
: null.esc  ( -- )
   ." Coprocessor Escape " instruction @ .  op8@ .
;
' null.esc is .esc

: .opd  ( -- )
   low4bits  case
      0 of  grp2op   .byte .ea  .,  ." 1"   endof
      1 of  grp2op         .ea  .,  ." 1"   endof
      2 of  grp2op   .byte .ea  ,cl  endof
      3 of  grp2op         .ea  ,cl  endof
      4 of  ." aam"   op8@ drop  endof   \ D4 is always followed by 0A (10)
      5 of  ." aad"   op8@ drop  endof   \ D5 is always followed by 0A (10)
      6 of  .unimp    endof
      7 of  ." xlatb" endof
          .esc
   endcase
;

string-array >loops
   ," loopne"  ," loope"  ," loop"  ," jcxz"
end-string-array

: .in    ( -- )  ." in"   op-col  ;
: .out   ( -- )  ." out"  op-col  ;
: .call  ( -- )  ." call" op-col  ;
: .jmp   ( -- )  ." jmp"  op-col  end-found on  ;
: dx  ( -- )  ." edx"  ;

: ub    ( -- )  op8@  (.) type  ;
: .ope  ( -- )
   low4bits  dup  4 <  if  >loops ".  op-col jb   exit  then   ( low4bits )
   case
      4 of  .in   al/x  ., ub   endof
      5 of  .in   al/x  ., ub   endof
      6 of  .out  ub    ,al/x   endof
      7 of  .out  ub    ,al/x   endof
      8 of  .call jv            endof
      9 of  .jmp  jv            endof
      a of  .jmp  ap            endof
      b of  .jmp  jb            endof
      c of  .in   al/x  .,  dx  endof
      d of  .in   al/x  .,  dx  endof
      e of  .out  dx    ,al/x   endof
      f of  .out  dx    ,al/x   endof
   endcase
;

string-array >fline-ops
   ," lock"  ," unimp"  ," repne"  ," repe"  ," hlt"   ," cmc"  ," "  ," "
   ," clc"   ," stc"    ," cli"    ," sti"   ," cld"   ," std"
end-string-array

: acc-op  ( -- )  op-col  al/x  ,ea   ;
: .grp3  ( -- )
   get-ea
   midbits  case
      0 of   .test             ?.byte .ea  ,ib/v  endof
      1 of   .test                    .ea  ,ib/v  endof
      2 of   ." not"   op-col  ?.byte .ea  endof
      3 of   ." neg"   op-col  ?.byte .ea  endof
      4 of   ." mul"   acc-op              endof
      5 of   ." imul"  acc-op              endof
      6 of   ." div"   acc-op              endof
      7 of   ." idiv"  acc-op              endof
   endcase
;
: .grp4  ( -- )
   get-ea midbits  dup 1 >  if
      drop .unimp
   else
      if  ." dec"  else  ." inc"  then
      op-col  ?.byte .ea
   then
;
: .ep  ( -- )  ." far ptr "  .ea  ;
: .grp5  ( -- )
   get-ea  midbits  case
      0 of  ." inc"  op-col  .ea   endof
      1 of  ." dec"  op-col  .ea   endof
      2 of  .call  .ea   endof
      3 of  .call  .ep   endof
      4 of  .jmp   .ea   instruction @  e7 =  end-found !  endof
      5 of  .jmp   .ep   endof
      6 of  .push  .ea   endof
         .unimp
   endcase
;
: .opf  ( -- )
   low4bits  lowbits  6 <  if
      >fline-ops ".
   else
      case
         6 of  .grp3   endof
         7 of  .grp3   endof
         e of  .grp4   endof
         f of  .grp5   endof
      endcase
   then
;
: .movi ( -- )
   ." mov" op-col  3 1 ibits  is wbit  lowbits >greg type  ,ib/v
;
d# 16 case: op-class
   .2op  .2op  .2op  .2op  .1op  .1op  .op6  .jcc
   .op8  .op9  .opa  .movi .opc  .opd  .ope  .opf
;

: (dis-body)  ( -- )  branch-target off  decode-op  op-class  ;
' (dis-body) is dis-body
: dis1  ( -- )
   ??cr
   pc @ showaddr  4 spaces  #out @  start-column !
   dis-body  cr
;
: +dis  ( -- )
   base @ >r  hex
   end-found off
   begin   dis1  end-found @  exit? or  until
   r> base !
;
: dis      ( adr -- )   pc !   +dis  ;
: pc!dis1  ( adr -- )   pc !   dis1  ;
forth definitions disassembler  \ Search disassembler but define in forth

alias pc!dis1 pc!dis1
alias +dis +dis
alias dis dis
alias dis16 dis16
alias dis32 dis32

previous previous previous definitions
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
