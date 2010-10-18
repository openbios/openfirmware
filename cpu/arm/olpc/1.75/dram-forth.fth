\ Generate an XDB (Marvell Extreme Debugger) script from DRAM setup info

0 value this-reg-xt
0 value this-reg-adr
0 value this-reg-value
: note-mem-reg  ( apf -- )
   dup body> to this-reg-xt
   @ +mem-ctrl to this-reg-adr
   0 to this-reg-value
;
' note-mem-reg to do-mem-reg

: (do-bits)  ( value start #bits -- )
   drop lshift this-reg-value or  to this-reg-value
;
' (do-bits) to do-bits

: .xl  ( n -- )
   push-hex
   <# u# u# u# u# u# u# u# u# u#> 2dup type
   pop-base
;
: xdb-outbits  ( -- )
   3 spaces
   this-reg-value .xl
   space
   this-reg-adr .xl
   ."  l!   \ "
   this-reg-xt >name name>string type
   cr
;
' xdb-outbits to outbits

: show-auto-cal  ( -- )
;

: wait-dram-init  ( -- )
   cr
   ."    begin  h# d00001b0 l@ 1 and  until"  cr
   cr
;

: wait-tzqinit  ( -- )  ;

: do-dummy-reads  ( -- )
   ."    d# 131 0  do  0 l@ drop  loop  \ dummy reads" cr
;

: show-dll-delay  ( -- )
   ."    ."" DLL_DELAY from PHY_CTRL_14: "" d0000240 l@ 8 rshift h# ff and .x cr" cr
;
: start-dram-init  ( -- )
   ." : init-dram" cr
;
: end-dram-init  ( -- )
   ." ;" cr
;
