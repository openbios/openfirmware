\ See license at end of file
purpose: Interrupt controller node for Marvell MMP2 (PXA688)

0 0  " d4282000"  " /" begin-package

" interrupt-controller" device-name
\ my-address my-space h# 400 reg
my-address my-space h# 1000 reg

0 value base-adr
d# 64 constant #levels

: ic@  ( offset -- l )  base-adr + rl@  ;
: ic!  ( l offset -- )  base-adr + rl!  ;

: intr@  ( level -- routing )  /l* ic@  ;
: intr!  ( routing level -- )  /l* ic!  ;

: block-irqs  ( -- )  1 h# 110 ic!  ;
: unblock-irqs  ( -- )  0 h# 110 ic!  ;

: irq-enabled?  ( level -- flag )  intr@ h# 20 and 0<>  ;
: enable-irq  ( level -- )  dup intr@  h# 20 or  swap intr!  ;  \ Enable for IRQ1
: disable-irq  ( level -- )  dup intr@  h# 20 invert and  swap intr!  ;

: run-interrupt  ( -- )
   h# 104 ic@  dup h# 40 and  if               ( reg )
      h# 3f and                                ( level )
      dup disable-irq                          ( level )
      dup  interrupt-handlers over 2* na+ 2@   ( level  level xt ih )
      package( execute )package                ( level )
      enable-irq                               ( )
   else                                        ( reg )
      drop                                     ( )
   then                                        ( )
;

: open  ( -- flag )
   my-unit h# 1000 " map-in" $call-parent to base-adr
\ Leave the IRQ table alone so as not to steal interrupts from the SP
\   block-irqs
\   d# 64 0  do  i disable-irq  loop
   unblock-irqs
   true
;
: close  ( -- )  ;

" mrvl,mmp2-intc" " compatible" string-property
1 " #address-cells" integer-property
1 " #size-cells" integer-property
: encode-unit  ( phys.. -- str )  push-hex (u.) pop-base  ;
: decode-unit  ( str -- phys.. )  push-hex  $number  if  0  then  pop-base  ;

0 0 " interrupt-controller" property
1 " #interrupt-cells" integer-property
\ d# 64 " mrvl,intc-numbers" integer-property
d# 64 " mrvl,intc-nr-irqs" integer-property
\ h# 20 " mrvl,intc-enable-mask" integer-property

