\ See license at end of file
purpose: Icon layout for OS items

headerless
: install-install-menu  ( -- )
   clear-menu

[ifdef] nt-ide-item
   nt-ide-item   1 1  selected  install-icon
   nt-scsi-item  1 2 install-icon
[then]

[ifdef] macos-to-rom
   macos-rom-item  0 1  selected  install-icon
\   macos-disk-item 0 2            install-icon
[then]

   " Exit to previous menu "
   ['] menu-done           exit.icon    2  cols 1-  install-icon
;

icon: install.icon      ${BP}/ofw/gui/install.icx
: installation-menu  ( -- )  ['] install-install-menu nest-menu  ;

: os-items  ( -- )

[ifdef] nt-item
   nt-item  0 1  selected  install-icon
[then]

[ifdef] macos-item
\   macos-present?  if
      macos-item 0 2  selected  install-icon
\   then
[then]

[ifdef] aix-item
   aix-item 0 2 install-icon
[then]

   " Menu: Install Operating Systems "
   ['] installation-menu  install.icon  0 3 install-icon
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
