\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: timedrec.fth
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
purpose: Network reception with timeout
copyright: Copyright 1990 Sun Microsystems, Inc.  All Rights Reserved

\ Defines:
\ timed-receive ( timeout-msecs -- [ buffer-handle data-address length ] err?)
\ set-timeout  ( timeout-msecs -- )
\ receive-unicast  ( -- [ buffer-handle data-address length ] err? )
\
\ defer handle-broadcast-packet     ' noop to handle-broadcast-packet
\   ( buff-handle data-addr len flag -- buff-handle data-addr len flag )
\

\ Uses this interface to the lower level receiver functions:

\ receive-ready? ( -- flag )   \ true if a packet has arrived
\ receive        ( -- buf-handle buffer length )
\ return-buffer  ( buf-handle -- ) \ give receive buffer back to chip
\ .error ( buffer-handle data-address length -- handle address length )
\   

decimal

instance variable alarmtime

: set-timeout  ( interval -- )  get-msecs  +  alarmtime !  ;
: timeout?  ( -- flag )  get-msecs  alarmtime @ >=  ;

instance defer handle-broadcast-packet
 ( buff-handle data-addr len flag -- buff-handle data-addr len flag )

: multicast? ( handle data-address length -- handle data-address length flag )
   \ Check for multicast/broadcast packets
   over                        ( ... data-address )
   c@ h# 80 and dup  if        \ Look at the multicast bit
       ( handle data-address length multicast? )
       handle-broadcast-packet
   then
;

: receive-good-packet  ( -- [ buffer-handle data-address length ]  | 0 )
   begin
      begin
         timeout?  if  false exit  then
         receive-ready?
      until
      receive dup 0=
   while
      .error  2drop return-buffer
   repeat
;
: receive-unicast-packet  ( -- [ buffer-handle data-address length ] | 0 )
   begin
      receive-good-packet  dup 0=  if  exit  then
      multicast?
   while
      2drop return-buffer
   repeat
;
\ Receive a packet, filtering out broadcast packets and timing
\ out if no packet comes in within a certain time.
: timed-receive ( timeout-msecs -- [ buffer-handle data-address length ] err?)
   set-timeout  receive-unicast-packet ?dup 0=
;
headers 
