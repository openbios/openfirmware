\ See license at end of file
purpose: Icon definition for demo-only icons

headerless
defer help-bootcmd  ' null$ to help-bootcmd \ Correct value is system-dependent

\ Boot EMACS with the README file displayed.
icon: help.icon       ${BP}/ofw/gui/help.icx
: menu-help  ( -- )
   restore-scroller
   " Starting the EMACS text editor to view the README file ..." progress
   progress-done
   help-bootcmd guarded-boot
   wait-return
;

: help-item  ( -- $ xt adr )
   " View detailed product information with MicroEMACS editor "
   ['] menu-help  help.icon
;

\ Display a brief description of the product.
icon: about.icon      ${BP}/ofw/gui/about.icx
text: about.txt       ${BP}/ofw/gui/aboutpf.txt
: about  ( -- )
   restore-scroller
   about.txt show-pages
   wait-return
;

: about-item  ( -- $ xt adr )
   " Brief description of Power Firmware "
   ['] about  about.icon
;

\ Display the demonstration license terms.
icon: license.icon    ${BP}/ofw/gui/license.icx
text: license.txt     ${BP}/ofw/gui/license.txt
: license  ( -- )
   restore-scroller
   license.txt show-pages
   wait-return
;

: license-item  ( -- $ xt adr )
   " Power Firmware Demonstration License Terms "
   ['] license  license.icon
;

defer emacs-path  ' null$ to emacs-path  \ Correct value is system-dependent

\ Boot the EMACS text editor
icon: emacs.icon      ${BP}/ofw/gui/bt_emacs.icx
: boot-emacs  ( -- )
   restore-scroller
   emacs-path guarded-boot
   wait-return
;

: emacs-item  ( -- $ xt adr )
   " Start the EMACS text editor "
   ['] boot-emacs  emacs.icon
;

\ Background for the icon menu, containing the overall title, logo, etc.

icon: product         ${BP}/ofw/gui/pwr_fwtm.icx
icon: logo            ${BP}/ofw/gui/logo3.icx
icon: demo-ver        ${BP}/ofw/gui/demo-ver.icx

: (title)
   product  d# 16         d# 300 d# 32  centered

   \ because of the interaction between the small "TM" at the end
   \ of "Power Firmware TM" and the small "by" at the beginning of
   \ "by FirmWorks", the logo line looks better if it is drawn a
   \ little to the left of center.
   logo     d# 200 d# 56    d# 200 d# 36  draw-rectangle
[ifdef] demo-version
   demo-ver max-y  text-height 4 * -  d# 450 d# 32  centered
[else]
   0 to version-height
[then]
;
' (title) to do-title
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
