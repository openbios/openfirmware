purpose: Load USB device fcode driver
\ See license at end of file

hex
headers

false value probemsg?	\ Optional probing messages

\ >tmp$ copies the string to allocated memory.  This is necessary because
\ the loading of a hub driver may cause another driver to be loaded,
\ thus re-entering load-fcodedriver .  The string that class$ returns
\ is in a static area that is overwritten on each call, so it must
\ be copied to a dynamically-allocated place.  It's tempting to
\ apply >tmp$ only to class$, but then the "free-mem" would have
\ to be omitted for strings from super$ and driver$

: >tmp$  ( $1 -- $2 )
   >r r@ alloc-mem    ( name-adr adr r: len )
   tuck r@ move       ( adr r: len )
   r>                 ( adr len )
;

\ $load-driver executes an FCode driver that is stored somewhere
\ other than on the device itself.  This should be defined outside
\ the FCode driver...

\ any-drop-ins? and do-drop-in are fcode driver loading methods in
\ FirmWorks' OpenFirmware implementation.
\ The following code may have to be changed for other OpenFirmware
\ implementation, provided they have a special way of loading fcode
\ driver from system ROM.

\ If any-drop-ins? or do-drop-in is missing, eval will throw an error
\ that will be caught in $load-driver.

: did-drop-in?  ( name$ -- flag )
   2dup  " any-drop-ins?" eval      ( name$ flag )
   0=  if  2drop false  exit  then  ( name$ )

   probemsg?  if                                  ( name$ )
      ." Matched dropin driver "  2dup type  cr   ( name$ )
   then                                           ( name$ )

   " do-drop-in" eval  true
;

: $load-driver  ( name$ -- done? )
   >tmp$            ( name$' )

   2dup ['] did-drop-in?  catch  if  2drop false  then  ( name$' done? )

   -rot  free-mem   ( done? )
;

\ Words to get my (as a child) properties

: get-int-property  ( name$ -- n )
   get-my-property 0=  if  decode-int nip nip  else  0  then
;
: get-class-properties  ( -- class subclass protocol )
   " class"    get-int-property
   " subclass" get-int-property
   " protocol" get-int-property
;
: get-vendor-properties  ( -- vendor product release )
   " vendor-id" get-int-property
   " device-id" get-int-property
   " release"   get-int-property
;

\ Some little pieces for easy formatting of USB name strings

: $hold  ( adr len -- )
   dup  if  bounds swap 1-  ?do  i c@ hold  -1 +loop  else  2drop  then
;

: usb#>   ( n -- )  " usb" $hold  0 u#> ;     \ Prepends: usb
: #usb#>  ( n -- )  u#s drop  usb#>  ;        \ Prepends: usbN
: #,      ( n -- )  u#s drop ascii , hold  ;  \ Prepends: ,N
: #.      ( n -- )  u#s drop ascii . hold  ;  \ Prepends: .N

: ?#,  ( n level test-level -- )   \ Prepends: ,N  if levels match
   >=  if  #,  else  drop  then
;

: device$  ( -- adr len )
   get-vendor-properties drop  		( vendor-id device-id )
   push-hex
   <# #, #usb#>
   pop-base
;

\ Return a string of the form usb,classC[,S[,P]] depending on level
\ Level: 0 -> C   1 -> C,S   2 -> C,S,P
: class$  ( level -- name$ )  
   >r  get-class-properties  r>	      ( class subclass protocol level )
   push-hex                           ( class subclass protocol level )
   <#                                 ( class subclass protocol level )
      tuck                            ( class subclass level protocol level )
      2 ?#,                           ( class subclass level )
      1 ?#,                           ( class )
      u#s " usb,class" $hold          ( )
   u#>
   pop-base
;

: usb-storage?  ( -- flag )
   get-class-properties			( class subclass protocol )
   h# 50 =  rot  8 =  and  if		( subclass )
      dup 2 =  if			\ atapi
         drop  " " " is-atapi" str-property   true
      else
         6 = 				\ scsi
      then
   else
      drop false
   then
;

\ XXX May consider expanding the vendor/product table to include a name field.
\ XXX E.g., usb-net? ( vid did -- false | name$ true )
\ XXX That will support network drivers for drastically differnt chip.

: super$  ( -- name$ )
   get-vendor-properties drop		( vendor-id device-id )
   2dup usb-uart?  if  2drop " usbserial"  exit  then
   usb-net?        if  " usbnet"           exit  then
   usb-storage?    if  " usbstorage"       exit  then
   0 0
;

: load-fcode-driver  ( -- )
   device$ $load-driver  if  exit  then
   super$  $load-driver  if  exit  then

   0 2  do
      i class$ $load-driver  if  unloop exit  then
   -1 +loop
;

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
