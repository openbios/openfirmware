\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: fb8.fth
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
purpose: High-level part of fb8 8-bit framebuffer support package
copyright: Copyright 1990 Sun Microsystems, Inc.  All Rights Reserved

\ Now supports 8bpp, 16bpp, and 32bpp frame buffer

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

hex
: rgb>565  ( r g b -- w )
   3 rshift
   swap 2 rshift  5 lshift or
   swap 3 rshift  d# 11 lshift or
;

create colors-8bpp
   0 , 1 , 2 , 3 , 4 , 5 , 6 , 7 , 8 , 9 , a , b , c , d , e , f ,

create colors-565
   00 00 00 rgb>565 ,  \ Black
   00 00 aa rgb>565 ,  \ Dark blue
   00 aa 00 rgb>565 ,  \ Dark green
   00 aa aa rgb>565 ,  \ Dark cyan
   aa 00 00 rgb>565 ,  \ Dark red
   aa 00 aa rgb>565 ,  \ Dark magenta
   aa 55 aa rgb>565 ,  \ Brown
\  aa aa aa rgb>565 ,  \ Light gray
   c0 c0 c0 rgb>565 ,  \ Light gray (OLPC background)
   55 55 55 rgb>565 ,  \ Dark gray
   55 55 ff rgb>565 ,  \ Light blue
   55 ff 55 rgb>565 ,  \ Light green
   55 ff ff rgb>565 ,  \ Light cyan
   ff 55 55 rgb>565 ,  \ Light red (pink)
   ff 55 ff rgb>565 ,  \ Light magenta
   ff ff 55 rgb>565 ,  \ Light yellow
   ff ff ff rgb>565 ,  \ White

create colors-32bpp
   000000 l,  \ Black
   0000aa l,  \ Dark blue
   00aa00 l,  \ Dark green
   00aaaa l,  \ Dark cyan
   aa0000 l,  \ Dark red
   aa00aa l,  \ Dark magenta
   aa55aa l,  \ Brown
\  aaaaaa l,  \ Light gray
   c0c0c0 l,  \ Light gray (OLPC background)
   555555 l,  \ Dark gray
   5555ff l,  \ Light blue
   55ff55 l,  \ Light green
   55ffff l,  \ Light cyan
   ff5555 l,  \ Light red (pink)
   ff55ff l,  \ Light magenta
   ffff55 l,  \ Light yellow
   ffffff l,  \ White
decimal

: >16-map  ( fg/bg- -- color )
   if  foreground-color  else  background-color  then  
   h# f and  fb-16map swap na+ @
;
: fg  ( -- n )  true  >16-map  ;
: bg  ( -- n )  false >16-map  ;
: screen-background  ( -- n )  inverse?  >16-map  ;
: text-background    ( -- n )  inverse?  >16-map  ;
: text-foreground    ( -- n )  inverse?  0= >16-map  ;
: logo-foreground    ( -- n )  text-foreground  ;

\ defer pix*       ' noop        to pix*
\ defer fb-invert  ' fb8-invert  to fb-invert
\ defer fb-paint   ' fb8-paint   to fb-paint

headers
: bytes/char  ( -- n )  char-width pix*  ;
: bytes/screen  ( -- n )  bytes/line  screen-height *  ;

: fb8-invert-screen  ( -- )
   frame-buffer-adr  screen-width screen-height bytes/line
   text-foreground screen-background  fb-invert
;
: fb8-erase-screen  ( -- )
   frame-buffer-adr  bytes/screen  screen-background fb-fill
;
: fb8-blink-screen  ( -- )   \ Better done by poking the DAC
    fb8-invert-screen  fb8-invert-screen
;
: fb8-reset-screen  ( -- )  ;
headerless

