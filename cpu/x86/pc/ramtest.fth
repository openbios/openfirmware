\ This can be included in-line in the early startup code, just
\ after memory controller turn-on, to verify basic RAM sanity.

ascii I report  ascii n report  ascii c report  
carret report  linefeed report
here asm-base - ResetBase + .x cr
0 # ax mov
begin
   ax 0 [ax] mov
   4 # ax add
   h# 10.0000 # ax cmp
0= until

0 # ax mov
begin
   0 [ax] bx mov
   ax bx cmp  <>  if
      ascii B report  ascii A report  ascii D report
      begin again
   then
   4 # ax add
   h# 10.000 # ax cmp
0= until
ascii G report  ascii o report  ascii o report  ascii d report
carret report  linefeed report

ascii P report  ascii a report  ascii t report  ascii 5 report  
carret report  linefeed report
0 # ax mov
begin
   h# 55555555 # 0 [ax] mov
   4 # ax add
   h# 10.0000 # ax cmp
0= until

0 # ax mov
begin
   0 [ax] bx mov
   h# 55555555 # bx cmp  <>  if
      ascii B report  ascii A report  ascii D report
      begin again
   then
   4 # ax add
   h# 10.000 ax # cmp
0= until
ascii G report  ascii o report  ascii o report  ascii d report
carret report  linefeed report

ascii P report  ascii a report  ascii t report  ascii A report  
carret report  linefeed report
0 # ax mov
begin
   h# aaaaaaaa # 0 [ax] mov
   4 # ax add
   h# 10.0000 # ax cmp
0= until

0 # ax mov
begin
   0 [ax] bx mov
   h# aaaaaaaa # bx cmp  <>  if
      ascii B report  ascii A report  ascii D report
      begin again
   then
   4 # ax add
   h# 10.000 # ax cmp
0= until
ascii G report  ascii o report  ascii o report  ascii d report
carret report  linefeed report
