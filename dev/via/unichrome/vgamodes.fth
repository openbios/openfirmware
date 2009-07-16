\ XXX get these from video/common/defer.fth
\ false instance value 6-bit-primaries?	\ Indicate if DAC only supports 6bpp
\ defer ext-textmode  ' noop to ext-textmode
\ These are just to make vga.fth happy.  They are ba
\ defer rs@   defer rs!
\ defer idac@ defer idac!
\ defer xvideo-on
\ From graphics.fth

\ defer plt@
\ defer plt!
\ defer rindex!
\ defer windex!

: ext-textmode
   use-vga-dac
   h# ff h# e crt!  h# ff h# f crt!  \ Move the hardware cursor off-screen
   h# 01 h# 33 crt!   \ Hsync adjustment
   h# 10 h# 35 crt!   \ Clear extended bits that can't be on for this mode's size
   h# 00 h# 15 seq!   \ Not using graphics modes
   h# 0c h# 16 seq!   \ FIFO
   h# 1f h# 17 seq!   \ FIFO
   h# 4e h# 18 seq!   \ FIFO
   h# 20 h# 1a seq!   \ Extended mode memory access disable
   h# 54 h# 1c seq!   \ Hdisp fetch count low
   h# 00 h# 1d seq!   \ Hdisp fetch count high
   h# 00 h# 51 seq!   \ FIFO
   h# 06 h# 58 seq!   \ FIFO
   h# 00 h# 71 seq!   \ FIFO
   h# 00 h# 73 seq!   \ FIFO
;
\ defer rmr@  defer rmr!

: (set-colors)  ( adr index #indices -- )
   swap windex!
   3 *  bounds  ?do  i c@  plt!  loop
;

\ fload ${BP}/dev/video/controlr/vga.fth
fload ${BP}/dev/video/common/textmode.fth

0 value pc-font-adr
: (pc-font)  ( -- fontparams )
   pc-font-adr 0=  if
      " pcfont" " find-drop-in" evaluate  if  ( adr len )
         drop to pc-font-adr
      else
         default-font exit
      then
   then

   " /packages/terminal-emulator" find-package  if  ( phandle )
      " decode-font" rot find-method  if   ( xt )
         pc-font-adr swap execute          ( font-params )
         exit
      then
   then

   \ Fallback
   default-font
;
' (pc-font) to pc-font

warning @ warning off
: text-mode3  ( -- )
   text-mode3
;
warning !
