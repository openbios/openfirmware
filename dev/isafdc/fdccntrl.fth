\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: fdccntrl.fth
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
purpose: Floppy Disk Controller driver, control words
copyright: Copyright 1990 Sun Microsystems, Inc.  All Rights Reserved

\ P. Thomas  12/21/87

headerless
hex

0 instance value floppy-#selects
: floppy-select    ( -- )
   floppy-#selects  dup 0=  if  floppy-xselect  then
   1+ is floppy-#selects
;
: floppy-deselect  ( -- )
   floppy-#selects 1-  dup 0<=  if  floppy-xdeselect  then
   0 max  is floppy-#selects
;


: h&d  ( head -- n )  1 and  2 <<  drive  3 and  or  ;

\ true if problem in execution
: floppy-error?  ( -- flag )  statbuf c@ h# c0 and  ;

: ck-density ( mfm -- ok? )
   floppy-select
   h# 0a or mt or fdc-cmd 0 h&d >fdc
   result floppy-error?
   floppy-deselect
;

\ Adds funky bits to the command code
\ : +xfer-bits   ( cmd -- cmd' )  
\    mfm ck-density  if  0  else  mfm  then
\    or  mt or  
\ ;

: +xfer-bits  ( cmd -- cmd' )  mfm or mt or ;

: sense-interrupt-status  ( -- status )  08 fdc-cmd  result  statbuf c@  ;

\ Read and discard all the interrupt events that the chip has queued up.
\ Stop when there are no more events to read.
: flush-int ( -- )
   d# 50 0  do
      sense-interrupt-status   ( status )
      \ wait for intr status
      h# c0 and  h# c0 =  ?leave
      1 ms
   loop
   \ Flush the queue
   d# 10 0  do 
      sense-interrupt-status   h# c0 and  h# 80 =  ?leave
   loop
;

\ Read and discard interrupt events until an event for this drive is seen.
: wait-done  ( -- )
   wait-command
   begin
      \ Discard status for other drives
      begin  sense-interrupt-status  3 and  drive =  until
      \ Wait until either Seek End or Equipment Check
      statbuf c@  h# 30 and
   until
;

: fdc-specify  ( -- )  \ sets drive characteristics
   3 fdc-cmd
   srt  4 <<  hut or  >fdc
   hlt  1 <<  nd  or  >fdc
;

: fdc-lock  ( -- )		\ Protect the config parameters
   94 fdc-cmd
   fdc-fifo-wait fifo@ 2drop
;

: fdc-configure  ( -- )		\ Sets the floppy controller chip parameters
   13 fdc-cmd
   moff  4 <<  hsda or   mon or   >fdc
   eis  efifo or  poll or   fifothr or  >fdc
   pretrk >fdc
;

: floppy-recalibrate  ( -- )	   \ Seeks to track 0
   floppy-select
   7 fdc-cmd   drive >fdc   wait-done
   floppy-deselect
;
: floppy-seek  ( cylinder -- )	   \ Seeks to the indicated cylinder
   floppy-select
   0f fdc-cmd   0 h&d >fdc   ( cylinder )  >fdc  wait-done
   d# 15 ms	\ Head settling time
   floppy-deselect
;
: diskette-present?  ( -- flag )   \ true if a floppy disk is in the drive
   floppy-select
   dir@ drop   \ Read once to clear out the old status
   1 floppy-seek  floppy-recalibrate
   dskchg-bitset? 0= 	( flag )
   floppy-deselect	( flag )
;

headers
: fdc-init  ( -- )
   map-floppy
   0 is floppy-#selects
   fdc-reset
   flush-int
   fdc-specify
   fdc-configure
   fdc-lock
;

: drive-present?  ( -- flag )
    fdc-init  floppy-recalibrate  statbuf c@  h# 10 and  0=
;
