\ See license at end of file
purpose: Icon definition for FLASH programming item

headerless

: eject-floppy  ( -- )
   " eject" $find  if	        ( xt )
      catch drop		( )
   else				( adr len )
      2drop			( )
   then				( )
;

icon: save-flash.icon      ${BP}/ofw/gui/flsh2flp.icx
: save-flash-item     ( -- )  emphasize save-flash eject-floppy highlight  ;

icon: restore-flash.icon   ${BP}/ofw/gui/flp2flsh.icx
: restore-flash-item  ( -- )  emphasize restore-flash eject-floppy highlight  ;

[ifdef] net-flash
icon: net-flash.icon       ${BP}/ofw/gui/net2flsh.icx
: net-flash-item  ( -- )
   emphasize  net-flash  highlight
;
[then]

icon: flash.icon           ${BP}/ofw/gui/flasht.icx
: install-flash-menu  ( -- )
   clear-menu

   " Copy the FLASH ROM contents to diskette "
   ['] save-flash-item     save-flash.icon     1 1  selected  install-icon

   " Program the FLASH ROM from a diskette file "
   ['] restore-flash-item  restore-flash.icon  1 2  install-icon
   
[ifdef] net-flash
   " Program the FLASH ROM from the network "
   ['] net-flash-item      net-flash.icon      1 3  install-icon
[then]
   
   " Exit to previous menu "
   ['] menu-done           exit.icon    2  cols 1-  install-icon
;

: flash-menu  ( -- )  ['] install-flash-menu nest-menu  ;

: flash-item  ( -- $ xt adr )
   " Menu: Program the FLASH ROM "
   ['] flash-menu  flash.icon
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
