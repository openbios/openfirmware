\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: fdcpkg.fth
\ 
\ Copyright (c) 2006 Sun Microsystems, Inc. All Rights Reserved.
\ 
\  - Do no alter or remove copyright notices
\ 
\  - Redistribution and use of this software in source and binary forms, with 
\    or without modification, are permitted provided that the following 
\    conditions are met: 
\ 
\  - Redistribution of source code must retain the above copyright notice, 
\    this list of conditions and the following disclaimer.
\ 
\  - Redistribution in binary form must reproduce the above copyright notice,
\    this list of conditions and the following disclaimer in the
\    documentation and/or other materials provided with the distribution. 
\ 
\    Neither the name of Sun Microsystems, Inc. or the names of contributors 
\ may be used to endorse or promote products derived from this software 
\ without specific prior written permission. 
\ 
\     This software is provided "AS IS," without a warranty of any kind. 
\ ALL EXPRESS OR IMPLIED CONDITIONS, REPRESENTATIONS AND WARRANTIES, 
\ INCLUDING ANY IMPLIED WARRANTY OF MERCHANTABILITY, FITNESS FOR A 
\ PARTICULAR PURPOSE OR NON-INFRINGEMENT, ARE HEREBY EXCLUDED. SUN 
\ MICROSYSTEMS, INC. ("SUN") AND ITS LICENSORS SHALL NOT BE LIABLE FOR 
\ ANY DAMAGES SUFFERED BY LICENSEE AS A RESULT OF USING, MODIFYING OR 
\ DISTRIBUTING THIS SOFTWARE OR ITS DERIVATIVES. IN NO EVENT WILL SUN 
\ OR ITS LICENSORS BE LIABLE FOR ANY LOST REVENUE, PROFIT OR DATA, OR 
\ FOR DIRECT, INDIRECT, SPECIAL, CONSEQUENTIAL, INCIDENTAL OR PUNITIVE 
\ DAMAGES, HOWEVER CAUSED AND REGARDLESS OF THE THEORY OF LIABILITY, 
\ ARISING OUT OF THE USE OF OR INABILITY TO USE THIS SOFTWARE, EVEN IF 
\ SUN HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
\ 
\ You acknowledge that this software is not designed, licensed or
\ intended for use in the design, construction, operation or maintenance of
\ any nuclear facility. 
\ 
\ ========== Copyright Header End ============================================
purpose: Floppy disk package.
copyright: Copyright 1990 Sun Microsystems, Inc.  All Rights Reserved

