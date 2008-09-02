\ See license at end of file
purpose: Banner customization for this system

headerless

: show-speeds  ( -- )
   \ Round so the numbers come out the way they are conventionally cited
   ." CPU "     cpu-speed d# 1,000,000 rounded-/ .d  ." MHz, "
   ." Memory "   gl-speed d# 1,000,000         / .d  ." MHz, "
   ." PCI "     pci-speed d# 1,000,000         / .d  ." MHz" cr
;
' show-speeds to banner-extras

: .rom  ( -- )
   ." OpenFirmware  "
   push-decimal
   major-release (.) type ." ." minor-release (.) type    sub-release type
   pop-base
[ifdef] bzimage-loaded
   ." booted from disk - " .built
[then]
;

: (xbanner-basics)  ( -- )
   ?spaces  cpu-model type  ." , "   .memory  ." , "  .rom cr
;
' (xbanner-basics) to banner-basics

' (banner-warnings) to banner-warnings


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
