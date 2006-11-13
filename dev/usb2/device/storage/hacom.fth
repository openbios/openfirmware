\ Common code for SCSI host adapter drivers.
\ See license at end of file

\ The following code is intended to be independent of the details of the
\ SCSI hardware implementation.  It is loaded after the hardware-dependent
\ file that defines execute-command, set-address, open-hardware, etc.

headers

-1 value inq-buf                  \ Address of inquiry data buffer
-1 value sense-buf                \ holds extended error information


0 value #retries  ( -- n )        \ number of times to retry SCSI transaction

\ Classifies the sense condition as either okay (0), retryable (1),
\ or non-retryable (-1)
: classify-sense  ( -- 0 | 1 | -1 )
   debug?  if
      base @ >r hex
      ." Sense:  " sense-buf 11 bounds  do  i c@ 3 u.r  loop  ."  ..." cr
      r> base !
   then
   sense-buf

   \ Make sure we understand the error class code
   dup c@  h# 7f and h# 70 <>  if  drop -1 exit  then

   \ Check for filemark, end-of-media, or illegal block length
   dup 2+ c@  h# e0  and  if  drop -1 exit  then

   2 + c@  h# f and   ( sense-key )

   \ no_sense(0) and recoverable(1) are okay
   dup 1 <=  if  drop 0 exit  then   ( sense-key )

   \ not-ready(2) may be retryable
   dup 2 =  if
      \ check (tapes, especially) for MEDIA NOT PRESENT: if the
      \ media's not there the command is not retryable
      drop sense-buf h# c + c@  h# 3a =  sense-buf h# d + c@ 0=  and  if
         -1 else 1 
      then exit
   then

   \ Media-error(3) is not retryable
   dup 3 =  if  drop -1 exit  then

   \ Attention(6), and target aborted (b) are retryable.
   dup 6 =  swap 0b =  or if  1  else  -1  then
;

0 value open-count

: $=  ( $1 $2 -- flag )
   rot tuck <>  if  3drop false exit  then
   comp 0= 
;

external
: open  ( -- flag )
   my-args  " debug" $=  if  debug-on  then
   open-count  if
      reopen-hardware  dup  if  open-count 1+ to open-count  then
      exit
   else
      open-hardware  dup  if
         1 to open-count
         100 dma-alloc to sense-buf
         100 dma-alloc to inq-buf
      then
   then
;
: close  ( -- )
   open-count 1- to open-count
   open-count  if
      reclose-hardware
   else
      close-hardware
      inq-buf   100 dma-free
      sense-buf 100 dma-free
   then
;


headers

create sense-cmd  3 c, 0 c, 0 c, 0 c, ff c, 0 c,

: get-sense  ( -- )     \ Issue REQUEST SENSE, which is not supposed to fail
   sense-buf ff  true  sense-cmd 6  execute-command   0=  if  drop  then
;

\ Give the device a little time to recover before retrying the command.
: delay-retry  ( -- )   2000 0 do loop  ;

0 value statbyte	\ Local variable used by retry?

\ RETRY? is used by RETRY-COMMAND to determine whether or not to retry the
\ command, considering the following factors:
\  - Success or failure of the command at the hardware level (failure at
\    this level is usually fatal, except in the case of an incoming bus reset)
\  - The value of the status byte returned by the command
\  - The condition indicated by the sense bytes
\  - The number of previous retries
\
\ The input arguments are as returned by "scsi-exec"
\ On output, the top of the stack is true if the command is to be retried,
\ otherwise the top of the stack is false and the results that should be
\ returned by retry-command are underneath it; those results indicate the type
\ of error that occurred.

