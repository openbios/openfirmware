\ See license at end of file
purpose: Handle various kinds of entries into Forth from traps, etc.

headerless
: .go-message  ( -- )
   \ Restarting is only possible if the state that was first saved
   \ is from a restartable exception.
   state-valid @  -1 =  already-go? and  if
      restartable? on
      ." Type  'go' to resume" cr
   then
;

: .entry  ( -- )
   talign		\ ... in case dp is misaligned

   aborted? @  if
      aborted? off  hex cr  ." Keyboard interrupt" cr  .go-message   exit
   then

   [ also hidden ] (.exception) [ previous ]
;

headers
stand-init:
   ['] .entry is .exception
;

\ Temporary hacks until we implement these functions correctly

defer user-interface ' quit to user-interface
also client-services definitions
\ " reenter.fth: Implement 'exit' client service correctly" ?reminder
: exit  ( -- )
   [ also hidden ] breakpoints-installed off  [ previous ]
   [ifdef] vector  vector off  [then]

   " restore"  stdout @  ['] $call-method  catch  if  3drop  then
   " restore"  stdin  @  ['] $call-method  catch  if  3drop  then

   user-interface
;
: enter  ( -- )  interact  ;
previous definitions

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
