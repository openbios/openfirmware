\ See license at end of file

\ Command completion interface for the Forth line editor

only forth also hidden also command-completion definitions

headerless
: install-fcmd
   ['] end-of-word               is find-end
   ['] insert-character          is cinsert
   ['] erase-previous-character  is cerase
;
install-fcmd

only forth also command-completion also hidden also keys-forth definitions

headers
\ TAB expands, TAB-TAB shows completions
: ^i beforechar @ control i =  if do-show  else  expand-word then  ;	\ tab
: ^` expand-word ;	\ Control-space or control-back-tick
: ^| expand-word ;	\ Control-vertical-bar or control-backslash
: ^} do-show ;		\ Control-right-bracket
: ^? do-show ;		\ Control-question-mark
h# 7f last @ name>string drop 1+ c!   	\ Hack hack

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
