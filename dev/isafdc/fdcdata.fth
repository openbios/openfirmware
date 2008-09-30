\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: fdcdata.fth
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
purpose: Floppy data transfer
copyright: Copyright 1990 Sun Microsystems, Inc.  All Rights Reserved

headerless
10 instance buffer: fcmdbuf
instance variable fcmdp
: putb  ( byte -- )  fcmdp @ c!  1 fcmdp +!  ;
: setcmd  ( -- )  fcmdbuf fcmdp !  putb  ;
: sendcmd  ( -- )  fcmdp @  fcmdbuf  ?do  i c@ >fdc  loop  ;

\ fills command block for transfer commands
: transfer-command  ( block# cmd -- )
   +xfer-bits setcmd		( block# )
   sec/trk /mod			( sector# track# )
   #heads  /mod			( sector# cylinder# head# )
   over h&d putb		( sector# cylinder# head# )

   putb  putb  1+ putb		( )
   size putb  end-of-trk putb   gpl3 putb   dtl putb
   sendcmd
;

headers

: r/w-data  ( adr block# #bytes read? -- false | fatal? true )
   dup  if  6  else  5  then   ( adr block# #bytes read? command )
   floppy-select               ( adr block# #bytes read? command )
   ff statbuf c!               ( adr block# #bytes read? command )
   >r  rot >r                  ( adr #bytes read? )    ( r: cmd block# )
   dma-setup                   ( adr devaddr #bytes )  ( r: cmd block# )
   r> r>                       ( adr devaddr #bytes block# cmd )
   transfer-command            ( adr devaddr #bytes )
   dma-wait drop result	       ( )
   floppy-error?               ( error? )
   floppy-deselect             ( error? )

   dup  if                                     ( true )
      statbuf 1+ c@ 30 and 0=                  ( true fatal? )
      dup 0=  if  floppy-recalibrate  then     ( true fatal? )
      swap
   then                        ( false | fatal? true )
;

headers
