also known-int-properties definitions
: clocks 2 ;
previous definitions

\ Given a clock index, retrieve the register offset and set/clear masks
\ from the clock-enable-registers property in the device node from which
\ this is called.  The format and usage of clock-enable-registers is
\ specific to PXA/MMP SoCs, but might be useful for any hardware whose
\ clock enabling can be expressed by clearing some register bits and
\ setting others.

: get-reg&masks  ( clock# -- set-mask ~clr-mask reg false | true )
   " clock-enable-registers" get-property  if  ( clock# )
      drop true exit      ( true -- )
   then                   ( clock# propval$ )

   \ Offset into clock-enable-registers array
   rot  h# 10 *           ( propval$ offset )
   2dup  <=  if           ( propval$ offset )
      3drop true exit     ( true -- )
   then                   ( propval-adr$ offset )
   /string                ( propval-adr$' )

   decode-int >r          ( propval-adr$'  r: reg )
   decode-int invert >r   ( propval-adr$'  r: reg ~clr-mask )
   get-encoded-int r> r>  ( set-mask ~clr-mask reg )
   false                  ( set-mask ~clr-mask reg false )
;

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
h# 054 +int  h#    1b +int  h#  41b +int  d# 200,000,000 +int  \ 3 SDH1
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

: generic-on/off  ( on? clock# -- )
   get-reg&masks  if  drop exit  then  ( on? set-mask clr-mask reg )
   >r  r@ pmua@  and                   ( on? set-mask regval   r: reg )
   rot  if  or  else  nip  then        ( regval'  r: reg )
   r> pmua!
;

h# 10c constant audio-clk

[ifdef] mmp3
h# 164 constant audio-dsa
h# 1e4 constant isld-dspa-ctrl
h# 240 constant audio-sram-pwr
[then]

\ Discrepancies - ms vs us, double-enabling of AXI
: dly  d# 10 us  ;

: audio-island-on  ( -- )
[ifdef] mmp3
   h# 200  audio-clk  pmua-set  dly  \ Power switch on
   h# 400  audio-clk  pmua-set  dly  \ Power switch more on
   1  audio-sram-pwr  pmua-set  dly  \ Audio SRAM on
   2  audio-sram-pwr  pmua-set  dly  \ Audio SRAM more on
   4  audio-sram-pwr  pmua-set  dly  \ Audio core on
   8  audio-sram-pwr  pmua-set  dly  \ Audio core more on
   h# 100  audio-clk  pmua-set  dly  \ Disable isolation

   4  audio-clk pmua-set           \ Start audio SRAM redundancy repair
   begin  audio-clk pmua@  4 and 0=  until  \ And wait until done

   \ Bring audio island out of reset
   1 audio-dsa pmua-set
   4 audio-dsa pmua-set
   1 audio-dsa pmua-set

   \ Enable dummy clocks to the SRAMs
   h# 10 isld-dspa-ctrl pmua-set  d# 250 us  h# 10 isld-dspa-ctrl pmua-clr

   \ Enable the AXI/APB clocks to the Audio island prior to programming island registers
   2 audio-dsa pmua-set
   8 audio-dsa pmua-set
[else]
   h# 600  audio-clk  pmua!  dly  \ Turn on power
   h# 610  audio-clk  pmua!  dly  \ Enable clock
   h# 710  audio-clk  pmua!  dly  \ Disable isolation
   h# 712  audio-clk  pmua!  dly  \ Release reset
[then]
;

: audio-island-off  ( -- )
[ifdef] true
[ifdef] mmp3
   h#   a  audio-dsa       pmua-clr  \ Disable AXI and APB clocks
   h#   5  audio-dsa       pmua-clr  \ Put AXI and APB clocks in reset
   h# 100  audio-clk       pmua-clr  \ Enable isolation
   h#   c  audio-sram-pwr  pmua-clr  \ Audio core off
   h#   3  audio-sram-pwr  pmua-clr  \ Audio SRAM off
   h# 600  audio-clk       pmua-clr  \ Enable isolation
[else]
   h# 710  audio-clk  pmua!  \ Set peripheral reset
   h# 610  audio-clk  pmua!  \ Enable isolation
   h# 600  audio-clk  pmua!  \ Disable clock
   h# 000  audio-clk  pmua!  \ Turn off power
[then]
[then]
   0 audio-clk pmua!
;
: audio-on/off  ( on? -- )
   if  audio-island-on  else  audio-island-off  then
;

[ifdef] mmp3
: ccic-isp-island-off  ( -- )
   h# 600 h# 1fc pmua!  \ Isolation enabled
   \ Fiddle with ISP_CLK_RES_CTRL here to turn off ISP engine
   h# 000 h# 1fc pmua!  \ Power off
;

: ccic-isp-island-on   ( -- )
   \ set ISP regs to the default value
   0 h#  50 pmua!
   0 h# 1fc pmua!

   \ Turn on the CCIC/ISP power switch
   h# 200 h# 1fc pmua!  \ Partially powered
   d# 10 ms
   h# 600 h# 1fc pmua!  \ Fully powered
   d# 10 ms
   h# 700 h# 1fc pmua!  \ Isolation disabled

[ifdef] notdef
   \ Empirically, the memory redundancy and SRAMs are unnecessary
   \ for camera-only (no ISP) operation.

   \ Start memory redundacy repair
   4 h# 224 pmua-set   \ PMUA_ISP_CLK_RES_CTRL
   begin  d# 10 ms h# 224 pmua@  4 and  0=  until
	
   \ Enable dummy clocks to the SRAMS
   h# 10 h# 1e0 pmua-set   \ PMUA_ISLD_CI_PDWN_CTRL
   d# 200 ms
   h# 10 h# 1e0 pmua-clr
[then]

   \ Enable ISP clocks here if you want to use the ISP
   \ 8 h# 224 pmua-set  \ Enable AXI clock in PMUA_ISP_CLK_RES_CTRL
   \ h# f00 h# 200 h# 224 pmua-fld \ Clock divider
   \ h#  c0 h#  40 h# 224 pmua-fld \ CLock source
   \ h# 10 h# 224 pmua-set

   \ enable CCIC clocks
   h# 8238 h# 50 pmua-set

   \ Deassert ISP clocks here if you want to use the ISP
   \ XXX should these be pmua-clr ?
   \ 1 h# 224 pmua-set  \ AXI reset
   \ 2 h# 224 pmua-set  \ ISP SW reset
   \ h# 10000 h# 50 pmua-set  \ CCIC1 AXI Arbiter reset

   \ De-assert CCIC Resets
   h# 10107 h# 50 pmua-set \ XXX change to 107
;
[then]

: ccic-on/off  ( on? -- )
   if
      [ifdef] mmp3  ccic-isp-island-on  [then]

      \ Enable clocks
      h#        3f h# 28 pmua!  \ Clock gating - AHB, Internal PIXCLK, AXI clock always on
      h# 0003.805b h# 50 pmua!  \ PMUA clock config for CCIC - /1, PLL1/16, AXI arb, AXI, perip on
   else
      h# 3f h# 50 pmua-clr
      [ifdef] mmp3  ccic-isp-island-off  [then]
   then
;

: on/off  ( on? clock# -- )
   \ Special-case devices that need more elaborate on/off procedures
   dup 2  =  if     \ CCIC         ( on? clock# )
      drop  ccic-on/off  exit      ( -- )
   then                            ( on? clock# )

   dup d# 20 =  if   \ AUDIO       ( on? clock# )
      drop  audio-on/off  exit     ( -- )
   then

   generic-on/off
;

end-package

\ This is a general-purpose mechanism for enabling/disabling a clock
\ that is described by a "clocks" property in the device node.  The
\ property value is a phandle and an index, as used in Linux.

: my-clock-on/off  ( on? -- )
   " clocks" get-my-property  abort" No clocks property"  ( on? propval$ )
   decode-int  >r                  ( on? propval$  r: phandle )
   get-encoded-int                 ( on? clock#  r: phandle )
   r> push-package                 ( on? clock#  )
   " on/off" package-execute       ( )
   pop-package                     ( )
;
: my-clock-off  ( -- )  false  my-clock-on/off  ;
: my-clock-on  ( -- )  true  my-clock-on/off  ;
