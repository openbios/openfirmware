\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: fb16.fth
\ 
\ Copyright (c) 2006 Sun Microsystems, Inc. All Rights Reserved.
\ 
\  - Do no alter or remove copyright notices
\ 
\  - Redistribution and use of this software in source and binary forms, with 
\    or without modification, are permitted provided that the following 
\    conditions are met: 
\ 
\  - Redistribution of source code must retain the above copyright notice, 
\    this list of conditions and the following disclaimer.
\ 
\  - Redistribution in binary form must reproduce the above copyright notice,
\    this list of conditions and the following disclaimer in the
\    documentation and/or other materials provided with the distribution. 
\ 
\    Neither the name of Sun Microsystems, Inc. or the names of contributors 
\ may be used to endorse or promote products derived from this software 
\ without specific prior written permission. 
\ 
\     This software is provided "AS IS," without a warranty of any kind. 
\ ALL EXPRESS OR IMPLIED CONDITIONS, REPRESENTATIONS AND WARRANTIES, 
\ INCLUDING ANY IMPLIED WARRANTY OF MERCHANTABILITY, FITNESS FOR A 
\ PARTICULAR PURPOSE OR NON-INFRINGEMENT, ARE HEREBY EXCLUDED. SUN 
\ MICROSYSTEMS, INC. ("SUN") AND ITS LICENSORS SHALL NOT BE LIABLE FOR 
\ ANY DAMAGES SUFFERED BY LICENSEE AS A RESULT OF USING, MODIFYING OR 
\ DISTRIBUTING THIS SOFTWARE OR ITS DERIVATIVES. IN NO EVENT WILL SUN 
\ OR ITS LICENSORS BE LIABLE FOR ANY LOST REVENUE, PROFIT OR DATA, OR 
\ FOR DIRECT, INDIRECT, SPECIAL, CONSEQUENTIAL, INCIDENTAL OR PUNITIVE 
\ DAMAGES, HOWEVER CAUSED AND REGARDLESS OF THE THEORY OF LIABILITY, 
\ ARISING OUT OF THE USE OF OR INABILITY TO USE THIS SOFTWARE, EVEN IF 
\ SUN HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
\ 
\ You acknowledge that this software is not designed, licensed or
\ intended for use in the design, construction, operation or maintenance of
\ any nuclear facility. 
\ 
\ ========== Copyright Header End ============================================
purpose: High-level part of fb16 16-bit framebuffer support package
copyright: Copyright 1990 Sun Microsystems, Inc.  All Rights Reserved

\ 16-bit generic frame-buffer driver
\ Uses 16 bits (2 bytes) per pixel.

\ Uses the following routines:
\ #lines	( -- n ) Number of text line positions in the window
\ #columns	( -- n ) Number of char positions on a line in the window
\ screen-height	( -- pix ) Height of the display (in pixels)
\ screen-width	( -- pix ) Width of the display (in pixels)
\ window-top	( -- pix ) Top edge of the window (in pixels)
\ window-left	( -- pix ) Left edge of the window (in pixels)
\ (These are all 'values', given working numbers by fb8-install.)

\ line#		( -- n ) Current line number of the cursor
\ column#	( -- n ) Current column number of the cursor
\ set-position	( line column -- ) Sets the cursor position

\ inverse?	( -- flag ) True if cursor is inverse (w-on-bl)
\ inverse-screen? ( -- flag ) True if screen is inverse (black backgnd)

\ char-height	( -- pix ) Height of standard font characters (in pixels)
\ char-width	( -- pix ) Width of standard font characters (in pixels)
\ >font		( char -- adr ) Location of 1-bit font entry
\		for this character.  Size is standard height x width.
\ fontbytes 	( -- bytes ) # of bytes per line of font

\ frame-buffer-adr  ( -- adr ) Starting address of the frame buffer
\		Assumed to be on a 32-bit boundary.

headerless
decimal

\ Moved to framebuf.fth
\  0 value emu-bytes/line	\ Later set to "#columns char-width *"
\  				\ this is the window width
: bytes/line16  screen-width 2* ;

