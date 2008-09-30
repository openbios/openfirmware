\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: fdc-test.fth
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
purpose: Selftest routines for floppy disk controller.
copyright: Copyright 1990 Sun Microsystems, Inc.  All Rights Reserved

headerless
: sense-drive-status  ( head -- status )
   floppy-select
   4 fdc-cmd   ( head )  h&d   >fdc
   result
   floppy-deselect
   statbuf c@
; 

: dumpreg  ( -- )  h# 0e fdc-cmd  result  ;

: chk  ( flag value index -- flag' )   statbuf + c@  <>  or  ;
: check-registers  ( -- error? )
\   0 c,  0 c,  0 c,  0 c,   \ Cylinder numbers
   false
   srt  4 <<  hut or                   4 chk   ( error? )
   hlt  1 <<  nd  or                   5 chk   ( error? )

\ This doesn't work on some chips, such as the SMC 37C935 Super-I/O
\  moff 4 <<  hsda or mon or flock or  7 chk   ( error? )

   eis  efifo or  poll or  fifothr or  8 chk   ( error? )
   \ We can't check the EOT/SC field because its value depends on a
   \ prior execution of a read, write, or format command.
;

\ If flag is true, displays the message "adr len", ?error places false on
\ the stack and returns to the caller's caller.  Otherwise discards adr,len

: ?error  ( flag adr len -- [ false ] )
   rot  if   type  cr  false r> drop  else  2drop  then
;

: 1cyl  ( -- #bytes )  sec/trk 2*  h# 200 *  ;

headers
: chip-okay?  ( -- okay? )
   false
\   statbuf c@  h# 80 <>  " Floppy chip initialization failed."  ?error

\   dumpreg  check-registers
\   " Floppy chip registers read back incorrectly." ?error
   0=
;
: drive-okay?  ( -- okay? )
   floppy-recalibrate  statbuf c@  h# 10 and  if
      ." Recalibrate failed.  The floppy drive is either missing," cr
      ." improperly connected, or defective."  cr
      false exit
   then

   false
   0 floppy-seek  statbuf c@
      h# 20 drive + <>  " Seek to track 0 failed."  ?error

   0 sense-drive-status
      h# 10 and  0=  " Track 0 not reported."  ?error

   2 floppy-seek  statbuf c@
      h# 20 drive + <>  " Seek to track 2 failed."  ?error

   0 sense-drive-status
      h# 10 and  " Track 0 reported when on track 2."  ?error

   0 floppy-seek  statbuf c@
      h# 20 drive + <>  " Seek to track 0 failed."  ?error

   0 sense-drive-status
      h# 10 and  0=  " Track 0 not reported."  ?error

   0 sense-drive-status
      4 and " Head select is 1; should be 0."  ?error

   1 sense-drive-status
      4 and 0=  " Head select is 0; should be 1."  ?error
   
   0=
;

: test-disk  ( drive# -- error? )
   ." Testing floppy disk system.  A formatted disk should be in the drive." cr
   to drive
   chip-okay?  0=  if  true exit  then
   drive-okay?  0=  if  true exit  then

   \ diskette-present? is sometimes redefined so we use $call-self to
   \ make sure we get the latest version...
   " diskette-present?" $call-self  0=  if
      ." Diskette not present" cr  true exit  
   then
      
   1cyl dma-alloc >r
   r@ 0 1cyl true r/w-data  dup  if		( fatal? true )
      nip                                       ( true )
      ." Can't read the first cylinder." cr     ( true )
   then                                         ( error? )
   r> 1cyl dma-free
;

