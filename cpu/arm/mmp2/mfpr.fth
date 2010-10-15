: aib-unlock  
   h# baba h# d4015068 l!  \ Unlock sequence
   h# eb10 h# d401506c l!
;
: set-camera-domain-voltage
   aib-unlock
   h# d401e80c l@  4 or   ( n )  \ Set 1.8V selector bit in AIB_GPIO2_IO
   aib-unlock
   h# d401e80c l!
;
: acgr-clocks-on  ( -- )
   h# 0818.F33C acgr-pa l!  \ Turn on all clocks
;
: set-gpio-directions  ( -- )
   3  h# 38 clock-unit-pa +  l!  \ Enable clocks in GPIO clock reset register
   
   h# 000e.0000  gpio-base h# 0c +  l!  \ Bits 19, 18, 17
   h# 0704.2000  gpio-base h# 10 +  l!  \ Bits 58,57,56,50 and 45
\   h# 03ec.3e00  gpio-base h# 14 +  l!  \ Bits 89:85,83,82, and 77:73
   h# 03ec.3200  gpio-base h# 14 +  l!  \ Bits 89:85,83,82, and 77:76 and 73 (leave 74 and 75 as input)

   h# 0200.3c00  gpio-base h# 20 +  l!  \ Turn off LEDS (3c00) and turn on 5V (0200.0000)
;

hex
create mfpr-offsets                                         \  GPIOs
   054 w, 058 w, 05C w, 060 w, 064 w, 068 w, 06C w, 070 w,  \   0->7
   074 w, 078 w, 07C w, 080 w, 084 w, 088 w, 08C w, 090 w,  \   8->15
   094 w, 098 w, 09C w, 0A0 w, 0A4 w, 0A8 w, 0AC w, 0B0 w,  \  16->23
   0B4 w, 0B8 w, 0BC w, 0C0 w, 0C4 w, 0C8 w, 0CC w, 0D0 w,  \  24->31
   0D4 w, 0D8 w, 0DC w, 0E0 w, 0E4 w, 0E8 w, 0EC w, 0F0 w,  \  32->39
   0F4 w, 0F8 w, 0FC w, 100 w, 104 w, 108 w, 10C w, 110 w,  \  40->47
   114 w, 118 w, 11C w, 120 w, 124 w, 128 w, 12C w, 130 w,  \  48->55
   134 w, 138 w, 13C w, 280 w, 284 w, 288 w, 28C w, 290 w,  \  56->63
   294 w, 298 w, 29C w, 2A0 w, 2A4 w, 2A8 w, 2AC w, 2B0 w,  \  64->71
   2B4 w, 2B8 w, 170 w, 174 w, 178 w, 17C w, 180 w, 184 w,  \  72->79
   188 w, 18C w, 190 w, 194 w, 198 w, 19C w, 1A0 w, 1A4 w,  \  80->87
   1A8 w, 1AC w, 1B0 w, 1B4 w, 1B8 w, 1BC w, 1C0 w, 1C4 w,  \  88->95
   1C8 w, 1CC w, 1D0 w, 1D4 w, 1D8 w, 1DC w, 000 w, 004 w,  \  96->103
   1FC w, 1F8 w, 1F4 w, 1F0 w, 21C w, 218 w, 214 w, 200 w,  \ 104->111
   244 w, 25C w, 164 w, 260 w, 264 w, 268 w, 26C w, 270 w,  \ 112->119
   274 w, 278 w, 27C w, 148 w, 00C w, 010 w, 014 w, 018 w,  \ 120->127
   01C w, 020 w, 024 w, 028 w, 02C w, 030 w, 034 w, 038 w,  \ 128->135
   03C w, 040 w, 044 w, 048 w, 04C w, 050 w, 008 w, 220 w,  \ 136->143
   224 w, 228 w, 22C w, 230 w, 234 w, 238 w, 23C w, 240 w,  \ 144->151
   248 w, 24C w, 254 w, 258 w, 14C w, 150 w, 154 w, 158 w,  \ 152->159
   250 w, 210 w, 20C w, 208 w, 204 w, 1EC w, 1E8 w, 1E4 w,  \ 160->167
   1E0 w,                                                   \ 168