: rgb>565  ( r g b -- w )
   3 rshift
   swap 2 rshift  5 lshift or
   swap 3 rshift  d# 11 lshift or
;

hex
create colors-565
   00 00 00 rgb>565 ,  \ Black
   00 00 aa rgb>565 ,  \ Dark blue
   00 aa 00 rgb>565 ,  \ Dark green
   00 aa aa rgb>565 ,  \ Dark cyan
   aa 00 00 rgb>565 ,  \ Dark red
   aa 00 aa rgb>565 ,  \ Dark magenta
   aa 55 aa rgb>565 ,  \ Brown
   aa aa aa rgb>565 ,  \ Light gray
   55 55 55 rgb>565 ,  \ Dark gray
   55 55 ff rgb>565 ,  \ Light blue
   55 ff 55 rgb>565 ,  \ Light green
   55 ff ff rgb>565 ,  \ Light cyan
   ff 55 55 rgb>565 ,  \ Light red (pink)
   ff 55 ff rgb>565 ,  \ Light magenta
   ff ff 55 rgb>565 ,  \ Light yellow
   ff ff ff rgb>565 ,  \ White
decimal

: fg16  ( -- n )  colors-565 foreground-color h# f and  na+ @  ;
: bg16  ( -- n )  colors-565 background-color h# f and  na+ @  ;
: screen-background16  ( -- n )  inverse?  if  fg16  else  bg16  then  ;
: text-background16  ( -- n )  inverse?  if  fg16  else  bg16  then  ;
: text-foreground16  ( -- n )  inverse?  if  bg16  else  fg16  then  ;
: logo-foreground16  ( -- n )  text-foreground16  ;

headers
: fb16-invert-screen  ( -- )
   frame-buffer-adr  screen-width screen-height bytes/line16
   text-foreground16 screen-background16  fb16-invert
;
: fb16-erase-screen  ( -- )
   frame-buffer-adr  bytes/line16  screen-height *  screen-background16 fb-fill
;
: fb16-blink-screen  ( -- )   \ Better done by poking the DAC
   fb16-invert-screen  fb16-invert-screen
;
: fb16-reset-screen  ( -- )  ;
headerless

