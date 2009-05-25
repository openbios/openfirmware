purpose: MIPS disassembler
\ See license at end of file

vocabulary disassembler
also disassembler also definitions

headerless

string-array real-regs
," $0"   ," $1"   ," v0"   ," v1"
," a0"   ," a1"   ," a2"   ," a3"
," t0"   ," t1"   ," t2"   ," t3"
," t4"   ," t5"   ," t6"   ," t7"
," s0"   ," s1"   ," s2"   ," s3" 
," s4"   ," s5"   ," s6"   ," s7" 
," t8"   ," t9"   ," k0"   ," k1"
," gp"   ," sp"   ," s8"   ," ra"
end-string-array

defer regs  ' real-regs is regs

string-array normalops
\ o# 0X
," "      ," "		\ special and regimm
," j"     ," jal"	\ target
," beq"   ," bne"	\ rs,rt,offset
," blez"  ," bgtz"	\ rs,offset

\ o# 1X
," addi"  ," addiu"   ," slti"    ," sltiu"	\ rt,rs,immed
," andi"  ," ori"     ," xori"    ," lui"	\ rt,rs,immed

\ o# 2X
," "  ," "  ," "  ," "  \ cop0, cop1, cop2, cop1x
," "  ," "  ," "  ," "  \ beql, bnel, blezl, bgtzl (obsolescent)

\ o# 3X
," daddi"   ," daddiu"  \ rt,rs,immed
," ldl"     ," ldr"     \ rt,offset(base)
," "        ," jalx"   ," "  ," "    \ special2, jalx, mdmx, reserved

\ o# 4X
," lb"    ," lh"      ," lwl"     ," lw"	\ rt,offset(base)
," lbu"   ," lhu"     ," lwr"     ," lwu"	\ rt,offset(base)

\ o# 5X
," sb"    ," sh"      ," swl"     ," sw"	\ rt,offset(base)
," sdl"   ," sdr"     ," swr"			\ rt,offset(base)
," cache"					\ code,offset(base)

\ o# 6X
," ll"    ," lwc1"    ," lwc2"    ," pref"	\ rt,offset(base)
," lld"   ," ldc1"    ," ldc2"    ," ld"	\ rt,offset(base)

\ o# 7X
," sc"    ," swc1"    ," swc2"    ," "		\ rt,offset(base)
," scd"   ," sdc1"    ," sdc2"    ," sd"	\ rt,offset(base)
end-string-array

string-array  specialops
\ o# 0X
," sll"     ," "        ," srl"    ," sra"	\ rd,rt,sa (hole is movci)
," sllv"    ," "        ," srlv"   ," srav"	\ rd,rt,rs
\ o# 1X
," jr"						\ rs
," jalr"					\ rd,rs
," movz"    ," movn"
," syscall" ," break"   ," "       ," sync"	\ -
\ o# 2X
," mfhi"    					\ rd
," mthi"    					\ rs
," mflo"   					\ rd
," mtlo"					\ rs
," dsllv"   ," "        ," dsrlv"  ," dsrav"	\ rd,rt,rs
\ o# 3X
," mult"    ," multu"   ," div"    ," divu"	\ rs,rt
," dmult"   ," dmultu"  ," ddiv"   ," ddivu"	\ rs,rt
\ o# 4X
," add"     ," addu"    ," sub"    ," subu"	\ rd,rs,rt
," and"     ," or"      ," xor"    ," nor"	\ rd,rs,rt
\ o# 5X
," "        ," "        ," slt"    ," sltu"	\ rd,rs,rt
," dadd"    ," daddu"   ," dsub"   ," dsubu"	\ rd,rs,rt
\ o# 6X
," tge"     ," tgeu"    ," tlt"    ," tltu"	\ rs,rt
," teq"     ," "        ," tne"    ," "		\ rs,rt
\ o# 7X
," dsll"    ," "        ," dsrl"   ," dsra"	\ rd,rt,sa
," dsll32"  ," "        ," dsrl32" ," dsra32"	\ rd,rt,sa
end-string-array

string-array regimmops
\ o# 0X
," bltz"    ," bgez"	," bltzl" ," bgezl"	\ rs,offset
," "        ," "        ," "      ," "
\ o# 1X
," tgei"    ," tgeiu"	," tlti"  ," tltiu"	\ rs,immed
," teqi"    ," "	," tnei"  ," "		\ rs,immed
\ o# 2X
," bltzal"  ," bgezal"	," bltzall" ," bgezall"	\ rs,offset
," "        ," "        ," "      ," "
\ o# 3X
," "        ," "        ," "      ," "
," "        ," "        ," "      ," "
end-string-array

