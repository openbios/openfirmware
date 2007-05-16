\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: banner.fth
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
id: @(#)banner.fth 3.17 04/05/26
purpose: Displays banner describing system configuration
copyright: Copyright 1990-2004 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

\ Display the startup message.

hex
headerless
true value auto-banner?

headers
: suppress-banner  ( -- )  false to auto-banner?  ;

false config-flag oem-banner?
" "  d# 80  config-string oem-banner

false config-flag oem-logo?
d# 512 nodefault-bytes oem-logo

headerless

d# 128 constant max-logo-width

defer .firmware  ' noop to .firmware

: memory-size ( -- #megs )
   " size" memory-node @ $call-method 1meg um/mod nip
;
: .memory  ( -- )
   memory-size dup d# 1024 / ?dup  if ( mb gb )
      nip "  GiB" rot                 ( gb$ gb )
   else                               ( mb )
      " MiB " rot                     ( mb$ mb )
   then                               ( m$ m )
   .d  type ." memory installed"      (  )
;
: .serial  ( -- )
   push-decimal  ." Serial #"  serial# (.) type
   \   ." ."
   pop-base
;

variable logo?
: ?spaces  ( -- )
   logo? @  if  max-logo-width  stdout-char-width  / 2+  spaces  then
;

variable banner-start
: chosen-logo  ( -- adr len )
   oem-logo?  if  oem-logo  else  default-logo  then   ( adr len )
;
: .logo  ( -- )
   logo? @  if
      banner-start @  #line @ -  stdout-line# +           ( line# )
      chosen-logo  if                                     ( line# adr )
         logo-width logo-height  stdout-draw-logo         ( )
      else                                                ( line# adr )
         2drop                                            ( )
      then
   then
;

: display?  ( -- flag )
   stdout @  if
      " device_type"  stdout @  ihandle>phandle  get-package-property  0= if
         ( adr len )  get-encoded-string  " display"  $= exit
      then
   then
   false
;
: test-logo  ( -- )
   \ Decide in advance whether or not to display a logo so that the
   \ text information may be located correctly.

   false logo? !

   chosen-logo  nip  0=  if  exit  then

   display?  logo? !
;

: cpu-model  ( -- adr len )
   current-device >r  root-device
   " banner-name" get-property  if  " model" get-property  else  false  then
   r> push-device  if  " "  else  get-encoded-string  then
;

: (banner-extras)  ( -- )  ;
: (banner-warnings)  ( -- )  ;
: (banner-basics)  ( -- )
   ?spaces  cpu-model type   ." , "  .serial  ." , "  .memory  cr
   ?spaces  .firmware
;
headers
defer banner-extras    ' (banner-extras)   to banner-extras
defer banner-warnings  ' (banner-warnings) to banner-warnings
defer banner-basics    ' (banner-basics)   to banner-basics
: banner  ( -- )
   auto-banner?  if  " banner-" do-drop-in  then

   test-logo

   ??cr
   #line @ banner-start !
   oem-banner?  if
      cr ?spaces oem-banner type  cr cr
   else
      banner-basics
      banner-extras
   then

   banner-warnings

   .logo  cr

   auto-banner?  if  " banner+" do-drop-in   then

   \ If "banner" is executed inside nvramrc, we may assume that the
   \ "probe-all install-console banner" sequence has been taken care of,
   \ so it isn't necessary to execute it again after nvramrc is finished.

   suppress-banner
;

: ?banner ( -- )  (silent-mode?  if  suppress-banner  else  banner  then  ;

: .built  ( -- )
   " build-date" $find  if
      ." Built " execute type
   else
      2drop
   then
;
: .version  ( -- )
   " /openprom" find-package  if
      " model"  rot get-package-property  0=  if
         get-encoded-string  type cr
      then
   then
   .built cr
;