: screen-adr16  ( column# line# -- adr )
   char-height *  window-top   +               ( column# ypixels )
   swap  char-width 2* *  window-left  +  swap ( xpixels ypixels )
   bytes/line16 *  +  frame-buffer-adr  +
;
: line-adr16  ( line# -- adr )  0 swap screen-adr16  ;
: column-adr16 ( column# -- adr )  line# screen-adr16  ;
: cursor-adr16  ( -- adr )  column# line#  screen-adr16  ;

headers
: fb16-draw-character  ( char -- )
   >font fontbytes  char-width char-height
   cursor-adr16 bytes/line16  text-foreground16 text-background16
   ( fontadr fontbytes width height screenadr bytes/line fg-color bg-color )
   fb16-paint
;
: fb16-toggle-cursor  ( -- )
   cursor-adr16 char-width char-height bytes/line16
   text-foreground16 text-background16  fb16-invert
;

: fb16-draw-logo  ( line# logoadr logowidth logoheight -- )
   2swap swap line-adr16 >r  -rot   ( logoadr width height )  ( r: scrn-adr )
   swap dup 2* d# 15 + d# 16 /      ( logoadr height width linebytes )
   swap rot                         ( logoadr linebytes width height )
   r> bytes/line16  logo-foreground16 screen-background16  fb16-paint
;

headerless

: move-line16    ( src-line-adr dst-line-adr -- )  emu-bytes/line fb-move  ;
: erase-line16   ( line-adr -- )  emu-bytes/line screen-background16 fb-fill  ;
: erase-lines16  ( last-line first-line -- )
   ?do  i erase-line16  bytes/line16 +loop
;
: cursor-y16  ( -- line-adr )  line# line-adr16  ;
: window-bottom16  ( -- line-adr )  #lines line-adr16  ;
: break-low16  ( delta-#lines -- line-adr )  line# +  #lines min  line-adr16  ;
: break-high16 ( delta-#lines -- line-adr )  #lines swap -  0 max  line-adr16  ;

headers
\ Delete n lines, starting with current cursor line.  Scroll the rest up
: fb16-delete-lines-slow  ( delta-#lines -- )
   break-low16  cursor-y16 window-bottom16  rot
   ?do   ( cursor-y' )
      i over move-line16  bytes/line16 +
   bytes/line16 +loop   ( break-high-adr )
   window-bottom16 swap  erase-lines16
;
: fb16-delete-lines  ( delta-#lines -- )
   dup break-high16 swap break-low16  ( break-high break-low )
   cursor-y16  over window-bottom16 swap -  ( b-hi b-lo cursor-y  bottom-blo )
   bytes/line16 emu-bytes/line  fb8-window-move   ( break-hi )
   window-bottom16 swap  erase-lines16
;

: fb16-insert-lines  ( delta-#lines -- )
   break-high16  window-bottom16      ( break-line-adr bottom-line-adr )
   swap bytes/line16 -                  ( bottom break-high- )
   cursor-y16   swap                  ( bottom  cursor-y break-high- )
   2dup <  if                         ( bottom  cursor-y break-high- )
      do                                    ( bottom' )
         bytes/line16 -  i over move-line16   ( bottom- )
      bytes/line16 negate +loop               ( break-low-adr )
   else
      2drop                                 ( break-low-adr )
   then
   cursor-y16  erase-lines16
;
headerless

: move-chars16  ( source-col# dest-col# -- )
   2dup max  #columns swap -         ( src dst #chars )
   char-width * -rot                 \ count is linelength-maxcol#
   swap column-adr16  swap column-adr16  ( count src-adr dst-adr )
   char-height 0  do
      3dup rot move   ( count src-adr dst-adr )
      swap bytes/line16 +  swap bytes/line16 +
   loop    2drop drop
;
: erase-chars16  ( #chars start-col# -- )
   swap char-width * swap
   column-adr16 char-height 0  do         ( count adr )
      2dup swap text-background16 fb-fill  ( count adr )
      bytes/line16 +
   loop  2drop
;
headers
: fb16-insert-characters  ( #chars -- )
   #columns column# - min  dup
   column# +   column# swap     ( #chars' cursor-col# cursor+count-col# )
   move-chars16  ( #chars' )  column#  erase-chars16
;
: fb16-delete-characters  ( #chars -- )
   #columns column# - min  dup  ( #chars' #chars' )
   column# +  column#           ( #chars' cursor+count-col#  cursor-col# )
   move-chars16  ( #chars' )  #columns over -  erase-chars16
;
headerless

: center-display16  ( -- )
   screen-height  #lines   char-height * -  2/  is window-top
   screen-width   #columns char-width  * -  2/  -32 and  is window-left
;

headers
: fb16-install  ( screen-width screen-height #columns #lines -- )
   \ Assume that the driver supports the 16-color extension
   true to 16-color?
   ['] not-dark to light

   \ my-self is display device's ihandle
   screen-#rows    min  is #lines
   screen-#columns min  is #columns
   is screen-height  is screen-width
   #columns char-width 2* *  is emu-bytes/line
   center-display16
   ['] fb16-reset-screen   	is reset-screen
   ['] fb16-toggle-cursor  	is toggle-cursor
   ['] fb16-erase-screen	is erase-screen
   ['] fb16-blink-screen	is blink-screen
   ['] fb16-invert-screen	is invert-screen
   ['] fb16-insert-characters	is insert-characters
   ['] fb16-delete-characters	is delete-characters
   ['] fb16-insert-lines	is insert-lines

   bytes/line16 16 mod  if
      ['] fb16-delete-lines-slow
   else
      ['] fb16-delete-lines
   then
   is delete-lines

   ['] fb16-draw-character	is draw-character
   ['] fb16-draw-logo		is draw-logo
;
