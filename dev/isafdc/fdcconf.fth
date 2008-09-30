\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: fdcconf.fth
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
purpose: Floppy controller driver variables and constants
copyright: Copyright 1990 Sun Microsystems, Inc.  All Rights Reserved

hex

headerless
d# 10 instance buffer: statbuf

   40 constant dio		\ Direction In, i.e. read FIFO
   10 constant busy		\ Not ready for new command

    2 instance value #heads	\ number of heads
d# 18 instance value sec/trk	\ sectors per track (9 for 720K, d# 18 for 1.44M )
  200 instance value bytes/sec	\ bytes per sector.  goes with size
    0 instance value drive	\ drive number

d# 18 instance value end-of-trk	\ final sector number of current track
    2 instance value size	\ bytes per sector (2 for 512)
  01b instance value gpl	\ read, write gap
  0ff instance value dtl	\ special sector size (0 for 128 byte sector)

   1b instance value gpl3	\ gap 3 size

\   0c instance value srt	\ 13 for 4 ms at 500Kbps
\    2 instance value hut	\ 2 for 16 ms at 500Kbps
\   19 instance value hlt	\ 25 for 50 ms at 500Kbps

\ 1.44 in 1.44 drive
   0a instance value srt	\ 0 for 16 ms at 500Kbps
   0f instance value hut	\ 0 for 256 ms at 500Kbps
    1 instance value hlt	\ 0 for 256 ms at 500Kbps

    0 instance value mot	\ 0 for wait for motor
    0 instance value moff	\ 6 for 5.2secs delay default, 300 rpm
    \ The 82077 does not support the MON field; the second "configure"
    \ byte must be 0
    0 instance value mon	\ 4 for 800msec motor on delay, 300 rpm
    0 instance value efifo	\ 20 for no fifo, default
    9 instance value fifothr	\ FIFO threshold; report ready as soon as possible
    0 instance value precomp	\ 0 for default, 125 ns at 500 Kbps
    0 instance value dratesel	\ data rate select, 0 for 500 Kbps

   40 constant mfm		\ 40 for mfm
   80 constant mt		\ multi-track - read until the end of a cylinder
    0 constant nd   		\ non-DMA mode
    0 constant hsda		\ no high speed disks
   80 constant flock		\ floppy parameters locked
   40 constant eis		\ implied seek
   10 constant poll		\ 10 to disable polling
    0 constant pretrk		\ 0 for pre-comp on track 0

    3 constant dor-drvsel	\ drive select bit mask
    4 constant dor-reset	\ hard reset
    8 constant dor-dmagate	\ enable INT, DRQ, TC, and DACK to the system
\  10 constant dor-motoren0	\ motor enable for drive 0
\  20 constant dor-motoren1	\ motor enable for drive 1
\  40 constant dor-motoren2	\ motor enable for drive 2
\  80 constant dor-motoren3	\ motor enable for drive 3
[ifdef] sun
   80 constant dor-eject	\ floppy eject (Sun-specific)
[then]

   80 constant dsr-swreset	\ soft reset
   80 constant dir-dskchg	\ disk change

: wait-command  ( -- )  begin  busy  fstat@ and 0=  until  ;

\ Reads result bytes as long as the chip has some to give us
: result  ( -- )
   statbuf  begin                     ( adr )
      \ If fdc-fifo-wait times out, the 80 bit will not be set
      fdc-fifo-wait  dio 80 or  tuck and  =    ( adr flag )
   while
      fifo@ over c!  1+               ( adr' )
   repeat                             ( adr )
   drop
;   

\ Sends a command byte to the floppy command registers
: >fdc  ( byte -- )
   fdc-fifo-wait  dio and  abort" Floppy chip not ready for command"
   fifo!
;

\ Sends the first command byte to the floppy command register
: fdc-cmd  ( command-byte -- )  wait-command >fdc  ;

: dor-motoren  ( -- mask )  h# 10  drive  lshift  ;

: floppy-xdeselect ( -- )  
   fstat@  busy and 0= 		( flag1 )
   dor@ dor-motoren and 	( flag1 flag2 )
   and if
      dor@ dor-motoren invert and  dor!
   then
;

: fdc-reset  ( -- )
   dor@ dor-reset invert and dor!
   1 ms   
   dor@ dor-reset or dor!
   1 ms   
\   dor-reset dor!
   clear-terminal-count
   dsr-swreset  fstat!
   precomp 2 <<  dratesel +  fstat!

   \ Theoretically, 2 milliseconds delay is needed before the oscillators
   \ stabilize, but this is overlapped with the head load delay, so we
   \ don't actually have to time it.

2 ms

   floppy-xdeselect
   dor@ dor-reset or dor-dmagate or dor!
\ dor-dmagate dor!
; 


: floppy-xselect   ( -- )
   dor@
     dor-drvsel invert and  drive or
     dor-motoren or
   dor!
\ d# 500 ms
;

: dskchg-bitset?   ( -- flag )  dir@  dir-dskchg and  ;
headers
[ifdef] sun
: floppy-eject     ( -- )
   map-floppy
   floppy-xselect
   dor@ dor-eject or dor! noop noop dor@ dor-eject invert and dor!
   floppy-xdeselect
   unmap-floppy
;
[then]
