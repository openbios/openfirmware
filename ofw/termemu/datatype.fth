\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: datatype.fth
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
id: @(#)datatype.fth 1.4 00/04/25
purpose: Defines terminal-emulator-specific data types
copyright: Copyright 1994-2000 Sun Microsystems, Inc.  All Rights Reserved

headers
d# 34 config-int  screen-#rows       \ EEPROM parameter
d# 80 config-int  screen-#columns    \ EEPROM parameter

partial-headers
\ Used to prevent re-entering the terminal emulator from a keyboard abort
variable terminal-locked?  terminal-locked? off

headerless
\ Will be initialized to (escape-state in fwritestr.fth
defer escape-state	\ Forward reference

: >termemu-data  ( pfa -- adr )  @  my-termemu +  ;
: forth-create  ( -- )
   also forth definitions  create  previous definitions
;

headers

3 actions
action:  >termemu-data token@ execute  ;
action:  >termemu-data token!  ;
action:  >termemu-data token@  ;

: termemu-defer  \ name  ( -- )
   forth-create
   ['] crash /token  ( value data-size )
   use-actions value#, ( value adr )
   token!
;

3 actions
action:  >termemu-data @  ;
action:  >termemu-data !  ;
action:  >termemu-data    ;

: termemu-value  \ name  ( initial-value -- )
   forth-create
   /n  ( value data-size )
   use-actions  value#,  ( value adr )
   !
;

3 actions
action:  >termemu-data swap na+ @  ;  ( index -- value )
action:  >termemu-data swap na+ !  ;  ( value index -- )
action:  >termemu-data swap na+    ;  ( index -- adr )

: termemu-array  \ name  ( #entries -- )
   forth-create              ( #entries )
   use-actions  /n* value#,  ( adr )
   drop
;
headers
