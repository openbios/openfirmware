
: lcd@  ( offset -- l )  lcd-pa + io@  ;
: lcd!  ( l offset -- )  lcd-pa + io!  ;

: init-lcd  ( -- )
   \ Turn on clocks
   h# 08 pmua-disp-clk-sel + h# 28284c io!
   h# 09 pmua-disp-clk-sel + h# 28284c io!
   h# 19 pmua-disp-clk-sel + h# 28284c io!
   h# 1b pmua-disp-clk-sel + h# 28284c io!

   0                  h# 190 lcd!  \ Disable LCD DMA controller
   fb-pa               h# f4 lcd!  \ Frame buffer area 0
   0                   h# f8 lcd!  \ Frame buffer area 1
   hdisp bytes/pixel * h# fc lcd!  \ Pitch in bytes

   hdisp vdisp wljoin  dup h# 104 lcd!  dup h# 108 lcd!  h# 118 lcd!  \ size, size after zoom, disp

   htotal >chunks  vtotal wljoin  h# 114 lcd!  \ SPUT_V_H_TOTAL

   htotal >chunks  hdisp -  hbp >chunks -  6 -  ( low )
   hbp >chunks  wljoin  h# 11c lcd!
   
   vfp vbp wljoin  h# 120 lcd!
   h# 2000FF00 h# 194 lcd!  \ DMA CTRL 1
   h# 2000000d h# 1b8 lcd!  \ Dumb panel controller - 18 bit RGB666 on LDD[17:0]
   h# 01330133 h# 13c lcd!  \ Panel VSYNC Pulse Pixel Edge Control
   clkdiv      h# 1a8 lcd!  \ Clock divider
\  h# 08021100 h# 190 lcd!  \ DMA CTRL 0 - enable DMA, 24 bpp mode
   h# 08001100 h# 190 lcd!  \ DMA CTRL 0 - enable DMA, 16 bpp mode
;

: normal-hsv  ( -- )
   \ The brightness range is from ffff (-255) to 00ff (255) - 8 bits sign-extended
   \ 0 is the median value
   h# 0000.4000 h# 1ac lcd!  \ Brightness.contrast  0 is normal brightness, 4000 is 1.0 contrast
   h# 2000.4000 h# 1b0 lcd!  \ Multiplier(1).Saturation(1)
   h# 0000.4000 h# 1b4 lcd!  \ HueSine(0).HueCosine(1)
;
: clear-unused-regs  ( -- )
   0 h# 0c4 lcd!   \ Frame 0 U
   0 h# 0c8 lcd!   \ Frame 0 V
   0 h# 0cc lcd!   \ Frame 0 Command
   0 h# 0d0 lcd!   \ Frame 1 Y
   0 h# 0d4 lcd!   \ Frame 1 U
   0 h# 0d8 lcd!   \ Frame 1 V
   0 h# 0dc lcd!   \ Frame 1 Command
   0 h# 0e4 lcd!   \ U and V pitch
   0 h# 130 lcd!   \ Color key Y
   0 h# 134 lcd!   \ Color key U
   0 h# 138 lcd!   \ Color key V
;

: centered  ( w h -- )
   hdisp third - 2/               ( w h x )    \ X centering offset
   vdisp third - 2/               ( w h x y )  \ Y centering offset
   wljoin h# 0e8 lcd!             ( w h )

   wljoin dup h# 0ec lcd!         ( h.w )  \ Source size
   h# 0f0 lcd!                    ( )      \ Zoomed size
;
: zoomed  ( w h -- )
   0 h# 0e8 lcd!                   ( w h )  \ No offset when zooming
   wljoin h# 0ec lcd!              ( )      \ Source size
   hdisp vdisp wljoin h# 0f0 lcd!  ( )      \ Zoom to fill screen
;

defer placement ' zoomed is placement