: retry?  ( hw-result | statbyte 0 -- true | [[sensebuf] f-hw] error? false )
   case
      0          of  to statbyte  endof  \ No hardware error; continue checking
      bus-reset  of  true exit    endof  \ Retry after incoming bus reset
      ( hw-result )  true false  exit    \ Other hardware errors are fatal
   endcase

   statbyte 0=  if  false false exit  then  \ If successful, return  "no-error"

   statbyte  2 and  if    \ "Check Condition", so get extended status
      get-sense  classify-sense  case                  ( -1|0|1 )
          \ If the sense information says "no sense", return "no-error"
          0  of  false false exit                      endof

         \ If the error is fatal, return "sense-buf,valid,statbyte"
         -1  of  sense-buf false statbyte false  exit  endof
      endcase

      \ Otherwise, the error was retryable.  However, if we have
      \ have already retried the specified number of times, don't
      \ retry again; instead return sense buffer and status.
      #retries 0=  if  sense-buf false statbyte false  exit  then
   then

   \ Don't retry if vendor-unique, reserved, intermediate, or
   \ "condition met/good" bits are set. Return "no-sense,status"
   statbyte h# f5 and  if  true statbyte false  exit  then

   \ Don't retry if we have already retried the specified number
   \ of times.  Return "no-sense,status"
   #retries 0=  if  true statbyte false  exit  then

   \ Otherwise, it was either a busy or a retryable check condition,
   \ so we retry.

   true
;

\ RETRY-COMMAND executes a SCSI command.  If a check condition is indicated,
\ performs a "get-sense" command.  If the sense bytes indicate a non-fatal
\ condition (e.g. power-on reset occurred, not ready yet, or recoverable
\ error), the command is retried until the condition either goes away or
\ changes to a fatal error.
\
\ The command is retried until:
\ a) The command succeeds, or
\ b) The select fails, or dma fails, or
\ c) The sense bytes indicate an error that we can't retry at this level
\ d) The number of retries is exceeded.

\ #retries is number of times to retry (0: don't retry, -1: retry forever)
\
\ sensebuf is the address of the sense buffer; it is present only
\ if f-hw is 0 and error? is non-zero.  The length of the sense buffer
\ is 8 bytes plus the value in byte 7 of the sense buffer.
\
\ f-hw is non-zero if there is a hardware error -- dma fails, select fails,
\ etc -- or if the status byte was neither 0 (okay) nor 2 (check condition)
\
\ error? is non-zero if there is a transaction error.  If error? is 0,
\ f-hw and sensebuf are not returned.
\
\ If sensebuf is returned, the contents are valid until the next call to
\ retry-command.  sensebuf becomes inaccessable when this package is closed.
\
\ dma-dir is necessary because it is not always possible to infer the DMA
\ direction from the command.

\ Local variables used by retry-command?

0 instance value dbuf             \ Data transfer buffer
0 instance value dlen             \ Expected length of data transfer
0 instance value direction-in     \ Direction for data transfer

-1 instance value cbuf            \ Command base address
 0 instance value clen            \ Actual length of this command

external

: retry-command  ( dma-buf dma-len dma-dir cmdbuf cmdlen #retries -- ... )
           ( ... -- [[sensebuf] f-hw] error? )
   to #retries   to clen  to cbuf  to direction-in  to dlen  to dbuf

   begin
      dbuf dlen  direction-in  cbuf clen  execute-command  ( hwerr | stat 0 )
      retry?
   while
      #retries 1- to #retries
      delay-retry
   repeat
;

headers

\ Collapses the complete error information returned by retry-command into
\ a single error/no-error flag.

: error?  ( false | true true | sensebuf false true -- error? )
   dup  if  swap 0=  if  nip  then  then
;

external

\ Simplified "retry-command" routine for commands with no data transfer phase
\ and simple error checking requirements.

: no-data-command  ( cmdbuf -- error? )
   >r  0 0 true  r> 6  -1  retry-command error?
;

\ short-data-command executes a command with the following characteristics:
\  a) The data direction is incoming
\  b) The data length is less than 256 bytes

\ The host adapter driver is responsible for supplying the DMA data
\ buffer; if the command succeeds, the buffer address is returned.
\ The buffer contents become invalid when another SCSI command is
\ executed, or when the driver is closed.

: short-data-command  ( data-len cmdbuf cmdlen -- true | buffer false )
   >r >r  inq-buf swap  true  r> r> -1  retry-command   ( retry-cmd-results )
   error?  dup 0=  if  inq-buf swap  then
;

headers

\ Here begins the implementation of "show-children", a word that
\ is intended to be executed interactively, showing the user the
\ devices that are attached to the SCSI bus.

\ Tool for storing a big-endian 24-bit number at an unaligned address

