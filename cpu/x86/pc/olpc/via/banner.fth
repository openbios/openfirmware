\ See license at end of file
purpose: Banner customization for this system

headerless


: partition-end  ( name$ -- false | d.end true )
   open-dev  ?dup  if                ( ihandle )
      >r                             ( r: ihandle )
      " offset-low" r@ $call-method  ( offset.low r: ihandle )
      " offset-high" r@ $call-method ( d.offset r: ihandle )
      " size" r@ $call-method        ( d.offset d.size r: ihandle )
      d+                             ( d.end r: ihandle )
      r> close-dev                   ( d.end )
      true                           ( d.end true )
   else                              ( )
      false                          ( false )
   then                              ( false | d.end true )
;

: .storage  ( -- )
   " int:0" partition-end  if    ( d.size )
      d# 200,000,000. d+         ( d.size' )  \ Round up
      d# 1,000,000,000 um/mod    ( rem Gb )
      nip  .d ." GB "            ( )
   else                          ( )
      ." No "                    ( )
   then                          ( )
   ." internal storage"          ( )
;

h# 40 buffer: partition-map
: partition-end  ( offset -- sector# )
   partition-map +  dup le-l@    ( adr start )
   swap la1+ le-l@ +             ( sector# )
;

0 value internal-disk-present?
0. 2value internal-disk-size
0. 2value internal-partition-end

: get-internal-disk-info  ( -- )
   " int:0" open-dev  ?dup  if          ( ihandle )
      true to internal-disk-present?    ( ihandle )
      >r                                                ( r: ihandle )
      " size" r@ $call-method to internal-disk-size     ( r: ihandle )

      h# 1be. " seek" r@ $call-method drop              ( r: ihandle )
      partition-map h# 40 " read" r@ $call-method drop  ( r: ihandle )
      r> close-dev                   ( )

      0                              ( max-sector )
      h# 40 h# 8  do                 ( max-sector )
         i partition-end max         ( max-sector' )
      h# 10 +loop                    ( max-sector' )
      dup 0<  if                     ( max-sector' )
         2drop                       ( )
      else
         d# 512 um* to internal-partition-end
      then
   else                              ( )
      false to internal-disk-present?
   then
;

: .storage  ( -- )
   get-internal-disk-info        ( )
   internal-disk-present?  if    ( )
      internal-disk-size         ( d.size )
      d# 200,000,000.  d+        ( d.size' )  \ Round up
      d# 1,000,000,000 um/mod    ( rem Gb )
      nip  .d ." GB "            ( )
   else                          ( )
      ." No "                    ( )
   then                          ( )
   ." internal storage"          ( )
;

: check-internal-partitions  ( -- )
   internal-disk-present?  0=  if  exit  then     ( )
   internal-partition-end  d0=  if  exit  then    ( )

   internal-disk-size internal-partition-end d<  if    ( )
      red-letters
      ." WARNING!  OS image larger than internal storage device!"  cr
      black-letters
      exit
   then

   internal-partition-end d# 1,000,000,000. d+   internal-disk-size  d<  if
      red-letters
      ." WARNING!  OS image much smaller than internal storage device"  cr
      black-letters
   then
;

: .rom  ( -- )
   ." OpenFirmware  "
   \ push-decimal
   \ major-release (.) type ." ." minor-release (.) type    sub-release type
   \ pop-base
   \ This is the manufacturing signature 
[ifdef] rom-loaded
   h# ffff.ffc0 h# 10 type 
[then]
;

: .ec
   " ec-name" ['] root-node  get-package-property  0=  if  ( adr len )
      get-encoded-string  ." EC Firmware "  type
   then
;

: (xbanner-basics)  ( -- )
   ?spaces  cpu-model type  ." , "   .memory
   ." , " .storage
   ." , S/N "  " SN" find-tag  if  type  else  ." Unknown"  then  cr
   ?spaces  .rom  ."    " .ec  cr
   check-internal-partitions
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
