purpose: Real-mode client interface fixups
\ See license at end of file

headerless
hex

\ The client program is required to disable i&d translation and 
\ disable interrupts before making a real-mode client interface call.
\ The firmware must save and restore


\ XXX finish the space optimization --- after exp fixups?
\ /exc h# 18 + ( dsi )  20 + ( dbats )  54 + ( sprs )
100 ( dsi )  20 + ( dbats )  54 + ( sprs )
\ /rm-tlbmiss 2* + ( dtlbs )	\ add this in stand-init
200 + ( dtlbs )
value /env

0 value fw-env
0 value client-env

code save-sprs   ( addr1 -- addr2 )	\ 54
   addi   tos,tos,-4
   mfspr  t0,sdr1	stwu  t0,4(tos)
   mfspr  t0,sprg0	stwu  t0,4(tos)
   mfspr  t0,sprg1	stwu  t0,4(tos)
   mfspr  t0,sprg2	stwu  t0,4(tos)
   mfspr  t0,sprg3	stwu  t0,4(tos)
   set t1,h#10
   begin
      addi  t1,t1,-1
      rlwinm  t0,t1,28,0,3
      mfsrin  t0,t0	stwu  t0,4(tos)
      cmpi  0,0,t1,0   <=
   until
   addi   tos,tos,4
c;
code restore-sprs   ( addr1 -- addr2 )
   addi  tos,tos,-4
   lwzu  t0,4(tos)	mtspr  sdr1,t0
   lwzu  t0,4(tos)	mtspr  sprg0,t0
   lwzu  t0,4(tos)	mtspr  sprg1,t0
   lwzu  t0,4(tos)	mtspr  sprg2,t0
   lwzu  t0,4(tos)	mtspr  sprg3,t0
   set t1,h#10
   sync		\ XXX move syncs inside the loop?
   isync	\ XXX do we *really* need both syncs both times?
   begin
      addi  t1,t1,-1
      rlwinm  t2,t1,28,0,3
      lwzu  t0,4(tos)	mtsrin  t0,t2
      cmpi  0,0,t1,0   <=
   until
   sync    
   isync   
   addi   tos,tos,4
c;

code save-dbats   ( addr1 -- addr2 )	\ 20
   mfspr  t0,dbat0u	stw  t0,0(tos)
   mfspr  t1,dbat0l	stw  t1,4(tos)
   mfspr  t2,dbat1u	stw  t2,8(tos)
   mfspr  t3,dbat1l	stw  t3,12(tos)
   mfspr  t4,dbat2u	stw  t4,16(tos)
   mfspr  t5,dbat2l	stw  t5,20(tos)
   mfspr  t6,dbat3u	stw  t6,24(tos)
   mfspr  t7,dbat3l	stw  t7,28(tos)
   addi   tos,tos,32
c;
code restore-dbats   ( addr1 -- addr2 )
   sync		\ XXX move syncs inside the loop?
   isync	\ XXX do we *really* need both syncs both times?
   lwz  t0,0(tos)	mtspr  dbat0u,t0
   lwz  t1,4(tos)	mtspr  dbat0l,t1
   lwz  t2,8(tos)	mtspr  dbat1u,t2
   lwz  t3,12(tos)	mtspr  dbat1l,t3
   lwz  t4,16(tos)	mtspr  dbat2u,t4
   lwz  t5,20(tos)	mtspr  dbat2l,t5
   lwz  t6,24(tos)	mtspr  dbat3u,t6
   lwz  t7,28(tos)	mtspr  dbat3l,t7
   sync    
   isync   
   addi   tos,tos,32
c;

