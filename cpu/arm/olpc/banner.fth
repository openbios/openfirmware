\ See license at end of file
purpose: Banner customization for this system

headerless

[ifdef] get-partition-from-driver
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
      d# 500,000,000. d+         ( d.size' )  \ Round up
      d# 1,000,000,000 um/mod    ( rem Gb )
      nip  .d ." GB "            ( )
   else                          ( )
      ." No "                    ( )
   then                          ( )
   ." internal storage"          ( )
;
[then]

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
   internal-disk-present? 0=  if ( )
      get-internal-disk-info     ( )
   then
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
      cancel
   then
;

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
   " ec-name" root-phandle  get-package-property  0=  if  ( adr len )
      get-encoded-string  ." EC Firmware "  type
   then
;

: .cpu-speed  ( -- )
   pj4-speed
   dup d# 988 =  if ." 1 GHz" else .d ." MHz" then
;

: .memory-brief  ( -- )
   memory-size dup d# 1024 / ?dup  if  ( mb gb )
      nip " GiB" rot                   ( gb$ gb )
   else                                ( mb )
      " MiB" rot                       ( mb$ mb )
   then                                ( m$ m )
   .d  type ."  memory"                ( )
;

: check-tags  ( -- )
   " TS" find-tag  if  ?-null  " SHIP" $=  if  exit  then
      red-letters
      ." WARNING!  TS tag is not SHIP"  cr
      cancel
   then
;

: (xbanner-basics)  ( -- )
   ?spaces  cpu-model type  ." , " .cpu-speed  ." , "   .memory-brief
   ." , " .storage
   ." , S/N "  " SN" find-tag  if  ?-null type  else  ." Unknown"  then  cr
   ?spaces  .rom  ."    " .ec  ."    " .clock
   check-internal-partitions
   check-tags
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
