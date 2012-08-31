0 0  " "  " /" begin-package
" apbc" name
" mrvl,pxa-apbc" +compatible
[ifdef] mmp3
" marvell,mmp3-apbc" +compatible
[else]
" marvell,mmp2-apbc" +compatible
[then]

h# d4015000 h# 1000 reg
1 " #clock-cells" integer-property

: +string  encode-string encode+  ;

0 0 encode-bytes
" RTC"       +string  \ 00
" TWSI1"     +string  \ 01
" TWSI2"     +string  \ 02
" TWSI3"     +string  \ 03
" TWSI4"     +string  \ 04
" ONEWIRE"   +string  \ 05
" KPC"       +string  \ 06
" TB_ROTARY" +string  \ 07
" SW_JTAG"   +string  \ 08
" TIMERS1"   +string  \ 09
" UART1"     +string  \ 10
" UART2"     +string  \ 11
" UART3"     +string  \ 12
" GPIO"      +string  \ 13
" PWM0"      +string  \ 14
" PWM1"      +string  \ 15
" PWM2"      +string  \ 16
" PWM3"      +string  \ 17
" SSP0"      +string  \ 18
" SSP1"      +string  \ 19
" SSP2"      +string  \ 20
" SSP3"      +string  \ 21
" SSP4"      +string  \ 22
" SSP5"      +string  \ 23
" AIB"       +string  \ 24
" ASFAR"     +string  \ 25
" ASSAR"     +string  \ 26
" USIM"      +string  \ 27
" MPMU"      +string  \ 28
" IPC"       +string  \ 29
" TWSI5"     +string  \ 30
" TWSI6"     +string  \ 31
" UART4"     +string  \ 32
" RIPC"      +string  \ 33
" THSENS1"   +string  \ 34
" CORESIGHT" +string  \ 35
" THSENS2"   +string  \ 36
" THSENS3"   +string  \ 37
" THSENS4"   +string  \ 38
" clock-output-names" property

: +int  encode-int encode+ ;

0 0 encode-bytes
\  offset      clr-mask    value       rate
h# 00 +int  h# f7 +int  h# 83 +int  d#     32,768 +int  \ 00 RTC
h# 04 +int  h# 77 +int  h#  3 +int  d# 26,000,000 +int  \ 01 TWSI1
h# 08 +int  h# 77 +int  h#  3 +int  d# 26,000,000 +int  \ 02 TWSI2
h# 0c +int  h# 77 +int  h#  3 +int  d# 26,000,000 +int  \ 03 TWSI3
h# 10 +int  h# 77 +int  h#  3 +int  d# 26,000,000 +int  \ 04 TWSI4
h# 14 +int  h# 77 +int  h#  3 +int  d# 26,000,000 +int  \ 05 ONEWIRE
h# 18 +int  h# 77 +int  h#  3 +int  d# 26,000,000 +int  \ 06 KPC
h# 1c +int  h# 77 +int  h#  3 +int  d# 26,000,000 +int  \ 07 TB_ROTARY
h# 20 +int  h# 77 +int  h#  3 +int  d# 26,000,000 +int  \ 08 SW_JTAG
h# 24 +int  h# 77 +int  h# 13 +int  d#  6,500,000 +int  \ 09 TIMERS1
h# 2c +int  h# 77 +int  h# 13 +int  d# 26,000,000 +int  \ 10 UART1
h# 30 +int  h# 77 +int  h# 13 +int  d# 26,000,000 +int  \ 11 UART2
h# 34 +int  h# 77 +int  h# 13 +int  d# 26,000,000 +int  \ 12 UART3
h# 38 +int  h# 77 +int  h#  3 +int  d# 26,000,000 +int  \ 13 GPIO
h# 3c +int  h# 77 +int  h#  3 +int  d# 26,000,000 +int  \ 14 PWM0
h# 40 +int  h# 77 +int  h#  3 +int  d# 26,000,000 +int  \ 15 PWM1
h# 44 +int  h# 77 +int  h#  3 +int  d# 26,000,000 +int  \ 16 PWM2
h# 48 +int  h# 77 +int  h#  3 +int  d# 26,000,000 +int  \ 17 PWM3
h# 4c +int  h# 77 +int  h#  3 +int  d# 26,000,000 +int  \ 18 SSP0
h# 50 +int  h# 77 +int  h#  3 +int  d# 26,000,000 +int  \ 19 SSP1
h# 54 +int  h# 77 +int  h#  3 +int  d# 26,000,000 +int  \ 20 SSP2
h# 58 +int  h# 77 +int  h#  3 +int  d# 26,000,000 +int  \ 21 SSP3
h# 5c +int  h# 77 +int  h#  3 +int  d# 26,000,000 +int  \ 22 SSP4
h# 60 +int  h# 77 +int  h#  3 +int  d# 26,000,000 +int  \ 23 SSP5
h# 64 +int  h# 77 +int  h#  3 +int  d# 26,000,000 +int  \ 24 AIB
h# 68 +int  h# 77 +int  h#  3 +int  d# 26,000,000 +int  \ 25 ASFAR
h# 6c +int  h# 77 +int  h#  3 +int  d# 26,000,000 +int  \ 26 ASSAR
h# 70 +int  h# 77 +int  h#  3 +int  d# 26,000,000 +int  \ 27 USIM
h# 74 +int  h# 77 +int  h#  3 +int  d# 26,000,000 +int  \ 28 MPMU
h# 78 +int  h# 77 +int  h#  3 +int  d# 26,000,000 +int  \ 29 IPC
h# 7c +int  h# 77 +int  h#  3 +int  d# 26,000,000 +int  \ 30 TWSI5
h# 80 +int  h# 77 +int  h#  3 +int  d# 26,000,000 +int  \ 31 TWSI6
h# 88 +int  h# 77 +int  h# 13 +int  d# 26,000,000 +int  \ 32 UART4
h# 8c +int  h# 77 +int  h#  3 +int  d# 26,000,000 +int  \ 33 RIPC
h# 90 +int  h# 77 +int  h#  3 +int  d# 26,000,000 +int  \ 34 THSENS1
h# 94 +int  h#  7 +int  h#  3 +int  d# 26,000,000 +int  \ 35 CORESIGHT
h# 98 +int  h# 77 +int  h#  3 +int  d# 26,000,000 +int  \ 36 THSENS2
h# 9c +int  h# 77 +int  h#  3 +int  d# 26,000,000 +int  \ 37 THSENS3
h# a0 +int  h# 77 +int  h#  3 +int  d# 26,000,000 +int  \ 38 THSENS4
" clock-enable-registers" property

: on/off  ( on? clock# -- )
   get-reg&masks  if  drop exit  then  ( on? set-mask clr-mask reg )
   >r  r@ apbc@  and                   ( on? set-mask regval   r: reg )
   rot  if  or  else  nip  then        ( regval'  r: reg )
   r> apbc!
;

end-package
