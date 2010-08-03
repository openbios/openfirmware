\ Screenshot for XO-1.5 (requires 32-bit display mode)
\
\ Copy this file to a USB stick - preferably FAT format
\  ok fload u:\scrnshot.fth
\ When you want to take a screenshot, hit the frame key.
\ The text on the screen will flash to show you it has happened.
\ To save the screenshot to file:
\  ok save-screenshot u:\shot.bmp
\ The format is .BMP at 32 bits per pixel 

: screen-bounds  ( -- x y w h )  0 0 screen-wh  ;
: screen-depth  ( -- n )  " depth" $call-screen  ;
: total-pixels  ( -- n )  screen-wh *  ;
: screenshot  ( -- )
   load-base screen-bounds " native-read-rectangle" $call-screen
   screen-ih package( blink-screen )package
;
4 buffer: bitbuf
: fput-le32  ( l -- )  bitbuf le-l!  bitbuf 4 ofd @ fputs  ;
: fput-le16  ( w -- )  bitbuf le-w!  bitbuf 2 ofd @ fputs  ;

   
: save-screenshot8  ( -- )
   ." 8 bit depth not yet implemented for save-screenshot" cr
;
: 16>32-screenshot
   ." 16 bit screenshots not yet implemented" cr
;
h# 4000 buffer: temp-line
: reorder-lines  ( -- )
   screen-wh swap /l*  >r        ( height r: line-width )
   r@ *                          ( total-bytes )
   load-base +  load-base        ( end-line start-line r: line-width )
   begin  2dup u>  while         ( end-line start-line r: line-width )
      dup temp-line r@ lmove     ( end-line start-line r: line-width )
      2dup r@ lmove              ( end-line start-line r: line-width )
      temp-line third r@ lmove   ( end-line start-line r: line-width )
      swap r@ -  swap r@ +       ( end-line' start-line' r: line-width )
   repeat                        ( end-line start-line r: line-width )
   r> 3drop
;
: save-screenshot32  ( "filename" -- )
   writing
   " BM" ofd @ fputs
   total-pixels /l*  d# 54 +  fput-le32  \ File size
   0 fput-le32   \ File creator 1 and 2
   d# 54 fput-le32  \ Offset to bits
   d# 40 fput-le32  \ DIB header size
   screen-wh swap fput-le32 fput-le32  \ Width and height
   1 fput-le16      \ Number of color planes
   d# 32 fput-le16  \ Depth
   0 fput-le32      \ No compression
   total-pixels /l* fput-le32  \ Bitmap size
   d# 7874 dup  fput-le32 fput-le32  \ H and V resolution in pixels/meter
   0 fput-le32      \ Colors in palette
   0 fput-le32      \ All colors are important 

   reorder-lines

   load-base  total-pixels /l*  ofd @ fputs  
   ofd @ fclose
;

: save-screenshot  ( -- )
   screen-depth case
      8 of  save-screenshot8  endof
      d# 16 of  16>32-screenshot  save-screenshot32  endof
      d# 24 of  save-screenshot32  endof
      d# 32 of  save-screenshot32  endof
      ( default )  ." Unsupported depth " dup .d cr
   endcase
;

: do-screenshot  ( -- )  screenshot 0  ;
patch do-screenshot allow-user-aborts? user-abort
