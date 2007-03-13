purpose: Marvel USB 8388 firmware loader
\ See license at end of file


\ =======================================================================
\ Firmware download data structures
\ =======================================================================

h# 4c56.524d constant boot-magic

\ USB boot2 command
struct
   4 field >boot-magic			\ boot-magic
   1 field >boot-cmd
   d# 11 +
constant /boot-cmd

\ >boot-cmd constants
1 constant cmd-fw-dl			\ Download firmware
2 constant cmd-fw-boot			\ Boot from EEPROM firmware
3 constant cmd-boot2-update		\ Download and update boot2
4 constant cmd-fw-update		\ Download and update firmware

\ USB boot2 ACK
struct
   5 +					\ Same fields in /boot-cmd
   1 field >cmd-status
   2 +
constant /boot-ack

\ >cmd-ack-status
0 constant boot-ack-ok			\ Download ok
1 constant boot-ack-fail		\ Download failed

\ Bulk out transfer: USB image download
struct
   4 field >dl-cmd			\ Download command
   4 field >dl-ba			\ Address in the device
   4 field >dl-len			\ Data length
   4 field >dl-crc
dup constant /dl-header
   4 field >dl-seq
   0 field >dl-data
drop

\ >dl-cmd constants
1 constant dl-block			\ Download image block
4 constant dl-done			\ Download image done

\ USB image download sync ACK
struct
   4 field >dl-sync-ack			\ Command ack: 0=ok, 1=failure
   4 field >dl-sync-seq			\ 0-based download block sequence #
constant /dl-sync


\ =========================================================================
\ Firmware Download
\
\ Host driver sends USB boot2 command to USB 8388.  If it does not get
\ the USB boot2 ack, it retries the boot2 command upto 5 times.
\
\ Then the driver should start download USB image.
\ =========================================================================

-1 value dl-seq

: dl-seq++  ( -- )  dl-seq 1+ to dl-seq  ;

: cmd-fw-dl-ok?  ( len -- flag )
   inbuf over vldump
   /boot-ack <>  if  " Bad command status length" vtype false exit  then
   inbuf >boot-magic le-l@ boot-magic <>  if  " Bad signature" vtype false exit  then
   inbuf >cmd-status c@ boot-ack-ok =
;

: wait-cmd-fw-dl-ack  ( -- acked? )
   false d# 100 0  do
      bulk-in?  if
         restart-bulk-in drop leave	\ USB error
      else
         ?dup  if
            cmd-fw-dl-ok? nip
            restart-bulk-in
            leave
         then
      then
      1 ms
   loop
;

: download-fw-init  ( -- )
   outbuf /boot-cmd erase
   boot-magic outbuf >boot-magic le-l!
   cmd-fw-dl  outbuf >boot-cmd   c!

   inbuf /inbuf bulk-in-pipe begin-bulk-in
   5 0  do
      outbuf /boot-cmd bulk-out-pipe bulk-out drop
      wait-cmd-fw-dl-ack  if  leave  then
   loop
;

: process-dl-resp  ( len -- )
   inbuf over vldump
   h# 8 <  if  ." Response too short" abort  then
   inbuf >dl-sync-seq le-l@ dl-seq <>  if  ." Bad sequence" abort  then
   inbuf >dl-sync-ack le-l@ if  ." Image download failed" abort  then
;

: wait-fw-dl-ack  ( -- )
   d# 500 0  do
      bulk-in?  if
         drop restart-bulk-in  leave
      else
         ?dup if
            process-dl-resp
            restart-bulk-in
            leave
         else
            1 ms
         then
      then
   loop
;

: (download-fw)  ( adr len -- )
   bounds  begin		( end start )
      dl-seq++				\ Increment sequence number
      dup outbuf /dl-header move	\ Move header to outbuf
      dl-seq outbuf >dl-seq le-l!	\ Add sequence number to outbuf
      dup /dl-header + outbuf >dl-data 2 pick >dl-len le-l@ dup >r move
					\ Move payload to outbuf
      outbuf r@ /dl-header + 4 + bulk-out-pipe bulk-out drop
					\ Send command
      wait-fw-dl-ack			\ Wait for ACK
      r> + /dl-header +			\ Advance pointer
      2dup <=				\ Test done condition
   until  2drop
;

: fw-image-ok?  ( adr len -- flag )
   bounds false -rot  begin		( flag end start )
      dup >dl-cmd le-l@  case
         dl-block  of  dup >dl-len le-l@ + /dl-header +  2dup <=  endof
         dl-done   of  rot drop true -rot true  endof
         ( default )  true swap
      endcase
   until  2drop
;

: download-fw  ( adr len -- )
   driver-state ds-not-ready <>  if  " Firmware downloaded" vtype 2drop exit  then
   2dup fw-image-ok? 0=  if  ." Bad WLAN firmware image" abort  then
   download-fw-init
   (download-fw)
   wait-cmd-resp drop			\ A packet is sent after download completes
   ds-ready to driver-state
   marvel-get-mac-address
;


\ LICENSE_BEGIN
\ Copyright (c) 2007 FirmWorks
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