: make-mux-node  ( statreg maskreg irq# #irqs )
   new-device
      " interrupt-controller" name             ( maskreg statreg irq# #irqs )
      " mrvl,intc-nr-irqs" integer-property    ( maskreg statreg irq# )
      " interrupts" integer-property           ( maskreg statreg )
      >r  4 encode-reg  r> 4 encode-reg encode+  " reg" property  ( )
      " mrvl,mmp2-mux-intc" +compatible
      0 0 " interrupt-controller" property
      1 " #interrupt-cells" integer-property
      " mux status" encode-string  " mux mask" encode-string  encode+ " reg-names" property
   finish-device
;

[ifdef] mmp3
   \ stat   mask
   h# 150 h# 168     4     4 make-mux-node \ intcmux4 - USB_CHARGER, PMIC, SPMI, CHRG_DTC_OUT
   h# 154 h# 16c     5     2 make-mux-node \ intcmux5 - RTC_ALARM, RTC
   h# 1bc h# 1a4     6     3 make-mux-node \ intcmux6 - ETHERNET, res, HSI_INT_3
   h# 1c0 h# 1a8     8     4 make-mux-node \ intcmux8 - GC2000, res, GC300, MOLTRES_NGIC_2

   h# 158 h# 170 d# 17     5 make-mux-node \ intcmux17 - TWSI2,3,4,5,6
   h# 1c4 h# 1ac d# 18     3 make-mux-node \ intcmux18 - Res, HSI_INT_2, MOLTRES_NGIC_1
   h# 1c8 h# 1b0 d# 30     2 make-mux-node \ intcmux30 - ISP_DMA, DXO_ISP
   h# 15c h# 174 d# 35 d# 31 make-mux-node \ intcmux35 - MOLTRES_(various)  (different from MMP2)
   h# 1cc h# 1b4 d# 42     2 make-mux-node \ intcmux42 - CCIC2, CCIC1
   h# 160 h# 178 d# 51     2 make-mux-node \ intcmux51 - SSP1_SRDY, SSP3_SRDY
   h# 184 h# 17c d# 55     4 make-mux-node \ intcmux55 - MMC5, res, res, HSI_INT_1
   h# 188 h# 188 d# 55 d# 20 make-mux-node \ intcmux57 - (various)
   h# 1d0 h# 1b8 d# 58     5 make-mux-node \ intcmux58 - MSP_CARD, KERMIT_INT_0, KERMIT_INT_1, res, HSI_INT_0
[else]
   h# 150 h# 168     4     2 make-mux-node \ intcmux4 - USB_CHARGER, PMIC
   h# 154 h# 16c     5     2 make-mux-node \ intcmux5 - RTC_ALARM, RTC
   h# 180 h# 17c     9     3 make-mux-node \ intcmux9 - KPC, ROTARY, TBALL
   h# 158 h# 170 d# 17     5 make-mux-node \ intcmux17 - TWSI2,3,4,5,6
   h# 15c h# 174 d# 35 d# 15 make-mux-node \ intcmux35 - (various)
   h# 160 h# 178 d# 51     2 make-mux-node \ intcmux51 - HSI_CAWAKE(1?), MIPI_HSI_INT1
   h# 188 h# 184 d# 55     2 make-mux-node \ intcmux55 - HSA_CAWAKE(0?), MIPI_HSI_INT0
[then]
   h# 128 h# 11c d# 48 d# 24 make-mux-node \ DMA mux - 16 PDMA, 4 ADMA, 2 VDMA channels

0 [if]
new-device
  " interrupt-controller" name
  " mrvl,mmp2-mux-intc" +compatible

  0 0
  h# 150 encode-int encode+  4 encode-int encode+  
  h# 168 encode-int encode+  4 encode-int encode+  " reg" property
  \  h# 150 " mrvl,intc-status" integer-property
  \  h# 168 " mrvl,intc-mask" integer-property

  4 " interrupts" integer-property
  d# 2 " mrvl,intc-nr-irqs" integer-property
  \ 0: USB_CHARGER 1: PMIC
finish-device
  
new-device
  " interrupt-controller" name
  " mrvl,mmp2-mux-intc" +compatible

  0 0
  h# 154 encode-int encode+  4 encode-int encode+  
  h# 16c encode-int encode+  4 encode-int encode+  " reg" property

  5 " interrupts" integer-property
  d# 2 " mrvl,intc-numbers" integer-property
  d# 1 " mrvl,clr-mfp-irq" integer-property
  \ 0: RTC_ALARM 1: RTC
finish-device

new-device
  " interrupt-controller" name

  " mrvl,mmp2-mux-intc" +compatible

  0 0
  h# 180 encode-int encode+  4 encode-int encode+  
  h# 17c encode-int encode+  4 encode-int encode+  " reg" property

  d# 9 " interrupts" integer-property
  d# 3 " mrvl,intc-numbers" integer-property
  \ 0:KPC (keypad) 1:ROT (rotary) 2: TBALL (trackball)
  \  h# 15c " mrvl,intc-status" integer-property
  \  h# 174 " mrvl,intc-mask" integer-property
finish-device

new-device
  " interrupt-controller" name
  " mrvl,mmp2-mux-intc" +compatible

  0 0
  h# 158 encode-int encode+  4 encode-int encode+  
  h# 170 encode-int encode+  4 encode-int encode+  " reg" property

  d# 17 " interrupts" integer-property
  d# 5 " mrvl,intc-numbers" integer-property
  \ 0: TWSI2 1: TWSI3 2: TWSI4 3: TWSI5 4: TWSI6
finish-device

new-device
  " interrupt-controller" name

  " mrvl,mmp2-mux-intc" +compatible

  0 0
  h# 15c encode-int encode+  4 encode-int encode+  
  h# 174 encode-int encode+  4 encode-int encode+  " reg" property
  \  h# 15c " mrvl,intc-status" integer-property
  \  h# 174 " mrvl,intc-mask" integer-property

  d# 35 " interrupts" integer-property
  d# 15 " mrvl,intc-numbers" integer-property
  \ 0: PERF 1: L2_PA_ECC 2: L2_ECC 3: L2_UECC 4: DDR
  \ 5: FABRIC0_TO 6: FABRIC1_TO 7: FABRIC2_TO  8: resv 9: THERMAL
  \ 10: MAIN_PMU 11: WDT2 12: CORESIGHT 13: COMMTX 14: COMMRX
finish-device

new-device
  " interrupt-controller" name
  0 0 " interrupt-controller" property
  " mrvl,mmp2-mux-intc" +compatible

  0 0
  h# 160 encode-int encode+  4 encode-int encode+  
  h# 178 encode-int encode+  4 encode-int encode+  " reg" property

  d# 51 " interrupts" integer-property
  d# 2 " mrvl,intc-numbers" integer-property
  \ 0:HSI_CAWAKE 1:MIPI_HSI_INT1
  \  h# 15c " mrvl,intc-status" integer-property
  \  h# 174 " mrvl,intc-mask" integer-property
finish-device
[then]

end-package

\ LICENSE_BEGIN
\ Copyright (c) 2010 FirmWorks
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
