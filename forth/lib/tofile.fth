purpose: Redirect the output stream.
\ See license at end of file

\ to-file  \ filename  ( -- )
\    causes output to be temporarily diverted to the named file.
\    The file is created if it doesn't exist, and overwritten if it does.
\    Output is restored to the console just before Forth prompts for a
\    new line of input.
\ append-to-file  \ filename  ( -- )
\    Similar to to-file but if the file already exists, the new stuff is
\    tacked onto the end, rather than overwriting the file.

\ We really need to make the output stream a multi-field structure, and
\ keep a stack of output streams.

only forth also hidden also definitions
variable old-status  ' noop old-status token!
variable old-(emit   ' noop old-(emit  token!
variable old-(type   ' noop old-(type  token!
variable old-cr      ' noop old-cr     token!
variable old-exit?   ' noop old-exit?  token!
variable old-#out    0      old-#out        !
variable old-#line   0      old-#line       !
variable saved-output-valid  saved-output-valid off

forth definitions
: save-output  ( -- )
   ['] status behavior  old-status token!
   ['] (emit  behavior  old-(emit  token!
   ['] (type  behavior  old-(type  token!
   ['] cr     behavior  old-cr     token!
   ['] exit?  behavior  old-exit?  token!
   #out  @  old-#out  !
   #line @  old-#line !
   saved-output-valid on
;
: unsave-output  ( -- )
   saved-output-valid @  if
      old-(emit  token@ is (emit
      old-(type  token@ is (type
      old-status token@ is status
      old-cr     token@ is cr
      old-exit?  token@ is exit?
      old-#out  @ #out  !
      old-#line @ #line !
      saved-output-valid off
   then
;
hidden definitions
: undo-file-output  ( -- )  unsave-output  ofd @ fclose  ;
: file-(emit  ( char -- )   ofd @ fputc  ;
: file-(type ( adr len -- )  ofd @ fputs  ;
: file-cr    ( adr len -- )
   #out off  1 #line +!  newline-string ofd @ fputs
;
forth definitions
: file-output  ( -- )
   save-output
   ['] undo-file-output is status
   ['] file-(emit       is (emit
   ['] file-(type       is (type
   ['] file-cr          is cr
   ['] false            is exit?
   #out off  #line off
;

: to-file  \ filename  ( -- )
   writing  file-output
;
: append-to-file  \ filename  ( -- )
   appending  file-output
;
only forth also definitions

\ LICENSE_BEGIN
\ Copyright (c) 2007 FirmWorks
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
