\ See license at end of file

headers
forth definitions

vocabulary keys-forth
defer skey  ' key is skey  \ Perhaps override with an ekey-based word later

hidden definitions

headerless
tuser keys  ' keys-forth keys token!

d# 32 buffer: name-buf

: add-char-to-string  ( str char -- )
   over ( str char str )
   count dup >r ( str char addr len )
   + c!  ( str )
   r> 1+ swap c!
;
: add-char-to-name  ( str char -- )
   dup bl u<  if    ( str char )  \ control character so translate to ^ form
      over ascii ^ add-char-to-string  ( str char )
      ascii a 1- +  ( str char' )  add-char-to-string
  else
      \ Map the Delete key to the string "del"
      dup d# 127 =  if   drop  " del" rot $cat  exit  then

      \ Map the Unicode Control Sequence Identifier to the string "ESC["
      dup h# 9b =  if   drop  " esc-[" rot $cat  exit  then

      \ Map the out-of-band character into the string "ext"
      dup -1 =   if   drop  " ext" rot $cat  exit  then

      add-char-to-string
  then
;
defer not-found

nuser lastchar		\ most-recently-typed character
nuser beforechar	\ next most-recently-typed character
: do-command  ( prefix-string -- )
   name-buf "copy
   name-buf lastchar @  add-char-to-name
   name-buf count  keys token@ search-wordlist  ( false | cfa true )
   if  execute  else  not-found  then
;

defer printable-char
nuser finished		\ is the line complete yet?

headers
: start-edit  ( bufadr buflen bufmax line# position display? -- )
   is display?   2>r                        ( adr len max r: line#,position )
   is bufmax  is buflen  is buf-start-adr   ( r: line#,position )
   2r> buf-start-adr +  swap  set-line
;
: finish-edit  ( -- length )  buflen  ;
headerless
: edit-command-loop  ( -- )
   open-display redisplay
   finished off
   begin
      lastchar @ beforechar !
      skey lastchar !
      lastchar @
      dup  bl     h# 7e  between
      swap h# a0  h# fe  between  or
      if  lastchar @ printable-char  else  nullstring  do-command  then
      redisplay
   finished @  until
   close-display
;
headerless

: edit-buffer  (s bufadr buflen bufmax line# position -- newlen )
[ifdef] set-window
   accepting?  0=  if
      0 0  display-width display-height  set-window
   then
[then]

   true start-edit

   edit-command-loop

   finish-edit
;
headers
: edit-file  (s addr len maxlen -- newlen )
   0 0 edit-buffer
;
also forth definitions
: edit-line  ( addr len maxlen -- newlen )
   true is accepting?		\ Edit on a single line
   0 0  true start-edit  end-of-line  edit-command-loop  finish-edit  ( len' )
   false is accepting?
;
previous definitions

headerless

d# 512  /tib 2* max  value hbufmax
hbufmax buffer: hbuf-adr
0 value hbuflen
: ensure-line-end  ( -- )
   \ Put a newline at the end of the last line if necessary
   hbuflen  if
      hbuf-adr hbuflen +  1-  c@  newline  <> if
         newline  hbuf-adr hbuflen +  c!
	 hbuflen 1+  is hbuflen
      then
   then
;
: make-room  ( needed -- )
   1+  hbufmax  hbuflen -  -  ( shortfall )
   dup  0>  if                ( shortfall )   \ Too little room at the end
      dup hbuf-adr +  hbuf-adr  hbuflen 3 pick -  move  ( shortfall )
      hbuflen swap - is hbuflen
   else
      drop
   then
\      hbuf-adr over +  hbufmax  rot -    ( adr remaining )
\      hbufmax -rot  bounds  ?do          ( next-line-adr )
\         i c@  newline =  if
\	    drop i 1+  hbuf-adr - leave
\         then
\      loop                               ( shortfall next-line-adr )
\      dup hbuf-adr
   ensure-line-end
;
: open-history  ( needed -- buf len maxlen line# position )
   make-room   ( )
   hbuf-adr  hbuflen  hbufmax  0  hbuflen
;
: xaccept  (s adr len -- actual )
   (interactive? 0=  if  sys-accept exit  then
   tuck dup hbufmax 1-  >  if    ( len adr len )
      0 swap  0 0                ( len adr 0 len 0 0 )
   else                          ( adr len )
      open-history               ( len adr  hbuf hlen hmax line# position )
   then

   true is accepting?
   edit-buffer  is hbuflen       ( len adr )
   false is accepting?

   swap linelen min  tuck        ( len' adr len' )
   line-start-adr  -rot move     ( len' )
;
: new-line-or-done  ( -- )
   accepting?  if
      finished on
      edit-line# -1 < if  ?copyline  then
   else
      new-line
   then
;

: self-insert  ( -- )  lastchar @ insert-character  ;

headers
keys-forth also definitions

: ^f  forward-character  ;
: ^b  backward-character  ;
: ^a  beginning-of-line  ;
: ^c  finished on  ;
: ^e  end-of-line  ;
: ^d  erase-next-character  ;
: ^h  erase-previous-character  ;
: ^i  bl insert-character  ;
: ^j  new-line-or-done  ;
: ^k  kill-to-end-of-line  ;
: ^l  recenter  ;
: ^m  new-line-or-done  ;
: ^n  next-line  ;
: ^o  split-line  ;
: ^p  previous-line  ;
: ^q  quote-next-character  ;
: ^x  finished on  ;		\ XXX for testing on systems where ^C is magic
: ^y  yank  ;

: ^{  key lastchar !  [""] esc- do-command  ;
: esc-o  only forth also definitions  beep beep beep  ;
: esc-h  erase-previous-word  ;
: esc-d  erase-next-word  ;
: esc-f  forward-word  ;
: esc-b  backward-word  ;
: esc-^h  erase-previous-word  ;
: esc-^d  erase-next-word  ;
: esc-^f  forward-word  ;
: esc-^b  backward-word  ;
: esc-del  erase-next-word  ;

\ ANSI cursor keys
: esc-[  key lastchar !  [""] esc-[ do-command  ;
: esc-[A previous-line  ;
: esc-[B next-line  ;
: esc-[C forward-character  ;
: esc-[D backward-character  ;
: esc-[P erase-previous-character  ;

hidden definitions
headerless
: emacs-edit
   ['] beep             is  not-found
   ['] insert-character is  printable-char
   ['] xaccept          is  accept
;
emacs-edit

headers
forth definitions
: init  ( -- )  init  emacs-edit  ;
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
