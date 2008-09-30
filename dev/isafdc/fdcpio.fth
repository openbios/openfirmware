purpose: Patch floppy driver to use programmed-I/O
\ See license at end of file

dev /fdc

headerless
\ patch 54 14 dma-setup  \ DREQ active high	\ use no dma before it's time
\ patch 50 10 dma-setup  \ DREQ active high

1 to nd		\ Set non-DMA mode

[ifdef] notdef
code pio-sector  ( adr len in? reg-adr -- error? )
   lwz   t2,0(sp)		\ direction in t2
   lwz   t0,1cell(sp)		\ len to t0
   lwz   t1,2cells(sp)		\ adr to t1
   addi  sp,sp,3cells		\ clear stack

   mtspr ctr,t0			\ Setup loop counter

   addi  t1,t1,-1		\ Account for pre-increment

   \ We can't allow interrupts because the time
   \ spent handling them could cause overruns
   mfmsr  t3
   rlwinm t0,t3,0,17,15		\ Mask off interrupt enable bit
   mtmsr  t0

   \ Now that interupts are disabled, we can use the DEC register
   \ to keep track of a timeout. But we must save the value that
   \ is there and restore it when we are done. We will use the T5
   \ register to do that hold hold the orignal value.

   mfspr t5,dec

   \ Now to calculate a timeout value and stuff it into DEC

   'user counts/ms lwz t6,*	\ Get counts per milisecond, store in t6

   mulli  t7,t6,d#10000		\ h# 2710 is 10000 (mS) ==> 10 Seconds
   mtspr  dec,t7		\ Set the DEC register
   mulli  t7,t6,d#1000		\ Set 1 second in t7, 3e8 is 1000.

   cmpi  0,0,t2,0		\ Incoming if nonzero
   <>  if
      set t9,h#40		\ Use t9 to hold mask value which determines 
   else				\ how to test status register. 40 for reads
      set t9,h#0		\ 00 for writes.
   then

   begin
      begin
         lbz      t4,0(tos)
         andi.    t8,t4,h#80
      0= while			\ Wait until device has data for us
         mfspr    t6,dec
         cmp  0,0,t6,t7
         < if			\ Less than 1 second left...timeout
         1 L:
            set   tos,-1	\ Set error flag
            mtspr ctr,up	\ Restore "next" pointer
            mtmsr t3		\ Restore previous state of interrupt enable
            mtspr dec,t5	\ Restore the DEC to it's original value.
            next
         then
      repeat

      andi.  t8,t4,h#20		\ If the Non-DMA bit is off, the data phase
      1 B:  0=  brif		\ is over prematurely, so go to error bailout

      andi.  t8,t4,h#40		\ If the direction is wrong, bail out
      cmp    0,0,t8,t9
      1 B:  <>  brif

      cmpi  0,0,t2,0
      <> if			\ Read case
         lbz   t0,1(tos)	\ Data byte
         stbu  t0,1(t1)		\ Store to memory
      else			\ Write case
         lbzu  t0,1(t1)		\ Load from memory
         stb   t0,1(tos)	\ Data byte
      then
   countdown

   mtspr  ctr,up		\ Restore "next" pointer
   mtspr  dec,t5		\ Restore the DEC to it's original value.
   mtmsr  t3			\ Restore previous state of interrupt enable
   set    tos,0
c;
: pio-data-transfer  ( adr len in? -- error? )  floppy-chip pio-sector  ;


[else]
: (pio-data-transfer)  ( adr len in? -- error? )
   if     ( adr len )
      bounds  ?do
         begin  fstat@ h# 80 and  until
         fstat@ h# 60 and h# 60 <>  if
            true unloop exit
         then
         fifo@ i c!
      loop
   else
      bounds  ?do
         begin  fstat@ h# 80 and  until
         fstat@ h# 60 and h# 20 <>  if
            true unloop exit
         then
         i c@  fifo!
      loop
   then
   false
;
: pio-data-transfer  ( adr len in? -- error? )
   lock[  \ Interrupts off to avoid overruns
   (pio-data-transfer)
   ]unlock
;

[then]
: unload  ( -- )
   begin  fdc-fifo-wait  dio 80 or  tuck and  =  while  fifo@ drop  repeat
;

: pio-error?  ( -- error? )
   statbuf c@ h# c0 and  h# 40 =  if
      statbuf 1+ c@  80 <>
   else
      floppy-error?
   then
;

patch pio-data-transfer dma-wait r/w-data
patch noop dma-setup r/w-data
patch pio-error? floppy-error? r/w-data

device-end
headers

\ LICENSE_BEGIN
\ Copyright (c) 1996 FirmWorks
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
