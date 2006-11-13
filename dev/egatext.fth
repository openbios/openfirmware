\ See license at end of file
purpose: Display driver for EGA/VGA in text mode

\ 0 0  " "  " /"  begin-package

hex
headers

" ega-text" device-name
" display"                      device-type
0 0  encode-bytes  " iso6429-1983-colors"  property

d# 80 constant #ega-columns
d# 25 constant #ega-lines
#ega-lines #ega-columns * constant #chars
#chars 2* constant /ega
7 value attributes

: background  ( -- n )
   inverse?  if  foreground-color  else  background-color  then
;
: foreground  ( -- n )
   inverse?  if  background-color  else  foreground-color  then
;
: set-attributes  ( -- )
   background 7 and  4 lshift  foreground or  to attributes
;

0 value ega
: fill-text  ( len value -- )
   ega rot 2*  bounds  do  dup i c!  2 +loop  drop
;
: fill-attrs  ( len value -- )
   ega rot 2*  bounds  do  dup i 1+ c!  2 +loop  drop
;

\ On many chipsets, to access the CRT registers you have to do things
\ like turning on the I/O enable in the PCI command register for the
\ display controller.  And on some chipsets the screen blanks if you
\ try to touch the CRT registers.
\ : crt-setup  ( index -- data-adr )  h# 03d4 pc!  h# 03d5  ;
\ : crt!  ( b index -- )  crt-setup pc!  ;
\ : crt@  ( index -- b )  crt-setup pc@  ;

: ega-screen-adr  ( column# line# -- adr )  #columns *  + 2*  ega +  ;
: ega-line-adr  ( line# -- adr )  0 swap ega-screen-adr  ;
: ega-column-adr ( column# -- adr )  line# ega-screen-adr  ;
: ega-cursor-adr  ( -- adr )  column# line#  ega-screen-adr  ;

: ega-draw-character  ( char -- )
   set-attributes  ega-cursor-adr tuck c!  attributes swap 1+ c!
;
: ega-reset-screen  ( -- )  ( TBD )  ;

\ Exchange foreground and background
: flop  ( attr-byte -- attr-byte' )
   dup h# 88 and  over 4 lshift h# 70 and or  swap 4 rshift 7 and  or
;
: ega-toggle-cursor  ( -- )
   set-attributes
   ega-cursor-adr 1+               ( attribute-adr )
   dup c@  flop  swap c!           ( )

\ Code for the hardware cursor; unwise to use it because accessing
\ the CRT registers often requires external setup.
\  line# #ega-columns *  column# +  wbsplit  h# e crt!  h# f crt!
;
: ega-erase-screen  ( -- )
   #chars attributes fill-attrs  #chars bl fill-text
;
: ega-invert-screen  ( -- )
   ega /ega  bounds  do  i 1+  c@  flop  i 1+ c!  2 +loop
;
: ega-blink-screen  ( -- )  ega-invert-screen  d# 100 ms  ega-invert-screen  ;

: ega-bytes/line  ( -- n )  #ega-columns 2*  ;
: blank-chars  ( adr #chars -- )
   2*  bounds  ?do  bl i c!  attributes i 1+ c!  2 +loop
;
: ega-erase-lines  ( last-line-adr first-line-adr -- )
   ?do   i  #ega-columns blank-chars  ega-bytes/line +loop
;
: ega-cursor-y  ( -- line-adr )  line# ega-line-adr  ;
: ega-window-bottom  ( -- line-adr )  #lines ega-line-adr  ;
: ega-break-low   ( delta-#lines -- line-adr )
   line# +  #lines min  ega-line-adr
;
: ega-break-high  ( delta-#lines -- line-adr )
   #lines swap -  0 max  ega-line-adr
;
: ega-delete-lines  ( delta-#lines -- )
   dup ega-break-high swap ega-break-low  ( break-high break-low )
   ega-cursor-y  over ega-window-bottom swap -  ( b-hi b-lo curs-y bottom-blo )
   move                                   ( break-high )
   ega-window-bottom swap  ega-erase-lines
;

: ega-insert-lines  ( delta-#lines -- )
   ega-break-high  ega-window-bottom   ( break-line-adr bottom-line-adr )
   swap ega-bytes/line -               ( bottom break-high- )
   ega-cursor-y   swap                 ( bottom  cursor-y break-high- )
   2dup <  if                          ( bottom  cursor-y break-high- )
      do                                          ( bottom' )
         ega-bytes/line -  i over  ega-bytes/line 2*  move   ( bottom- )
      ega-bytes/line negate +loop      ( break-low-adr )
   else                                ( bottom  cursor-y break-high- )
      2drop                            ( break-low-adr )
   then                                ( break-low-adr )
   ega-cursor-y  ega-erase-lines
;
: ega-move-chars  ( source-col# dest-col# -- )
   2dup max  #columns swap -                 ( src-col# dst-col# #chars )
   2* -rot                                   ( #bytes src-col# dst-col# )
   swap ega-column-adr  swap ega-column-adr  ( #bytes src-adr dst-adr )
   rot move
;
: ega-erase-chars  ( #chars start-col# -- )
   ega-column-adr  swap  blank-chars
;
: ega-insert-characters  ( n -- )
   #columns column# - min  dup
   column# +   column# swap     ( #chars' cursor-col# cursor+count-col# )
   ega-move-chars  ( #chars' )  column#  ega-erase-chars
;
: ega-delete-characters  ( #chars -- )
   #columns column# - min  dup  ( #chars' #chars' )
   column# +  column#           ( #chars' cursor+count-col#  cursor-col# )
   ega-move-chars  ( #chars' )  #columns over -  ega-erase-chars
;

: ega-draw-logo  ( line# addr width height -- )  2drop 2drop  ;

: ega-install  ( -- )
   h# b8000 /ega  " map-in" $call-parent  to ega

   set-attributes

\ Accessing the hardware cursor is a lot of trouble.
\   d# 0 h# a crt!  d# 15 h# b crt!   \ Block cursor

   #ega-columns to #columns  #ega-lines to #lines
   
   true to 16-color?

   ['] ega-reset-screen   	is reset-screen
   ['] ega-toggle-cursor	is toggle-cursor
   ['] ega-erase-screen	        is erase-screen
   ['] ega-blink-screen	        is blink-screen
   ['] ega-invert-screen	is invert-screen
   ['] ega-insert-characters	is insert-characters
   ['] ega-delete-characters	is delete-characters
   ['] ega-insert-lines	        is insert-lines
   ['] ega-delete-lines         is delete-lines
   ['] ega-draw-character	is draw-character
   ['] ega-draw-logo		is draw-logo
;
: ega-remove  ( -- )
   ega /ega  " map-out" $call-parent
;

: ega-selftest  ( -- failed? )  false  ;

headers

: probe  ( -- )
   ['] ega-install  is-install
   ['] ega-remove   is-remove
   ['] ega-selftest is-selftest
;
probe

\ end-package
\ 
\ devalias screen /ega-text
\ LICENSE_BEGIN
\ Copyright (c) 2006 FirmWorks
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
