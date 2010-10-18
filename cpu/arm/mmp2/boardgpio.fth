purpose: Board-specific setup details - pin assigments, etc.

: set-camera-domain-voltage
   aib-unlock
   h# d401e80c l@  4 or   ( n )  \ Set 1.8V selector bit in AIB_GPIO2_IO
   aib-unlock
   h# d401e80c l!
;

: set-gpio-directions  ( -- )
   3  h# 38 clock-unit-pa +  l!  \ Enable clocks in GPIO clock reset register
   
   h# 000e.0000  gpio-base h# 0c +  l!  \ Bits 19, 18, 17
   h# 0704.2000  gpio-base h# 10 +  l!  \ Bits 58,57,56,50 and 45
\   h# 03ec.3e00  gpio-base h# 14 +  l!  \ Bits 89:85,83,82, and 77:73
   h# 03ec.3200  gpio-base h# 14 +  l!  \ Bits 89:85,83,82, and 77:76 and 73 (leave 74 and 75 as input)

   h# 0200.3c00  gpio-base h# 20 +  l!  \ Turn off LEDS (3c00) and turn on 5V (0200.0000)
;

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
         i af!              ( )
      then
   loop
;

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