headers
1 encode-int " #address-cells" property
0 encode-int " #size-cells" property
: decode-unit  ( adr len -- n )  push-hex  $number  if  0  then  pop-base  ;
: encode-unit  ( n -- adr len )  push-hex  (u.)  pop-base  ;
: open   ( -- flag )  fdc-init  true  ;
: reset  ( -- )  fdc-init  unmap-floppy  ;
: close  ( -- )  unmap-floppy  ;
: set-address  ( dev# -- )  to drive  ;
: probe  ( -- )
   2  0  do
      i set-address  drive-present?  if
         " /fdc/disk" find-package  if
             push-package
                \ "i" must be executed outside of package( ... )package,
                \ which uses the return stack
                i  0 package(  encode-int  " reg" property  )package
             pop-package
         then
      then
   loop
;

\ We set both the block size and the maximum transfer size to one cylinder.
\ Reading a cylinder at a time improves the performance dramatically
\ compared to reading a block at at a time.
\ XXX: Override these values if the installed drive isn't 3.5-inch 1.44MB.
: sec/cyl       ( -- n )  sec/trk 2*  ;
: max-transfer  ( -- n )  h# 200 sec/cyl *  ;
\ : block-size    ( -- n )  max-transfer  ;
\ : #blocks       ( -- n )  d# 80  ;	\ For 1.44 MByte floppies
: block-size    ( -- n )  h# 200  ;
: #blocks       ( -- n )  d# 80 sec/cyl * ;	\ For 1.44 MByte floppies

new-device
" disk" device-name
" block" device-type

headerless
0 instance value deblocker
: init-deblocker  ( -- okay? )
   " "  " deblocker"  $open-package  is deblocker
   deblocker if
      true
   else
      ." Can't open deblocker package"  cr  false
   then
;

0 instance value offset-low     \ Offset to start of partition
0 instance value offset-high

0 instance value label-package

\ Sets offset-low and offset-high, reflecting the starting location of the
\ partition specified by the "my-args" string.

: init-label-package  ( -- okay? )
   0 is offset-high  0 is offset-low
   my-args  " disk-label"  $open-package is label-package
   label-package  if
      0 0  " offset" label-package $call-method is offset-high is offset-low
      true
   else
      ." Can't open disk label package"  cr  false
   then
;

headers

: dma-alloc  ( size -- virt )  " dma-alloc" $call-parent  ;
: dma-free  ( virt size -- )  " dma-free" $call-parent  ;
: max-transfer  ( -- n )  " max-transfer" $call-parent  ;
: block-size    ( -- n )  " block-size" $call-parent  ;
: #blocks       ( -- n )  " #blocks" $call-parent  ;
\ : sec/cyl  ( -- n )  " sec/cyl" $call-parent  ;

headerless
instance variable floppy-#retries
[ifdef] notdef
: r/w-blocks  ( adr cyl# #cyls read? -- #read )
   >r -rot  2 pick                                   ( #cyls adr cyl# #rem )
   begin  dup   while                                ( #cyls adr cyl# #rem )
      floppy-#retries off                            ( #cyls adr cyl# #rem )
      begin                                          ( #cyls adr cyl# #rem )
         2 pick  2 pick ( sec/cyl * )                ( #cyls adr cyl# #rem adr #blks )
         block-size  r@  " r/w-data" $call-parent    ( #cyls adr cyl# #rem error? )
      while                                          ( #cyls adr cyl# #rem fatal? )
         if  r>  drop nip nip -  exit  then  ( #cyls adr cyl# #rem )

         1 floppy-#retries +!
         floppy-#retries @  8  >=  if  r>  drop nip nip -  exit  then
         
      repeat                                         ( #cyls adr cyl# #rem )
      rot block-size +  rot 1+  rot 1-               ( #cyls adr' cyl#' #rem' )
   repeat                                            ( #cyls adr' cyl#' 0 )
   r> drop  3drop                                    ( #cyls )
;
[else]
: r/w-blocks  ( adr blk# #blks read? -- actual# )
   over >r >r                                        ( adr blk# #blks r: #blks read? )
   block-size * r> " r/w-data" $call-parent  if      ( r: #blks )
      r> drop 0                                      ( 0 )
   else                                              ( r: #blks )
      r>                                             ( #blks )
   then                                              ( actual# )
;
[then]

headers
: read-blocks   ( adr cyl# #cyls -- #read )     true r/w-blocks   ;
: write-blocks  ( adr cyl# #cyls -- #written )  false r/w-blocks  ;

: load   ( adr -- size )                 " load"  label-package $call-method  ;
: seek   ( offset.low offset.high -- okay? )
   offset-low offset-high d+  " seek"   deblocker $call-method
;
: write  ( adr len -- actual-len )           " write" deblocker $call-method  ;
: read   ( adr len -- actual-len )           " read"  deblocker $call-method  ;

: close  ( -- )  label-package close-package  deblocker close-package  ;
: open   ( -- flag )
   my-unit  " set-address" $call-parent
   " chip-okay?"  $call-parent  0=  if  false exit  then
   " drive-okay?"  $call-parent  0=  if  false exit  then
   " diskette-present?" $call-parent  0=  if  false exit  then
   init-deblocker  0=  if  false exit  then
   init-label-package  0=  if  deblocker close-package  false exit  then
   true
;
: selftest  ( -- bad? )  my-unit  " test-disk" $call-parent  ;

finish-device
