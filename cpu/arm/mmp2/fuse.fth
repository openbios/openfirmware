\ See license at end of file
purpose: Display MMP2 fuse settings

: fuse@  ( offset -- )   h# 29.0000 + io@  ;

[ifdef] notdef
: .4b  ( n -- n' )  u# u# u# u# [char] . hold  ;
: .fuse-bin  ( n -- )
   base @ >r  binary
   <# .4b .4b .4b .4b .4b .4b .4b u# u# u# u# u#> type
   r> base !
;
: .3digits  ( n -- )  <# u# u# u# u#> type  ;
: .fuse#s  ( long# -- )
    ."     Fuses" 
    push-decimal
    d# 32 *  dup .3digits  ." -"  d# 31 +  .3digits
    pop-base
   ." : " 
;
: .block-binary  ( reg #regs -- )
   0  do                            ( reg )
      i .fuse#s                     ( reg )
      dup fuse@ .fuse-bin cr  la1+  ( reg' )
   loop                             ( reg )
   drop                             ( )
;
[then]
: .2hex  ( n -- )  push-hex <# u# u# u#> type pop-base  ;
: .8hex  ( n -- )  push-hex <# u# u# u# u# u# u# u# u# u#> type pop-base  ;
: .block-hex  ( reg #regs -- )
   0  do                           ( reg )
      dup fuse@ .8hex space  la1+  ( reg )
   loop                            ( reg )
   drop                            ( )
;
: .3bits  ( n -- n' )  dup 7 and .d  3 rshift  ;
string-array freqs  ," 800" ," 910" ," 1001" ," ??? " end-string-array
: .max-freq  ( n -- ) ."  Max Freq: " 3 and freqs count type   ;
: .block3-brief  ( -- )
   ." Block 3 - Voltages: "  h# 28a0 fuse@  5 0 do  .3bits  loop  2/  .3bits drop
   h# 28a4 fuse@  d# 14 rshift .max-freq  cr
;
: .block3  ( -- )
   ." Block 3" cr
   ."     Voltages: "  h# 28a0 fuse@  5 0 do  .3bits  loop  2/  .3bits  cr
   ."     Lifecycle:"    h# 2888 fuse@    ( n )
       ."  CM " .3bits  ."  DM " .3bits  ."  DD " .3bits  ."  FA " .3bits  cr  ( n' )

   ."     JTAG disable: " .3bits drop   ."  SW version " h# 2898 2 .block-hex cr ( )

   ."     ISP_DIS: "  h# 28a4 fuse@ .3bits  ."  DIS_TMP_FA: " .3bits
   8 rshift
   dup .max-freq space  2 rshift
   d# 16 rshift
   ."  HW Lock: " dup 1 and .d  1 rshift
   ."  SW Lock: " 1 and .d  cr
;

: ind  ( -- )  4 spaces  ;
: .block0-brief  ( -- )  ." Block 0 - SoC Config " h# 2904 4 .block-hex cr  ;
: .fuses  ( -- )  .block0-brief  .block3-brief  ;
: .fuses-all  ( -- )
   ." Block 0 - SoC Config" cr            ind  h# 2904 4 .block-hex cr
   ." Block 1 - WTM Root Key (RKEK)" cr   ind  h# 2924 8 .block-hex cr
   ." Block 2 - OEM Platform Key Hash" cr ind  h# 2944 8 .block-hex cr
   .block3
   ." Block 5 - Chip ID" cr               ind  h# 29e8 fuse@ .8hex space h# 29ec fuse@ .8hex cr
   ." Block 6 - OEM JTAG Key Hash" cr     ind  h# 2964 8 .block-hex cr
\  ." Block 7 - OEM JTAG Key HASH ECC"         h# 29a8 fuse@ .8hex space h# 298c fuse@ .8hex cr
\  ." Block 7 - USB ECC"                       h# fuse@ d# 16 rshift .2hexits cr
   ." Block 7 - USB ID" cr                ind  h# 2998 fuse@ .8hex space h# 299c fuse@ .8hex cr
   ." Block 8 - EC 521 low" cr            ind  h# 28a8 8 .block-hex cr
   ." Block 9 - EC 521 high" cr           ind  h# 28c8 4 .block-hex  h# 29f0 4 .block-hex cr
;

\ LICENSE_BEGIN
\ Copyright (c) 2011 FirmWorks
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
