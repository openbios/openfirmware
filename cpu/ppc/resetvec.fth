purpose: Reset vector handler for dropin-driver format
\ See license at end of file

\ create debug-reset

[ifdef] debug-reset
h# 8000.0000 constant io-base  \ Wrong for GoldenGate
[then]

\needs start-assembling fload ${BP}/cpu/ppc/asmtools.fth
\needs write-dropin     fload ${BP}/tools/mkdropin.fth

h#  e.0000  d# 16 rshift  constant inflate-offset    \ Shifted for addis
h#  f.0000  d# 16 rshift  constant workspace-offset  \ Shifted for addis

\ This code is intended to execute from ROM, in big-endian byte order

start-assembling
h# 20 to asm-origin	\ Skip dropin header

" Copyright 1995 FirmWorks" c$,

\ Destroys: r5, r6
label strcmp  ( r3: str1 r4: str2 -- r3: 0 if match, nonzero if mismatch )
   addi   r3,r3,-1    \ Account for pre-increment
   addi   r4,r4,-1    \ Account for pre-increment
   begin
      lbzu  r5,1(r3)
      lbzu  r6,1(r4)
      cmp   0,0,r5,r6
   = while
      cmpi  0,0,r5,0
      = if
         set    r3,0
         bclr   20,0
      then
   repeat         

   subf  r3,r5,r6
   bclr  20,0
end-code

label find-dropin    ( r3: module-name-ptr -- r3: address|-1 )
   mfspr  r31,lr

   mr     r30,r3

   \ Compute ROMbase
   here 4 +  bl *
   mfspr  r29,lr
   here 4 -  asm-base -  asm-origin +  negate  addi r29,r29,*

   begin
      lwz  r4,0(r29)
      set  r5,h#4f424d44   \ 'OBMD'
      cmp  0,0,r4,r5
   = while
      mr   r3,r30
      addi r4,r29,16
      strcmp  bl *
      cmpi 0,0,r3,0
      = if			\ It the strings match, we found the dropin
         mr     r3,r29
         mtspr  lr,r31
         bclr   20,0
      then
      lwz     r3,4(r29)		\ Length of dropin image
      add     r3,r3,r29		\ Added to base address of previous dropin
      addi    r3,r3,35		\ Plus length of header (32) + roundup (3)
      rlwinm  r29,r3,0,0,29	\ Aligned to 4-byte boundary = new dropin addr
   repeat

   set    r3,-1     \ No more dropins; return -1 to indicate failure

   mtspr  lr,r31
   bclr   20,0
end-code

label memcpy  ( r3: dst r4: src r5: n -- r3: dst )
   mtspr  ctr,r5
   mr     r6,r3

   addi   r3,r3,-1	\ Account for pre-decrement
   addi   r4,r4,-1	\ Account for pre-decrement
   begin
      lbzu r5,1(r4)
      stbu r5,1(r3)
   countdown

   mr    r3,r6		\ Return dst
   bclr  20,0
end-code

\ Firmware startup sequence:
\ 1) Execute a dropin named "start", to initialize the host bridge and memory
\ 2) Locate a dropin named "firmware", either copy it or inflate it into RAM,
\    and execute it from RAM

\ Add padding so "startup" begins at address h# 100

h# 100 pad-to

[ifdef] debug-reset
label my-entry
   0 ,				\ To be patched later
end-code

fload ${BP}/arch/prep/reports.fth
[then]

label startup  ( -- )

   mfspr  r3,hid0
   ori    r3,r3,2
   mtspr  hid0,r3

   " start" $find-dropin,  \ Assemble call to find-dropin with literal arg

   \ What should we do it this fails?  Perhaps call a default routine
   \ to try to initialize com1 and display a message?
   \ For now, we assume success

   addi   r3,r3,32	\ Skip dropin header
   mtspr  ctr,r3
   bcctrl 20,0

   mr     r26,r3	\ Save firmware load address
   mr     r27,r4	\ Save firmware RAM size

[ifdef] debug-reset
   ascii 0 ?report
[then]

   " firmware" $find-dropin,  \ Assemble call to find-dropin with literal arg

   lwz   r4,12(r3)
   cmpi  0,0,r4,0
   <> if
      \ The firmware dropin is compressed, so we load the inflater into RAM
      \ and use it to inflate the firmware into RAM
      mr  r28,r3		\ Save address of firmware dropin

      " inflate" $find-dropin,  \ Assemble call to find-dropin with literal arg

      lwz    r5,4(r3)		\ Length of inflater
      addi   r4,r3,32		\ src: Base address of inflater code in ROM
      inflate-offset  addis  r3,r26,*  \ Dst: Base address of inflater

      memcpy  bl *		\ Returns dst
      
\ XXX we might want to turn on the cache, or perhaps flush it
\ We should decide whether or not the cache is on when 'start' returns

      mtspr  ctr,r3

[ifdef] debug-reset
   dot bl *
   mr r3,r28 dot bl *
   mr r3,r26 dot bl *
   mr r3,r27 dot bl *
   ascii 1 ?report
[then]

      addi   r3,r28,32		\ Address of compressed bits of firmware dropin
      mr     r4,r26		\ Firmware RAM address
      workspace-offset  addis  r5,r26,*  \ Scratch RAM for inflater
      mr     r6,r27		\ Firmware RAM size
      add    r1,r26,r27	        \ Stack for inflater
      addi   r1,r1,h#-10	\ Because LR is saved at FP+8

      bcctrl 20,0		\ Inflate the firmware

   else
      \ The firmware dropin isn't compressed, so we just copy it to RAM

      addi    r4,r3,32		\ Skip dropin header
      lwz     r5,4(r3)		\ Length of image
      mr      r3,r26		\ Firmware RAM address
      memcpy  bl *		\ Copy the firmware
   then

[ifdef] debug-reset
   ascii 2 ?report
[then]

   mr     r3,r26		\ Firmware RAM address
   mr     r4,r27		\ Firmware RAM size

   mtspr  ctr,r26
   bcctrl 20,0			\ Execute the firmware

   \ Notreached, in theory
   begin again
end-code

[ifdef] debug-reset
startup  my-entry  put-branch
[then]

\ Add padding so this entire module ends at address h# 1e0.  Doing so makes
\ it easy to concatenate a dropin driver (with its 32-byte header) to handle
\ other exception vectors, the first of which begins at ROM offset h# 200

h# 1e0 pad-to

end-assembling

writing resetvec.di
asm-base here over -  0  " reset-vector" write-dropin
ofd @ fclose

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
