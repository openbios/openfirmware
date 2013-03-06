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
1 constant boot-ack-ok			\ Download ok
\ 0 constant boot-ack-fail		\ Download failed
\ 2 constant boot-ack-unsupported	\ Unsupported command

\ USB image download request structure
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

: cmd-fw-dl-ok?  ( adr len -- flag )
   2dup vldump                              ( adr len )
   /boot-ack <>  if                         ( adr )
      drop                                  ( )
      " Bad command status length" vtype
      false exit
   then                                     ( adr )
   dup >boot-magic le-l@ boot-magic <>  if  ( adr )
      drop                                  ( )
      " Bad magic number in boot response" vtype  ( )
      false exit
   then                                     ( adr )
   >cmd-status c@ boot-ack-ok =             ( ok? )
;

: wait-cmd-fw-dl-ack  ( -- acked? )
   d# 100 0  do			( )
      bulk-in-ready?  if	( error | buf len type 0 )
         if			( )
            false		( acked? )
         else			( buf len )
            cmd-fw-dl-ok?	( acked? )
         then			( acked? )
         recycle-packet         ( acked? )
         unloop exit
      then			( )
      1 ms			( )
   loop				( )
   false			( acked? )
;

: download-fw-init  ( -- )
   outbuf /boot-cmd erase
   boot-magic outbuf >boot-magic le-l!
   cmd-fw-dl  outbuf >boot-cmd   c!

   5 0  do
      outbuf /boot-cmd packet-out drop
      wait-cmd-fw-dl-ack  if  leave  then
   loop
;

: process-dl-resp  ( adr len -- )
   2dup vldump
   h# 8 <  if  ." Response too short" abort  then
   dup >dl-sync-seq le-l@ dl-seq <>  if  drop  ." Bad sequence" abort  then
   >dl-sync-ack le-l@  if  ." Image download failed" abort  then
;

: wait-fw-dl-ack  ( -- )
   d# 500 0  do				( )
      bulk-in-ready?  if		( error | buf len 0 )
         0= if  process-dl-resp  then	( )
         recycle-packet			( )
         leave
      then				( )
      1 ms				( )
   loop					( )
;

: (download-fw)  ( adr len -- )
   bounds  begin		( end start )
      dl-seq++				\ Increment sequence number
      dup outbuf /dl-header move	\ Move header to outbuf
      dl-seq outbuf >dl-seq le-l!	\ Add sequence number to outbuf
      dup /dl-header + outbuf >dl-data 2 pick >dl-len le-l@ dup >r move
					\ Move payload to outbuf
      outbuf r@ /dl-header + 4 + packet-out drop
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

: wait-fw  ( -- )
   \ We first get a response packet saying that the download completed
   wait-cmd-resp  if
      ." No firmware download response; continuing anyway"  cr
      d# 200 ms   \ Backwards compatibility with old firmware
      exit
   then

   \ Wait for the "started" indicator
   wait-event  if
      ." Timeout waiting for firmware-started event" cr
      exit
   then    ( event )

   h# 30 <>  if
      ." Unexpected event while waiting for firmware-started" cr
   then
;
: download-fw  ( adr len -- error? )
   2dup fw-image-ok? 0=  if  ." Bad WLAN firmware image" cr  true  exit  then
   download-fw-init
   (download-fw)

   wait-fw
   false
;

: load-all-fw  ( -- error? )
   fw-loaded?  if  false exit  then
   wlan-fw find-fw  ( adr len )
   dup  if  download-fw  else  2drop true  then  ( error? )
   dup 0=  to fw-loaded?                         ( error? )
;
: (setup-transport)  ( -- error? )
   setup-bus-io  ?dup  if  exit  then
   load-all-fw  dup  if  release-bus-resources  then  ( error? )
;
' (setup-transport) to setup-transport

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
