also known-int-properties definitions
: clocks 2 ;
previous definitions

0 0  " "  " /" begin-package
" pmua" name
" mrvl,pxa-apmu" +compatible
" mrvl,mmp2-apmu" +compatible

h# d4282800 h# 1000 reg
1 " #clock-cells" integer-property

: +string  encode-string encode+  ;

0 0 encode-bytes
" IRE"      +string \ 0
" DISPLAY1" +string \ 1
" CCIC"     +string \ 2
" SDH1"     +string \ 3
" SDH2"     +string \ 4
" USB"      +string \ 5
" NF"       +string \ 6
" DMA"      +string \ 7
" WTM"      +string \ 8
" BUS"      +string \ 9
" VMETA"    +string \ 10
" GC"       +string \ 11
" SMC"      +string \ 12
" MSPRO"    +string \ 13
" SDH3"     +string \ 14
" SDH4"     +string \ 15
" CCIC2"    +string \ 16
" HSIC1"    +string \ 17
" FSIC3"    +string \ 18
" HSI"      +string \ 19
" AUDIO"    +string \ 20
" DISPLAY2" +string \ 21
" ISP"      +string \ 22
" EPD"      +string \ 23
" APB2"     +string \ 24
[ifdef] mmp3
" SPMI"     +string \ 25
" USB3SS"   +string \ 26
" SDH5"     +string \ 27
" DSA"      +string \ 28
" TPIU"     +string \ 29
" HSIC2"    +string \ 30
" SLIM"     +string \ 31
" FASTENET" +string \ 32
[then]
" clock-output-names" property

: +int  encode-int encode+ ;

0 0 encode-bytes
\    offset  clr-mask         value               rate
h# 048 +int  h#    19 +int  h#   19 +int  d#           0 +int  \ 0 IRE
h# 04c +int  h# fffff +int  h#  71b +int  d# 400,000,000 +int  \ 1 DISPLAY1
h# 050 +int  h#    3f +int  h#   3f +int  d#           0 +int  \ 2 CCIC
h# 054 +int  h#    1b +int  h#   1b +int  d# 200,000,000 +int  \ 3 SDH1
h# 058 +int  h#    1b +int  h#   1b +int  d# 200,000,000 +int  \ 4 SDH2
h# 05c +int  h#    09 +int  h#   09 +int  d# 480,000,000 +int  \ 5 USB
h# 060 +int  h#   1ff +int  h#   bf +int  d# 100,000,000 +int  \ 6 NF
h# 064 +int  h#    09 +int  h#   09 +int  d#           0 +int  \ 7 DMA
h# 068 +int  h#    1b +int  h#   1b +int  d#           0 +int  \ 8 WTM
h# 06c +int  h#    01 +int  h#   01 +int  d#           0 +int  \ 9 BUS
h# 0a4 +int  h#    1b +int  h#   1b +int  d#           0 +int  \ 10 VMETA
h# 0cc +int  h#    0f +int  h#   0f +int  d#           0 +int  \ 11 GC
h# 0d4 +int  h#    1b +int  h#   1b +int  d#           0 +int  \ 12 SMC
h# 0d8 +int  h#    3f +int  h#   3f +int  d#           0 +int  \ 13 MSPRO - MMP2 only, but left in table to preserve numbering
h# 0e8 +int  h#    1b +int  h#   1b +int  d# 200,000,000 +int  \ 14 SDH3
h# 0ec +int  h#    1b +int  h#   1b +int  d# 200,000,000 +int  \ 15 SDH4
h# 0f4 +int  h#    3f +int  h#   3f +int  d#           0 +int  \ 16 CCIC2
h# 0f8 +int  h#    1b +int  h#   1b +int  d#           0 +int  \ 17 HSIC1
h# 100 +int  h#    1b +int  h#   1b +int  d#           0 +int  \ 18 FSIC3
h# 108 +int  h#    09 +int  h#   09 +int  d#           0 +int  \ 19 HSI
h# 10c +int  h#    13 +int  h#   13 +int  d#           0 +int  \ 20 AUDIO
h# 110 +int  h#    1b +int  h#   1b +int  d#           0 +int  \ 21 DISPLAY2
[ifdef] mmp3
h# 120 +int  h#    3f +int  h#   3f +int  d#           0 +int  \ 22 ISP
h# 124 +int  h#    1b +int  h#   1b +int  d#           0 +int  \ 23 EPD
[else]
h# 224 +int  h#    1b +int  h#   1b +int  d#           0 +int  \ 22 ISP Need to do the redundancy dance
h# 144 +int  h#   21b +int  h#  21b +int  d#           0 +int  \ 23 EPD
[then]
h# 134 +int  h#    12 +int  h#   12 +int  d#           0 +int  \ 24 APB2
[ifdef] mmp3
h# 140 +int  h#    1b +int  h#   1b +int  d#           0 +int  \ 25 SPMI - XXX may need to set clock divisor bits
h# 148 +int  h#     9 +int  h#    9 +int  d#           0 +int  \ 26 USB3SS
h# 15c +int  h#    1b +int  h#   1b +int  d#           0 +int  \ 27 SDH5
h# 164 +int  h#     f +int  h#    f +int  d#           0 +int  \ 28 DSA xx
h# 18c +int  h#    12 +int  h#   12 +int  d#           0 +int  \ 29 TPIU
h# 0f8 +int  h#    1b +int  h#   1b +int  d#           0 +int  \ 30 HSIC2
h# 104 +int  h#    1b +int  h#   1b +int  d#           0 +int  \ 31 SLIM - XXX check bits
h# 210 +int  h#    1b +int  h#   1b +int  d#           0 +int  \ 32 FASTENET
[then]
" clock-enable-registers" property

end-package
