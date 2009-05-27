\ This can be included in-line in the early startup code, just
\ after memory controller turn-on, to verify basic RAM sanity.

ascii I report  ascii n report  ascii c report  
carret report  linefeed report
\ here asm-base - ResetBase + .x cr
ramtest-start # ax mov
begin
   ax 0 [ax] mov
   4 # ax add
   ramtest-end # ax cmp
0= until

ramtest-start # ax mov
begin
   0 [ax] bx mov
   ax bx cmp  <>  if
      ax di mov
      ascii B report  ascii A report  ascii D report
      di ax mov  dot #) call
      0 [di] ax mov  dot #) call
1 [if]  \ Fire up C Forth
   dcached-base 6 +          0  206 set-msr   \ Dcache base address, write back
   /dcached negate h# 800 +  f  207 set-msr   \ Dcache size
   \ This region is for CForth
   h# ffff.0000 6 +          0  208 set-msr   \ ROM base address
   /icached negate h# 800 +  f  209 set-msr   \ Icache size

   \ Access ROM to load it into the icache
   h# ffff.0000 #  esi  mov
   /icached 4 / #  ecx  mov
   rep  eax lods

   \ Access "RAM" area to load it into the dcache
   dcached-base #  esi  mov
   /dcached 4 / #  ecx  mov
   rep  eax lods

   \ Put the stack pointer at the top of the dcached area
   dcached-base /dcached + 4 - #  esp  mov
   ds ax mov  ax ss mov

   h# ffff.0000 # ax mov  ax jmp
[then]


      begin again
   then
   4 # ax add
   ramtest-end # ax cmp
0= until
ascii G report  ascii o report  ascii o report  ascii d report
carret report  linefeed report

ascii P report  ascii a report  ascii t report  ascii 5 report  
carret report  linefeed report
ramtest-start # ax mov
begin
   h# 55555555 # 0 [ax] mov
   4 # ax add
   ramtest-end # ax cmp
0= until

ramtest-start # ax mov
begin
   0 [ax] bx mov
   h# 55555555 # bx cmp  <>  if
      ( bx ax mov  ) dot #) call
      ascii B report  ascii A report  ascii D report
      h# ffff.0000 # ax mov  ax jmp  \ CForth
      begin again
   then
   4 # ax add
   ramtest-end #  ax  cmp
0= until
ascii G report  ascii o report  ascii o report  ascii d report
carret report  linefeed report

ascii P report  ascii a report  ascii t report  ascii A report  
carret report  linefeed report
ramtest-start # ax mov
begin
   h# aaaaaaaa # 0 [ax] mov
   4 # ax add
   ramtest-end # ax cmp
0= until

ramtest-start # ax mov
begin
   0 [ax] bx mov
   h# aaaaaaaa # bx cmp  <>  if
      ascii B report  ascii A report  ascii D report
      begin again
   then
   4 # ax add
   ramtest-end # ax cmp
0= until
ascii G report  ascii o report  ascii o report  ascii d report
carret report  linefeed report
