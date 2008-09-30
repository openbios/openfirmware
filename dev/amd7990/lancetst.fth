\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: lancetst.fth
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
purpose: LANCE selftest
copyright: Copyright 1990 Sun Microsystems, Inc.  All Rights Reserved

hex
headers
instance variable lance-verbose?
instance variable ext-lbt?	ext-lbt? off

create loopback-prototype
   ff c, 00 c,					    \ Ones and zeroes
   01 c, 02 c, 04 c, 08 c, 10 c, 20 c, 40 c, 80 c,  \ Walking ones
   fe c, fd c, fb c, f7 c, ef c, 0df c, 0bf c, 7f c,  \ Walking zeroes

: loopback-buffer  ( -- adr len )
   /loopback get-buffer  ( adr )
   mac-address drop    over              6 cmove   \ Set source address
   mac-address drop    over 6 +          6 cmove   \ Set destination address
   loopback-prototype  over d# 12 +  d# 20 cmove   \ Set buffer contents
   /loopback
;

: pdump  ( adr -- )
   base @ >r  hex
   dup      d# 10  bounds  do  i c@  3 u.r  loop  cr
   d# 10 +  d# 10  bounds  do  i c@  3 u.r  loop  cr
   r> base !
;

: .loopback  ( -- )
   mode @  intl and  if  ." Internal "  else  ." External "  then
   ." loopback test -- "
;

: ?.loopback  ( -- )
   lance-verbose? @  0=  if  .loopback  then  ;

: switch-off  ( -- false )
   lance-verbose? off  false
;

: bad-rx-data  ( buf-handle data-address -- false )
   ?.loopback
   ." Received packet contained incorrect data.  Expected: " cr
   loopback-prototype pdump
   ." Observed:" cr
   d# 12 + pdump
   switch-off
;

: check-data  ( buf-handle data-address length -- flag )
						\ flag is true if data ok
   drop  ( buf-handle data-address )
   dup d# 12 +  loopback-prototype  d# 20 comp
   if  bad-rx-data
   else  drop   ( buf-handle )
     return-buffer
     lance-verbose? @  if  ." succeeded." cr  then
     mode off   true
   then
;

: check-len&data  ( buf-handle data-address length -- flag )
						\ flag is true if data, len ok
   \ The CRC is appended to the packet, thus it is 4 bytes longer than
   \ the packet we sent.
   dup /loopback 4 + <>  if
      ?.loopback
      ." Wrong packet length; expected " /loopback 4 + 2 .r 
      ." , observed " .d cr
      switch-off
   else
      check-data
   then
;

: loopback-test  ( internal/external -- flag )	\ flag is true if test passed
   lpbk or  mode !
   lance-verbose? @  if  ."  " .loopback  then
   net-on  if
      loopback-buffer short-send  if
	 ?.loopback  ." send failed." cr
	 switch-off
      else
	 d# 2000 timed-receive  if
	    ?.loopback
	    ." Did not receive expected loopback packet." cr
	    switch-off
	 else         (  buf-handle data-address length )
	    check-len&data
	 then
      then
   else
      switch-off
   then
   net-off  mode off
;

: net-init  ( -- flag )			\ flag is true if net-init succeeds
   mode @		\ Save requested mode because loopback changes it
   intl loopback-test  if	\ mode_saved ; passed int. loopback test
      ext-lbt? @  if  0 loopback-test  else  true  then  ( saved-mode flag )
      swap mode !  if  net-on  else  false  then
   else
      mode !  false
   then
;

: wait-for-packet  ( -- )
   begin  key?	receive-ready?  or  until
;

: watch-test  ( -- )
   ." Looking for Ethernet packets." cr
   ." '.' is a good packet.  'X' is a bad packet."  cr
   ." Type any key to stop."  cr
   begin
      wait-for-packet
      receive-ready?  if
         receive  if  ." ."  else  ." X"  then
         drop  return-buffer
      then
      key? dup  if  key drop  then
   until
;
headers