: screen-adr  ( column# line# -- adr )
    char-height *  window-top   +                  ( column# ypixels )
    swap  char-width *  window-left +  pix*  swap  ( xpixels ypixels )
    bytes/line *  +  frame-buffer-adr  +
;
: line-adr  ( line# -- adr )  0 swap screen-adr  ;
: column-adr ( column# -- adr )  line# screen-adr  ;
: cursor-adr  ( -- adr )  column# line#  screen-adr  ;

headers
: fb8-draw-character  ( char -- )
   >font fontbytes  char-width char-height
   cursor-adr bytes/line  text-foreground text-background
   ( fontadr fontbytes width height screenadr bytes/line fg-color bg-color )
   fb-paint
;
: fb8-toggle-cursor  ( -- )
   cursor-adr char-width char-height bytes/line
   text-foreground text-background  fb-invert
;

: fb8-draw-logo  ( line# logoadr logowidth logoheight -- )
   2swap swap line-adr >r  -rot   ( logoadr width height )  ( r: scrn-adr )
   swap dup 7 + 8 /               ( logoadr height width linebytes )
   swap rot                       ( logoadr linebytes width height )
   r> bytes/line  logo-foreground screen-background  fb-paint
;

headerless

: move-line    ( src-line-adr dst-line-adr -- )  emu-bytes/line fb-window-move  ;
: erase-line   ( line-adr -- )  emu-bytes/line screen-background fb-fill  ;
: erase-lines  ( last-line first-line -- )
   ?do  i erase-line  bytes/line +loop
;
: cursor-y  ( -- line-adr )  line# line-adr  ;
: window-bottom  ( -- line-adr )  #lines line-adr  ;
: break-low  ( delta-#lines -- line-adr )  line# +  #lines min  line-adr  ;
: break-high ( delta-#lines -- line-adr )  #lines swap -  0 max  line-adr  ;

headers
\ Delete n lines, starting with current cursor line.  Scroll the rest up
: fb8-delete-lines-slow  ( delta-#lines -- )
    break-low  cursor-y window-bottom  rot
    ?do   ( cursor-y' )
       i over move-line  bytes/line +
    bytes/line +loop   ( break-high-adr )
    window-bottom swap  erase-lines
;
: fb8-delete-lines  ( delta-#lines -- )
    dup break-high swap break-low  ( break-high break-low )
    cursor-y  over window-bottom swap -  ( b-hi b-lo cursor-y  bottom-blo )
    bytes/line emu-bytes/line  fb-window-move   ( break-hi )
    window-bottom swap  erase-lines
;

: fb8-insert-lines  ( delta-#lines -- )
    break-high  window-bottom          ( break-line-adr bottom-line-adr )
    swap bytes/line -                  ( bottom break-high- )
    cursor-y   swap                    ( bottom  cursor-y break-high- )
    2dup <  if                         ( bottom  cursor-y break-high- )
       do                                  ( bottom' )
          bytes/line -  i over move-line   ( bottom- )
       bytes/line negate +loop             ( break-low-adr )
    else
       2drop                               ( break-low-adr )
    then
    cursor-y  erase-lines
;
headerless

: move-chars  ( source-col# dest-col# -- )
    2dup max  #columns swap -                ( src dst #chars )
    bytes/char *  -rot                       ( #bytes src dst )
    swap column-adr  swap column-adr         ( #bytes src dst )
    char-height 0  do                        ( #bytes src dst )
       3dup rot move                         ( #bytes src dst )
       swap bytes/line +  swap bytes/line +  ( #bytes src' dst' )
    loop    3drop                            ( )
;
: erase-chars  ( #chars start-col# -- )
    swap bytes/char * swap                  ( #bytes start-col# )
    column-adr char-height 0  do            ( #bytes adr )
        2dup swap text-background fb-fill   ( #bytes adr )
        bytes/line +                        ( #bytes adr' )
    loop  2drop                             ( )
;
headers
: fb8-insert-characters  ( #chars -- )
    #columns column# - min  dup
    column# +   column# swap     ( #chars' cursor-col# cursor+count-col# )
    move-chars  ( #chars' )  column#  erase-chars
;
: fb8-delete-characters  ( #chars -- )
    #columns column# - min  dup  ( #chars' #chars' )
    column# +  column#           ( #chars' cursor+count-col#  cursor-col# )
    move-chars  ( #chars' )  #columns over -  erase-chars
;
headerless

: center-display  ( -- )
    screen-height  #lines   char-height * -  2/  is window-top
    screen-width   #columns char-width  * -  2/  8 pix* negate and  is window-left
;

headers
: fb-install  ( screen-width screen-height #columns #lines bytes/line depth -- )
   case
      8 of
         ['] noop       to pix*
         ['] fb8-invert to fb-invert
         ['] fill       to fb-fill
         ['] fb8-paint  to fb-paint
         ['] colors-8bpp  to fb-16map
      endof

      d# 16 of
         ['] /w*         to pix*
         ['] fb16-invert to fb-invert
         ['] wfill       to fb-fill
         ['] fb16-paint  to fb-paint
         ['] colors-565  to fb-16map
      endof

      d# 32 of
         ['] /l*         to pix*
         ['] fb32-invert to fb-invert
         ['] lfill       to fb-fill
         ['] fb32-paint  to fb-paint
         ['] colors-32bpp to fb-16map
      endof
   endcase

   \ Assume that the driver supports the 16-color extension
   true to 16-color?
   ['] not-dark to light

   \ my-self is display device's ihandle      ( width height #columns #lines bytes/line )
   is bytes/line                              ( width height #columns #lines )
   screen-#rows    min  is #lines             ( width height #columns )
   screen-#columns min  is #columns           ( width height )
   is screen-height  is screen-width          ( )
   #columns bytes/char *  is emu-bytes/line   ( )
   center-display
   ['] fb8-reset-screen   	is reset-screen
   ['] fb8-toggle-cursor  	is toggle-cursor
   ['] fb8-erase-screen	        is erase-screen
   ['] fb8-blink-screen	        is blink-screen
   ['] fb8-invert-screen	is invert-screen
   ['] fb8-insert-characters	is insert-characters
   ['] fb8-delete-characters	is delete-characters
   ['] fb8-insert-lines	        is insert-lines
   bytes/line 8 pix* mod
   if   ['] fb8-delete-lines-slow
   else ['] fb8-delete-lines
   then     			is delete-lines
   ['] fb8-draw-character	is draw-character
   ['] fb8-draw-logo		is draw-logo
;
: fb8-install  ( width height #cols #lines -- )  3 pick 8 fb-install  ;
