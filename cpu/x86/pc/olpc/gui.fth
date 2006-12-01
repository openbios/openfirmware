\ See license at end of file
purpose: Graphical display of boot sequence

d# 0  d# 0  2value first-icon-xy
0 0 2value icon-xy
0 value text-y

: show-565  ( image-adr,len -- )
   drop
   dup  " C565" comp  abort" Not in C565 format"
   dup 4 + le-w@  to image-width
   dup 6 + le-w@  to image-height
   8 +
   icon-xy  image-width  image-height
   " draw-rectangle" $call-screen
;

: $get-image  ( filename$ -- true | adr,len false )
   ['] $read-open catch  if  2drop true exit  then  ( )
   ifd @ fsize  dup alloc-mem swap   ( bmp-adr,len )
   2dup  ifd @ fgets  over <>        ( bmp-adr,len error? )
   ifd @ fclose                      ( bmp-adr,len )
   if  free-mem true  else  false  then  ( true | bmp-adr,len false )
;
: $show  ( filename$ -- )
   not-screen?  if  2drop exit  then
   $get-image  if  exit  then  2dup show-565  free-mem
;
: $show&advance  ( filename$ -- )
   0 to image-width   \ In case $show fails
   $show
   icon-xy  image-width 0  d+  to icon-xy
;

: fix-cursor  ( -- )  cursor-on  ['] user-ok to (ok)  user-ok  ;

: .mem  ( -- )  memory-size .d ." MB SDRAM"   ; 

: .pciid   ( vendor-id product-id -- )
   <# u#s drop  [char] , hold u#s u#>		( adr len )
   d# 10					( adr len 10 )
   over						( adr len 10 len ) 
   -						( adr len pad)
   spaces                                       ( adr len )
   type						( )
;

: get-slot-name  ( # -- adr len )
   " /pci" find-package drop			( # phandle )
   " slot-names" rot get-package-property drop	( # adr len )
   decode-int  drop				( # adr len' ) \ Loose mask

   rot 1- 0 ?do
      decode-string 2drop
   loop

   decode-string 2>r 2drop 2r>
;

0 value slot#
false value looking-for-nic?
0 value slot-mask
0 value slot-displayed

: display-this-node  ( phandle -- )

   base @ swap
   hex

   looking-for-nic?  if
      " name" 2 pick get-package-property drop
      decode-string  " ethernet" $= nip nip 0=  if  drop  base !  exit  then
   then

   " reg" 2 pick get-package-property drop decode-int nip nip
   h# 800 / 1 swap lshift
   slot-displayed =  if  drop  base !  exit  then

   >r					( ) ( r: phandle )

   looking-for-nic?  if
      ." NIC: "
   else
      slot# get-slot-name type
   then

\   ."    ID: "

   " vendor-id" r@ get-package-property drop
   decode-int nip nip				( vendor )

   " device-id" r@ get-package-property drop
   decode-int nip nip				( vendor device )

   .pciid					( )

   ."  "
   " name" r@ get-package-property drop
   decode-string type 2drop

   looking-for-nic?  if  ."  in " slot# get-slot-name type  then

   r>  looking-for-nic? 0=  if 
      drop
   else
      " reg" rot get-package-property drop
      decode-int nip nip
      h# 800 / 1 swap lshift to slot-displayed
   then

   cr

   base !
;

: in-mask?  ( base -- flag )
   h# 800 / >r r@			( slot# ) ( r: slot# )
   1 swap lshift slot-mask and		( flag )

   r> over 0=  if  drop exit  then	( flag )

   0 to slot#

   1 swap
   1+ 0 do
      dup slot-mask and  if  slot# 1+ to slot#  then
      1 lshift
   loop
   drop 
;

: display-if-slot  ( phandle -- )
   ?dup 0=  if  exit  then		\ Just in case...

   " reg" 2 pick get-package-property  if  drop exit  then

   decode-int				( phandle prop$ base )
   nip nip				( phandle base )
   in-mask?  if				( phandle )
      display-this-node			( )
   else					( phandle )
      drop				( )
   then					( )
;

: .pci-slots  ( -- )
   " /pci" find-package drop		( phandle.p )	\ It better be there!

   " slot-names" 2 pick			( phandle.p $ phandle.p )
   get-package-property drop		( phandle.p prop$ )
   decode-int nip nip			( phandle.p slot-mask )
   to slot-mask				( phandle.p )

   child				( phandle )	\ First child

   begin				( phandle )
      dup display-if-slot		( phandle )
      peer ?dup	0=			( phandle false | 0 true )
   until
;

: .cpu-data  ( -- )
   " /cpu@0" find-package drop	( phandle )
   " clock-frequency" rot get-package-property  if  exit  then  ( adr )
   decode-int nip nip  d# 1000000 /  ." CPU Speed:  "  .d ."  MHz" cr
;

: .usb  ( -- )
   " /usb" find-package 0=  if  exit  then

   ( phandle )

   child			( phandle.c )

   dup if			( phandle.c )
      ." USB Devices:" cr	( phandle.c )
   else				( 0 )
      drop  exit		( )
   then				( phandle.c )

   begin			( phandle.c )
      dup  " name" rot get-package-property  0=  if
         ."   "  type cr
      then			( phandle.c )
      peer			( phandle.next )
      dup 0=
   until
   drop
;

: .sd  ( -- )
   " /pci/sdhci/disk"  open-dev  ?dup  0=  if
      ." Non-Volatile Memory Module Not Installed" cr  exit
   then

   ( ihandle )
   " size" 2 pick $call-method		( ihandle lo hi )
   rot close-dev			( lo hi )

   drop  d# 100000 /			( 100Ks )
   d# 5 +				( 100Ks' )
   d# 10 /				( MBs )
   .d  ." MB SD memory card" cr
;

false value info-shown?
false value show-sysinfo?

also chords definitions
: f7  ( -- )  true to show-sysinfo?  ;
alias w f7
: f8  ( -- )  true to fru-test?  ;
previous definitions

warning @ warning off
: .chords
   .chords
   " F7   Show System Information" .chord
   " F8   Execute FRU Tests" .chord
;
warning !

: .build-date  ( -- )
   " build-date" $find  if  ." , Built " execute type  else  2drop  then
;
: .sysinfo  ( -- )
   info-shown?  if  exit  then   true to info-shown?
   ." MAC Address: " .enet-addr cr
   .rom .build-date cr
   true to looking-for-nic?  .pci-slots
   .mem cr
   .sd
   false to looking-for-nic?  .pci-slots
   .usb
   .cpu-data cr
;

\ Make the terminal emulator use a region that avoids the logo area
: avoid-logo  ( -- )
   0  h# f                                       ( fg-color bg-color )
   screen-wh drop  char-wh drop  d# 80 *  -  2/  ( fg-color bg-color x )
   text-y                                        ( fg-color bg-color x y )
   char-wh drop d# 80  *                         ( fg-color bg-color x y w )
   screen-wh nip text-y -                        ( fg-color bg-color x y w h )
   set-text-region
;

: debug-net?  ( -- flag )  bootnet-debug  ;

: text-area?  ( -- flag )
   show-sysinfo?  debug-net?  or  user-mode? 0<> or  diagnostic-mode? or
   gui-safeboot?  or  show-chords? or
;

false value error-shown?

: error-banner  ( -- )
   error-shown?  if  exit  then   true to error-shown?

   " rom:error.565" $show&advance

   .sysinfo
;
: visual-error  ( error# -- )
   ['] (.error) is .error
   not-screen?  if  (.error) exit  then   
   restore-output
   error-banner
   0 'source-id !  0 error-source-id !  \ Suppress <buffer@NNNN>: prefix
   user-mode?  if                       ( error# )
      (.error)                          ( )
   else                                 ( error# )
      begin                             ( error# | 0 )
         key?  if                       ( error# | 0 )
            key drop                    ( error# | 0 )
            ?dup  if  (.error) 0  then  ( 0 )
         then                           ( error# | 0 )
      user-mode? until                  ( error# | 0 )
      drop
   then
;

: logo-banner  ( -- error? )
   display?  0=  if  true exit  then

\ Do this later...
\   diagnostic-mode?  0=  if  ['] visual-error to .error  then

   stdout @ to screen-ih

   text-area?  if
      d# 146 to text-y
      first-icon-xy to icon-xy
   else
      null-output
   then

   cursor-off  ['] fix-cursor to (ok)	\ hide text cursor
   avoid-logo
   
   0 to image-width  0 to image-height   \ In case $show-bmp fails
   " rom:olpc.565" $show&advance

   show-sysinfo?  if  .sysinfo  then
   show-chords?  if  " .chords" evaluate  then

   false
;
' logo-banner is gui-banner

[ifdef] resident-packages
dev /obp-tftp
: (configured)  ( -- )  " rom:netconfigured.565" $show  ;
: show-timeout  ( adr len -- )
   2dup (.dhcp-msg)                 ( adr len )
   " Timeout" $=  not-screen? 0=  and  if
      " rom:nettimeout.565" $show
      .sysinfo
   then
;
\ ' show-timeout to .dhcp-msg
\ ' (configured) to configured
device-end
[then]

: show-nand  ( -- )  " rom:nand.565"   $show&advance  ;
: show-disk  ( -- )  " rom:usbkey.565" $show&advance  ;
: show-xo   ( -- )   " rom:xo.565"     $show&advance  ;

: simple-load-started  ( -- )
   not-screen?  if  exit  then
   ['] show-xo to load-done
;
['] simple-load-started to load-started

h# 32 buffer: icon-name

: ?show-icon  ( adr len -- )
   locate-device  0=  if                               ( phandle )
      " icon" 2 pick  get-package-property  0=  if     ( phandle prop$ )
         rot drop                                      ( prop$ )
         $show&advance                                 ( )
      else                                             ( phandle )
         " name" rot  get-package-property  if  exit  then  ( prop$ )
         get-encoded-string                            ( name$ )
         icon-name pack  " .565" rot $cat              ( )
         icon-name count  find-drop-in  0=  if  exit  then  ( adr,len )
         2dup $show&advance release-dropin             ( )
      then                                             ( )
   then                                                ( )
;
: (?show-device)  ( adr len -- ihandle )
   not-screen? 0=  if  2dup ?show-icon  then
;
' (?show-device) to ?show-device

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