h# d401.e000 constant mfpr-base
: gpio>mfpr  ( gpio# -- mfpr-pa )
   mfpr-offsets swap wa+ w@
   mfpr-base +
;                                                                

: dump-mfprs  ( -- )
   base @
   d# 169 0 do  decimal i 3 u.r space  i gpio>mfpr l@ 4 hex u.r cr  loop
   base !
;

: no-update,  ( -- )  8 w,  ;  \ 8 is a reserved bit; the code skips these
: af,   ( n -- )  h# c0 + w,  ;
: pull-up,  ( n -- )  h# c0c0 + w,  ;
: pull-dn,  ( n -- )  h# a0c0 + w,  ;

create mfpr-table
   1 af,      \ GPIO_00 - KP_MKIN[0]
   1 af,      \ GPIO_01 - KP_MKOUT[0]
   1 af,      \ GPIO_02 - KP_MKIN[1]
   1 af,      \ GPIO_03 - KP_MKOUT[1]
   1 af,      \ GPIO_04 - KP_MKIN[2]
   1 af,      \ GPIO_05 - KP_MKOUT[2]
   no-update, \ GPIO_06 - Not used
   no-update, \ GPIO_07 - Not used
   no-update, \ GPIO_08 - Not used
   no-update, \ GPIO_09 - Not used
   no-update, \ GPIO_10 - Not used
   no-update, \ GPIO_11 - Not used
   no-update, \ GPIO_12 - Not used
   no-update, \ GPIO_13 - Not used
   no-update, \ GPIO_14 - Not used
   no-update, \ GPIO_15 - Not used
   no-update, \ GPIO_16 - Not used
   0 af,      \ GPIO_17 - BB_GPIO1   (use as GPIO out)
   0 af,      \ GPIO_18 - BB_GPIO2   (use as GPIO out)
   0 af,      \ GPIO_19 - BB_GPIO3   (use as GPIO out)
   0 af,      \ GPIO_20 - ISP_INT    (use as GPIO  in)
   0 af,      \ GPIO_21 - WIFI_GPIO2 (use as GPIO i/o)
   0 af,      \ GPIO_22 - WIFI_GPIO3 (use as GPIO i/o)
   0 af,      \ GPIO_23 - CODEC_INT  (use as GPIO  in)
   1 af,      \ GPIO_24 - I2S_SYSCLK (Codec - HI-FI)
   1 af,      \ GPIO_25 - SSPA2_SCLK (Codec - HI-FI)
   1 af,      \ GPIO_26 - SSPA2_SFRM (Codec - HI-FI)
   1 af,      \ GPIO_27 - SSPA2_TXD  (Codec - HI-FI)
   1 af,      \ GPIO_28 - SSPA2_RXD  (Codec - HI-FI)
   1 af,      \ GPIO_29 - UART1_RXD  (Bluetooth)
   1 af,      \ GPIO_30 - UART1_TXD  (Bluetooth)
   1 af,      \ GPIO_31 - UART1_CTS  (Bluetooth)
\
   1 af,      \ GPIO_32 - UART1_RTS (Bluetooth)
   0 af,      \ GPIO_33 - SSPA2_CLK (Codec - LO-FI)
   0 af,      \ GPIO_34 - SSPA2_FRM (Codec - LO-FI)
   0 af,      \ GPIO_35 - SSPA2_TXD (Codec - LO-FI)
   0 af,      \ GPIO_36 - SSPA2_RXD (Codec - LO-FI)
   1 af,      \ GPIO_37 - MMC2_DAT<3>
   1 af,      \ GPIO_38 - MMC2_DAT<2>
   1 af,      \ GPIO_39 - MMC2_DAT<1>
   1 af,      \ GPIO_40 - MMC2_DAT<0>
   1 af,      \ GPIO_41 - MMC2_CMD
   1 af,      \ GPIO_42 - MMC2_CLK
   1 af,      \ GPIO_43 - TWSI2_SCL (for codec/noise/FM)
   1 af,      \ GPIO_44 - TWSI2_SDA (for codec/noise/FM)
   0 af,      \ GPIO_45 - WM8994_LDOEN (use as GPIO out)
   0 af,      \ GPIO_46 - HDMI_DET     (use as GPIO  in)
   2 af,      \ GPIO_47 - SSP2_CLK
   2 af,      \ GPIO_48 - SSP2_FRM
   2 af,      \ GPIO_49 - SSP2_RXD
   0 af,      \ GPIO_50 - GPS_STBY      (use as GPIO out)
   1 af,      \ GPIO_51 - UART3_RXD (debug port)
   1 af,      \ GPIO_52 - UART3_TXD (debug port)
   5 af,      \ GPIO_53 - PWM3 (Keypad backlight)
   4 af,      \ GPIO_54 - HDMI_CEC  (MOVED to GPIO 113?)
   0 af,      \ GPIO_55 - WIFI_GPIO0  (use as GPIO  in)
   0 af,      \ GPIO_56 - WIFI_GPIO1  (use as GPIO out)
   0 af,      \ GPIO_57 - WIFI_PD_N   (use as GPIO out)
   0 af,      \ GPIO_58 - WIFI_RST_N  (use as GPIO out)
   1 af,      \ GPIO_59 - CCIC_IN<7>
   1 af,      \ GPIO_60 - CCIC_IN<6>
   1 af,      \ GPIO_61 - CCIC_IN<5>
   1 af,      \ GPIO_62 - CCIC_IN<4>
   1 af,      \ GPIO_63 - CCIC_IN<3>
\
   1 af,      \ GPIO_64 - CCIC_IN<2>
   1 af,      \ GPIO_65 - CCIC_IN<1>
   1 af,      \ GPIO_66 - CCIC_IN<0>
   1 af,      \ GPIO_67 - CAM_HSYNC
   1 af,      \ GPIO_68 - CAM_VSYNC
   1 af,      \ GPIO_69 - CAM_MCLK
   1 af,      \ GPIO_70 - CAM_PCLK
   1 af,      \ GPIO_71 - TWSI3_SCL    (for CAM)
   1 af,      \ GPIO_72 - TWSI3_CLK    (for CAM)
   0 af,      \ GPIO_73 - CCIC_RST_N   (use as GPIO out)
\    0 af,      \ GPIO_74 - LED - ORANGE (use as GPIO out)  LCD VSYNC
\    0 af,      \ GPIO_75 - LED - BLUE   (use as GPIO out)  LCD HSYNV
\    0 af,      \ GPIO_76 - LED - RED    (use as GPIO out)  LCD PCLK
\    0 af,      \ GPIO_77 - LED - GREEN  (use as GPIO out)
   4 af,      \ GPIO_74 - SSP3_CLK - EC_SPI
   4 af,      \ GPIO_75 - SSP3_FRM - EC_SPI
   4 af,      \ GPIO_76 - SSP3_TXD - EC_SPI
   4 af,      \ GPIO_77 - SSP3_RXD - EC_SPI
\    5 af,      \ GPIO_78 - SSP4_CLK
\    5 af,      \ GPIO_79 - SSP4_FRM
   0 af,      \ GPIO_78 - EC_SPI CMD
   0 af,      \ GPIO_79 - EC_SPI ACK
   5 af,      \ GPIO_80 - SSP4_SDA
   0 af,      \ GPIO_81 - VBUS_FLT_N   (use as GPIO  in)
   0 af,      \ GPIO_82 - VBUS_EN      (use as GPIO out)
   0 af,      \ GPIO_83 - LCD_RST_N    (use as GPIO out)
   0 af,      \ GPIO_84 - USB_INT_N    (use as GPIO  in)
   0 af,      \ GPIO_85 - USB_RST_N    (use as GPIO out)
   0 af,      \ GPIO_86 - USB_PWDN_N   (use as GPIO out)
   0 af,      \ GPIO_87 - USB_HUB_EN   (use as GPIO out)
   0 af,      \ GPIO_88 - USB_MMC_EN   (use as GPIO out)
   0 af,      \ GPIO_89 - 5V_Enable    (use as GPIO out)
   no-update, \ GPIO_90 - Not used
   0 af,      \ GPIO_91 - ACC_INT      (use as GPIO  in)
   0 af,      \ GPIO_92 - PROX1_INT    (use as GPIO  in)
   no-update, \ GPIO_93 - Not used
   3 pull-dn, \ GPIO_94 - SPI_CLK
   3 pull-up, \ GPIO_95 - SPI_CSO
\
   3 pull-dn, \ GPIO_96  - SPI_SDA
   2 af,      \ GPIO_97  - TWSI6_SCL (HDMI EDID)
   2 af,      \ GPIO_98  - TWSI6_SDA (HDMI EDID)
   4 af,      \ GPIO_99  - TWSI5_SCL (CAP TOUCH)
   4 af,      \ GPIO_100 - TWSI5_SDA (CAP TOUCH)
   0 af,      \ GPIO_101 - TSI_INT     (use as GPIO  in)
   0 af,      \ GPIO_102 - USIM_UCLK
   0 af,      \ GPIO_103 - USIM_UIO
   0 af,      \ GPIO_104 - ND_IO[7]
   0 af,      \ GPIO_105 - ND_IO[6]
   0 af,      \ GPIO_106 - ND_IO[5]
   0 af,      \ GPIO_107 - ND_IO[4]
   0 af,      \ GPIO_108 - ND_IO[15]
   0 af,      \ GPIO_109 - ND_IO[14]
   0 af,      \ GPIO_110 - ND_IO[13]
   0 af,      \ GPIO_111 - ND_IO[8]    Use 2 af,  for eMMC
   0 af,      \ GPIO_112 - ND_RDY[0]   Use 2 af,  for eMMC
   no-update, \ GPIO_113 - Not used
   1 af,      \ GPIO_114 - M/N_CLK_OUT (G_CLK_OUT)
   0 af,      \ GPIO_115 - GPIO_115 (i/o)
   0 af,      \ GPIO_116 - GPIO_116 (i/o)
   0 af,      \ GPIO_117 - GPIO_117 (i/o)
   0 af,      \ GPIO_118 - GPIO_118 (i/o)
   0 af,      \ GPIO_119 - GPIO_119 (i/o)
   0 af,      \ GPIO_120 - GPIO_120 (i/o)
   0 af,      \ GPIO_121 - GPIO_121 (i/o)
   0 af,      \ GPIO_122 - GPIO_122 (i/o)
   0 af,      \ GPIO_123 - MBFLT_N    (use as GPIO  in)
   1 af,      \ GPIO_124 - MMC1_DAT[7]
   1 af,      \ GPIO_125 - MMC1_DAT[6]
   0 pull-up, \ GPIO_126 - Board Rev ID bit 0
   0 pull-up, \ GPIO_127 - Board Rev ID bit 1
\
   0 pull-up, \ GPIO_128 - Board Rev ID bit 2
   1 af,      \ GPIO_129 - MMC1_DAT[5]
   1 af,      \ GPIO_130 - MMC1_DAT[4]
   1 af,      \ GPIO_131 - MMC1_DAT[3]
   1 af,      \ GPIO_132 - MMC1_DAT[2]
   1 af,      \ GPIO_133 - MMC1_DAT[1]
   1 af,      \ GPIO_134 - MMC1_DAT[0]
   no-update, \ GPIO_135 - Not used
   1 af,      \ GPIO_136 - MMC1_CMD
   no-update, \ GPIO_137 - Not used
   no-update, \ GPIO_138 - Not used
   1 af,      \ GPIO_139 - MMC1_CLK
   1 af,      \ GPIO_140 - MMC1_CD
   1 af,      \ GPIO_141 - MMC1_WP
   0 af,      \ GPIO_142 - USIM_RSTn
   0 af,      \ GPIO_143 - ND_CS[0]
   0 af,      \ GPIO_144 - ND_CS[1]
   no-update, \ GPIO_145 - Not used
   no-update, \ GPIO_146 - Not used
   0 af,      \ GPIO_147 - ND_WE_N
   0 af,      \ GPIO_148 - ND_RE_N
   0 af,      \ GPIO_149 - ND_CLE
   0 af,      \ GPIO_150 - ND_ALE
   2 af,      \ GPIO_151 - MMC3_CLK
   no-update, \ GPIO_152 - Not used
   no-update, \ GPIO_153 - Not used
   0 af,      \ GPIO_154 - SM_INT
   1 af,      \ MMC3_RST_N (use as GPIO)
   no-update, \ GPIO_156 - PRI_TDI (JTAG)
   no-update, \ GPIO_157 - PRI_TDS (JTAG)
   no-update, \ GPIO_158 - PRI_TDK (JTAG)
   no-update, \ GPIO_159 - PRI_TDO (JTAG)
\
   0 af,      \ GPIO_160 - ND_RDY[1]
   0 af,      \ GPIO_161 - ND_IO[12]
   0 af,      \ GPIO_162 - ND_IO[11]  Use 2 af,  for eMMC
   0 af,      \ GPIO_163 - ND_IO[10]  Use 2 af,  for eMMC
   0 af,      \ GPIO_164 - ND_IO[9]   Use 2 af,  for eMMC
   0 af,      \ GPIO_165 - ND_IO[3]   Use 2 af,  for eMMC
   0 af,      \ GPIO_166 - ND_IO[2]   Use 2 af,  for eMMC
   0 af,      \ GPIO_167 - ND_IO[1]   Use 2 af,  for eMMC
   0 af,      \ GPIO_168 - ND_IO[0]   Use 2 af,  for eMMC

: init-mfprs
   d# 169 0  do
      mfpr-table i wa+ w@   ( code )
      dup 8 =  if           ( code )
         drop               ( )
      else                  ( code )
         i gpio>mfpr l!     ( )
      then
   loop
;

: af!  ( function# gpio# -- )  gpio>mfpr l!  ;
: gpios-for-nand  ( -- )
   h# c0 d# 111 af!
   h# c0 d# 112 af!
   d# 169 d# 162  do  h# c0 i af!  loop
;
: gpios-for-emmc  ( -- )
   h# c2 d# 111 af!
   h# c2 d# 112 af!
   d# 169 d# 162  do  h# c2 i af!  loop
;
