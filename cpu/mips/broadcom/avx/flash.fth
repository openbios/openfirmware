purpose: Setup for Flash ROM access
copyright: Copyright 1995-2001 Firmworks.  All Rights Reserved.

h# 10.0000 to /flash

\  Flash usage:
\    bfc0.0000-bfc5.ffff	backup ofw	(hardware protected)
\    bfc7.0000-bfc7.ffff	fixed VPD	(hardware protected)
\    bfc8.0000-bfcd.ffff	new ofw
\    bfcf.0000-bfcf.ffff	variable VPD
\    bfce.0000-bfce.ffff	temp nvram	(hardware protected eventually)

h# 0.0000 constant ofw-b-offset
h# 8.0000 constant ofw-offset
h# 7.0000 constant vpd-f-offset
h# f.0000 constant vpd-v-offset

/rom constant /ofw
[ifdef] use-flash-nvram
h# 1.0000 constant /nvram
h# e.0000 constant nvram-offset 
/nvram to config-size
[then]
h# 1.0000 constant /vpd
/vpd to vpd-size

0 value flashbase
0 value fixed-vpd-node
0 value var-vpd-node

headerless
: (fctl!)   ( n a -- )  flashbase +  rb!  ;  ' (fctl!)  to fctl!
: (fdata!)  ( n a -- )  flashbase +  rb!  ;  ' (fdata!) to fdata!
: (fc@)     ( a -- n )  flashbase +  rb@  ;  ' (fc@)    to fc@

headers
: open-flash  ( -- )
   rom-pa /flash  root-map-in  to flashbase
;
: close-flash  ( -- )
   flashbase /flash  root-map-out  0 to flashbase
;
' open-flash to enable-flash-writes

