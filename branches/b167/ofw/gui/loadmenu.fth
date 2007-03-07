\ See license at end of file
purpose: Load file for icon menu GUI

fload ${BP}/ofw/gui/nullio.fth		        \ Discard console output
fload ${BP}/ofw/gui/graphics.fth		\ Low-level graphics
fload ${BP}/ofw/gui/mouse.fth			\ Mouse tracking
fload ${BP}/ofw/gui/dialog.fth			\ GUI dialogs
fload ${BP}/ofw/gui/button.fth			\ GUI buttons and alerts
fload ${BP}/ofw/gui/iconmenu.fth		\ Generic GUI code
fload ${BP}/ofw/gui/menumisc.fth		\ Menu item helpers
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
