\ See license at end of file
purpose: Graphical display of boot sequence

: ?cleanup  ;

0 0 2value xy
: set-xy  ( x y -- )  to xy  ;

: screen-draw-rectangle  ( adr w h -- )
   xy 2swap " draw-rectangle" $call-screen
;

h# f constant background-color#
d# 16 value next-color#
0 value icon-color#

: screen-erase-rectangle  ( w h -- )
   background-color# -rot xy 2swap " fill-rectangle" $call-screen
;

: prepare-clut  ( adr w h #planes  clut-adr color# #colors -- adr w h #planes )
   2>r >r  2over 2over *  r> 2r>   ( adr w h #planes  adr w h'  clut c#,#c )
   next-color# pack-colors         ( adr w h #planes  adr w h'  clut c#,#c )
   2dup + to next-color#           ( adr w h #planes  adr w h'  clut c#,#c )
   3dup screen-set-colors          ( adr w h #planes  adr w h'  clut c#,#c )
   nip 3 * free-mem                ( adr w h #planes  adr w h' )
   3drop                           ( adr w h #planes )
;
: show-plane  ( adr w h plane# -- )
   #planes min      ( adr w h plane#' )
   -rot  2>r        ( adr plane#  r: w,h )
   2r@ * * +        ( adr' r: w,h )
   2r> screen-draw-rectangle
;
: show-planes  ( adr w h #planes -- )
   dup >r  0  do               ( adr w h )
      3dup  i show-plane       ( adr w h )
      d# 500 ms                ( adr w h )
   loop                        ( adr w h )
   * r> * free-mem
;
: show-bmp  ( bmp-adr,len -- )
   drop bmp>rects              ( adr w h #planes  clut-adr color# #colors )
   prepare-clut                ( adr w h #planes )
   >r  3dup 0  show-plane      ( adr w h r: #planes )
   * r> * free-mem             ( )
;

: $get-bmp  ( filename$ -- true | bmp-adr,len false )
   $read-open                        ( )
   ifd @ fsize  dup alloc-mem swap   ( bmp-adr,len )
   2dup  ifd @ fgets  over <>        ( bmp-adr,len error? )
   ifd @ fclose                      ( bmp-adr,len )
   if  free-mem true  else  false  then  ( true | bmp-adr,len false )
;
: $show-bmp  ( filename$ -- )
   $get-bmp  if  exit  then  2dup show-bmp  free-mem
;
: bmp  ( "name" -- )  safe-parse-word $show-bmp  ;

\ ok 18 screen-color@ rot . swap . .   \ 107  99 165 
\ ok 19 screen-color@ rot . swap . .   \ 123 115 177 
\ ok 20 screen-color@ rot . swap . .   \ 132 123 181 
: fix-cursor  ( -- )  cursor-on  ['] user-ok to (ok)  user-ok  ;

d# 292  d# 300  2value name-xy
0 0 2value first-icon-xy
0 0 2value icon-xy
0 0 2value logo-xy
d# 486 constant text-y

: position-icons  ( -- )
   name-xy  d#  400  d#  0  d+  to first-icon-xy
   first-icon-xy             to icon-xy

   name-xy  d#  200  d#  0  d+  to logo-xy
;
position-icons

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

0 value images
: free-images  ( -- )
   images  if
      images  image-width image-height *  #planes *  free-mem
      0 to images
   then
;

false value error-shown?
: visible-icons  ( -- )
   0 screen-color@  icon-color# 1+ screen-color!
;

: error-banner  ( -- )
   visible-icons
   error-shown?  if  exit  then   true to error-shown?

   logo-xy set-xy  " rom:error.bmp" $show-bmp

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
   free-images
;

\ Make the terminal emulator use a region that avoids the logo area
: avoid-logo  ( -- )
   0  h# f                 ( fg-color bg-color )
   screen-wh drop  char-wh drop  d# 80 *  -  2/  ( fg-color bg-color x )
   text-y                                        ( fg-color bg-color x y )
   char-wh drop d# 80  *                         ( fg-color bg-color x y w )
   screen-wh nip text-y -                        ( fg-color bg-color x y w h )
   set-text-region
;

-1 value logo-color#
: reset-colors  ( -- )
   logo-color# -1 =  if
      next-color# to logo-color#
   else
      logo-color# to next-color#
   then
;

: gui-cleanup  ( -- )
   ?cleanup
   not-screen?  if  exit  then
   reset-colors
   first-icon-xy to icon-xy
;

: debug-net?  ( -- flag )  bootnet-debug  ;

: text-area?  ( -- flag )
   show-sysinfo?  debug-net?  or  user-mode? 0<> or  diagnostic-mode? or
   gui-safeboot?  or  show-chords? or
;

: logo-banner  ( -- error? )
   display?  0=  if  true exit  then

   ['] gui-cleanup  to cleanup

\ Do this later...
\   diagnostic-mode?  0=  if  ['] visual-error to .error  then

   stdout @ to screen-ih

   text-area?  if
      d# 0 d#  0 to name-xy
      d# 176 to text-y
      position-icons
   else
      null-output
   then

\   0 6 at-xy
   cursor-off  ['] fix-cursor to (ok)	\ hide text cursor
   avoid-logo
   
   0 to image-width  0 to image-height   \ In case $show-bmp fails
   name-xy set-xy
   " rom:myname.bmp" $show-bmp

   next-color# to icon-color#

\    color# screen-color@  d# 15  screen-color!  \ Change background
\    d# 255  d# 255 d# 255  d#  0  screen-color!  \ Make text foreground white

   show-sysinfo?  if  .sysinfo  then
   show-chords?  if  " .chords" evaluate  then

   false
;
' logo-banner is gui-banner

0 0 2value last-icon

: ?erase-icon  ( -- )
   last-icon drop  if  icon-xy set-xy  last-icon screen-erase-rectangle  then
;

: image  ( image# -- )
   not-screen?  images 0= or  if  drop exit  then
   dup  #planes >=  if  drop exit  then
   logo-xy set-xy
   >r  images  image-width  image-height  r> show-plane
;

: timeout-banner  ( -- )
   5 image
   .sysinfo
;

false value animate?
: (configured)  ( -- )
   animate? 0=  not-screen?  or  if  exit  then  1 image
;

[ifdef] resident-packages
dev /obp-tftp
fload ${BP}/cpu/x86/pc/olpc/guitftp.fth
device-end
[then]

0 value last-progress
2 value image#
: animate  ( adr -- adr )
   not-screen?  if  show-meter exit  then
   dup last-progress u<  if  dup to last-progress  then  ( adr )
   dup last-progress -  h# 2.0000 >=  if                 ( adr )
      dup to last-progress                               ( adr )
      image# 1 xor  to image#                            ( adr )
      image# image
   then
;

: (load-done)  ( -- )
   4 image  free-images  restore-output
   false to animate?
;

: enable-animation  ( -- )
   diagnostic-mode?  0=  if  ['] visual-error to .error  then
   ['] animate to show-progress
   ['] (load-done) to load-done
;

: (load-started)  ( -- )
   not-screen?  if  exit  then
   enable-animation
   ?erase-icon
   free-images
   0 to #planes  0 to images
   " rom:oslogo.bmp" $get-bmp  if  exit  then  ( bmp$ )

   2dup  drop bmp>rects                   ( bmp$  adr w h #planes  clut c# #c )
   prepare-clut                           ( bmp$  adr w h #planes )
   to #planes                             ( bmp$  adr w h )
   to image-height  to image-width        ( bmp$  adr )
   to images                              ( bmp$ )
   free-mem
   0 image
   true to animate?
;
['] (load-started) to load-started

true value spread-icons?
: show-icon  ( bmp$ -- )
   spread-icons?  if
      icon-xy set-xy
      icon-color# to next-color#
      show-bmp
      icon-xy  image-width 0  d+  to icon-xy
   else
      ?erase-icon
      logo-xy  4  d# 40  d+  to icon-xy
      icon-xy set-xy show-bmp
      image-width image-height to last-icon
   then
;

h# 32 buffer: icon-name

: ?show-icon  ( adr len -- )
   locate-device  0=  if                               ( phandle )
      " icon" 2 pick  get-package-property  0=  if     ( phandle prop$ )
         rot drop                                      ( prop$ )
         show-icon                                     ( )
      else                                             ( phandle )
         " name" rot  get-package-property  if  exit  then  ( prop$ )
         get-encoded-string                            ( name$ )
         icon-name pack  " .bmp" rot $cat              ( )
         icon-name count  find-drop-in  0=  if  exit  then  ( adr,len )
         2dup show-icon release-dropin                 ( )
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
