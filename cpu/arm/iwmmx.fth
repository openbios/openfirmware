\ See license at end of file
purpose: Intel Wireless MMX support

: enable-iwmmx  ( -- )
   coprocessor-access@ h# f or coprocessor-access!
;

d# 16 8 *  d# 8 4 *  +  buffer: iwmmx-buf 
code get-iwmmx  ( adr -- )
   wstrd wr0,[tos],#8
   wstrd wr1,[tos],#8
   wstrd wr2,[tos],#8
   wstrd wr3,[tos],#8
   wstrd wr4,[tos],#8
   wstrd wr5,[tos],#8
   wstrd wr6,[tos],#8
   wstrd wr7,[tos],#8
   wstrd wr8,[tos],#8
   wstrd wr9,[tos],#8
   wstrd wr10,[tos],#8
   wstrd wr11,[tos],#8
   wstrd wr12,[tos],#8
   wstrd wr13,[tos],#8
   wstrd wr14,[tos],#8
   wstrd wr15,[tos],#8
   wstrw wcgr0,[tos],#4
   wstrw wcgr1,[tos],#4
   wstrw wcgr2,[tos],#4
   wstrw wcgr3,[tos],#4
   wstrw wcgr0,[tos],#4
   wstrw wcid,[tos],#4
   wstrw wcon,[tos],#4
   wstrw wcssf,[tos],#4
   wstrw wcasf,[tos],#4
c;
: dump-iwmmx  ( -- )
   iwmmx-buf get-iwmmx
   push-hex
   d# 16 0 do
      i 4 bounds  do
	 iwmmx-buf i 8 * + d@  d# 17 ud.r
      loop
      cr
   4 +loop
   space
   ." wCGRs: "
   4 0  do
      iwmmx-buf h# 40 +  i la+ l@  d# 9 u.r
   loop
   cr
   ." cid, con, cssf, casf: "
   4 0  do
      iwmmx-buf h# 50 +  i la+ l@  d# 9 u.r
   loop
   cr
   pop-base
;

0 [if]  \ These code words are not expected to be used much; they are examples
: mcr    0e00.0010 {cond}   amode-copr   ;
: mrc    0e10.0010 {cond}   amode-copr   ;

code wcid@  ( -- n )  psh tos,sp  tmrc tos,wcid  c;  \ Coprocessor ID

code wcon@  ( -- n )  psh tos,sp  tmrc tos,wcon  c;  \ Control
code wcon!  ( n -- )  tmcr wcon,tos  pop tos,sp  c;

code wcasf@  ( -- n )  psh tos,sp  tmrc tos,wcasf  c; \ Arithmetic flags
code wcasf!  ( n -- )  tmcr wcasf,tos  pop tos,sp  c;

code wcssf@  ( -- n )  psh tos,sp  tmrc tos,wcssf  c; \ Saturation flags
code wcssf!  ( n -- )  tmcr wcssf,tos  pop tos,sp  c;

code wcgr0@  ( -- n )  psh tos,sp  tmrc tos,wcgr0  c; \ General registers for constants
code wcgr0!  ( n -- )  tmcr wcgr0,tos  pop tos,sp  c;
code wcgr1@  ( -- n )  psh tos,sp  tmrc tos,wcgr1  c;
code wcgr1!  ( n -- )  tmcr wcgr1,tos  pop tos,sp  c;
code wcgr2@  ( -- n )  psh tos,sp  tmrc tos,wcgr2  c;
code wcgr2!  ( n -- )  tmcr wcgr2,tos  pop tos,sp  c;
code wcgr3@  ( -- n )  psh tos,sp  tmrc tos,wcgr3  c;
code wcgr3!  ( n -- )  tmcr wcgr3,tos  pop tos,sp  c;
[then]




code wtest
   wldrd wr1,[sp],#8
   tmrrc r3,r4,wr1
   psh   r3,sp
   mov   r4,tos
c;

code firstep  ( adr1 adr2 -- adr1' adr2' d.acc )
   ldr     r0,[sp]

   wldrd   wr0,[r0],#8
   wldrd   wr1,[tos],#8

   wldrd   wr2,[r0],#8
   wmacsz  wr4,wr1,wr0
   wldrd   wr3,[tos],#8

   wldrd   wr0,[r0],#8
   wmacs   wr4,wr2,wr3
   wldrd   wr1,[tos],#8

   wldrd   wr2,[r0],#8
   wmacs   wr4,wr1,wr0
   wldrd   wr3,[tos],#8

   wmacs   wr4,wr2,wr3

   str     r0,[sp]
   psh     tos,sp

   tmrrc   r3,tos,wr4
   psh     r3,sp
c;