code save-lomem   ( addr1 --  addr2 )	\ 120
   addi  t0,tos,-4		\ Dst into t0
   
   \ save 300-3ff
   300 4 -	set  t1,*	\ Src
   100 4 /	set  t2,*	\ set length
   mtspr ctr,t2		\ Count in count register
   begin
      lbzu  t2,4(t1)	\ Load byte
      stbu  t2,4(t0)	\ Store byte
   countdown		\ Decrement & Branch if nonzero
   
   \ check for 603-class processor
   mfspr   t3,pvr
   rlwinm  t3,t3,16,24,31
   cmpi  0,0,t3,6  = if   set t3,3   then
   cmpi  0,0,t3,7  = if   set t3,3   then
   cmpi  0,0,t3,3  = if		\ this is a 603-class processor
      \ save 1100-12ff
      1100 4 -	set  t1,*	\ Src
      200 4 /	set  t2,*	\ set length
      mtspr ctr,t2		\ Count in count register
      begin
	 lbzu  t2,4(t1)	\ Load byte
	 stbu  t2,4(t0)	\ Store byte
      countdown		\ Decrement & Branch if nonzero
   then
   addi  tos,t0,4	\ addr2
   mtspr ctr,up		\ Restore "next" pointer
c;
code restore-lomem   ( addr1 --  addr2 )
   addi  t1,tos,-4		\ Src into t1
   
   \ restore 300-3ff
   300 4 -	set  t0,*	\ Dst
   100 4 /	set  t2,*	\ set length
   mtspr ctr,t2		\ Count in count register
   begin
      lbzu  t2,4(t1)	\ Load byte
      stbu  t2,4(t0)	\ Store byte
   countdown		\ Decrement & Branch if nonzero
   
   \ check for 603-class processor
   mfspr   t3,pvr
   rlwinm  t3,t3,16,24,31
   cmpi  0,0,t3,6  = if   set t3,3   then
   cmpi  0,0,t3,7  = if   set t3,3   then
   cmpi  0,0,t3,3  = if		\ this is a 603-class processor
      \ restore 1100-12ff
      1100 4 -	set  t0,*	\ Dst
      200 4 /	set  t2,*	\ set length
      mtspr ctr,t2		\ Count in count register
      begin
	 lbzu  t2,4(t1)	\ Load byte
	 stbu  t2,4(t0)	\ Store byte
      countdown		\ Decrement & Branch if nonzero
   then
   addi  tos,t1,4	\ addr2
   mtspr ctr,up		\ Restore "next" pointer
c;

: save-environment   ( addr -- )   \ data handlers only???
   save-lomem
   save-dbats
   save-sprs
   drop
;
: restore-environment   ( addr -- )   \ data handlers only???
   restore-lomem
\   #tlb-lines invalidate-tlbs
   restore-dbats
   restore-sprs
   drop
;

: ?real-mode-entry  ( -- )
   client-env  save-environment
   fw-env    restore-environment
    \ msr@ h# 10 or msr!
   msr@ h# 10 and 0= dcache-on? and if  dcache-off  then
;
: ?real-mode-exit  ( -- )
    \ msr@ h# 10 invert and msr!
   msr@ h# 10 and 0= if
      \ If the cache was on when we entered, turn it back on
      cif-reg-save 88 + @  h# 4000 or  if  dcache-on  then
   then
   client-env  restore-environment
;

headers
stand-init: Real mode CIF
\ : rm-cif ( XXX for testing )
   use-real-mode?  if
      \ XXX optimize later:
      \ 603-class? if   /rm-tlbmiss 2* /env + to /env   then
      \ exp?     if  /exp-tlbmiss 2* /env + to /env   then
      /env alloc-mem to fw-env
      /env alloc-mem to client-env
      ['] ?real-mode-entry to rm-cif-entry
      ['] ?real-mode-exit  to rm-cif-exit
      fw-env save-environment
   then
;

warning off
dev /client-services
: claim  ( align size virt -- base )
   in-real-mode?  if    ( align size virt )
      swap rot dup  if  ( virt size align )
         rot drop       ( size align )
         ['] mem-claim catch  if  2drop 0  then
      else		( virt size 0 )
         ['] mem-claim catch  if  3drop 0  then
      then
   else
      claim
   then
;
: release  ( size virt -- )
   in-real-mode?  if              ( virt=phys size )
      swap ?release-mem		  ( )
   else                           ( virt size )
      release
   then
;
device-end
warning on

\ LICENSE_BEGIN
\ Copyright (c) 2007 FirmWorks
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
