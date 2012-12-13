\ See license at end of file
purpose: MMP3 HDMI driver

   new-device
      " hdmi" device-name

      " mrvl,pxa688-hdmi" +compatible
      0 0 encode-bytes
         hdmi-hp-det-gpio# 0 encode-gpio
      " gpios" property
      " /hdmi-i2c" encode-phandle " ddc-i2c-bus" property

      : +i  encode-int encode+  ;
      h# 60010005 " clock-divider-regval" integer-property
      decimal
      0 0 encode-bytes
      \ xres,  yres, refresh,       clockhz,  left, right,  top, bottom, hsync, vsync, flags, widthmm, heightmm
      1280 +i 720 +i    60 +i  74,250,000 +i  110 +i  220 +i  5 +i    20 +i  40 +i    5 +i   1 +i   0 +i   0 +i
      hex
      " linux,timing-modes" property
      " 1280x720@60"  " linux,mode-names" string-property
   finish-device

: hdmi-present?  ( -- flag )   hdmi-hp-det-gpio# gpio-pin@ 0=  ;

: +hdmi  h# 20bc00 +  ;
: hdmi!  +hdmi io!  ;
: hdmi@  +hdmi io@  ;

: hdmi-i!  ( b reg# -- )  swap  0 hdmi!  h# 8000.0000 or 4 hdmi!  ;
: hdmi-i@  ( reg# -- b )  h# 4000.0000 or 4 hdmi!  0 hdmi@  ;

: phy-cfg0@  ( -- n )  h# 08 hdmi@  ;  : phy-cfg0!  ( n -- )  h# 08 hdmi!  ;
: phy-cfg1@  ( -- n )  h# 0c hdmi@  ;  : phy-cfg1!  ( n -- )  h# 0c hdmi!  ;
: phy-cfg2@  ( -- n )  h# 10 hdmi@  ;  : phy-cfg2!  ( n -- )  h# 10 hdmi!  ;
: phy-cfg3@  ( -- n )  h# 14 hdmi@  ;  : phy-cfg3!  ( n -- )  h# 14 hdmi!  ;

: audio-cfg@ ( -- n )  h# 18 hdmi@  ;  : audio-cfg! ( n -- )  h# 18 hdmi!  ;
: clock-cfg@ ( -- n )  h# 1c hdmi@  ;  : clock-cfg! ( n -- )  h# 1c hdmi!  ;

: pll-cfg0@  ( -- n )  h# 20 hdmi@  ;  : pll-cfg0!  ( n -- )  h# 20 hdmi!  ;
: pll-cfg1@  ( -- n )  h# 24 hdmi@  ;  : pll-cfg1!  ( n -- )  h# 24 hdmi!  ;
: pll-cfg2@  ( -- n )  h# 28 hdmi@  ;  : pll-cfg2!  ( n -- )  h# 28 hdmi!  ;
: pll-cfg3@  ( -- n )  h# 2c hdmi@  ;  : pll-cfg3!  ( n -- )  h# 2c hdmi!  ;

: -bits  ( n value bit# -- n' )  lshift invert and  ;
: +bits  ( n value bit# -- n' )  lshift or  ;

[ifdef] debug-words
h# f090099 value pll3-ctrl1
h#      9b value pll3-fbdiv
h#       3 value pll3-refdiv
: pll3-on
   h# 20000000  h# 58 mpmu-clr      \ Reset PLL3 reset
   h#      100  h# 50 mpmu-clr      \ Ensure PLL3 off 
   1 h# 60 mpmu-set                \ set SEL_VCO_CLK_SE in PMUM_PLL3_CTRL2
   0  pll3-refdiv  d# 19 +bits  pll3-fbdiv d# 10 +bits  1 d# 9 +bits  h# 50 mpmu!
   pll3-ctrl1   h# 58 mpmu!
   h#      100  h# 50 mpmu-set      \ Power up PLL3
   d# 50 us
   h# 20000000  h# 58 mpmu-set      \ Release PLL3 reset
;

create pll-table-mmp2
  decimal
\  f   div     offset    fb   ref    kvco
  25 ,   4 ,  h# 4ec5 ,  38 ,  16 ,  h# c ,
  27 ,   4 ,  h# 35cb ,  41 ,  16 ,  h# b , 
  54 ,   2 ,  h# 35cb ,  41 ,  16 ,  h# b , 
  74 ,   2 ,  h#  84b ,  57 ,  16 ,  h# 3 ,
 108 ,   1 ,  h# 35cb ,  41 ,  16 ,  h# b , 
 148 ,   1 ,  h#  84b ,  57 ,  16 ,  h# 3 ,
  -1 ,
hex
[then]

create pll-table
  decimal
\  0     1           2     3    4       5
\  f  post      offset    fb  ref    kvco
  25 ,   3 ,  h# 11c47 ,  39 ,  0 ,  h# 4 ,
  27 ,   3 ,  h# 12d03 ,  42 ,  0 ,  h# 4 , 
  54 ,   2 ,  h# 12d02 ,  42 ,  0 ,  h# 4 , 
  74 ,   2 ,  h# 0084b ,  57 ,  0 ,  h# 4 ,
 108 ,   1 ,  h# 12d03 ,  42 ,  0 ,  h# 4 , 
 148 ,   1 ,  h# 0084b ,  57 ,  0 ,  h# 4 ,
  -1 ,
hex

: find-pll  ( freq -- adr )
   pll-table  begin  dup @  -1 <>  while  ( freq adr )
      2dup @ =  if  nip exit  then        ( freq adr )
      6 na+                               ( freq adr' )
   repeat                                 ( freq adr )
   -6 na+
;

1 value vpll-calclk-div
1 value vddm
9 value vddl
9 value icp
2 value vreg-ivref
0 value reset-offset
1 value clk-det-en
5 value intpi
0 value reset-intp-ext
1 value pll-mode
2 value vth-vpll-ca

: pll-cfg  ( freq -- )
   find-pll  >r     ( table-adr )

   pll-cfg3@  3 invert and  pll-cfg3!  \ Power off and reset

   0
   intpi           d# 27 +bits
   clk-det-en      d# 26 +bits
   r@ 5 na+ @      d# 20 +bits   \ KVCO
   vreg-ivref      d# 17 +bits
   r@ 1 na+ @      d# 14 +bits   \ POSTDIV
   icp             d# 10 +bits
   vddl            d#  6 +bits
   vddm            d#  4 +bits
   vpll-calclk-div d#  1 +bits
   1               d#  0 +bits   \ "Chicken bit" to enable PHY register access
   pll-cfg0!

   0
   vth-vpll-ca   d# 29 +bits
   1             d# 24 +bits   \ EN_PANEL
   1             d# 23 +bits   \ EN_HDMI
   r@ 2 na+ @    d#  4 +bits   \ FREQ_OFFSET_INNER
   pll-mode      d#  3 +bits   \ MODE
   pll-cfg1!

   0                           \ FREQ_OFFSET_ADJ
   pll-cfg2!

   pll-cfg3@
   h# fffc invert and          \ Clear FBDIV and REFDIV fields
   r@ 3 na+ @    d#  7 +bits
   r@ 4 na+ @    d#  2 +bits
   dup       pll-cfg3!         \ Set divisors
   1 or  dup pll-cfg3!  1 ms   \ Power up
   2 or      pll-cfg3!         \ Release reset

   d# 100 0  do
      pll-cfg3@ h# 400000 and  ?leave
      1 ms
      i 9 =  if  ." HDMI PLL failed to lock"  cr  then
   loop

   r> drop
;

: send-packet  ( adr len packet# -- )
   >r                               ( adr len  r: packet# )
   r@ d# 32 * h# 60 +               ( adr len index )

   \ Clear trailing bytes
   over  d# 31 swap  ?do            ( adr len index )
      0 i hdmi-i!                   ( adr len index )
   loop

   0 swap  2swap                    ( sum  index adr  len )
   0  ?do                           ( sum  index adr  )
      2dup i + c@                   ( sum  index adr  index byte )
      tuck swap c!                  ( sum  index adr  byte )
      3 roll +  -rot                ( sum' index adr  )
   loop                             ( sum  index adr  )
   drop                             ( sum  index )
   swap negate h# ff and            ( index  sum' )
   over 3 + hdmi-i!                 ( index )

   \ I'm not sure what this is for; one of the drivers did it
   1 over d# 31 + hdmi-i!           ( index )
   drop                             ( )

   1 r> lshift  dup h# 5f hdmi-i!  h# 5e hdmi-i!  \ HDTX_HOST_PKT_CTRL1/0
;

create avi-packet
   h# 82 c,  h#  2 c,  h# 0d c,  0 c,  \ 0-3: header
   h# 10 c,  \ 4: 10 is active format, validates bits 3:0 of next byte
   h# a8 c,  \ 5: 80 is ITU709 colors, 20 is 16:9, 8 is same aspect ratio
   h# 00 c,  \ 6: 80 bit means computer display ...
   h# 00 c,  \ 7: panel type
       0 c,  \ 8: pixel repetition factor
   \ The rest would be top, bottom, left, right bars
here avi-packet - constant /avi-packet

\ The columns up to "Code" are from CEA-861-D (the DVI spec)
\ The remaining columns (sync parameters) are from Marvell bringup code - lcd0_tv.c

create hdmi-resolutions
decimal
\    0      1    2      3     4      5     6     7    8     9    10    11   12   13   14
\  Hact   Vact Refr   Htot Hblnk Vtotal Vblnk PxMHz Code Hsync  Hfp   Hbp Vsync Vfp  Vbp
   640 ,  480 , 60 ,  800 , 160 ,  525 ,  45 ,  25 ,  1 ,  96 ,  48 ,  16 ,  2 , 33 , 10 ,
   720 ,  480 , 60 ,  858 , 138 ,  525 ,  45 ,  27 ,  3 ,  62 ,  60 ,  16 ,  6 , 30 ,  9 ,
  1280 ,  720 , 60 , 1650 , 370 ,  750 ,  30 ,  74 ,  4 ,  40 , 220 , 110 ,  5 , 20 ,  5 ,
  1440 ,  240 , 60 , 1716 , 276 ,  262 ,  22 ,  27 ,  9 , 124 , 114 ,  38 ,  3 , 15 ,  4 ,
\ 2880 ,  240 , 60 , 3432 , 552 ,  262 ,  22 ,  54 , 13 , ???  \ Sync values unknown ...
\ 1440 ,  480 , 60 , 1716 , 276 ,  525 ,  45 ,  54 , 15 , ???
  1920 , 1080 , 60 , 2200 , 280 , 1125 ,  45 , 148 , 16 ,  44 , 148 ,  88 ,  5 , 36  , 4 ,
   720 ,  576 , 50 ,  864 , 144 ,  625 ,  49 ,  27 , 18 ,  64 ,  68 ,  12 ,  5 , 39  , 5 ,
  1440 ,  288 , 50 , 1728 , 288 ,  312 ,  24 ,  27 , 24 , 126 , 138 ,  24 ,  3 , 18  , 3 ,
\ 2880 ,  288 , 50 , 3456 , 576 ,  312 ,  24 ,  54 , 28 , ???
\ 2880 ,  480 , 60 , 3432 , 552 ,  525 ,  45 , 108 , 36 , ???
\ 2880 ,  576 , 50 , 3456 , 576 ,  625 ,  49 , 108 , 38 , ???
-1 ,
hex

0 value res-adr
: res@  ( index -- value ) res-adr swap na+ @  ;

: find-resolution  ( h v -- error? )
   hdmi-resolutions  begin      ( h v adr )
      dup @ -1 <>               ( h v adr flag )
   while                        ( h v adr )
      3dup 2@ swap  d=  if      ( h v adr )
         to res-adr  2drop      ( )
         false exit             ( -- adr false )
      then                      ( h v adr )
      d# 15 na+                 ( h v adr' )
   repeat                       ( h v adr )
   3drop true
;

: set-hdmi-clock-cfg  ( -- )
\  3         \ The docs say to write 0 to bits 0:3 but the code writes 3
             \ On MMP2 this is the the FIFO read and write timing
   0
   1     4 +bits \ HDMI_ENABLE
   6     5 +bits \ MCLK_DIV
   5     9 +bits \ TCLK_DIV
   5 d# 13 +bits \ PRCLK_DIV
   clock-cfg!
;
: hdmi-set-detection  ( on/off -- )
   h# 14 hdmi@  h# 400                  ( on/off value bitmask )
   rot  if  or  else  invert and  then  ( value' )
   h# 14 hdmi!
;

: select-phy  ( -- )  pll-cfg0@ 1 or pll-cfg0!  ;   \ alias phy select-phy
: select-3d   ( -- )  pll-cfg0@ 1 invert and pll-cfg0!  ;

\ Tune these for best eye diagram
6 value damp  2 value eamp  0 value cp
0 value ajd   1 value svtx  8 value idrv  

: setup-phy  ( freq -- )
   d# 148 =  if  9  else  8  then  to idrv

   select-phy

   damp o# 1111 *
   eamp o# 11110000 * or
   cp h# 55000000 * or
   phy-cfg0!

   ajd  h# f0000000 *
   svtx o# 1111 * d# 16 +bits
   idrv h# 1111 *     0 +bits
   phy-cfg1!
;
: setup-fifo  ( -- )
   1     h#  3a hdmi-i!     \ HDMI, not DCI, Mode.  No pixel repetition
   1     h#  48 hdmi-i!     \ DC_FIFO_WR_PTR  \ Alt value:  0
   h# 1a h#  49 hdmi-i!     \ DC_FIFO_RD_PTR  \ Alt value: 1f

   1     h#  47 hdmi-i!     \ DC_FIFO_SFT_RST
   0     h#  47 hdmi-i!     \ DC_FIFO_SFT_RST

   8     h# 131 hdmi-i!     \ PHY_FIFO_PTRS \ Alt value: 80

   1     h# 130 hdmi-i!     \ PHY_FIFO_SOFT_RST
   0     h# 130 hdmi-i!     \ PHY_FIFO_SOFT_RST

   0     h#  39 hdmi-i!     \ VIDEO_CTRL
   h# 40 h#  39 hdmi-i!     \ VIDEO_CTRL (set INT_FRM_SEL) \ Alt value: 58
;

: hdmi-video-cfg  ( -- )
   true hdmi-set-detection

   7 res@ pll-cfg

   set-hdmi-clock-cfg

   0 phy-cfg2!                \ Unreset TX
   h# 0001.0000 phy-cfg2!     \ RESET_TX
   h#        10 phy-cfg2!     \ Termination

   8 res@ avi-packet 7 + c!
   avi-packet /avi-packet  1  send-packet

   h# e0  h# 58 hdmi-i!     \ HDTX_TDATA3_0
   h# 83  h# 59 hdmi-i!     \ HDTX_TDATA3_1
   h# 0f  h# 5a hdmi-i!     \ HDTX_TDATA3_2

   7 res@ setup-phy
   setup-fifo
;

: init-tv-clock  ( -- )
   h# 4c pmua@ dup  h# 10 and  0=  if  ( val )
\     h# f8fc0 invert and   \ Clear prescaler and divisor fields
\     h# d0280 or           \ DSI PHY Prescaler to default value 1a, /2, PLL2
\     dup h# 4c pmua!       ( val )
\     h# 103f or            ( val' )
\     dup h# 4c pmua!       ( val )
   then                     ( val )
   h# 2000 or  h# 4c pmua!  ( )     \ Enable HDMI ref clock

   \ Integer divisor (5), reserved (1<<16), select HDMI CLK (3<<29)
\  5  1 d# 16 +bits  3 d# 29 +bits  h# 9c lcd!  \ LCD_TCLK_DIV
   5  3 d# 29 +bits  h# 9c lcd!  \ LCD_TCLK_DIV
;

: lcd-xy!  ( hor vert reg# -- )  >r  wljoin  r> lcd!  ;
\ : tv-video-src-res!  ( hor vert -- )  wljoin h# 2c lcd!  ;
\ : tv-video-dst-res!  ( hor vert -- )  wljoin h# 30 lcd!  ;
: tv-gfx-base!  ( adr -- )  h# 34 lcd!  ;
: tv-gfx-pitch!  ( pitch -- )  h# 3c lcd!  ;
: tv-gfx-offset!  ( hor vert -- )  h# 40 lcd-xy!  ;
: tv-gfx-src-res!  ( hor vert -- )  h# 44 lcd-xy!  ;
: tv-gfx-dst-res!  ( hor vert -- )  h# 48 lcd-xy!  ;
: tv-cursor-pos!  ( hor vert -- )  h# 4c lcd-xy!  ;
: tv-cursor-size!  ( hor vert -- )  h# 50 lcd-xy!  ;
: tv-size!  ( hor vert -- )  h# 54 lcd-xy!  ;
: tv-active!  ( hor vert -- )  h# 58 lcd-xy!  ;
: tv-porch!  ( hfront hback vfront vback -- )  h# 60 lcd-xy!  h# 5c lcd-xy!  ;
: tv-blank-color!  ( color -- )  h# 64 lcd!  ;
: tv-vsync!  ( rising falling -- )  h# 7c lcd-xy!  ;
: tv-dma-ctrl0!  ( n -- )  h# 80 lcd!  ;  : tv-dma-ctrl0@  ( -- n )  h# 80 lcd@  ;
: tv-dma-ctrl1!  ( n -- )  h# 84 lcd!  ;
: tv-contrast!  ( contrast brightness -- )  h# 88 lcd-xy!  ;
: tv-saturation!  ( saturation mult -- )  h# 8c lcd-xy!  ;
: tv-hue!  ( cos sin -- )  h# 90 lcd-xy!  ;
: tv-tvif!  ( n -- )  h# 94 lcd!  ;  : tv-tvif@  ( -- n )  h# 94 lcd@  ;
: tv-divider!  ( n -- )  h# 9c lcd!  ;

\ : dither!  ( n -- )  h# a0 lcd!  ;
\ : dither-table!  ( n -- )  h# a4 lcd!  ;

d# 16 value tv-bpp
: init-tv-graphics  ( -- )
   init-tv-clock

   0 tv-dma-ctrl0!    \ Start with graphics DMA off

   0 res@  1 res@  tv-active!
   
   tv-dma-ctrl0@  
   1    d#  8 +bits  \ DMA enable

   h# f d# 16 -bits
   0    d# 16 +bits  \ Pixel format RGB565

   7    d#  9 -bits  \ Turn off YUV422PACK, YVYU422P, UYVY422P

   1 	d# 12 +bits  \ RGBswap (RGB, not BGR)
	     	
   1    d# 27 +bits  \ DMA AXI arbiter enable
   tv-dma-ctrl0!

\  tv-dma-ctrl1@  h# a00eff00 or tv-dma-ctrl1!  \ or h# 2000FF04;
\  h# 283eff00 tv-dma-ctrl1!
   h# 2803ff00 tv-dma-ctrl1!

   h# f4 lcd@  tv-gfx-base!     \ Same base address as DCON panel
   hdisp vdisp tv-gfx-src-res!  \ Same source res as DCON panel
	
   hdisp  bytes/pixel *  tv-gfx-pitch!
	
   0 res@  1 res@  tv-gfx-dst-res!

   h# 00ff1000 tv-tvif!  \ XXX check this
	
   \  hbp        hres+hbp
   d# 11 res@   dup 0 res@ +  tv-vsync!

   \ htotal  vtotal	
   3 res@    5 res@  tv-size!

   \ hfp       hbp         vfp         vbp
   d# 10 res@  d# 11 res@  d# 13 res@  d# 14 res@  tv-porch!

\	/* deafult registers */
\	BU_REG_WRITE( LCD_SRAM_CTRL, 0 );
\	BU_REG_WRITE( LCD_SRAM_WRDAT, 0 );
\	BU_REG_WRITE( LCD_SRAM_PARA0, 0 );
\	BU_REG_WRITE( LCD_SRAM_PARA1, 0x0 );

   h# 4000 0  tv-contrast!
   h# 4000 h# 2000  tv-saturation!
   h# 4000 0  tv-hue!

   h# 1bc lcd@  h# 30 or  h# 1bc lcd!  \ PN_IOPAD_CONTROL - 1K boundary, burst 16

   h# 1dc lcd@  h# fff0 or  h# 1dc lcd!  \ LCD_TOP_CTRL - burst lengths

   tv-tvif@  1 or  tv-tvif!    \ Enable
;

: start-hdmi  ( h v -- )
   \ XXX need to do monitor detection and use EDID to find its resolutions
   find-resolution  abort" Unsupported resolution"  ( )
   init-tv-graphics
   hdmi-video-cfg
;	

: 720p  d# 1280 d# 720 start-hdmi  ;
: 1080p  d# 1920 d# 1080 start-hdmi  ;

also forth definitions
: 1080p  ( -- )  " 1080p" $call-screen  ;
: 720p  ( -- )  " 720p" $call-screen  ;
previous definitions

\ /* A:B means that g_res_support[B] = 1 if videoID == A */
\ /* 1:3 2:0 3:0 4:1 8:4 9:4 12:7 13:7 14:8 15:8 16:2 17:2 18:2 */
\ /* 21:10 22:10 23:6 24:6 27:9 28:9 35:11 36:11 37:12 38:12 */
\ static enum edid_returns edid_parseSVD(unsigned char *data_buf,unsigned char svd_len)  // Short Video Descriptor
\ {
\     for (unsigned char   dataOfs = 0; ++dataOfs <= svd_len; )  { // Skip the header
\       unsigned char videoID = (data_buf[dataOfs] & 0x7F);          // Parse SVD
\       if (videoID == 0 || videoID >= sizeof(video_code_map)/sizeof(struct cea_res_info))  {  continue; }         /* Don't add it */
\ 	switch (videoID){
\ 		/* See comment above */
\ 	}
\     }
\     return EDID_ERR_OK;
\ }

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
