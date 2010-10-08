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

: .xu  ( n -- )
   push-hex
   <# u# u# u# u# u# u# u# u# u#> 2dup upper type
   pop-base
;
: xdb-outbits  ( -- )
   ." set value *(unsigned long *)0x"
   this-reg-adr .xu
   ."  = 0x"
   this-reg-value .xu
   ."         !#____"
   this-reg-xt >name name>string
   bounds  ?do
      i c@ dup [char] - =  if  drop ." _"  else  upc emit  then
   loop
   cr
;
' xdb-outbits to outbits

: show-auto-cal  ( -- )
   ." print ""**** Result of Pad drive strength auto cal (ZPR in [23:20], ZNR in [19:16] of PHY_CTRL14)\n\n""" cr
   ." show mem /length=4 /size=long 0xD0000240" cr
   ." print ""              __^^____\n""" cr
;

: wait-dram-init  ( -- )
   cr
   ." print ""**** DDR Init completed bit0=1 of DRAM_STATUS:\n""" cr
   ." show mem /length=4 /size=long 0xD00001B0" cr
   ." print ""              _______^\n""" cr
   ." print ""\n""" cr
   cr
;

: wait-tzqinit  ( -- )  ;

: do-dummy-reads  ( -- )
   exit  \ Maybe we don't need this because we don't set dll_auto_update_en
   ." !#__Dummy Reads for PHY DQ byte read DLLs to update (U-PHY65)__________________" cr
   ." !# if auto_update_en is used we need 131 dummy DQS cycles to allow master DLL" cr
   ." !#  to update properly per DRAM PHY App Note." cr
   ." print ""**** Performing 131 DWORD Dummy Reads for PHY DQ DLL auto update mode:\n""" cr
   ." set val @input=0" cr
   ." while 1 then" cr
   ."   set val @temp = *(unsigned long *) 0x0" cr
   ."   set val @input=@input+1" cr
   ."   if @input==131 then break end" cr
   ." end" cr
;

: show-dll-delay  ( -- )
   cr
   ." print ""**** DDRPHY: DLL_DELAY_OUT delay value in bits 15:8 of register PHY_CTRL14:\n""" cr
   ." show mem /length=4 /size=long 0xD0000240" cr
   ." print ""              ____^^__\n""" cr
   ." print ""\n""" cr
;
