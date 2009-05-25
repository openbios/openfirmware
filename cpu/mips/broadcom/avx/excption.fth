purpose: Exception handlers
copyright: Copyright 2001 FirmWorks  All Rights Reserved

headers
hex

defer exception-hook  ' noop to exception-hook

: .dis1  ( addr -- )  [ also disassembler ] pc l! [ previous ] dis1  ;

: .epc  ( -- )
   epc@
   cause@ h# 8000.0000 and  if  la1+  then
   .dis1
;

: .badvaddr  ( -- )
   ." Bad virtual address = " badvaddr@ u. cr reset-all
;

: (exception-handler)  ( exception# -- )
   base @ >r  hex
   exception-hook
   dup (.exception)
   .epc
   case
      4  of  .badvaddr  endof
      5  of  .badvaddr  endof
   endcase
   r> base !
;
' (exception-handler) to dispatch-exceptions

: ?report  ( char -- )
   " uart-base d# 16 >> t0 lui" evaluate
   " begin   t0 h# 3fd t1 lbu   t1 h# 20 t1 andi  t1 0 <> until  nop" evaluate
   ( char )  " t1 set   t1 t0 h# 3f8 sb  " evaluate
;

label (tlb-handler)
   carret ?report linefeed ?report
   ascii T ?report ascii L ?report ascii B ?report bl ?report
   ascii R ?report ascii e ?report ascii f ?report ascii i ?report
   ascii l ?report ascii l ?report bl ?report
   ascii E ?report ascii x ?report ascii c ?report ascii e ?report
   ascii p ?report ascii t ?report ascii i ?report ascii o ?report
   ascii n ?report
   carret ?report linefeed ?report
   begin again
   nop
end-code
' (tlb-handler) to tlb-handler

label (xtlb-handler)
   carret ?report linefeed ?report
   ascii X ?report ascii T ?report ascii L ?report ascii B ?report bl ?report
   ascii R ?report ascii e ?report ascii f ?report ascii i ?report
   ascii l ?report ascii l ?report bl ?report
   ascii E ?report ascii x ?report ascii c ?report ascii e ?report
   ascii p ?report ascii t ?report ascii i ?report ascii o ?report
   ascii n ?report
   carret ?report linefeed ?report
   begin again
   nop
end-code
' (xtlb-handler) to xtlb-handler

label (cache-handler)
   carret ?report linefeed ?report
   ascii C ?report ascii a ?report ascii c ?report ascii h ?report
   ascii e ?report bl ?report
   ascii E ?report ascii r ?report ascii r ?report ascii o ?report
   ascii r ?report bl ?report
   ascii E ?report ascii x ?report ascii c ?report ascii e ?report
   ascii p ?report ascii t ?report ascii i ?report ascii o ?report
   ascii n ?report
   carret ?report linefeed ?report
   begin again
   nop
end-code
' (cache-handler) to cache-handler

headers