\ flash update words
0 value flash-offset
0 value /max-image
: ?partial-programmable  ( len -- len )
   dup /max-image >  if
      collect(
      ." Image is too big." cr
      )collect alert
      abort
   then
   flash-offset over ['] ?partial-protected  catch  throw
;
: partial-erase-flash  ( len -- len )  flash-offset over partial-erase  ;
: partial-program-flash  ( adr len -- )  flash-offset swap write-bytes  ;
: partial-verify-flash  ( adr offset len -- )  nip flash-offset swap verify-bytes  ;

' ?partial-programmable to ?programmable
' partial-erase-flash to erase-flash
' partial-program-flash to program-flash
' partial-verify-flash to verify-flash

\ OFW update words
: use-ofw  ( -- ) 		\ Update primary OFW
   ofw-offset to flash-offset
   /ofw to /max-image
;

: use-backup-ofw  ( -- )	\ Update backup OFW, R/O on AVX product
   ofw-b-offset to flash-offset
   /ofw to /max-image
;

\ VPD update words
: use-var-vpd  ( -- )		\ Update variable VPD
   vpd-v-offset to flash-offset
   /vpd to /max-image
;

: use-fixed-vpd  ( -- )		\ Update fixed VPD, R/O on AVX product
   vpd-f-offset to flash-offset
   /vpd to /max-image
;

[ifdef] use-flash-nvram
: use-nvram  ( -- )		\ Update backup flash-based nvram
   nvram-offset to flash-offset
   /nvram to /max-image
;
[then]

0 0 rom-pa <# u#s u#>  " /" begin-package
   " flash" device-name
   /flash value /device
   my-address my-space /device reg
   1 " #address-cells" integer-property

   : decode-unit  ( adr len -- phys )  push-hex  $number  if  0  then  pop-base  ;
   : encode-unit  ( phys -- adr len )  push-hex  (u.)  pop-base  ;

   : map-in  ( offset size -- virt )
      >r >r  my-address my-space r> + r> " map-in" $call-parent
   ;
   : map-out  ( virt size -- )  " map-out" $call-parent  ;
   : open  ( -- flag )  true  ;
   : close  ( -- )  ;

new-device
   0 0 vpd-f-offset <# u#s u#>  set-args
   " vpd-fixed" device-name
   my-address my-space /vpd reg
   /vpd value /device
   fload ${BP}/cpu/mips/broadcom/avx/vpdflash.fth

   : write  ( adr len -- )
      use-fixed-vpd clip-size (flash)
   ;
finish-device

new-device
   0 0 vpd-v-offset <# u#s u#>  set-args
   " vpd-var" device-name
   my-address my-space /vpd reg
   /vpd value /device
   fload ${BP}/cpu/mips/broadcom/avx/vpdflash.fth

   : write  ( adr len -- )
      use-var-vpd clip-size (flash)
   ;
finish-device

[ifdef] use-flash-nvram
new-device
   0 0 nvram-offset <# u#s u#>  set-args
   " flash-nvram" device-name
   /nvram value /device
   my-address my-space /nvram reg
   fload ${BP}/cpu/mips/broadcom/avx/vpdflash.fth

   0 value nvram-buf
   : write  ( adr len -- len )
       use-nvram
       clip-size		( len' adr len' )
       seek-ptr >r		( len adr len )  ( R: offset )
       /device alloc-mem >r	( len adr len )  ( R: offset buf )
       0 0 seek drop		( len adr len )  ( R: offset buf )
       r@ /device read drop	( len adr len )  ( R: offset buf )
       r@ -rot r> r> + swap move ( len buf )
       dup /device (flash)	( len buf )
       /device free-mem		( len )
   ;
finish-device
[then]

new-device
   0 0 ofw-b-offset <# u#s u#>  set-args
   " ofw" device-name
   /rom value /device
   my-address my-space /device reg
   1 " #address-cells" integer-property

   : decode-unit  ( adr len -- phys )  push-hex  $number  if  0  then  pop-base  ;
   : encode-unit  ( phys -- adr len )  push-hex  (u.)  pop-base  ;

   : map-in  ( offset size -- virt )
      >r >r  my-address my-space r> + r> " map-in" $call-parent
   ;
   : map-out  ( virt size -- )  " map-out" $call-parent  ;
   : open  ( -- flag )  true  ;
   : close  ( -- )  ;

   new-device
      0 0 /resetjmp <# u#s u#>  set-args
      " dropins" device-name
      /rom /resetjmp - value /device
      my-address my-space /device reg
      fload ${BP}/dev/flashpkg.fth
   finish-device

finish-device

new-device
   0 0 ofw-offset <# u#s u#>  set-args
   " ofw" device-name
   /rom value /device
   my-address my-space /device reg
   1 " #address-cells" integer-property

   : decode-unit  ( adr len -- phys )  push-hex  $number  if  0  then  pop-base  ;
   : encode-unit  ( phys -- adr len )  push-hex  (u.)  pop-base  ;

   : map-in  ( offset size -- virt )
      >r >r  my-address my-space r> + r> " map-in" $call-parent
   ;
   : map-out  ( virt size -- )  " map-out" $call-parent  ;
   : open  ( -- flag )  true  ;
   : close  ( -- )  ;

   new-device
      0 0 /resetjmp  <# u#s u#>  set-args
      " dropins" device-name
      /rom /resetjmp - value /device
      my-address my-space /device reg
      fload ${BP}/dev/flashpkg.fth
   finish-device

finish-device

end-package

0 value ofw-b-node	' ofw-b-node     " ofw-backup" chosen-value
0 value ofw-a-node	' ofw-a-node     " ofw-active" chosen-value
0 value fixed-vpd-node  ' fixed-vpd-node " vpd-fixed"  chosen-value
0 value var-vpd-node    ' var-vpd-node   " vpd-var"    chosen-value

stand-init: rom chosen
   ofw-b-offset <# u#s " /ofw@" hold$ u#> open-dev to ofw-b-node
   push-hex
   " rom"  myrombase rom-pa - <# " /dropins" hold$ u#s " /ofw@" hold$ u#>  $devalias
   pop-base
   myrombase rom-pa =  if
      ofw-b-node
   else
      ofw-offset <# u#s " /ofw@" hold$ u#> open-dev
   then
   to ofw-a-node
;

[ifdef] use-flash-nvram
stand-init: NVRAM
   flash-type 1 = swap h# 37 = and  if
      ." NVRAM in flash" cr
      " /flash-nvram" open-dev to nvram-node
      nvram-node 0=  if
         ." The flash-based NVRAM is not working." cr
      then
      ['] init-config-vars catch drop
   else
      0 to config-size
      ." No NVRAM" cr
   then
;
[then]

stand-init: VPDs
   flash-type 1 = swap h# 37 = and  if
      ." VPDs in flash" cr
      " /vpd-var" open-dev dup to var-vpd-node to vpd-node
      vpd-node 0=  if
         ." The variable VPD is not working." cr
      then
      ['] init-vpd-buffer catch drop
      " /vpd-fixed" open-dev dup to fixed-vpd-node to vpd-node
      vpd-node 0=  if
         ." The fixed VPD is not working." cr
      then
      ['] init-vpd-buffer catch drop
   else
      0 to vpd-size
      ." No VPDs" cr
   then
;

\ Words to toggle the view between the two VPDs.
: select-fixed-vpd  ( -- )
   fixed-vpd-node to vpd-node
   init-vpd-buffer
;

: select-var-vpd  ( -- )
   var-vpd-node to vpd-node
   init-vpd-buffer
;

