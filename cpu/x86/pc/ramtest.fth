\ This can be included in-line in the early startup code, just
\ after memory controller turn-on, to verify basic RAM sanity.

ramtest-start #mmxdot  mmxcr

ascii I report  ascii n report  ascii c report  
ramtest-start # ax mov
begin
   ax 0 [ax] mov
   4 # ax add
   ramtest-end # ax cmp
0= until

ascii . report

ramtest-start # ax mov
begin
   0 [ax] bx mov
   \   ax bx cmp  <>  if
ax bx cmp  <>  if
   ax mmxdot
   bx mmxdot
   0 [ax] mmxdot
      ascii B report  ascii A report  ascii D report
0 [if]  \ Fire up C Forth
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
      begin hlt again
   then
   4 # ax add
   ramtest-end # ax cmp
0= until
ascii G report  ascii o report  ascii o report  ascii d report
carret report  linefeed report

ascii P report  ascii a report  ascii t report  ascii 5 report  
ramtest-start # ax mov
begin
   h# 55555555 # 0 [ax] mov
   4 # ax add
   ramtest-end # ax cmp
0= until

ascii . report

ramtest-start # ax mov
begin
   0 [ax] bx mov
   h# 55555555 # bx cmp  <>  if
      ax mmxdot
      bx mmxdot
      ascii B report  ascii A report  ascii D report
      begin hlt again
   then
   4 # ax add
   ramtest-end #  ax  cmp
0= until
ascii G report  ascii o report  ascii o report  ascii d report
carret report  linefeed report

ascii P report  ascii a report  ascii t report  ascii A report  
ramtest-start # ax mov
begin
   h# aaaaaaaa # 0 [ax] mov
   4 # ax add
   ramtest-end # ax cmp
0= until

ascii . report

ramtest-start # ax mov
begin
   0 [ax] bx mov
   h# aaaaaaaa # bx cmp  <>  if
      ax mmxdot
      bx mmxdot
      ascii B report  ascii A report  ascii D report
      begin hlt again
   then
   4 # ax add
   ramtest-end # ax cmp
0= until
ascii G report  ascii o report  ascii o report  ascii d report
carret report  linefeed report
