: +!@     ( value offset base -- )  + tuck l! l@ drop  ;
: timer!  ( value offset -- )  timer-pa +!@  ;
: init-timers  ( -- )
   h# 13  h# 24 clock-unit-pa + l!
   0  h# 84 timer-pa + l!      \ TMR_CER  - count enable
   begin  h# 84 timer-pa + l@  7 and  0=  until
   h# 24  h# 00 timer-pa +!@   \ TMR_CCR  - clock control
   h# 200 0 do loop
   0  h# 88 timer!       \ count mode - periodic
   0  h# 4c timer!       \ preload value timer 0
   0  h# 50 timer!       \ preload value timer 1
   0  h# 54 timer!       \ preload value timer 2
   0  h# 58 timer!       \ free run timer 0
   0  h# 5c timer!       \ free run timer 1
   0  h# 60 timer!       \ free run timer 2
   7  h# 74 timer!       \ interrupt clear timer 0
   h# 100  h# 4 timer!   \ Force match
   h# 100  h# 8 timer!   \ Force match
   h# 100  h# c timer!   \ Force match
   h# 200 0 do loop
   7 h# 84 timer!
;


code timer0@  ( -- n )  \ 3.25 MHz
   psh  tos,sp
   set  r1,0xD4014000
   mov  r0,#1
   str  r0,[r1,#0xa4]
   mov  r0,r0
   ldr  tos,[r1,#0x28]
c;

code timer1@  ( -- n )  \ 32.768 kHz
   psh  tos,sp
   set  r1,0xD4014000
   mov  r0,#1
   str  r0,[r1,#0xa8]
   mov  r0,r0
   ldr  tos,[r1,#0x2c]
c;

code timer2@  ( -- n )  \ 1 kHz
   psh  tos,sp
   set  r1,0xD4014000
   mov  r0,#1
   str  r0,[r1,#0xac]
   mov  r0,r0
   ldr  tos,[r1,#0x30]
c;
