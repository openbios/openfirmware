purpose: TLB miss handlers for 823-style MMU
\ See license at end of file

also assembler definitions
\needs set-y  : set-y  ( -- )  h# 0020.0000 add-bits  ;
previous definitions

headerless

h# 00d constant twc-mem		\ Unguarded, 8MB, writeback
h# 01f constant twc-io		\ Guarded, 8MB, writethrough
h# 9fd constant rpn-mem		\ Cacheable
h# 9ff constant rpn-io		\ Cache inhibit

\ On entry:
\ sprg0 = &exception-save-area  (don't clobber it!)

\ Save registers in:
\ sprg1 = cr
\ sprg2 = r2
\ sprg3 = r3

label dtlb-miss

   mtspr  sprg3,r3		\ Save R3
   mtspr  sprg2,r2		\ Save R2

   mfcr   r3
   mtspr  sprg1,r3		\ Save cr

   mfmsr  r3
   rlwinm r3,r3,0,15,28,26	\ Disable DR
   mtmsr  r3

   \ Generate new TLB
   set    r3,h#2000.0000
   mfspr  r2,md-epn		\ Get effective address
   rlwinm r2,r2,0,0,19
   cmpl   0,0,r2,r3
   <  if
      twc-mem set    r3,*
      mtspr   md-twc,r3		\ Table Walk Control Reg
      rpn-mem set    r3,*
   else
      twc-io  set    r3,*
      mtspr  md-twc,r3		\ Table Walk Control Reg
      rpn-io  set    r3,*
   then

   or     r3,r3,r2
   mtspr  md-rpn,r3		\ Real Page Number Reg
   sync isync

   \ Restore registers
   mfmsr  r3
   ori    r3,r3,h#10		\ Enable DR
   mtmsr  r3

   mfspr  r3,sprg1
   mtcrf  h#ff,r3		\ Restore CR
   mfspr  r2,sprg2		\ Restore R2
   mfspr  r3,sprg3		\ Restore R3

   \ Return from interrupt
   rfi
end-code
here dtlb-miss - constant /dtlb-miss

: init-dtlb  ( -- )
   0 m-casid!			\ Current address space
   0 md-ap!			\ Access protection groups
   h# 0400.0000 md-ctr!		\ PowerPC mode, Page res protection, TWAN=1
				\ DTLB_INDX dec mod 8, ignore problem/privilege
				\ DTLB_INDX=0
;
: init-tlb-entries  ( -- )
   h# 0000.0200 md-epn!			\ EPN=0
   twc-mem      md-twc!
   h# 0000.0000 rpn-mem or md-rpn!	\ RPN=EPN

   h# 0080.0200 md-epn!			\ EPN=80.0000
   twc-mem      md-twc!
   h# 0080.0000 rpn-mem or md-rpn!	\ RPN=EPN

   h# fa20.0200 md-epn!			\ EPN=FA20.0000
   twc-io       md-twc!
   h# fa20.0000 rpn-io or md-rpn!	\ RPN=EPN
;
defer init-tlb		' init-dtlb to init-tlb

: put-handler  ( adr exc-adr len -- )  2dup 2>r move  2r> sync-cache  ;   

: install-tlb-miss  ( -- )
   software-tlb-miss?  if
      dtlb-miss h# 1200 /dtlb-miss put-handler   \ Data TLB miss
   then
   \ Redirect the implementation-dependent emulation trap, which
   \ is what the 8xx PPC core generates instead of the usual program
   \ interrupt, to the program interrupt vector.
   h# 700 h# 1000 put-branch
;
headers


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