decimal
\ Generates a mask with #bits set in the low part.  4 >mask  yields  0000000f
lvariable instruction
variable end-found
lvariable pc
lvariable display-offset  0 display-offset l!
lvariable branch-target		\ Help for tracing/single-stepping

' ul.  is showaddr

: +offset  ( adr -- adr' )  display-offset l@  -  ;
: >mask  ( #bits -- mask )  -1  32  rot  -  >> ;
: bits  ( right-bit #bits -- field )
   instruction l@ rot >>   ( #bits shifted-instruction )
   swap >mask  land        ( field )
;
: bit?  ( bit# -- f )  instruction l@ 1 rot lshift land  ;

\ Display formatting
variable start-column
: op-col  ( -- )  start-column @  d# 8 +  to-column  ;

: .,  ( -- )  ." ,"  ;
: 5bits  ( pos -- bits )  5 bits  ;
: rd  ( -- n )  11 5bits  ;
: rt  ( -- n )  16 5bits  ;
: rs  ( -- n )  21 5bits  ;
: sa  ( -- n )   6 5bits  ;
: .freg  ( n -- )  dup  d# 16 <  if  ." FGR"  else  ." FPR"  then  .d  ;
: .dreg  ( n -- )  ." DR" .d  ;
: .reg  ( n -- )    regs ".  ;
: .rd  ( -- )   rd .reg   ;
: .rs  ( -- )   rs .reg   ;
: .rt  ( -- )   rt .reg   ;
: 2u.d  ( n -- )    base @ >r decimal  0 <# # # #> type  r> base !  ;
: 8u.h  ( n -- )  base @ >r hex  0 <# # # # # # # # # #> type  r> base !  ;
: 0s.h  ( n -- )  base @ >r hex  (.) type  r> base !  ;
: .sa   ( n -- )  sa 2u.d  ;
: simmed  ( -- n )  0 16 bits  16 << 16 >>a  ;
: 0immed  ( -- u )  0 16 bits  16 << 16 >>   ;
: .target  ( -- )
   pc @  h# f000.0000  and   0 26 bits  2 <<  or  8u.h
;
: opcode  ( -- n )  26 6 bits  ;
: funct  ( -- n )  0 6 bits  ;
: .broffset  ( -- )  pc l@ 4 +  simmed 2 <<  +  8u.h  ;
: .rs,rt,offset  ( -- )  .rs ., .rt ., .broffset  ;
: .rs,offset  ( -- )  .rs ., .broffset  ;
: .rt,offset(base)  ( -- )  .rt ., simmed 0s.h ." (" .rs ." )"  ;
: .rd,rt,sa  ( -- )  .rd ., .rt ., .sa  ;
: .rd,rt,rs  ( -- )  .rd ., .rt ., .rs  ;
: .rs,rt     ( -- )  .rs ., .rt ;
: .rd,rs     ( -- )  .rd ., .rs ;
: .rd,rs,rt  ( -- )  .rd ., .rs ., .rt  ;
: .rs,immed  ( -- )  .rs ., simmed 0s.h  ;
: .rt,rs,immed  ( n -- )  .rt ., .rs ., 0s.h  ;
: .unimp  ( -- )  ." UNIMP"  op-col  ;

string-array cachesps
," I" ," D" ," SI" ," SD"
end-string-array
string-array cacheops
," IndexInvalidate" ," IndexWriteBackInvalidate" ," IndexInvalidate" ," IndexWriteBackkInvalidate"
," IndexLoadTag"    ," IndexLoadTag"             ," IndexLoadTag"    ," IndexLoadTag"
," IndexStoreTag"   ," IndexStoreTag"            ," IndexStoreTag"   ," IndexStoreTag"
," "                ," CreateDirtyExclusive"     ," "                ," CreateDirtyExclusive"
," HitInvalidate"   ," HitInvalidate"            ," HitInvalidate"   ," HitInvalidate"
," Fill"            ," HitWriteBackInvalidate"   ," "                ," HitWriteBackInvalidate"
," HitWriteBack"    ," HitWriteBack"             ," "                ," HitWriteBack"
," "                ," "                         ," HitSetVirtual"   ," HitSetVirtual"
end-string-array

: .cache  ( -- )
   rt cacheops ".
   ." (" 16 2 bits cachesps ". ." )"
   ., simmed 0s.h ." (" .rs ." )"
;

: .op	( pstr -- )
   dup c@ 0=  if  drop  .unimp  else  ".  op-col  then
;
: above  ( selector limit -- selector testval )  over tuck  >  if  1-  then  ;
: .regimm  ( -- )
   rt   dup regimmops  .op   ( opbits )
   o# 10  o# 20 within  if  .rs,immed  else  .rs,offset  then
;
: .iw  instruction l@ 8u.h  ;
: bits23..21  ( -- n )  d# 21 3 bits  ;

string-array bcops
," f"  ," t"  ," fl"  ," tl"
end-string-array

: .bad  ( -- )  .unimp .iw  ;
: .fop  ( pstr -- )
   ".  rs  case
      o# 20 of  ." .s"  endof
      o# 21 of  ." .d"  endof
      o# 24 of  ." .w"  endof
      ( default )  ." .?"
   endcase
   op-col
;
: .f1r  ( -- )  sa .freg .,  rd .freg  ;
: .f2r  ( -- )  .f1r ., rt .freg  ;
: bits2..0  ( -- n )  0 3 bits  ;
string-array cvtops
   ," cvt.s"  ," cvt.d"  ," "  ," "  ," cvt.w"   ," cvt.l"  ," cvt.ps"  ," "
end-string-array

: bits2..0  ( -- n )  0 3 bits  ;

string-array fcalcops
   ," add" ," sub" ," mul" ," div" ," sqrt" ," abs" ," mov" ," neg"

end-string-array

string-array fc1ops
   ," round" ," trunc" ," ceil" ," floor"
end-string-array

string-array fcmpops
   ," c.f"    ," c.un"   ," c.eq"   ," c.ueq"
   ," c.olt"  ," c.ult"  ," c.ole"  ," c.ule"
   ," c.sf"   ," c.ngle" ," c.seq"  ," c.ngl"
   ," c.lt"   ," c.nge"  ," c.le"   ," c.ngt"
end-string-array

: .fcmp  ( -- )
   0 4 bits fcmpops  .fop  rd .freg  .,  rt .freg
;

[ifdef] notyet
string-array f2ops
   ," "  ," {movcf}"  ," movz"   ," movn"  ," "  ," recip"  ," rsqrt"  ," "
end-string-array
string-array f3ops
   ," recip2"  ," recip1"  ," rsqrt1"   ," rsqrt2"
end-string-array
[then]

: .fcalc  ( -- )
   3 3 bits case
   0 of  bits2..0 dup  fcalcops .fop  4 <  if  .f2r  else  .f1r  then  endof
   1 of  bits2..0 4 - dup 0<  if drop .bad  else  fc1ops .fop .f1r  then  endof
[ifdef] notyet
   2 of  bits2..0 f2ops  .fop ( .f1r ??)  endof
   3 of  bits2..0 4 - dup 0<  if drop .bad  else  f3ops .fop ( .f1r ??) then  endof
[then]
   4 of  bits2..0 cvtops .fop .f1r  endof
   6 of .fcmp  endof
   7 of .fcmp  endof
   ( default )  .bad
   endcase
;

string-array cp0ops
   ," "     
   ," tlbr"  
   ," tlbwi" 
   ," " ," " ," "
   ," tlbwr"
   ," "
   ," tlbp"
   ," "     ," "  ," "  ," "  ," "  ," "  ," "  \ holes
   ," "     ," "  ," "  ," "  ," "  ," "  ," "  ," "  \ holes
   ," eret" ," "  ," "  ," "  ," "  ," "  ," "  ," deret"
   ," wait"
end-string-array

: .cp0  ( -- )
   pc l@ l@  h# 3f and  h# 18 =  end-found !
   0 6 bits  cp0ops .op
;

string-array mfcops	\ rt(16), fs(11=rd)
," mfc" ," dmfc"   ," cfc"    ," "  ," mtc" ," dmtc" ," ctc" ," "
," bc"  ," bcany2" ," bcany4" ," "  ," "    ," "     ," "    ," "
," s"   ," d"      ," "       ," "  ," w"   ," l"    ," ps"  ," "
end-string-array

: .(cop)  ( pstr -- )
   dup c@ 0=  if  drop  ." UNIMP"  else  ". d# 26 2 bits ascii 0 + emit  then
;

: .copx  ( -- )
   d# 24 2 bits  case
      0  of  ." Coprocessor instruction "  .iw
      1  of  bits23..21  if
                .bad
             else
                rt 4 >  if  .bad  else  rs mfcops .(cop) rt bcops .op  .broffset  then
             then
             endof
      ( default )  .bad
   endcase
;

: .cop0  ( -- )
   d# 24 2 bits  case
      0 of  rs mfcops .(cop) op-col  .rt ., rd 2u.d  endof
      1 of  bits23..21  if
               .bad
            else
               rt 4 >  if  .bad  else  rs mfcops .(cop) rt bcops .op  .broffset  then
            then
            endof
      2 of  .cp0  endof
      3 of  .bad  endof
   endcase
;

: .cop1  ( -- )
   d# 24 2 bits  case
      0 of  rs mfcops .(cop) op-col  .rt ., rd .freg  endof
      1 of  bits23..21  if
               .bad
            else
               rt 4 >  if  .bad  else  rs mfcops .(cop) rt bcops .op  .broffset  then
            then
            endof
      2 of  .fcalc  endof
      ( default )  .bad
   endcase
;

: .special  ( -- )
   \ Stop when we see  jr
   pc l@ l@   h# fc00.003f and  h# 0000.0008 =  end-found !

   0 6 bits  dup specialops  .op   ( opbits )
   case
      o# 70 above of  .rd,rt,sa   endof
      o# 60 above of  .rs,rt      endof
      o# 40 above of  .rd,rs,rt   endof
      o# 30 above of  .rs,rt      endof
      o# 24 above of  .rd,rt,rs   endof
      o# 23       of  .rs         endof
      o# 22       of  .rd         endof
      o# 21       of  .rs         endof
      o# 20       of  .rd         endof
      o# 14 above of              endof		\ no operands
      o# 11 above of  .rd,rs      endof
      o# 10 above of  .rs         endof
      o# 04 above of  .rd,rt,rs   endof
      ( default )     .rd,rt,sa
   endcase
;

\ XXX implement me
: .mdmx  ( -- )  ." MDMX ..." cr  ;

: .special2  ( -- )
   \ Stop when we see  jr
   pc l@ l@   h# 0000.003f and  h# 0000.003e =  end-found !

   0 6 bits  case
[ifdef] notyet
      o# 00 of  ." madd"  endof
      o# 01 of  ." maddu" endof
      o# 02 of  ." mul"   endof
      o# 04 of  ." msub"  endof
      o# 05 of  ." msubu" endof
      o# 40 of  ." clz"   endof
      o# 41 of  ." clo"   endof
      o# 44 of  ." dclz"  endof
      o# 45 of  ." dclo"  endof
[then]
      o# 75 of  rs case
                   0  of  ." mfdr" .rt ., rd .dreg  endof
                   4  of  ." mtdr" .rt ., rd .dreg  endof
                   ( default )  .rd,rt,rs
                endcase
      o# 76 of  ." dret"    endof
      o# 77 of  ." dbreak"  endof
      ( default )  .rd,rt,sa
   endcase
;

: .normal  ( -- )
   \ Stop when we see  j
   pc l@ l@   h# fc00.0000 and  h# 0800.0000 =  end-found !
   26 6 bits  dup normalops  .op   ( opbits )
   case
      o# 60 above of  .rt,offset(base)     endof
      o# 57       of  .cache               endof
      o# 32 above of  .rt,offset(base)     endof
      o# 30 above of  simmed .rt,rs,immed  endof
      o# 26 above of  .rs,offset           endof
      o# 24 above of  .rs,rt,offset        endof
      o# 17 above of  .rt ., 0immed 16 << 8u.h   endof
      o# 14 above of  0immed .rt,rs,immed  endof
      o# 10 above of  simmed .rt,rs,immed  endof
      o# 06 above of  .rs,offset           endof
      o# 04 above of  .rs,rt,offset        endof
      ( default )     .target
   endcase
;

: disasm  ( 32b -- )
   instruction l!
   26 6 bits  case
          0  of  .special  endof
          1  of  .regimm   endof
      o# 20  of  .cop0     endof
      o# 21  of  .cop1     endof
      o# 22  of  .copx     endof
      o# 23  of  .copx     endof
      o# 34  of  .special2 endof
      o# 36  of  .mdmx     endof
      ( default )  .normal
   endcase
   cr
;

forth definitions
headers \ ****************
alias disasm disasm
\ : .5bits  ( n -- n' )
\    octal
\    ascii . hold over h# 1f and 0 # # 2drop drop 5 >> 0
\ ;
\ : .xop  ( -- )
\    pc l@ l@  0 <# # # # # .5bits .5bits ascii . hold # # #> type  hex
\ ;
: .xop ;
: dis1  ( -- )
   ??cr
   pc l@ +offset  showaddr  2 spaces  .xop
   4 spaces  #out @  start-column !
   pc l@ l@ disasm
   /l pc +!
;
: +dis  ( -- )
   base @ >r  hex
   end-found off
   begin   dis1  end-found @  exit? or  until
   dis1       \ Disassemble the delay instruction too
   r> base !
;
: dis  ( adr -- )   pc l!   +dis  ;
alias (dis dis
previous previous definitions

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
