\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: install.fth
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
id: @(#)install.fth 1.5 03/04/16
purpose: Converts V1 display interface to V2 package interface
copyright: Copyright 1990-2003 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headers
\ Compatibility package to present a package-style interface for
\ old-style display drivers.

: $makealias  ( xt adr len -- )
   2dup my-voc find-method  if  ( xt adr len acf' )
      2drop 2drop
   else                         ( xt adr len )
      $create -1 setalias
   then
;

headerless
: disp-selftest ( -- failed? )
   my-self >r
   initial-addr my-termemu @  ( first-ihandle )
   ?dup  if  is  my-self  then (  )
   " disp-test" $call-self     ( failed? )
   r> is my-self               ( failed? )
;

: disp-close  ( -- )
   current-device >r  my-voc push-device
   \ Reset the my-termemu value in the instance record
   my-termemu  if
      initial-addr my-termemu       off
      initial-addr frame-buffer-adr off
      my-termemu " remove" $call-self    close-package
   then
   r> push-device
;
: disp-open   ( -- flag )
   \ If this device is already open
   \ then my-termemu will be initialized
   \ with the ihandle from the prev. open
   my-termemu ?dup  if  ( first-ihandle )
      close-chain    is my-self
   else
      \ Open an instance of the terminal emulator
      0 0  " terminal-emulator" $open-package  to my-termemu

      " install" $call-self
      install-terminal-emulator
      \ Save the ihandle in the instance record
      my-self           initial-addr my-termemu       !
      frame-buffer-adr  initial-addr frame-buffer-adr !
   then  true
;
: disp-write  ( adr len -- len )  tuck ansi-type  ;

: stdout-execute  ( xt -- )  stdout @ package( execute )package  ;
: stdout-termemu   ( -- flag )  ['] my-termemu stdout-execute   ;
: stdout-value  ( xt -- n )
   stdout-termemu  if  stdout-execute  else  drop 0  then
;

partial-headers
: stdout-line#      ( -- line# )    ['] line#      stdout-value  ;
: stdout-column#    ( -- column# )  ['] column#    stdout-value  ;
: stdout-char-width ( -- pixels )   ['] char-width stdout-value  ;
: stdout-draw-logo  ( -- )
   stdout-termemu  if  ['] draw-logo  stdout-execute  else  2drop  then
;

headers
: is-install   ( xt -- )
   ( xt )            " install"   $makealias
   ['] disp-open     " open"      $makealias
   ['] disp-write    " write"     $makealias
   ['] draw-logo     " draw-logo" $makealias
   ['] reset-screen  " restore"   $makealias
;
: is-remove    ( xt -- )
   ( xt )            " remove"    $makealias
   ['] disp-close    " close"     $makealias
;
: is-selftest  ( xt -- )
   ( xt )             " disp-test"  $makealias
   ['] disp-selftest  " selftest"   $makealias
;
