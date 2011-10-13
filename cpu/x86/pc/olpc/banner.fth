\ See license at end of file
purpose: Banner customization for this system

headerless

: ofw-model$  ( -- adr len )
   " /openprom" find-package drop  ( phandle )
   " model" rot get-package-property  if  ( )
      " ???   ?????  ???"          ( adr len )
   else                            ( adr len )
      decode-string 2nip           ( adr len' )
   then                            ( adr len )
;
: ofw-version$  ( -- adr len )
   ofw-model$ drop 6 +  7  -trailing
;
: .rom  ( -- )
   ." OpenFirmware  "  ofw-version$ type
;

: .ec
   " ec-name" ['] root-node  get-package-property  0=  if  ( adr len )
      get-encoded-string  ." EC Firmware "  type
   then
;

: (xbanner-basics)  ( -- )
   ?spaces  cpu-model type  ." , "   .memory
   ." , S/N "  " SN" find-tag  if  type  else  ." Unknown"  then  cr
   ?spaces  .rom  ."    " .ec  cr
;
' (xbanner-basics) to banner-basics

' (banner-warnings) to banner-warnings

: stop-auto?  ( -- flag )  idprom-valid? 0=  auto-boot?  and ;

defer gui-banner  ' true to gui-banner
: ?gui-banner  ( -- )
   stop-auto?  if  suppress-auto-boot  then

   gui-banner drop
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
