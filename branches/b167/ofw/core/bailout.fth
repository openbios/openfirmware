\ See license at end of file
purpose: Interrupt or modify startup sequence by keyboard command

headerless
false value early-interact?
false value show-chords?
defer .chord-prefix
\ : alt-prefix  ." ALT-"  ;
\ ' alt-prefix to .chord-prefix
' noop to .chord-prefix
: .because  ( adr len -- )  cr type  ."  because of keyboard command." cr  ;
: .chord  ( adr len -- )  .chord-prefix  type cr  ;

vocabulary chords
also chords definitions
headers
: f1  ( -- )  " .chords" evaluate  true to show-chords?  ;
: f2  ( -- )
   " Suppressing auto-boot" .because  ['] true to interrupt-auto-boot?
;
: f3  ( -- )  " Setting network debugging switch" .because  debug-net  ;
: f4  ( -- )  " Setting diag-switch?" .because   true to diag-switch?  ;
: f5  ( -- )  " Resetting NVRAM to default values" .because  set-defaults  ;
: f6  ( -- )  true to early-interact?  ;
alias h f1
alias a f2
alias b f3
alias d f4
alias n f5
alias f f6
alias break f2

headerless
previous definitions

\ Systems that add new chords can chain (.chords)
: .chords  ( -- )
   " F1   Show this message"          .chord
   " F2   Don't auto-boot"            .chord
   " F3   Debug net booting"          .chord
   " F4   Set diagnostic mode"        .chord
   " F5   Restore NVRAM to defaults"  .chord
   " F6   Enter Forth before probing" .chord
;

: key>string  ( byte -- adr len )
   \ -1 as a key value means the keyboard-dependent interrupt key
   dup -1 =  if  drop " break" exit  then

   \ Numbers 81, 82, ... mean the F1, F2, ... keys
   dup h# 80 >  if
      [char] f string2 c!  h# 80 -  [char] 0 +  string2 1+ c!
      string2 2
   else
      string2 c!
      string2 1
   then
;

headers
: ?bailout  ( -- )
   " keyboard" open-dev  ?dup  if  close-dev  else  exit  then

   security-on?  if  exit  then

   " keyboard" " initial-key?" execute-device-method  if
      if         ( char )   \ CTRL-ALT-something was typed
         key>string  ['] chords  search-wordlist  if
            execute
         else
            [ also chords ]  h  [ previous ]
         then
      then
   then
;
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
