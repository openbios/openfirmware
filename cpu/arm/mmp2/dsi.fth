h# 004c constant pmua_display1_clk_res_ctrl_offset  \ DISPLAY1 Clock/Reset Control Register
h# 0110 constant pmua_display2_clk_res_ctrl_offset  \ DISPLAY2 Clock/Reset Control Register
h# 0050 constant pmua_ccic_clk_res_ctrl_offset      \ CCIC Clock/Reset Control Register

: pmua@  ( offset -- n )  pmua-pa + io@  ;
: pmua!  ( n offset -- )  pmua-pa + io!  ;

: dsi-twsi!  ( l reg# -- )
   >r  lbsplit  swap 2swap swap  r> wbsplit  6  twsi-write
; 
: dsi-twsi-w!  ( w reg# -- )
   >r  wbsplit  swap  r> wbsplit  4  twsi-write
; 
: dsi-twsi@  ( reg# -- l )  wbsplit 2 4 twsi-get  bljoin  ;
: dsi-twsi-w@  ( reg# -- w )  wbsplit 2 2 twsi-get  bwjoin  ;

: dsi1!  ( n offset -- )  dsi1-pa + io!  ;
: dsi1@  ( n offset -- )  dsi1-pa + io@  ;
: dsi2!  ( n offset -- )  dsi2-pa + io!  ;
: dsi2@  ( n offset -- )  dsi2-pa + io@  ;

0 value dsi-base
: dsi!   ( n offset -- )  dsi-base + io!  ;
: dsi@   ( n offset -- )  dsi-base + io@  ;

: bitset  ( mask reg-adr -- )  tuck io@  or  swap io!  ;
: bitclr  ( mask reg-adr -- )  tuck io@  swap invert and   swap io!  ;
: init-dsi1  ( -- )
   \ Ensure that the pins are set up properly
   h# c0 d# 83 gpio>mfpr io!  \ Configure GPIO83 for function 0 - GPIO
   d# 83 gpio-dir-out        \ Set the direction control to output

   h#  d123f  h# 4c pmua!  \ Send clock to TC358762 MIPI DSI bridge
   \ Enable the M/N clock output
   main-pmu-pa h# 1024 +  io@  h# 200 or  main-pmu-pa h# 1024 +  io!  \ Set (GPC) G_CLK_OUT ena in clock gating register
   \ Set the M/N value and re-enable the clock gate register
   h# 20001  main-pmu-pa h# 30 + io!  \ Set M/N divider values in PMUM_GPCR register
   h# 4000  mfpr-base h# 160 +  bitset  \ pull-up
   
   \ Disable DSI
   0  h# 00 dsi1!  \ Stop the interface
   h# c000.0000  dsi1-pa h# 00 +  bitset
   2 ms
   h# c000.0000  dsi1-pa h# 00 +  bitclr
   2 ms
   d# 83 gpio-clr  1 ms  d# 83 gpio-set  1 ms  \ LCD_RST_N line resets DSI bridge
   
   h# 16 5 set-twsi-target    \ TWSI address of TC358762 MIPI DSI bridge
   \ Data   Reg#.......
   0  h# 047c dsi-twsi!  \ Turn off sleep mode
   2 ms
   7  h# 0210 dsi-twsi!  \ Enable 2 lanes + clock lane
   h# b8230000  h# 0470 dsi-twsi!  \ Set PCLK to 33.2 MHz
   5 ms
   h# 0400  h# 0464 dsi-twsi!     \ Set PCLK divider
   5 ms
   1  h# 204 dsi-twsi!     \ Start RX
   0  h# 144 dsi-twsi!     \ Analog timer setup for lane 0
   0  h# 148 dsi-twsi!     \ Analog timer setup for lane 1

   \ Set asserting period for the duration between LP-00 detect and
   \ High Speed data reception for each lane. (This is for LANE 0)
   \ Set between 85ns + 6*UI and 145 ns + 10*UI based on HSBCLK
   h# a  h# 164 dsi-twsi!  \ D0S_CLRSIPOCOUNT register

   \ Set asserting period for the duration between LP-00 detect and
   \ High Speed data reception for each lane. (This is for LANE 1)
   \ Set between 85ns + 6*UI and 145 ns + 10*UI based on HSBCLK
   h# a  h# 168 dsi-twsi!  \ D1S_CLRSIPOCOUNT register

   h# 150 h# 420 dsi-twsi!  \ LCDCTR0 - RGB888 24-bit color

   h# 3FF0000 h# 0450 dsi-twsi!  \ SPIRCMR/SPICTRL

   1  h# 0104 dsi-twsi!   \  STARTPPI

   \ High speed mode setup
   h# 2102  h# 0020 dsi-twsi!   \  CLW_DLYCNTRL = 20pS  -> CLW_DPHYCONTRX
   h# 2002  h# 0024 dsi-twsi!   \  D0W_DLYCNTRL = 10pS  -> D0W_DPHYCONTRX
   h# 2002  h# 0028 dsi-twsi!   \  D1W_DLYCNTRL = 10pS  -> D1W_DPHYCONTRX

   1  h# 204 dsi-twsi!   \  Start RX -> STARTDSI  (repeat)

   h# 152 h# 420 dsi-twsi!  \ LCDCTR0 - RGB888 24-bit color

   hsync h# 424 dsi-twsi-w!  \ HSYNC width
   hbp   h# 426 dsi-twsi-w!  \ Horizontal back porch
   hdisp h# 428 dsi-twsi-w!  \ Horizontal display
   hfp   h# 42a dsi-twsi-w!  \ Horizontal front porch
   vsync h# 42c dsi-twsi-w!  \ VSYNC
   vbp   h# 42e dsi-twsi-w!  \ Vertical back porch
   vdisp h# 430 dsi-twsi-w!  \ Vertical display
   vfp   h# 432 dsi-twsi-w!  \ Vertical front porch

   \ Magic numbers, tuned with scope
   h# 07320302 h# c0 dsi1!  \ PHY time 0
   h# 370afff0 h# c4 dsi1!  \ PHY time 1
   h# 070a1504 h# c8 dsi1!  \ PHY time 2
   h# 00000400 h# cc dsi1!  \ PHY time 3

   h#       30 h# 88 dsi1!  \ PHY control 2 - enable 2 lanes
   h#  30.0000 h# 24 dsi1!  \ Packet command 1 - enable low power tx on 2 lanes

   htotal bytes/pixel * #lanes /   ( total-chunks )
   hdisp  bytes/pixel * #lanes /   ( total-chunks disp-chunks )

                wljoin  h# 110 dsi1!  \ DSI_LCD1_TIMING_0
   hbp    hsync wljoin  h# 114 dsi1!  \ DSI_LCD1_TIMING_1

\       For now the active size is set really low (we'll use 10) to allow
\       the hardware to attain V Sync. Once the DSI bus is up and running,
\       the final value will be put in place for the active size (this is
\       done below). In a later stepping of the processor this workaround
\       will not be required.

   vtotal ( vdisp ) d# 10 wljoin  h# 118 dsi1!  \ DSI_LCD1_TIMING_2

   \ The 1- below is for debugging, to get first line positioned properly
   vbp 1- vsync wljoin  h# 11c dsi1!  \ DSI_LCD1_TIMING_3

   hsync >bytes  d# 11 - 0 max  4 - 6 -  ( low )
   hbp hsync +  >bytes  4 -  6 -         ( low high )
   wljoin h# 120 dsi1!  \ DSI_LCD1_WC_0

   hdisp >bytes  hfp >bytes 6 - 6 -  wljoin  h# 124 dsi1!  \ DSI_LCD1_WC_1

   h# 0040.0010  h# 100 dsi1!  \ DSI_LCD1_CTRL_0
   h# 0014.0007  h# 104 dsi1!  \ DSI_LCD1_CTRL_1 - non-burst w/ sync, 24bpp

   h# e4 h# 4 dsi1!  \ DSI_CTRL_1 - virtual channel setup
   h#  1 h# 0 dsi1!  \ DSI_CTRL_0 - active panel 1 enable
   d# 100 ms
   
   \ Reset timing register 2 to its final value (workaround)
   h# 118 dsi1@  \ DSI_LCD1_TIMING_2
   lwsplit drop
   vdisp 2-   wljoin
   h# 118 dsi1!  \ DSI_LCD1_TIMING_2
;

[ifdef] debug-dsi
: .dsi  ( index -- )  dup 3 u.r space dsi-twsi@ 8 u.r cr  ;
: .dsiw  ( index -- )  dup 3 u.r space dsi-twsi-w@ 8 u.r cr  ;
: dump-dsi  ( -- )
   16 5 set-twsi-target
   47c .dsi
   210 .dsi
   470 .dsi
   464 .dsi
   204 .dsi
   144 .dsi
   148 .dsi
   164 .dsi
   168 .dsi
   420 .dsi
   450 .dsi
   104 .dsi
    20 .dsi
    24 .dsi
    28 .dsi
   204 .dsi
   420 .dsi
   424 .dsiw
   426 .dsiw
   428 .dsiw
   42a .dsiw
   42c .dsiw
   42e .dsiw
   430 .dsiw
   432 .dsiw
;
[then]

[ifdef] support-low-speed-dsi
: parity  ( n -- 0|1 )
   dup d# 16 rshift xor
   dup 8 rshift xor
   dup 4 rshift xor
   dup 2 rshift xor
   dup u2/ xor
   1 and
;

\ ECC bits
\                        10 11  12 13 14 15  16 17 18 19     21 22 23   ->ecc[5]  h# effc00
\           4 5 6 7  8 9                     16 17 18 19  20    22 23   ->ecc[4]  h# df03f0
\   1 2 3         7  8 9           13 14 15           19  20 21    23   ->ecc[3]  h# b8e38e
\ 0   2 3     5 6      9    11  12       15        18     20 21 22      ->ecc[2]  h# 749a6d
\ 0 1   3   4   6    8   10     12    14        17        20 21 22 23   ->ecc[1]  h# f2555b
\ 0 1 2     4 5   7      10 11     13        16           20 21 22 23   ->ecc[0]  h# f12cb7

: calc-ecc  ( l -- )
   >r
   \ The following masks are all 00 in the low byte, because the calculation
   \ skips the first byte in the array
   r@ 00ef.fc00 and  parity  d# 29 lshift
   r@ 00df.03f0 and  parity  d# 28 lshift or
   r@ 00b8.e38e and  parity  d# 27 lshift or
   r@ 009a.746d and  parity  d# 26 lshift or
   r@ 00f2.555b and  parity  d# 25 lshift or
   r@ 00f1.2cb7 and  parity  d# 24 lshift or   ( ecc )
   r> or
;
: updcrc  ( byte crc -- crc' )
   8 0  do                  ( byte crc )
      2dup xor 1 and  if    ( byte crc )
         u2/ h# 8408 xor    ( byte crc' )
      else  
         u2/                ( byte crc' )
      then                  ( byte crc )
      swap u2/ swap         ( byte' crc )
   loop                     ( byte crc )
   nip                      ( crc )
;
: calc-crc16  ( adr len -- )   \ Len includes the CRC
   swap 4 +  swap 6 -   ( payload-adr payload-len )
   h# ffff >r           ( adr len  r: crc )
   begin  dup  while    ( adr len  r: crc )
      over c@           ( adr len byte  r: crc )
      r> updcrc >r      ( adr len   r: crc' )
   repeat               ( adr len   r: crc' )
   drop  r>             ( adr crc )
   swap le-w!           ( )
;
: calc-checksums  ( adr len low-speed? -- )
   \ Calculate ECC and maybe CRC if low speed - hardware does it in high speed mode
   third  if                 ( adr len )
      over le-l@ calc-ecc    ( adr len ecc )
      third le-l!            ( adr len )
      \ Calculate CRC if long packet
      dup 4 <>  if           ( adr len )
         2dup calc-crc16     ( adr len )
      then                   ( adr len )
   then                      ( adr len )
;

[then]

[ifdef] use-dsi2
: set-dsi-data  ( l index -- )
   swap h# 30 dsi!                  ( index )   \ Data register
   d# 16 lshift  h# c000.0000 or   h# 2c dsi!    \ Packet data address to CPU_CMD_3 register
   h# 400 0  do   h# 2c dsi@  0>= abort" DSI timeout"  loop
;
: stuff-dsi-fifo  ( adr len -- )
   0  ?do                               ( adr' )
      dup le-l@  i la1+  set-dsi-data   ( adr )
      la1+                              ( adr' )
   4 +loop                              ( adr )
   drop                                 ( )
;
: run-dsi-cmd  ( cmd -- )
   h# 20 dsi!                        ( )
   h# 400 0  do                      ( )
      h# 20 dsi@  0>= ?leave         ( )
   loop                              ( )
;
: dsi-write-short  ( l -- )  \ high speed short packet
\  calc-ecc                  ( l' )
   0 set-dsi-data            ( )
   h# c000.0000 run-dsi-cmd  ( )
;

: dsi-write  ( adr len -- )
   \ Send the long payload code and the length as the first word
   dup 8 lshift  h# 29 or  0  set-dsi-data  ( adr len )
   tuck stuff-dsi-fifo                      ( len )
   h# 8000.0000 or  run-dsi-cmd
;

: setup-lcd  ( -- )
   " "(F1 5A 5A)" dsi-write
   " "(FC 5A 5A)" dsi-write
   " "(B7 00 11 11)" dsi-write
   " "(B8 2d 21)" dsi-write
   " "(B8 00 06)" dsi-write
   " "(2a 00 00 01 df)" dsi-write
   " "(2b 00 00 02 7f)" dsi-write
   h# 00001105 dsi-write-short
   5 ms
   " "(F4 00 23 00 64 5C 00 64 5C 00 00)" dsi-write
   " "(F5 00 00 0E 00 04 02 03 03 03 03)" dsi-write
   " "(EE 32 29 00)" dsi-write
   " "(F2 00 30 88 88 57 57 10 00 04)" dsi-write
   " "(F3 00 10 25 01 2D 2D 24 2D 10 12 12 73)" dsi-write
   " "(F6 21 AE BF 62 22 62)" dsi-write
   " "(F7 00 01 00 F2 0A 0A 0A 30 0A 00 0F 00 0F 00 4B 00 8C)" dsi-write
   " "(F8 00 01 00 F2 0A 0A 0A 30 0A 00 0F 00 0F 00 4B 00 8C)" dsi-write
   " "(F9 11 10 0F 00 01 02 04 05 08 00 0A 00 00 00 0F 10 11 00 00 C3 FF 7F)" dsi-write
   d# 120 ms
   h# 00002905 dsi-write-short
;

\ This is for the TV path
: init-dsi2  ( -- )
   \ Send clock to TC358762 MIPI DSI bridge
   h#  d123f  h#  4c pmua!  \ Display 1 clock
   h#  d123f  h# 110 pmua!  \ Display 2 clock

   \ Disable DSI
   0  h# 00 dsi2!  \ Stop the interface
   h# c000.0000  dsi2-pa h# 00 +  bitset
   1 ms
   h# c000.0000  dsi2-pa h# 00 +  bitclr
   1 ms

   \ Magic numbers, tuned with scope
   h# 07320302 h# c0 dsi2!  \ PHY time 0
   h# 370afff0 h# c4 dsi2!  \ PHY time 1
   h# 070a1504 h# c8 dsi2!  \ PHY time 2
   h# 00000400 h# cc dsi2!  \ PHY time 3

   h#       30 h# 88 dsi2!  \ PHY control 2 - enable 2 lanes
   h#  30.0000 h# 24 dsi2!  \ Packet command 1 - enable low power tx on 2 lanes

   setup-lcd
   htotal >chunks  hdisp  >chunks  wljoin  h# 190 dsi2!  \ DSI_LCD2_TIMING_0
   hbp             hsync           wljoin  h# 194 dsi2!  \ DSI_LCD2_TIMING_1

   \ For now the active size is set really low (we'll use 10) to allow
   \ the hardware to attain V Sync. Once the DSI bus is up and running,
   \ the final value will be put in place for the active size (this is
   \ done below). In a later stepping of the processor this workaround
   \ will not be required.

   vtotal vdisp wljoin  h# 198 dsi2!  \ DSI_LCD2_TIMING_2

   \ The 1- below is for debugging, to get first line positioned properly
   vbp 1- vsync wljoin  h# 19c dsi2!  \ DSI_LCD2_TIMING_3

   hsync bytes/pixel *  d# 11 - 0 max  4 - 6 -  ( low )
   hbp hsync +  bytes/pixel *  4 -  6 -         ( low high )
   wljoin h# 1a0 dsi2!  \ DSI_LCD2_WC_0

   hdisp  hfp bytes/pixel *  wljoin  h# 124 dsi1!  \ DSI_LCD1_WC_1
   
   h# 0050.0010  h# 180 dsi2!  \ DSI_LCD2_CTRL_0
   h# 0014.0007  h# 184 dsi2!  \ DSI_LCD2_CTRL_1 - non-burst w/ sync, 24bpp

   h# e4 h# 4 dsi2!  \ DSI_CTRL_1 - virtual channel setup
   h#  1 h# 0 dsi2!  \ DSI_CTRL_0 - active panel 1 enable
   d# 100 ms
   
   \ Reset timing register 2 to its final value (workaround)
   h# 198 dsi2@  \ DSI_LCD2_TIMING_2
   lwsplit drop
   vdisp 2-  wljoin
   h# 198 dsi2!  \ DSI_LCD2_TIMING_2

;
: dsi-read  ( -- n )  h# 64 dsi2@  ;

: dsi-lcd  ( enable? -- )
   0 dsi1@  7 invert and  0 dsi1!   \ Disable all panels
   h# 4c pmua@  2 invert and  h# 4c pmua!  \ stop clock?
   ( enable? )  if
      d# 100 ms
      h# 4c pmua@  2 or  h# 4c pmua!  \ start clock
      d# 100 ms
      0 dsi1@  1 or  0 dsi1!   \ Enable panel 0
   then
;

h# 106 buffer: dsi-cmd-buf

: lcd-send-some   ( code adr len -- code' adr' len' )
   rot dup dsi-cmd-buf c!         ( adr len code )
   h# 10 or  -rot                 ( code' adr len )   \ Change code to 3c after first time
   dup d# 240 min                 ( code adr len thislen )
   third  dsi-cmd-buf 1+  third   ( code adr len thislen  adr dst thislen )
   move                           ( code adr len thislen )
   dsi-cmd-buf over  dsi-write    ( code adr len thislen )
   /string                        ( code adr' len' )
;

: lcd-send  ( adr len -- )
   h# 2c -rot                ( code adr len )
   begin  dup  while         ( code adr len )
      lcd-send-some          ( code' adr' len' )
   repeat                    ( code' adr' len' )
   3drop
;
[then]
