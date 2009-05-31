\ See license at end of file
purpose: Icon menu screen layout for Power Firmware demonstration version

\ fload ${BP}/ofw/gui/macosi.fth	\ Boot/install MacOS items
\ fload ${BP}/ofw/gui/nti.fth		\ Boot/install NT items
\ fload ${BP}/ofw/gui/aixi.fth		\ Boot AIX item

: boot-configure ;
fload ${BP}/ofw/gui/linuxi.fth		\ Boot Linux item
\ fload ${BP}/ofw/gui/osi.fth		\ Install OS items

fload ${BP}/ofw/gui/demoi.fth		\ Demo license items and background
\ fload ${BP}/ofw/gui/confvari.fth	\ Configuration variables item
fload ${BP}/ofw/gui/configur.fth	\ Configuration variables item
fload ${BP}/ofw/gui/showdevi.fth	\ Show device tree item
fload ${BP}/ofw/gui/flashi.fth		\ FLASH programming submenu
fload ${BP}/ofw/gui/forthi.fth		\ Forth item
fload ${BP}/ofw/gui/restarti.fth	\ Restart system item

headerless
\ Install the icons that comprise the main menu for the Open Firmware
\ demonstration program.

: demo-menu  ( -- )
   clear-menu

   about-item     2  0  selected  install-icon
   license-item   2  1            install-icon
   help-item      2  2            install-icon	\ Requires EMACS client

   restart-item   2  3            install-icon
   forth-item     2  cols 1-      install-icon

   config-item    1  0            install-icon
   showdevs-item  1  1            install-icon
   flash-item     1  2            install-icon

\  emacs-item     0  0            install-icon	\ Requires EMACS client
\   os-items					\ In row 0
   linux-item     0  0            install-icon	\ In row 0

\   " Menu: Install Operating Systems "
\   ['] installation-menu  install.icon  0 3 install-icon
;

' demo-menu to root-menu

\ Install the menu system as the preferred user interface
' menu-or-quit to user-interface
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
