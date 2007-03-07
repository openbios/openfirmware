\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: callback.fth
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
purpose: Callbacks into client program, callback and sync commands
copyright: Copyright 1990-2002 Sun Microsystems, Inc.  All Rights Reserved

headerless

nuser vector     0 vector !

\ Max#rets (6) + max#args (20) + service + n_args + n_returns
6 d# 20 + 3 + /n* buffer: cb-array

\ #rets (1) + #args (1) + service + n_args + n_returns
1 1 + 3 + /n* buffer: int-cb-array

/n negate constant -/n
: !+  ( n adr -- adr' )  tuck ! na1+  ;

headers
\ This version is for the special case where there is one argument, we
\ have already checked the vector, and we don't care about the result.
\ It uses a private copy of the callback array so it can be used for
\ timer tick callbacks, which may happen during the execution of other
\ callbacks.
: ($callback1)  ( arg1 adr len -- )
   vector @  0=  if  3drop exit  then

   \ Prepare argument array
   $cstr int-cb-array !+    \ service name    ( arg1 adr )
   1 swap !+                \ N_args          ( arg1 adr )
   1 swap !+                \ N_rets          ( arg1 adr )
   !                        \ arg1            ( )

   int-cb-array  vector @  callback-call      ( )
;

: ($callback)
   ( argn .. arg1 nargs adr len -- [ retn .. ret2 Nreturns-1 ] ret1  )
   vector @  0=  if
      2drop  0  ?do  drop  loop  true exit
   then

   \ Prepare argument array
   $cstr cb-array !+       \ service name   ( argn .. arg1 nargs adr )
   over >r  !+             \ N_args         ( argn .. arg1 adr' r: nargs )
   6 swap !+               \ N_rets         ( argn .. arg1 adr'' r: nargs )
   r@ 0  ?do  !+  loop  drop                ( r: nargs )  \ arg1 .. argN

   cb-array  vector @ callback-call         ( )

   \ Compute address of ret1
   cb-array r> 3 + na+                      ( ret1-adr )

   \ Exit if ret1 is nonzero
   dup @  if  @ exit  then                  ( ret1-adr )

   cb-array 2 na+ @ 1 max  1-  dup >r       ( ret1-adr #rets-1 r: Nrets-1 )
   /n* over +                               ( ret1-adr retN-1-adr r: Nrets-1 )
   do  i @  -/n +loop                       ( retN .. ret1 r: Nrets-1 )

   r> swap                                  ( retN .. ret2 Nrets-1 ret1 )
;
: $callback  ( argn .. arg1 nargs adr len -- retn .. ret2 Nreturns-1 )
   ($callback)  throw
;
: sync  ( -- )  0 " sync" $callback drop  ;
: callback  \ service-name  rest of line  ( -- )
   parse-word  -1 parse  dup over + 0 swap c!  ( adr len arg-adr )
   -rot 1 -rot  $callback
;

also client-services definitions
: interpret  ( arg-P .. arg1 cstr -- res-Q ... res-1 catch-result )
   cscount  ['] interpret-string  catch  dup  if  nip nip  then
;

: set-callback  ( newfunc -- oldfunc )
   vector @  swap vector !
   cb-array drop		\ Force allocation now
   int-cb-array drop
;
previous definitions
