\ See license at end of file
purpose: Miscellaneous ISA "devices" - interrupt and DMA controllers and timer

new-device   0 0  " i0"  set-args   
   " dma-controller" device-name
   " dma-controller" device-type

0 0 encode-bytes
[ifndef] basic-isa
   " chrp,dma"   encode-string encode+
[then]
   " pnpPNP,200" encode-string encode+
" compatible" property

     0 1 10 encode-reg
    80 1 20 encode-reg encode+
    c0 1 20 encode-reg encode+
[ifndef] isa-dma-only
[ifdef] PREP    
   40a 1  2 encode-reg encode+		\ AIX wants this
[else]
   40a 1  1 encode-reg encode+		\ MacOS wants this
   40b 1  1 encode-reg encode+
[then]   
   410 1 30 encode-reg encode+
   481 1  b encode-reg encode+
   4d6 1  1 encode-reg encode+
[then]
   " reg" property

   internal
   create dma-init-table
   \ data    register
   h# 00 c,  h# 0d c,		\ DMA1 master clear
   h# 00 c,  h# da c,		\ DMA2 master clear
   h# 04 c,  h# 08 c,		\ Disable 0-3 group
   h# 04 c,  h# d0 c,		\ Disable 4-7 group
   h# 0f c,  h# 0f c,		\ Mask off channels 0-3
   h# 0f c,  h# de c,		\ Mask off channels 4-7
   h# c0 c,  h# d6 c,		\ Put channel 4 in cascade mode
   h# 00 c,  h# d4 c,		\ Unmask channel 4 (cascade for chs. 0-3)
   h# 00 c,  h# 08 c,		\ Enable 0-3 group
   h# 00 c,  h# d0 c,		\ Enable 4-7 group
   h# ff c,  h# ff c,		\ End of table

   external
   : init  ( -- )
      dma-init-table  begin              ( adr )
         dup ca1+ c@ dup h# ff <>        ( adr reg flag )
      while                              ( adr reg )
         over c@ swap pc!                ( adr )
         wa1+                            ( adr' )
      repeat                             ( adr reg )
      2drop
      4 0  do  i h# 40b pc!  loop	\ Put channels 0-3 in byte mode
      8 5  do  i h# 4d6 pc!  loop	\ Put channels 5-7 in word mode
      \ The preceding depends on the fact that the word-mode bit is the
      \ bit masked by 4, and the low 2 bits of the register are the channel
      \ number mod 4.  Conveniently, the numbers 5,6,7 are the correct values
      \ to put channels 5,6,7 into word mode.  Admittedly, it is a dubious
      \ coding practice to depend on such a coincidence, but the architecture
      \ of the ISA DMA controller is so cast-in-stone that this code is very
      \ unlikely ever to break.
   ;
[ifdef] tokenizing  init  [then]

finish-device

new-device  0 0  " i20"  set-args
   0 0 encode-bytes  " interrupt-controller" property
[ifdef] PREP
   2 encode-int  d encode-int encode+  " interrupts" property
[else]   

[ifndef] basic-isa
   \ This defines the way the ISA PIC feeds into the parent (CHRP
   \ Open PIC) interrupt controller.
   0 encode-int  0 encode-int encode+  " interrupts" property
[then]

   2  " #interrupt-cells"  integer-property
[then]

   \ "#address-cells" is used by interrupt-resolution code, which needs
   \ to know how many unit-address cells to prepend to the interrupt token.
   0 encode-int  " #address-cells" property

   " interrupt-controller" device-name
   " interrupt-controller" device-type

   " pnpPNP,0" " compatible" string-property

   20 1 2 encode-reg  a0 1 2 encode-reg encode+
[ifndef] basic-isa
   4d0 1 2 encode-reg encode+ 
[then]
   " reg" property

   fload ${BP}/dev/i8259.fth
finish-device

new-device  0 0  " i40" set-args
   " timer" device-name
   " timer" device-type

   " pnpPNP,100" " compatible" string-property

   40 1 4 encode-reg  61 1 1 encode-reg encode+  " reg" property
[ifdef] PREP
   0 encode-int  " interrupts" property
[else]   
   0 encode-int  3 encode-int encode+  " interrupts"  property
[then]

   fload ${BP}/dev/i8254.fth
finish-device

[ifndef] tokenizing
also forth definitions
warning @  warning off
: beep  ( -- )  " /isa/timer" " ring-bell" execute-device-method drop  ;
warning !

stand-init: ISA
   " /isa"                 " init"  execute-device-method drop
   " /isa/interrupt-controller"  " init"  execute-device-method drop
   " /isa/timer"           " init"  execute-device-method drop
   " /isa/dma-controller"  " init"  execute-device-method drop
;
previous definitions
[then]
\ LICENSE_BEGIN
\ Copyright (c) 2006 FirmWorks
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
