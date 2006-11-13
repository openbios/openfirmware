\ See license at end of file

\ Command line editing.  See "install-line-editing" for functions
\ implemented and key bindings

d# 80 value display-width

only forth also hidden also
hidden definitions

decimal

headers
true value display?     \ Turns display update on or off
false value accepting?	\ True when "accept" is calling the editor
headerless

\ Values used by redisplay code

: beep  ( -- )  display? 0=  if  exit  then   control G (emit  ;

\ Values describing the current edit line

0 value line-start-adr  \ address of start of input buffer
0 value linelen         \ current size of input line
0 value #before         \ position of cursor within line

0 value edit-line#

\ Positional information derived from the basic information

: #after        ( -- n )        linelen #before -  ;
: cursor-adr    ( -- adr )      line-start-adr  #before  +  ;
headers
\ "after" needs a header because it's used by nvalias.fth
: after         ( -- adr len )  cursor-adr #after  ;
headerless
: line-end-adr  ( -- adr )      after +  ;

\ Size and position of displayable "window" into the text line
d# 79 value window-width	\ Width of window in characters
0 value window-x		\ Offset from start of line buffer

-1 value xdamage	\ The first character that doesn't match the display.
			\ Offset in characters from start of line buffer.

-1 value ydamage	\ The first line that doesn't match the display.
			\ Offset in lines from beginning of buffer.

defer new-line-end  ( new-lineend -- old-lineend )

0 value dirty-x			\ Offset from start of window
: (new-line-end)  ( new-lineend -- old-lineend )
   dirty-x  swap is dirty-x   ( new-lineend old-lineend )
;
' (new-line-end) is new-line-end

: #to-clear  ( -- #spaces )
   #out @  new-line-end  #out @  -  0 max
;

: new-window-width  ( -- )
   \ The 1- leaves room for the cursor
   display-width 1-  #out @ -  is window-width
   0 #out !  0 #line !			\ Re-origin character counter
;

false value redisplay-line#?	\ Flag

\ Displays a line number.
defer .line#
: (.line#)  ( -- )
   accepting?  redisplay-line#? 0=  or  if  exit  then
   (cr  0 #out !		\ Left edge of display
   push-decimal  edit-line#  4 u.r  ." : "  pop-base
   false is redisplay-line#?
   new-window-width
;
' (.line#) is .line#

: wtype  ( cursor len -- )  swap window-x +  line-start-adr +  swap type  ;
: hmove-cursor  ( column# -- )
   #out @ -  ?dup  if                               ( distance-right )
      dup 0>  if                                    ( distance-right )
         \ Move forward n positions on the display.
         [ifdef] rights  dup 4 >  if  rights  exit  then  [then]
   
         #out @  swap  wtype                        ( )
      else                                          ( distance-right )
         negate                                     ( distance-left )

         \ Move backward n positions on the display.
         \ An optimization for the case where we have cursor control
         [ifdef] lefts   dup 4 >  if  lefts  exit  then   [then]

         0  ?do  bs (emit  -1 #out +!  loop
      then
   then
;

\ Converts buffer-line-oriented coordinates to window-relative coordinates
: clip-x  ( line-x -- window-x )  window-x -  0 max  window-width min  ;

\ Computes a new position for window-x
\ Any change in window-x effectively forces a complete redisplay
: set-window-x  ( new-window-x -- )
   \ Fix things so clipped-redisplay redisplays the entire line
   \ If xdamage is nonzero, clipped-redisplay will first move the
   \ cursor to xdamage.
   dup is xdamage  is window-x
;

[ifdef] smooth-hscroll
\ If the cursor is at either end of the line, we allow it to go
\ all the way to the end;  Otherwise, we limit it to the adjacent
\ cell, so that you can always tell what you will delete.
: #before-min  ( -- n )  #before  #before 0<>  if  1-  then  ;
: #before-max  ( -- n )  #before  #after  0<>  if  1+  then  ;
[then]

: ?reframe  ( -- )
   \ If we don't have an overflow condition, we cancel the window-x offset
   linelen window-width <=  window-x 0<>  and  if  0 set-window-x  exit  then

   \ The text doesn't fit, so we must decide where to put it in the window

[ifdef] smooth-hscroll
   \ If the cursor is out of the window in either direction, set window-x so
   \ the cursor is back in the window at the end closest to where it was.
   #before-min  window-x  <  if  #before-min set-window-x   exit  then

   #before-max  window-x window-width +  >=  if
      #before-max  window-width -  set-window-x
      exit
   then
[else]
   \ If the cursor is out of the window in either direction, set window-x so
   \ the cursor is back in the window at the end closest to where it was.
   #before  window-x  dup window-width +  within  0=  if
      #before  window-width 2/  -  0 max  set-window-x
      exit
   then
[then]

   \ If we get here, the cursor is still in the window, so we leave
   \ window-x as-is
;

: clipped-redisplay  ( -- )
   \ Redisplay everything after the first damaged location

   \ The reframer has ensured that #before is in the window.

   xdamage -1 <>  if                                ( )
      \ Move the cursor to the leftmost damaged position
      xdamage clip-x  dup  hmove-cursor             ( damage )

      \ Redraw from the damaged position to the new end-of-line
      linelen clip-x                                ( damage end )
      over - wtype                                  ( )

      \ If the old end-of=line is greater than the new one, blank the residue
      #to-clear  spaces                             ( )
   then                                             ( )

   #before clip-x hmove-cursor
;

\ Redisplays the editing line, optimizing for common types of changes.

: hredisplay  ( -- )
   .line#
   ?reframe
   clipped-redisplay
   -1 is xdamage
;

defer vredisplay  ' noop is vredisplay
: redisplay  ( -- )  display?  if  vredisplay  hredisplay  then  ;

defer line-moved
: (line-moved)  ( -- )     \ Version for 1-line display
   0 is xdamage  true is redisplay-line#?  0 is window-x
;
' (line-moved) is line-moved

\ Invalidate the line display values.  The cursor must be on a line
\ that is clear to the right of the cursor when this is called.
\ The scrolling area will extend from the current cursor position,
\ as indicated by the current value of #out, to display-width.
: clear-line  ( -- )
   0 is dirty-x                   \ Force update of line end information 
   new-window-width  line-moved
;
defer open-display  ( -- )
defer close-display  ( -- )
' clear-line is open-display
' cr is close-display

\ Goes to a clean line on the display, noting that the old line display
\ values are now invalid.  This will cause the redisplay code to do a
\ full redisplay of the current line.
: fresh-line  ( -- )  display?  if  cr  clear-line  then  ;

defer scroll-down
' fresh-line is scroll-down

\ Movement within a line, which doesn't affect the state of the buffer

headers
\ Move forward "#chars" positions, but stop at the end of the line.
: forward-characters  ( #chars -- )  #after min  #before +  is #before  ;

\ Move backward "#chars" positions, but stop at the beginning of the line.
: backward-characters  ( #chars -- )  #before min  #before swap -  is #before ;

: forward-character   ( -- )  1 forward-characters  ;
: backward-character  ( -- )  1 backward-characters  ;
: end-of-line         ( -- )  #after forward-characters  ;
: beginning-of-line   ( -- )  #before backward-characters  ;

\ Redisplays the current line
: retype-line  ( -- )  scroll-down  ;

headerless

\ Locates the beginning of the previous (blank-delimited) word.
\ Doesn't move the cursor or change the display.  Internal.

: find-previous-word  ( -- adr )
   line-start-adr  dup cursor-adr 1-  ?do   ( linestart )
      i c@  bl <>  if  drop i leave  then
   -1 +loop
   ( nonblank-adr )
   line-start-adr  dup  rot  ?do   ( linestart )
      i c@  bl =  if  drop i 1+  leave  then
   -1 +loop
;

\ Locates the beginning of the next (blank-delimited) word.
\ Doesn't move the cursor or change the display.  Internal.

: find-next-word  ( -- adr )
   line-end-adr  dup  cursor-adr  ?do  ( bufend-adr )
      i c@  bl =  if  drop i leave  then
   loop
   line-end-adr  dup  rot  ?do  ( bufend-adr )
      i c@  bl <>  if  drop i leave  then
   loop
;

\ This is used by the command completion package; it ought to be elsewhere,
\ and it also should find the end of the word without going there.
: end-of-word  ( -- )
   after bounds  ?do
      i c@  bl =  ?leave  forward-character
   loop
;

headers
: forward-word  ( -- )  find-next-word cursor-adr -  forward-characters  ;
: backward-word  ( -- )
   cursor-adr find-previous-word -  backward-characters
;

\ Values describing the buffer that contains multiple editing lines

headerless
0 value buf-start-adr   \ address of start of input buffer
headers
\ "buflen" needs a header because it's used by nvalias.fth
0 value buflen          \ current size of input buffer
headerless
0 value bufmax          \ maximum size of input buffer

\ : buf-extent    ( -- adr len )  buf-start-adr  buflen  ;
\ : buf-end-adr   ( -- n )        buf-extent +  ;
: buf-end-adr   ( -- adr )   buf-start-adr buflen +  ;
: buf#after     ( -- n )     buf-end-adr  cursor-adr -  ;

\ The words after this point manipulate the buffer and its cursor
\ position, calling the display routines as needed to maintain the display.

headers
81 buffer: kill-buffer
headerless

\ Deletes "#chars" characters after the cursor.  This affects the characters
\ in the buffer, but does not update the screen display.  It will delete
\ newline characters the same as any others.

: (erase-characters)  ( #chars -- )
   >r
   r@ 1 >  if  cursor-adr r@  kill-buffer  place  then
   cursor-adr  dup r@ +  swap  buf#after r@ -  cmove  \ Remove from buffer
   buflen r> - is buflen
;

headers
\ "(insert-characters)" needs a header because it's used by nvalias.fth

\ Inserts characters from "adr len" into the buffer, up to the amount
\ of space remaining in the buffer.  #inserted is the number that
\ were actually inserted.  Does not update the display.

: (insert-characters)  ( adr len -- #inserted )
   dup buflen +  bufmax  <=  if        ( adr len )
      dup buflen + is buflen           ( adr len )
      dup linelen + is linelen         ( adr len )
      cursor-adr   2dup +              ( adr len  src-addr dst-addr )
      buf#after 3 pick -  cmove>       ( adr len  )
      tuck cursor-adr  swap cmove      ( len=#inserted )
   else
      2drop 0                          ( 0 )
   then
;
headerless

\ Finds the line length.  Used after moving to a new line.  Internal.
: update-linelen  ( -- )
   buf#after  0  ?do
      cursor-adr  i ca+ c@  newline =  ?leave
      linelen 1+ is linelen
   loop
;
headers
: last-line?  ( -- flag )  line-end-adr  buf-end-adr  u>=  ;
headerless
: set-line  ( line-start-adr line# -- )
   is edit-line#  is line-start-adr  0 is #before  0 is linelen  update-linelen
;
: +line  ( -- )
   last-line?  if
      line-end-adr  edit-line#
   else
      line-end-adr 1+  edit-line# 1+
   then
   set-line
;
: end-line?  ( -- flag )  line-start-adr buf-end-adr u>=  ;
: -line  ( -- )
   buf-start-adr  dup 1+                  ( previous-length buf0 buf1 )
   dup line-start-adr 1- max  ?do         ( previous-length buf0 )
      i -1 ca+ c@                         ( previous-length buf0 char )
      newline =  if  drop i leave  then   ( previous-length line-adr )
   -1 +loop                               ( previous-length line-adr )
   edit-line# 1-  set-line                ( previous-length )
;

: (to-command-line)  ( -- )
   0 is #before
   begin  edit-line# 0<  while  +line  repeat
;

: ?copyline  ( -- )
   edit-line#  0<  if
      #before  line-start-adr  linelen               ( cursor adr len )
      (to-command-line)                              ( cursor adr len )
      #after  if
         #after (erase-characters)
         0 is linelen
      then                                           ( cursor adr len )
      (insert-characters) drop                       ( cursor )
      is #before
   then
;

: set-ydamage  ( -- )  edit-line# 1+ is ydamage  ;
: set-xdamage  ( -- )  xdamage #before umin  is xdamage  ;

\ Insertion and deletion

headers

\ Inserts characters from "adr len" into the buffer, and redisplays
\ the rest of the line.
: insert-characters  ( adr len -- )
   ?copyline
   (insert-characters)          ( #inserted )
   dup  if  set-xdamage  then   ( #inserted )
   forward-characters
;

\ Erases characters within a line and redisplays the rest of the line.
\ "#chars" must not be more than "#after"
: erase-characters  ( #chars -- )
   ?copyline
   set-xdamage
   dup (erase-characters)
   linelen swap - is linelen
;

headerless
nuser ch	\ One-element array used to convert character to "adr len"

headers
: insert-character  ( char -- )  ch c!  ch 1 insert-characters  ;
: quote-next-character  ( -- )  key insert-character  ;

: erase-next-character  ( -- )  #after 1 min  erase-characters  ;

: erase-previous-character  ( -- )
   #before 1 min  dup backward-characters  erase-characters
;

\ EMACS-style "kill-line".  If executed in the middle of a line, kills
\ the rest of the line.  If executed at the end of a line, kills the
\ "newline", thus joining the next line to the end of the current one.

: kill-to-end-of-line  ( -- )
   #after  ?dup  if
      erase-characters				\ Kill rest of line
   else
      accepting? 0=  if
         \ Join lines unless we're already at the end of the file
         buf#after  if
            1 (erase-characters)
            update-linelen
            set-xdamage  set-ydamage
         then
      then
   then
;
: erase-next-word  ( -- )  find-next-word cursor-adr -  erase-characters  ;
: erase-previous-word  ( -- )
   cursor-adr  backward-word  cursor-adr -  erase-characters
;
: beginning-of-file  ( -- )  buf-start-adr 0 set-line  ;

headerless

defer to-goal-column  ( -- )
' end-of-line is to-goal-column

headers
defer deny-history?   \ Turns off history access for security
' false is deny-history?

\ Goes to the next line, if there is one
: next-line  ( -- )
   accepting? deny-history?  and  if  exit  then
   last-line? 0=  if
      line-moved
      +line to-goal-column
      accepting? 0=  if  scroll-down  then
   then
;

\ Goes to the previous line
: previous-line  ( -- )
   accepting? deny-history?  and  if  exit  then
   buf-start-adr  line-start-adr  <  if  line-moved -line to-goal-column  then
;

\ : forward-lines  ( #lines -- )   0  ?do  next-line  loop  ;
\ : backward-lines  ( #lines -- )   0  ?do  previous-line  loop  ;

: split-line  ( -- )
   accepting?  if  beep exit  then

   newline ch c!  ch 1 (insert-characters)  if
      set-xdamage  set-ydamage
      #before is linelen    \ Erase the rest of the line
   then
;
: new-line  ( -- )  split-line  next-line  ;
: list-file  ( -- )
   accepting? deny-history? and  if  exit  then
   #before line-start-adr edit-line#    ( #before adr line# )
   beginning-of-file                    ( #before adr line# )
   begin                                ( #before adr line# )
      line-moved retype-line redisplay  ( #before adr line# )
   exit? last-line? or  0=  while       ( #before adr line# )
      +line                             ( #before adr line# )
   repeat                               ( #before adr line# )
   set-line  is #before
   retype-line
;
: yank  ( -- )  kill-buffer count insert-characters  ;

defer recenter  ( -- )
' list-file is recenter

: one-line-display  ( -- )
   ['] clear-line      is open-display
   ['] cr              is close-display
   ['] noop            is vredisplay
   ['] (new-line-end)  is new-line-end
   ['] (.line#)        is .line#
   ['] (line-moved)    is line-moved
   ['] end-of-line     is to-goal-column
   ['] fresh-line      is scroll-down
   ['] list-file       is recenter
;

headers
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