: 3c!  ( n addr -- )  >r lbsplit drop  r@ c!  r@ 1+ c!  r> 2+ c!  ;


\ Command block template for Inquiry command

create inquiry-cmd  h# 12 c, 0 c, 0 c, 0 c, ff c, 0 c,

external

: inquiry  ( -- error? )
   \ 8 retries should be more than enough; inquiry commands aren't
   \ supposed to respond with "check condition".
   \ However, empirically, on MC2 EVT1, 8 proves insufficient.

   inq-buf ff  true  inquiry-cmd 6  10  retry-command  error?
;

headers

\ Reads the indicated byte from the Inquiry data buffer

: inq@  ( offset -- value )  inq-buf +  c@  ;

: .scsi1-inquiry  ( -- )  inq-buf 5 ca+  4 inq@  fa min  type  ;
: .scsi2-inquiry  ( -- )  inq-buf 8 ca+  d# 28 type    ;

\ Displays the results of an Inquiry command to the indicated device

: show-lun  ( unit -- )
   dup  set-address                               ( unit )
   inquiry  if  drop exit  then                   ( unit )
   0 inq@  h# 60 and  if  drop exit  then         ( unit )
   ."   Unit " . ."   "                           ( )
   1 inq@  h# 80 and  if  ." Removable "  then    ( )
   0 inq@  case                                   ( )

      0 of  ." Disk "              endof
      1 of  ." Tape "              endof
      2 of  ." Printer "           endof
      3 of  ." Processor "         endof
      4 of  ." WORM "              endof
      5 of  ." Read Only device"   endof
      ( default ) ." Device type " dup .h
   endcase                                        ( )

   4 spaces
   3 inq@ 0f and  2 =  if  .scsi2-inquiry  else  .scsi1-inquiry  then
   cr
;

external

\ Searches for devices on the SCSI bus, displaying the Inquiry information
\ for each device that responds.

: show-children  ( -- )
   open  0=  if  ." Can't open SCSI host adapter" cr  exit  then

   max-lun 1+ 0  do  i show-lun  loop

   close
;

\ Inquire into the specified scsi device type and return the scsi
\ type and true if the device at the specified scsi address is found.

: get-scsi-type  ( lun -- false | type true )
   open  0=  if  2drop false exit  then
   set-address inquiry
   if  false  else  0 inq@ dup 7f =  if  drop false  else  true  then  then
   close
;

headers

\ The diagnose command is useful for generic SCSI devices.
\ It executes bothe "test-unit-ready" and "send-diagnostic"
\ commands, decoding the error status information they return.

create test-unit-rdy-cmd        0 c, 0 c, 0 c, 0 c, 0 c, 0 c,
create send-diagnostic-cmd  h# 1d c, 4 c, 0 c, 0 c, 0 c, 0 c,

: send-diagnostic ( -- error? )  send-diagnostic-cmd  no-data-command  ;


external

: diagnose  ( -- flag )
   0 0 true  test-unit-rdy-cmd 6   -1   ( dma$ dir cmd$ #retries )
   retry-command  if                    ( [ sensebuf ] hardware-error? )
      ." Test unit ready failed - "     ( [ sensebuf ] hardware-error? )
      if                                ( )
         ." hardware error (no such device?)" cr          ( )
      else                              ( sensebuf )
         ." extended status = " cr      ( sensebuf )
         base @ >r  hex                 ( sensebuf )
         8 bounds ?do  i 3 u.r  loop cr ( )
         r> base !
      then
      true
   else
      send-diagnostic  ( fail? )
   then
;

headers

\ LICENSE_BEGIN
\ Copyright (c) 2006 FirmWorks
\ 
\ Permission is hereby granted, free of charge, to any person obtaining
\ a copy of this software and associated documentation files (the
\ "Software"), to deal in the Software without restriction, including
\ without limitation the rights to use, copy, modify, merge, publish,
\ distribute, sublicense, and/or sell copies of the Software, and to
\ permit persons to whom the Software is furnished to do so, subject to
\ the following conditions:
\ 
\ The above copyright notice and this permission notice shall be
\ included in all copies or substantial portions of the Software.
\ 
\ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
\ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
\ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
\ NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
\ LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
\ OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
\ WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
\
\ LICENSE_END
