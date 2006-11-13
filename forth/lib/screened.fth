\ See license at end of file
purpose: Screen-oriented extension for the line editor

also hidden definitions

d# 24 value display-height

headerless
0 value window-y	\ The line at the top of the window
			\ Offset in lines from beginning of buffer
1 value window-height	\ Height of window in lines
0 value old-line#	\ The line that the cursor was on at the last redisplay
			\ This tells which line window-x applies to.
			\ Offset in lines from beginning of buffer

\ Move cursor vertically
: vmove-cursor  ( window-line# -- )
   #line @ -  ?dup  if                             ( #lines-down )
      dup  0<  if  negate ups  else  downs  then   ( )
   then
;

\ Converts buffer-line-oriented coordinates to window-relative coordinates
: clip-y  ( buf-line# -- window-line# )  window-y - 0 max  window-height min  ;

: vreframe  ( -- )
   edit-line#  window-height 2/  -  0 max  ( new-window-y )
   dup is ydamage  is window-y
   line-moved			\ The old line info is useless now
;

\ If the cursor is out of the window in either direction, set the window so
\ the cursor is in the middle of the window, but don't let window-y
\ be negative.
: ?vreframe  ( -- )
   edit-line#  window-y  dup window-height +  within  0=  if  vreframe  then
;

: move-cursor  ( x y -- )  ( 0 hmove-cursor )  vmove-cursor  hmove-cursor  ;

d# 100 buffer: line-ends  
: w-new-line-end  ( new-line-end -- old-line-end )
   line-ends  #line @  +          ( new-line-end adr )
   dup c@  -rot c!                ( old-line-end )
;

\ The lower boundary of non-white lines in the window
\ Offset in lines from top of window
: rest-blank?  ( -- flag )
   true                                      ( flag )
   window-height  #line @  ?do               ( flag )
      line-ends i + c@  if  0=  leave  then  ( flag )
   loop                                      ( flag )
;

\ (display-range) refreshes the display beginning at start-line (in buffer
\ line coordinates), and continuing for a maximum of #lines, subject to the
\ lower limit of the window.  (display-range) clips the #lines argument as
\ necessary.

: (display-range)  ( start-line #lines -- )
   #before line-start-adr edit-line# >r >r >r	\ Save current buffer position

   \ Find start-line in the buffer
   beginning-of-file  over 0  ?do  +line  loop            ( start-line #lines )

   \ Convert start-line from a buffer line number to a window line number,
   swap clip-y swap bounds                                ( end start )

   \ Clip the range so it doesn't extend past the bottom of the window.
   swap  window-height min  swap                          ( end start )

   \ Loop over display window lines, beginning at the window line
   \ corresponding to the buffer line "start-line", continuing for
   \ the minimum of "#lines" or the number of lines remaining in the
   \ display window, or until there are no more lines left in the
   \ buffer and the remaining display lines are already blank.
   ?do
      \ Move the cursor to the beginning of the next line
      0 i move-cursor

      end-line?  if
         \ We have displayed all the lines in the buffer,
         \ so we continue looping and clearing display lines
         \ until all the lines below us are already blank.
         rest-blank? ?leave
      else
         \ There is a (possibly zero-length) buffer line here; display it
         line-start-adr  window-width linelen min  type
      then

      \ Erase the rest of the line (perhaps the entire line)
      #to-clear  spaces

      \ Advance to the next line; +line stops at the end of the buffer
      +line
   loop

   r> r> r> set-line  is #before		\ Restore buffer position
;

: old-damaged?  ( -- flag )  ydamage old-line# u<=  ;
: shifted?  ( -- flag )  window-x 0<>  ;
: line-moved?  ( -- flag )  edit-line# ( window-y - )  old-line# <>  ;

: display-below  ( -- )
   shifted?  old-damaged?  and  line-moved? 0=  and  if
      \ If the vertical damage includes the current line and it was
      \ shifted, the vertical redisplay procedure will mess it up,
      \ so we do this to trigger a horizontal redisplay later.
      window-x  set-window-x
   then
   ydamage window-height (display-range)
;

: (vredisplay)  ( -- )
   ?vreframe
   ydamage -1 <>  if  display-below  then

   line-moved?  if   \ Need to move vertically
      shifted?  old-damaged? 0=  and  if
         \ Old line was shifted and hasn't yet been redrawn
         old-line# 1 (display-range)
         0 is window-x
      then
      0  edit-line# clip-y  move-cursor
   then
   edit-line# clip-y vmove-cursor
   edit-line# is old-line#
   -1 is ydamage
;

: transfer-damage  ( -- )
   \ Horizontal damage only applies to the current line, so when we
   \ move to a different line, we have to transfer the old line's
   \ horizontal damage to vertical damage.
   xdamage -1 <>  if				\ Old line is damaged
      edit-line# ydamage umin  is ydamage	\ Record as vertical damage
      -1 is xdamage				\ Cancel horizontal damage
   then
;
: open-window  ( -- )
   0 #out !  0 #line !
   line-ends window-height window-width fill
   0 is ydamage
;

: close-window  ( -- )
   window-height 1- vmove-cursor  cr  kill-screen
   one-line-display
;

: screen-display  ( -- )
   ['] open-window     is open-display
   ['] close-window    is close-display
   ['] (vredisplay)    is vredisplay
   ['] w-new-line-end  is new-line-end
   ['] transfer-damage is line-moved
   ['] noop            is .line#
   ['] noop            is to-goal-column
   ['] noop            is scroll-down
   ['] vreframe        is recenter
;
: (set-window)  ( column# line# #columns #lines -- )
   1 max is window-height         ( column# line# #columns )

   2 pick  +                      ( col# line#  max-col# )
   display-width 1- min           ( col# line#  clipped-col# )
   2 pick  -                      ( col# line#  clipped-#cols )
   is window-width                ( col# line# )

   at-xy                          ( )

   screen-display
;
defer set-window
' (set-window) is set-window

headers
: no-screen  ( -- )  ['] 4drop is set-window  ;
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
