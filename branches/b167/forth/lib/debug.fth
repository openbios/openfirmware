\ See license at end of file

\ Debugger.  Thanks, Mike Perry, Henry Laxen, Mark Smeder.
\
\ The debugger lets you single step the execution of a high level
\ definition.  To invoke the debugger, type debug xxx where xxx is
\ the name of the word you wish to trace.  When xxx executes, you will
\ get a single step trace showing you the word within xxx that
\ is about to execute, and the contents of the parameter stack.
\ Debugging makes everything run slightly slower, even outside
\ the word being debugged.  see debug-off
\
\ debug name	Mark that word for debugging
\ stepping	Debug in single step mode
\ tracing	Debug in trace mode
\ debug-off	Turn off the debugger (makes the system run fast again)
\ resume	Exit from a pushed interpreter (see the f keystroke)
\
\ Keystroke commands while you're single-stepping:
\   d		go down a level
\   u		go up a level
\   c		continue; trace without single stepping
\   g		go; turn off stepping and continue execution
\   f		push a Forth interpreter;  execute "resume" to get back
\   q		abort back to the top level

only forth also definitions

hex
headerless
variable slow-next?  slow-next? off

only forth hidden also forth also definitions
bug also definitions
variable step? step? on
variable res
headers
: (debug)       (s low-adr hi-adr -- )
   unbug   1 cnt !   ip> !   <ip !   pnext
   slow-next? @ 0=  if
      here  low-dictionary-adr  slow-next
      slow-next? on
   then
   step? on
;
headerless
: 'unnest   (s pfa -- pfa' )
   begin   dup ta1+  swap  token@ ['] unnest =  until
;
: set-<ip  (s pfa -- )
   <ip !  <ip @  ip> @  u>=  if  <ip @  'unnest  ip> !  then
;

false value first-time?
headers
\ Enter and leave the debugger
forth definitions
: defer?  ( acf -- flag )  word-type  ['] key word-type =  ;
: (debug  ( acf -- )
   begin  dup defer?  while  behavior  repeat

   dup colon-cf?  0= abort" Not a colon definition"
   >body dup 'unnest  (debug)  true is first-time?
;
\ Debug the caller
: debug-me  (s -- )  ip@ find-cfa (debug  ;
: debug(  (s -- )  ip@ dup 'unnest (debug)  ;
: )debug  (s -- )  ip@ ip> !  ;
: debug-off (s -- )
   unbug  here  low-dictionary-adr  fast-next slow-next? off
;
bug definitions
headerless
\ Go up the return stack until we find the return address left by our caller
: caller-ip  ( rp -- ip )
   begin
      na1+ dup @  dup  in-dictionary?  if    ( rs-adr ip )
         ip>token token@
         dup ['] execute =  over defer? or  swap <ip @ body> =  or
      else
         drop false
      then
   until                                     ( rs-adr )
   @ ip>token
;
: up1  ( rp -- )
   caller-ip
   dup find-cfa   ( ip cfa )
   dup ['] catch = if  2drop exit  then
   cr ." [ Up to " dup .name ." ]" cr  ( ip cfa )
   over token@ .name                   ( ip cfa )
   >body swap 'unnest (debug)
;
defer to-debug-window  ' noop is to-debug-window
defer restore-window   ' noop is restore-window
: .debug-short-help  ( -- )
  ." Stepper keys: <space> Down Up Continue Forth Go Help ? See $tring Quit" cr
;
: .debug-long-help  ( -- )
   ." Key     Action" cr
   ." <space> Execute displayed word" cr
   ." D       Down: Step down into displayed word" cr
   ." U       Up: Finish current definition and step in its caller" cr
   ." C       Continue: trace current definition without stopping" cr
   ." F       Forth: enter a subordinate Forth interpreter" cr
   ." G       Go: resume normal execution (stop debugging)" cr
   ." H       Help: display this message" cr
   ." ?       Display short list of debug commands" cr
   ." R       RSTrace: Show contents of Forth return stack" cr
   ." S       See: Decompile definition being debugged" cr
   ." $       Display top of stack as adr,len text string" cr
   ." Q       Quit: abandon execution of the debugged word" cr
;
d# 24 constant cmd-column
0 value rp-mark
: to-cmd-column  ( -- )  cmd-column to-column  ;

\ set-package is a hook for Open Firmware.  When Open Firmware is loaded,
\ set-package should be set to a word that sets the active package to the
\ package corresponding to the current instance.  set-package is called
\ by the "F" key, so the user will see the methods of the current instance.
headers
defer   set-package  ' noop is   set-package
defer unset-package  ' noop is unset-package
headerless

: try  ( n acf -- okay? )
   catch  ?dup if  .error drop false  else  true  then
;
: executer  ( xt -- xt' )
   dup ['] execute =  over ['] catch =  or  if  drop dup  then
;
d# 72 constant /#buf
/#buf buffer: #buf-save
variable hld-save
: save#     ( -- )  #-buf /#buf -  #buf-save  d# 72 move    hld @  hld-save !  ;
: restore#  ( -- )  #buf-save  #-buf /#buf -  d# 72 move    hld-save @  hld !  ;
: (trace  ( -- )
   first-time?  if
      ??cr
      ip@  <ip @ =  if  ." : "  else  ." Inside "  then
      <ip @ find-cfa .name
      false is first-time?
      rp@ is rp-mark
   then
   begin
      step? @  if  to-debug-window  then
      save#
      cmd-column 2+ to-column  ." ( " .s ." )" cr   \ Show stack
      restore#

      ['] noop is indent
      ip@ .token drop		  \ Show word name
      ['] (indent) is indent
      to-cmd-column

      step? @  key? or  if
         step? on  res off
         key dup bl <  if  drop bl  then  dup emit  upc
         restore-window
         reset-page
         case
            ascii D  of  ip@ token@ executer  ['] (debug try endof \ Down
	    ascii U  of  rp@ ['] up1 try                     endof \ Up
            ascii C  of  step? @ 0= step? !           true   endof \ Continue
            ascii F  of
               cr ." Type 'resume' to return to debugger" cr
               set-package  interact  unset-package   false
            endof						   \ Forth
            ascii G  of  debug-off  cr  exit                 endof \ Go
            ascii H  of  cr .debug-long-help          false  endof \ Help
            ascii R  of  cr rp0 @ rp@ na1+ (rstrace   false  endof \ RSTrace
            ascii S  of  cr <ip @ body> (see)         false  endof \ See
            ascii ?  of  cr .debug-short-help	      false  endof \ Short Help
            ascii $  of  space 2dup type cr to-cmd-column false endof \ String
            ascii Q  of  cr ." unbug" abort           true   endof \ Quit
            ascii (  of  ip@ set-<ip                  false  endof
            ascii <  of  ip@ ta1+ set-<ip  1 cnt !    false  endof
            ascii )  of  ip@ ip> !  1 cnt !           false  endof
            ascii *  of  ip@ find-cfa dup <ip !  'unnest ip> !  false  endof
            ( default )  true swap
         endcase
      else
         true
      then
   until
   restore#
   ip@ token@  dup ['] unnest =  swap ['] exit =  or  if
      cr  true is first-time?
   then
   pnext
;
' (trace  'debug token!

headers

only forth bug also forth definitions

: debug  \ name (s -- )
   '
   .debug-short-help
   (debug
;
: debugging  ( -- )  ' .debug-short-help  dup (debug  execute  ;
: resume    (s -- )  true is exit-interact?  pnext  ;
: stepping  (s -- )  step? on  ;
: tracing   (s -- )  step? off ;

only forth also definitions

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
