\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: lancecom.fth
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
purpose: Code common to all LANCE versions
copyright: Copyright 1995 Sun Microsystems, Inc.  All Rights Reserved

d# 1514 encode-int  " max-frame-size" property

headers

\ buffer# to address calculations
: rmd#>rmdaddr  ( n -- addr )  /rmd * rmd0 +  ;
: rbuf#>rbufaddr  ( n -- addr )  /rbuf * rbuf0 +  ;

1 #rmdsfactor lshift   to #rmds
#rmds /rmd *           to /rmds

\ patch routine to change buffer count
: set-factor  ( rmdsfactor -- )  \ 1=2bufs, 2=4bufs, 3=8bufs, etc.
   8 min            \ max buffers is 256
   to #rmdsfactor
   1 #rmdsfactor lshift to #rmds
   #rmds /rmd * to /rmds
;

: status@  ( rmd/tmd-addr -- statusflag )  >laflags c@  ;

\ Masks out OWN, ENP and STP bits; they aren't errors
: rerrors@  ( rmd/tmd-addr -- errorsflag )  status@ ready invert and  ;


\ *** Lance message descriptor ring value storage ***

\ Put a buffer back in the chip's ready list
: give-buffer  ( rmd/tmd-addr -- )  >laflags  ready  swap c!  synchronize  ;

\ *** Initialization routines ***

: set-address  ( en-addr len -- )  drop  this-en-addr 6 cmove  ;

\ Initialize a single message descriptor
: rmd-init  ( rbufaddr rmdaddr -- ) 
   /rbuf over length!             \ Buffer length
   addr!                          \ Buffer address
;

\ Set up the data structures necessary to receive a packet
instance variable nextrmd
: rinit  ( -- )
   rmd0 nextrmd !
   #rmds 0  do   i rbuf#>rbufaddr  i rmd#>rmdaddr  rmd-init loop
   #rmds 0  do  i rmd#>rmdaddr give-buffer  loop   
;

\ *** Receive packet routines ***

: .err-text  ( err-code -- err-code )
   enp over and  if
      fram over and  if  ." Framing error "  then
      crc  over and  if  ." CRC error "      then
   else
      oflo over and  if  ." FIFO overflow "  then
   then
   buff over and  if  ." No buffers "     then
;

instance defer .error
: (.error  ( buf-handle buffer length -- buf-handle buffer length )
   2 pick rerrors@  if
      2 pick status@ dup mser and  if  .err-text  then   drop
      drop 0
   then
;

: receive-ready? ( -- packet-waiting? )
   synchronize
   nextrmd @ status@  own and  0=  
;

: receive  ( -- buf-handle buffer len )		\ len non-zero if packet ok
   nextrmd @  dup addr@  over ( nlover )  ( rmd bufferaddr rmd )
   length@ .error
;

: to-next-rmd  ( -- )
   /rmd nextrmd +!
   nextrmd @  rmd0 -  /rmds >=  if   rmd0 nextrmd !   then
;

: return-buffer ( buf-handle -- )  give-buffer to-next-rmd  ;


\  *** start of transmit routines ***

instance variable nexttmd    \ tmd0 nexttmd !, never changes presently

\ Wait until transmission completed
: send-wait  ( -- )  begin  0 csr@ tint and  until  tint 0 csr!  ;

\ *** Transmit initialization routines ***

\ transmit buffer initialize routine
: tinit ( -- )
   tmd0 nexttmd !
   tbuf0  nexttmd @  addr!
   nexttmd @   clear-errors
;

\ Set up CPU page maps
: map-lance-buffers  ( -- )
   #rmdsfactor set-factor
   #rmds /rbuf *                ( rbuf-size )

   \ Figure out how much total DMA space we're going to need

   /ib +  /tmd +  /rmds +  /tbuf +     ( total-dma-size )
   to lance-dma-size

   \ Allocate and map that space
   lance-dma-size lance-allocate-dma  ( dma-area-adr )
   dup to dma-base

   \ Set the addresses of the various DMA regions used by the chip
   dup  to ib         /ib +  ( next-address )
   dup  to tmd0      /tmd +  ( next-address )
   dup  to rmd0     /rmds +  ( next-address )
   dup  to tbuf0    /tbuf +  ( next-address ) \ Enough for max packet
        to rbuf0             ( )
;

: unmap-lance-buffers  ( -- )
   dma-base lance-dma-size  lance-free-dma
   0 to dma-base
;

\ Initializes the chip, allocating the necessary memory, and enabling the
\ transmitter and receiver.
: net-on  ( -- flag )		\ true if net-on succeeds
   mac-address set-address 
   tinit rinit
   lance-init
;

: net-off  ( -- )  stopb 0 csr!  ;

\ *** Main transmit routines ***

\ Ignores the size argument, and uses the standard buffer.
: get-buffer  ( dummysize -- buffer )  drop  nexttmd @ addr@  ;

\ Display time domain reflectometry information
: .tdr  ( xerrors -- )  h# 3ff and  ." TDR: (decimal) " .d  ;

: .terr-text  ( tmd -- )
   xerrors@  >r
   xbuf r@ and  if  ." Buffer Error  "               then
   uflo r@ and  if  ." Underflow  "                  then
   lcol r@ and  if  ." Late Collision  "    r@ .tdr  then
   lcar r@ and  if  ." Lost Carrier  (transceiver cable problem?)  "   then
   rtry r@ and  if  ." Too Many Retries  "  r@ .tdr  then
   r> drop cr
;

\ print summary of any HARD errors
: (.transmit-error  ( tmd len -- tmd len )
   over  status@ mser and  if  over .terr-text  then
;
instance defer .transmit-error

\ This send routine does not enforce the minimum packet length.  It is
\ used by the loopback test routines.  Loopback only works with packets
\ whose length is <= 32 bytes.
:  short-send  ( buffer length -- error? )
   tuck nexttmd @   length!  ( length buffer )
   drop          		\ discard buffer address, assumes using nexttmd
   nexttmd @  give-buffer	\ Give tmd to chip
   tdmd 0 csr!			\ Force chip to look at it right away
   send-wait             	\ wait for completion
   nexttmd @  swap  ( tmd length )
   .transmit-error  ( tmd length )
   drop  xerrors@ dup  if  nexttmd @ clear-errors  then   ( error? )
;

\ transmit packet routine
: net-send  ( buffer length -- error? )
   d# 64 max       		\ force minimum length to be 64
   short-send  ( error? )
;

headers
