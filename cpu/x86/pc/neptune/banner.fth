\ See license at end of file
purpose: Banner customization for this system

headerless

: geode-print-pll ( -- )
   ." Geode CPU Speed "
   h# 4c00.0014 rdmsr swap drop
   h# 3E and 2/
   1 + d# 66 * 2/ decimal . cr

   ." GeodeLink Speed "
   h# 4c00.0014 rdmsr swap drop
   h# FFF and 7 >>
   1 + d# 66 * 2/ decimal . cr

   ." PCI Speed "
   h# 4c00.0014 rdmsr drop
   1 7 << and
   0= if d# 33 . else d# 66 . then cr

   hex
;
' geode-print-pll to banner-extras

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
   ?spaces  cpu-model type  ." , "   .memory  cr
   ?spaces  .rom cr
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
