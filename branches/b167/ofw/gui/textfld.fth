\ See license at end of file
purpose: Generic GUI text edit fields for use within dialog boxes

headerless

: >edit      ( node -- adr )  >private @  ;	\ edit's buffer adr and maxlen
: >edit-len  ( node -- adr )  >edit  2 na+  ;	\ edit's buffer cur len
: >echo?     ( node -- adr )  >edit-len na1+  ;	\ true if chars are displayed
/n 2* /n + /c +  constant /edit-private

light-gray constant edit-lf-color
black      constant edit-hf-color
background constant edit-hb-color
light-gray constant edit-tt-color

variable dialog-edit?
true value echo?
0 value save-skey

d# 256 dup constant /asterisks
buffer: asterisks
d# 80 dup constant /blanks
buffer: blanks

warning @ warning off
keys-forth also definitions also hidden
\ Used for debugging pgdn only:
\ : ^d     dialog-edit? @  if  new-line-or-done pgdn? on  exit  then  ^d  ;
: ^i     dialog-edit? @  if  new-line-or-done  exit  then  ^i  ;
: ^n     dialog-edit? @  if  new-line-or-done  exit  then  ^n  ;
: ^o     dialog-edit? @  if  new-line-or-done  exit  then  ^o  ;
: ^p     dialog-edit? @  if  new-line-or-done goto-next? off  exit  then  ^p  ;
: esc-[A
   dialog-edit? @  if  new-line-or-done goto-next? off exit  then  esc-[A 
;
: esc-[B dialog-edit? @  if  new-line-or-done  exit  then  esc-[B  ;
: esc-[/ dialog-edit? @  if  new-line-or-done  pgdn? on  then  ;  \ pgdn
: esc-[? dialog-edit? @  if  new-line-or-done  pgup? on  then  ;  \ pgup
previous forth definitions
warning !
hidden also definitions
: my-open-display  ( -- )
   0 to dirty-x
   \ The 1- leaves room for the cursor
   window-width 1-  is window-width
   0 #out !  0 #line !			\ Re-origin character counter
   line-moved
;
previous forth definitions

[ifdef] notdef
0 value my-xdamage
0 value my-linelen
0 value my-#before
0 value my-window-width
0 value my-dirty-x
0 value my-window-x
0 value my-#out
keys-forth also definitions also hidden
: ^z
   xdamage to my-xdamage
   linelen to my-linelen
   #before to my-#before
   window-width to my-window-width
   dirty-x to my-dirty-x
   window-x to my-window-x
   #out @ to my-#out
;
previous forth definitions
: .^z
   ." xdamage = " my-xdamage .d cr
   ." linelen = " my-linelen .d cr
   ." #before = " my-#before .d cr
   ." window-width = " my-window-width .d cr
   ." dirty-x = " my-dirty-x .d cr
   ." window-x = " my-window-x .d cr
   ." #out = " my-#out .d cr
;
[then]

: (edit-moused)  ( -- ?? done? )
   moused-node  ?dup  if
      " up" run-method
      moused-node do-hook
      moused-node " done?" run-method
   else
      false
   then
;
' (edit-moused) to edit-moused

: ?edit-depressed  ( buttons -- )  to moused-node-down?  ;
: edit-mouse-buttons  ( buttons list -- false | key true )
   mouse-node  dup  if		( buttons dbutton)
      dup moused-node =  if
         drop  moused-node-down?	( buttons was-down? )
         over ?edit-depressed		( buttons was-down? )
         swap 0=  and  if  0e edit-moused? on true  else  false  then	\ ^c
         exit
   then then
   to moused-node			( buttons )
   ?edit-depressed			( )
   false
;

variable redraw-mouse-cursor?
: edit-skey  ( -- char )
   redraw-mouse-cursor? @  if
      draw-mouse-cursor
      redraw-mouse-cursor? off
   then
   begin
      key?  if
         redraw-mouse-cursor? on
         (key remove-mouse-cursor exit
      then
      mouse-ih  if
         begin  10 get-event  while
            remove-mouse-cursor
            -rot update-position
            draw-mouse-cursor
            interact-list edit-mouse-buttons  if  exit  then
         repeat
      then
   again
;

d# 78 d# 27 2constant def-edit-col-row
: center-title  ( adr len row# -- )
   >r
   def-edit-col-row drop  over - 2/  0 max
   r> screen-at-xy
   screen-write
;
: display-edit-title  ( adr len -- )
   2dup count-lines  0  ?do 	                     ( adr len )
      split-line i center-title                      ( adr' len' )
   loop                                              ( adr' 0 )
   2drop
;

: dialog-edit  ( xt adr len -- ok? )
   asterisks /asterisks ascii * fill
   blanks /blanks blank
   dialog-edit? on
   ['] skey behavior to save-skey
   ['] edit-skey to skey
   def-edit-col-row alert-text-box display-edit-title
   >r  controls(
      r> execute
      ok&cancel-buttons
   )controls
   save-skey to skey
   dialog-edit? off
   set-description-region
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
