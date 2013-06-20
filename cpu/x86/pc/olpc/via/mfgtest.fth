\ See license at end of file
purpose: Menu for manufacturing tests

h# f800 constant mfg-color-red
h# 07e0 constant mfg-color-green

: blank-screen  ( -- )
   h# ffff              ( color )
   0 0                  ( color x y )
   screen-wh            ( color x y w y )
   fill-rectangle-noff  ( )
;

: clear-n-restore-scroller  ( -- )
   blank-screen
   restore-scroller-bg
;

defer scroller-on
defer scroller-off
' clear-n-restore-scroller to scroller-on
' noop to scroller-off

: sq-border!  ( bg -- )  current-sq sq >border !  ;

warning off
\ Intentional redefinitions.  It would be better to change the name, but
\ Quanta could be using these words directly in manufacturing test scripts.
: red-screen    ( -- )  h# ffff mfg-color-red   " replace-color" $call-screen  ;
: green-screen  ( -- )  h# ffff mfg-color-green " replace-color" $call-screen  ;
warning on

0 value pass?
0 value overall-fail?
0 value stop?

: mfg-wait-return  ( -- )
   ." ... Press any key to proceed ... "
   cursor-off
   gui-alerts
   begin
      key?  if  key drop  refresh exit  then
      mouse-ih  if
         mouse-event?  if
            \ Ignore movement, act only on a button down event
            nip nip  if  wait-buttons-up  exit  then
         then
      then
   again
;

: mfg-test-result  ( return-code true | false -- )
   if               ( return-code )
      ?dup  if                                         ( return-code )
         ??cr ." Selftest failed. Return code = " .d cr
         mfg-color-red sq-border!
         false to pass?  true to overall-fail?
         red-screen
         flush-keyboard
         mfg-wait-return
      else                                                   ( )
         green-letters
         ??cr ." Okay" cr
         cancel
         mfg-color-green sq-border!
         true to pass?
         d# 2000 hold-message  if  true to stop?  then
      then
   else
      ??cr ." Selftest failed due to abort"  cr
      mfg-color-red sq-border!
      false to pass?  true to overall-fail?
      red-screen
      flush-keyboard
      mfg-wait-return
   then
   cursor-off  scroller-off   gui-alerts  refresh
   flush-keyboard
;
: (mfg-test-dev)  ( $ -- return-code true | false )
   2dup locate-device  if                         ( $ )
      ." Can't find device node " type cr  exit   ( -- )
   else                                           ( $ phandle )
      drop                                        ( $ )
   then                                           ( $ )
   " selftest" execute-device-method              ( return-code true | false )
;
: mfg-test-dev  ( $ -- )
   scroller-on
   ??cr  ." Testing " 2dup type cr                ( $ )
   (mfg-test-dev)                                 ( return-code true | false )
   mfg-test-result
;
: gfx-test-dev  ( $ -- )
   (mfg-test-dev)                                 ( return-code true | false )
   scroller-on                                    ( return-code true | false )
   mfg-test-result
;

0 value #mfgtests
0 value #mfgcols
0 value #mfgrows

: #mfgtests++  ( -- )  #mfgtests 1+ to #mfgtests  ;

0 value cur-col
0 value cur-row
: cur-col++  ( -- )  cur-col 1+ to cur-col  ;
: cur-row++  ( -- )  cur-row 1+ to cur-row  ;
: set-row-col  ( row col -- )  to cur-col  to cur-row  ;
: add-icon   ( -- )
   cur-col #mfgcols =  if
      cur-row++  cur-row #mfgcols >=  if  abort" Too many icons"  then
      0 to cur-col
   then
   cur-row  cur-col  install-icon
   cur-col++
   #mfgtests++
;

: (mfg-test)  ( n -- )
   i set-current-sq
   refresh
   d# 1000 ms
   run-menu-item
;

: mfg-test-autorunner  ( -- )  \ Unattended autorun of all tests
   #mfgcols #mfgtests +  #mfgcols  ?do
      i (mfg-test)
      pass? 0= ?leave
   loop
;

[ifdef] notdef  \ to be used by factory in final.fth
: mfg-test-runner  ( -- )  \ Attended autorun, each test retried until pass
   #mfgcols #mfgtests +  #mfgcols  ?do
      begin
         i (mfg-test)
         pass?
      until
   loop
;
patch mfg-test-runner mfg-test-autorunner autorun-mfg-tests
[then]

icon: play.icon     rom:play.565
icon: quit.icon     rom:quit.565

: play-item     ( -- )   \ Interactive autorun of all tests
   false to overall-fail?
   false to stop?
   #mfgcols #mfgtests +  #mfgcols  ?do
      i set-current-sq
      refresh
      d# 200 0 do
         d# 10 ms  key? if  unloop unloop exit  then
      loop
      run-menu-item
      stop?  if unloop exit  then
   loop
   page  overall-fail?  if
      0 1  \ play-item
      [ifdef] show-fail  show-fail  [then]
      ." "(1b)"[;15HSome hardware tests failed. Please review red boxes."
   else
      0 3  \ quit-item
      [ifdef] show-pass  show-pass  [then]
      ." "(1b)"[;28HAll hardware tests passed."
   then
   begin key? while key drop repeat  key drop
   set-default-selection
   refresh
;

false value quit?
: quit-item     ( -- )  true to quit?  menu-done  ;

: init-menu  ( -- )
   ?open-screen  ?open-pointer
   #mfgrows to rows
   #mfgcols to cols
   d# 180 to sq-size
   d# 128 to image-size
   d# 128 to icon-size
   cursor-off
   scroller-off
;

defer test-menu-items

: tiny-menu  ( -- )
   init-menu
   clear-menu
   test-menu-items
;

: full-menu  ( -- )
   tiny-menu

   " Run all non-interactive tests. (Press a key between tests to stop.)"
   ['] play-item     play.icon     0 1 selected install-icon

   " Exit selftest mode."
   ['] quit-item     quit.icon     0 3 install-icon
;

' full-menu to root-menu
' noop to do-title

: autorun-mfg-tests  ( -- )
   ['] run-menu behavior >r
   ['] mfg-test-autorunner to run-menu   \ Run menu automatically
   true to diag-switch?
   ['] tiny-menu ['] nest-menu catch  drop
   r> to run-menu
   false to diag-switch?
   restore-scroller-bg
;

: pause-to-interact
   refresh
   (cr kill-line
   0  d# 30  do
      i d# 10 mod 0=  if  (cr i d# 10 / .d  then
      touchscreen-event?  dup  if  nip nip nip  then  ( touched? )
      mouse-event?  dup  if  nip nip nip  then  or  ( touched-or-moused? )
      key?  or  if                     ( )
	 drop                          ( )
	 menu-interact                 ( )
	 true to quit?
	 unloop exit                   ( -- )
      then                             ( )
      d# 100 ms                        ( )
   -1 +loop
;

: autorun-from-gamekey  ( -- )
   false to quit?
   default-selection set-current-sq
   pause-to-interact
   quit?  if  exit  then
   play-item
   stop?  if  menu-interact exit  then
   quit?  if  exit  then
   menu-interact
;

: gamekey-auto-menu  ( -- )
   ['] run-menu behavior >r
   ['] autorun-from-gamekey to run-menu   \ Run menu automatically after a timeout
   (menu)
   r> to run-menu
;

\ LICENSE_BEGIN
\ Copyright (c) 2009 Luke Gorrie
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