: set-video-alpha  ( 0..ff -- )
   8 lshift                ( xx00 )
   h# 194 lcd@             ( xx00 regval )
   h# ff00 invert and      ( xx00 regval' )
   or                      ( regval' )
   h# 194 lcd!             ( )
;

\ 0:RBG565 1:RGB1555 2:RGB888packed 3:RGB888unpacked 4:RGBA888
\ 5:YUV422packed 6:YUV422planar 7:YUV420planar 8:SmartPanelCmd
\ 9:Palette4bpp  A:Palette8bpp  B:RGB888A
: set-video-mode  ( mode -- )
   d# 20 lshift            ( x00000 )
   h# 190 lcd@             ( x00000 regval )
   h# f00000 invert and    ( x00000 regval' )
   or                      ( regval' )
   h# 190 lcd!             ( )
;
: video-on  ( -- )  h# 190 lcd@ 1 or h# 190 lcd!  ;
: video-off  ( -- )  h# 190 lcd@ 1 invert and h# 190 lcd!  ;
: set-video-dma-adr  ( adr -- )  h# 0c0 lcd!  ;

\ Assumes RGB565
: start-video  ( adr w h -- )
   clear-unused-regs  normal-hsv  ( adr w h )
   over 2* h# 0e0 lcd!            ( adr w h )  \ Pitch - width * 2 bytes/pixel
   placement                      ( adr )
   set-video-dma-adr              ( )  \ Video buffer
   0 set-video-mode               ( )  \ RGB565
   d# 255 set-video-alpha         ( )  \ Opaque video
   video-on
;
: stop-video  ( -- )  video-off  ;

: bg!  ( r g b -- )  h# 124 lcd!  ;
: lcd-set  ( mask offset -- )  tuck lcd@ or swap lcd!  ;
: lcd-clr  ( mask offset -- )  tuck lcd@ swap invert and swap lcd!  ;

: cursor-on  ( -- )  h# 100.0000 h# 190 lcd-set  ;
: cursor-off  ( -- )  h# 100.0000 h# 190 lcd-clr  ;

: cursor-xy@  ( -- x y )  h# 10c lcd@ lwsplit  ;
: cursor-xy!  ( x y -- )  cursor-off  wljoin h# 10c lcd!  cursor-on  ;

: cursor-wh@  ( -- w h )  h# 110 lcd@ lwsplit  ;
: cursor-wh!  ( w h -- )  wljoin h# 110 lcd!  ;

: rgb<>bgr  ( rgb -- bgr )  lbsplit drop  swap rot  0 bljoin  ;
: cursor-fgbg!  ( fg-rgb bg-rgb -- )  rgb<>bgr h# 12c lcd!  rgb<>bgr h# 128 lcd!  ;
: cursor-fgbg@  ( -- fg-rgb bg-rgb )  h# 128 lcd@ rgb<>bgr  h# 12c lcd@ rgb<>bgr  ;

: cursor-1bpp-mode  ( -- )  h# 200.0000 h# 190 lcd-set  ;
: cursor-2bpp-mode  ( -- )  h# 200.0000 h# 190 lcd-clr  ;
: cursor-opaque  ( -- )  cursor-1bpp-mode  h# 400.0000 h# 190 lcd-set  ;
: cursor-transparent  ( -- )  cursor-1bpp-mode  h# 400.0000 h# 190 lcd-clr  ;

: sram-write-mode  ( -- )  h# 198 lcd@ h# c000 invert and  h# 8000 or  h# 198 lcd!  ;
: sram-read-mode  ( -- )  h# 198 lcd@ h# c000 invert and  h# 198 lcd!  ;
: cursor-sram@  ( offset -- value )  h# 0c bwjoin h# 198 lcd!  h# 158 lcd@  ;
: cursor-sram!  ( value offset -- )  swap h# 19c lcd!  h# 8c bwjoin h# 198 lcd!  ;
: sram-read  ( adr len start path -- )
   bwjoin  -rot  bounds ?do                 ( index )
      dup h# 198 lcd!  h# 158 lcd@  i l!    ( index )
      1+                                    ( index' )
   /l +loop                                 ( index )
   drop                                     ( )
;
: sram-write  ( adr len start path -- )
   h# 80 or                                ( adr len start mode )
   bwjoin  -rot  bounds ?do                ( index )
      i l@ h# 19c lcd!  dup h# 198 lcd!    ( index )
      1+                                   ( index' )
   /l +loop                                ( index )
   drop                                    ( )
;
: cursor-sram-read   ( adr len start -- )  h# c sram-read   ;
: cursor-sram-write  ( adr len start -- )  h# c sram-write  ;

0 value cursor-w
0 value cursor-h

\ allow writes to cursor SRAM
: enable-cursor-writes  ( -- )  h# 8000 h# 1a4 lcd-set  ;

0 value #cursor-bits
0 value cursor-bits
0 value cursor-index
: flush-cursor-bits  ( -- )
   cursor-bits cursor-index cursor-sram!
   0 to #cursor-bits
   0 to cursor-bits
   cursor-index 1+ to cursor-index
;
: +2bits  ( 0..3 -- )
   #cursor-bits lshift cursor-bits or to cursor-bits
   #cursor-bits 2+ to #cursor-bits
   #cursor-bits d# 32 =  if
      flush-cursor-bits
   then
;
: init-cursor-bits  ( -- )
   0 to #cursor-bits
   0 to cursor-bits
   0 to cursor-index
;
0 value cursor-pitch
: set-cursor-line  ( fg-l bg-l -- )
   cursor-w  0  do                 ( fg-l bg-l )
      over  h# 8000.0000 and  if   ( fg-l bg-l )
	 1     \ Color 1           ( fg-l bg-l value )
      else                         ( fg-l bg-l )
         dup h# 8000.0000 and  if  ( fg-l bg-l )
            2  \ Color 2           ( fg-l bg-l value )
	 else                      ( fg-l bg-l )
	    0  \ Transparent       ( fg-l bg-l value )
	 then                      ( fg-l bg-l value )
      then                         ( fg-l bg-l value )
      +2bits                       ( fg-l bg-l )
      swap 2* swap 2*              ( fg-l' bg-l' )
   loop                            ( fg-l bg-l )
   2drop                           ( )
;
: set-cursor-image  ( 'fg 'bg w h fg-color bg-color -- )
   init-cursor-bits                ( 'fg 'bg w h fg-color bg-color )
   enable-cursor-writes            ( 'fg 'bg w h fg-color bg-color )
   cursor-off                      ( 'fg 'bg w h fg-color bg-color )
   cursor-2bpp-mode                ( 'fg 'bg w h fg-color bg-color )
   cursor-fgbg!                    ( 'fg 'bg w h )
   to cursor-h  to cursor-w        ( 'fg 'bg )
   cursor-w cursor-h cursor-wh!    ( 'fg 'bg )
   cursor-h  0  do                 ( 'fg 'bg )
      over l@  over l@             ( 'fg 'bg fg-l bg-l )
      set-cursor-line              ( 'fg 'bg )
      swap la1+  swap la1+         ( 'fg' 'bg' )
   loop                            ( 'fg 'bg )
   2drop                           ( )
   flush-cursor-bits               ( )
;
