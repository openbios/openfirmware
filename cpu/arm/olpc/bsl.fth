\ See license at end of file
purpose: Downloader for TI MSP430 BootStrap Loader (BSL) protocol


\ TODO:
\  friendlier programming interface ( "ok flash-bsl u:\file.hex")
\  progress indicator during programming
\  print, perhaps in red, the msp430 password after programming,
\     iff the password doesn't match all-ff or the known neonode password.
\  save calibration data in mfg tag, in case it's lost.
\  create msp430 recalibrator programmer

\ devalias bsl /uart@NNNN:9600,8,e,1//bsl-protocol

\ the MSP430 BSL has the annoying trait that it will self-erase if
\  an incorrect password is used to access its restricted functions. 
\  worse, the self-erase includes the factory-supplied calibration
\  values.  happily, if a specific interrupt vector (at address
\  0xffde) is set to null, using a bad password won't cause an
\  erase.  but that still leaves us with the inability to program
\  the flash.
\
\  there are several cases to consider:
\
\      - a fresh, blank chip, with calibration data.
\          the password for this chip is all-ff.
\      - a programmed chip, with calibration data.
\          the password for this chip is supplied by neonode.
\      - a mishandled chip:  blank, with no calibration data
\          the password for this chip is all-ff.
\
\  when programming, _always_ finish by writing 0000 to 0xffde. 
\  this ensures that a subsequent bad password will preserve
\  calibration data.  neonode has already said that their firmware
\  will set that value to 0, but this ensures it for any image
\  written.
\
\  to erase the chip, and leave it accessible for programming:
\
\      send an all-ff password,
\      if nak'd, send the neonode password.
\      if nak'd, send the all-ff password (again, in case erase has occurred)
\      if nak'd, we're hosed, give up.
\
\      \ we were acked (one of those passwords worked)
\      send the 'erase main' command
\      write 0000 to ffde
\
\      if the calibration data is missing (i.e., all-ff),
\          program and run a calibration program, which should
\                write new calibration values
\          send the 'erase main' command
\
\      program the new image


\ This is platform-dependent

: setup-gpios  ( -- )
\ The pin setup should be done in CForth, but it's complicated by
\ the fact that the touch-enabled CL2 uses GPIO 56 differently from
\ the ordinary one
[ifdef] olpc-cl2
   3 d# 55 af!                 \ Setup pins for UART2
   3 d# 56 af!
   0 touch-tck-gpio# af!       \ Set to GPIO function
   1 touch-rst-gpio#  af!      \ Set to GPIO function (AF0 is SM_BELn for this pin)
[then]
;

0 [if]
\ This is for the test system on which this code was originally developed
: setup-gpios-hack  ( -- )
   \ On the test system, the BSL device is driven from the console UART,
   \ not a dedicated UART, so we must disconnect that UART from the console mux
   fallback-in-ih  ?dup  if  dup remove-input  close-dev  0 to fallback-in-ih   then
   fallback-out-ih ?dup  if  dup remove-output close-dev  0 to fallback-out-ih  then

   h# 16000 +io to bsl-uart-base   \ UART4

   d# 115 to test-gpio#  \ Normally UART3 TXD, but repurposed as a GPIO
   d# 116 to rst-gpio#   \ Normally UART3 RXD, but repurposed as a GPIO

   0 touch-tck-gpio# af!  \ Set to GPIO function instead of UART3
   0 touch-rst-gpio#  af!  \ Set to GPIO function instead of UART3
;
[then]

\ These are MMP2/3 dependent

: bsl-baud  ( baud-rate -- )   \ 9600,8,e,1
   uart-base >r                 ( baud-rate r: uart-base )
   bsl-uart-base to uart-base
   h# 13 bsl-uart-clock-offset apbc!      \ enable the uart2 clocks
   h# 40 1 uart!                          \ uart unit enable
   baud  h# 1b 3 uart!          ( r: uart-base )
   r> to uart-base              ( )
;

: bsl-send  ( char -- )  uart-base >r  bsl-uart-base to uart-base  uemit  r> to uart-base  ;

: receive?  ( -- false | char true )
   uart-base >r  bsl-uart-base to uart-base
   ukey?  if  ukey true  else  false  then
   r> to uart-base
;


\ After this point the code is largely generic

: bsl-open  ( -- )
   setup-gpios

   touch-rst-gpio# gpio-clr
   touch-tck-gpio# gpio-clr
   touch-rst-gpio# gpio-dir-out
   touch-tck-gpio# gpio-dir-out

   d# 9600 bsl-baud
;
: bsl-close  ( -- )
   touch-rst-gpio# gpio-dir-in
   touch-tck-gpio# gpio-dir-in
;
: msp430-off  ( -- )
   touch-rst-gpio# gpio-clr
   touch-tck-gpio# gpio-clr
;

: dly  ( -- )  d# 10 ms  ;
: start-bsl  ( -- )
   bsl-open
   d# 250 ms
   touch-tck-gpio# gpio-set
   dly
   touch-tck-gpio# gpio-clr
   dly
   touch-tck-gpio# gpio-set
   dly
   touch-rst-gpio# gpio-set
   dly
   touch-tck-gpio# gpio-clr
;

: flush-bsl
   get-msecs d# 2000 +                  ( limit )
   begin
      receive?  0=  if drop exit  then      ( limit char )
      drop  dup get-msecs - 0<          ( limit timeout? )
   until
   drop  true abort" BSL flush timeout"
;

: rst-bsl  ( -- )  msp430-off  start-bsl  flush-bsl  ;

d# 1000 constant timeout
: wait-byte  ( -- char )
   get-msecs timeout +        ( limit )
   begin                      ( limit )
      receive?  if            ( limit char )
         nip exit             ( -- char )
      then                    ( limit )
      dup get-msecs - 0<      ( limit timeout? )
   until                      ( limit )
   drop  true abort" BSL data timeout"
;

: ack?  ( -- okay? )
   get-msecs timeout +        ( limit )
   begin                      ( limit )
      receive?  if            ( limit char )
         case
            h# 90  of         ( limit )
               drop true exit ( -- true )
            endof
            h# a0  of         ( limit )
               \ ." NAK!"
               drop false exit
            endof
         endcase
      then                    ( limit )
      dup get-msecs - 0<      ( limit timeout? )
   until                      ( limit )
   drop false                 ( false )
;
: bsl-sync  ( -- )
   d# 4  0  do
      h# 80 bsl-send  ack?  if  unloop exit  then
   loop
   true abort" BSL unresponsive"
;

0 value checksum

: +sum  ( w -- )  checksum xor to checksum ;
: send-summed  ( w -- )
   dup +sum  wbsplit swap bsl-send  bsl-send
;
: send-length  ( n -- )
   dup 1 and  abort" BSL odd length!"
   dup d# 255 >  abort" BSL length >255"
   dup bwjoin send-summed
;
: frame(  ( extra-len cmd -- )
   bsl-sync               ( extra-len cmd )
   0 to checksum          ( extra-len cmd )
   h# 80 swap bwjoin      ( extra-len cmd,hdr )
   send-summed            ( extra-len )
   4 + send-length        ( )
;

: send-address  ( w -- )  send-summed  ;
: send-data-length  ( w -- )  send-summed  ;
: send-xx  ( -- )  0 send-summed  ;  \ Send don't care word
: send-data  ( adr len -- )
   bounds  ?do  i le-w@ send-summed  /w +loop
;
: )frame-no-ack  ( -- )
   checksum h# ffff xor  wbsplit swap bsl-send bsl-send
;
: )frame  ( -- )
   )frame-no-ack
   ack?  0=  abort" BSL - no ACK!"
;

: rx-data-block  ( adr len device-adr -- )
   over  h# 12 frame(     ( adr len device-adr )
   send-summed            ( adr len )   \ device address
   dup send-summed        ( adr len )   \ data length
   send-data              ( )
   )frame
;
: rx-password  ( adr len -- )
   dup d# 32 <> abort" BSL password must be 32 bytes long"
   dup  h# 10 frame(     ( adr len )
   send-xx send-xx       ( adr len )
   send-data             ( )
   )frame-no-ack
;

   
: ff-password  ( -- )
   " "(ff ff ff ff  ff ff ff ff  ff ff ff ff  ff ff ff ff  ff ff ff ff  ff ff ff ff  ff ff ff ff  ff ff ff ff)"
   rx-password
;
: 00-password  ( -- )
   " "(00 00 00 00  00 00 00 00  00 00 00 00  00 00 00 00  00 00 00 00  00 00 00 00  00 00 00 00  00 00 00 00)"
   rx-password
;

: neo-password  ( -- )
   " "(30 fe 30 fe  00 fe 04 fe  30 fe 08 fe  0c fe 10 fe  14 fe 18 fe  1c fe 30 fe  20 fe 24 fe  28 fe 2c fe)"
   rx-password
;

: (erase)   ( device-adr code -- )
   swap                  ( device-adr code )
   0  h# 16 frame(       ( code device-adr )
   send-summed           ( code )
   send-summed           ( )
   )frame
;
: erase-segment  ( device-adr -- )  h# a502 (erase)  ;
: erase-main  ( -- )  h# 8000 h# a504 (erase)  ;
: erase-info  ( -- )  h# 1000 h# a504 (erase)  ;
: mass-erase  ( -- )  0 h# a506 (erase)  ;

: erase-check ( device-adr len -- )
   swap               ( len device-adr )
   0 h# 1c frame(     ( len device-adr )
   send-summed        ( len )
   send-summed
   )frame-no-ack
;
   
: change-baud-rate  ( d3 d2 d1 -- )
   0  h# 20 frame(          ( d3 d2 d1 )
   swap bwjoin send-summed  ( d3 )
   send-summed              ( )
   )frame
;
: set-mem-offset  ( device-adr -- )
   0 h# 21 frame(     ( device-adr )
   send-xx            ( device-adr )
   send-summed        ( )
   )frame
;
: load-pc  ( device-adr -- )
   0 h# 1a frame(     ( device-adr )
   send-summed        ( )
   send-xx            ( )
   )frame
;
: wait-word  ( -- w )  wait-byte wait-byte  bwjoin dup +sum  ;

: )frame-receive  ( adr len -- )
   )frame-no-ack
   wait-byte  case
      h# 80 of  endof
      h# a0 of  true abort" NAK!"  endof
      ( default )  ." Received unexpected response frame first byte " dup .x  cr
           abort
   endcase
   wait-byte  ?dup  if
      ." Received unexpected response frame second byte " dup .x  cr
      abort
   then
   h# 80 to checksum

   wait-word  wbsplit  ( adr len response-len1 response-len2 )

   over <>  abort" BSL - response length check byte mismatch"  ( adr len response-len )
   over <>  abort" BSL - unexpected response length"  ( adr len )
   bounds ?do  wait-word  i le-w!   /w +loop          ( )
   wait-word drop                                     ( )  \ Get checksum and add it in
   checksum h# ffff <>  abort" BSL - bad response checksum"       ( )
;
: tx-data-block  ( adr len device-adr -- )
   0 h# 14 frame(    ( adr len device-adr )
   send-summed       ( adr len )
   dup send-summed   ( adr len )
   )frame-receive    ( )
;
: tx-bsl-version  ( adr len -- )
   dup d# 16 <> abort" BSL version buffer must be 16 bytes long"
   0 h# 1e frame(    ( adr len )
   send-xx           ( adr len )
   send-xx           ( adr len )
   )frame-receive    ( )
;

d# 250 constant /bsl-max-read
: bsl-read  ( adr len device-adr -- )
   >r even                    ( adr len'  r: device-adr )
   begin  dup 0>  while       ( adr len   r: device-adr )
      r@ (cr .x 
      2dup /bsl-max-read min  ( adr len  adr thislen  r: device-adr )
      r@ tx-data-block        ( adr len   r: device-adr )
      /bsl-max-read /string   ( adr' len' r: device-adr )
      r> /bsl-max-read + >r   ( adr len   r: device-adr' )
   repeat                     ( adr len   r: device-adr' )
   r>  3drop
;

: null-ffde!  ( -- )
   " "(00 00)" h# ffde rx-data-block
;

: calibration-missing  ( -- missing? )
    h# 1000 h# 100 erase-check ack?
;

: do-calibration  ( -- )
   \ erase-info
   \ FIXME
;

: force-erase  ( -- )
   rst-bsl
   ff-password ack? dup 0= if
	drop
	neo-password ack? dup 0= if
	    drop
	    ff-password ack? dup 0= if
		drop
		." BSL is locked" exit
	    then
	then
   then
   erase-main
   null-ffde!

   calibration-missing if
	do-calibration null-ffde!
   then
;

\ Decoder for TI TXT file format

0 value next-address
0 value line-#bytes
d# 50 buffer: binary-buf

: hex-number  ( adr len -- n )
   push-hex          ( adr len )
   $number abort" Bad number in TI TXT file"  ( n )
   pop-base
;
: program-bytes  ( adr len -- )
   d# 50 0  do                ( adr len )
      dup  if                 ( adr len )
         bl left-parse-string ( adr' len' head$ )
         hex-number           ( adr len n )
         binary-buf i + c!    ( adr len )
      else                    ( adr len )
         2drop                ( )
         (cr next-address .   ( )
         i 1 and  if          ( )
            h# ff binary-buf i + c!  ( )
            i 1+                     ( len )
         else                        ( )
	    i                        ( len )
         then
         binary-buf swap next-address rx-data-block
	 next-address i + to next-address
	 unloop exit
      then
   loop                       ( adr len )
   true abort" TI TXT Line too long!"
;
: ti-txt-handle-line  ( adr len -- )
   dup 0=  if  2drop cr exit  then    ( adr len )
   over c@  case
      [char] @ of                  ( adr len )
         1 /string  hex-number to next-address
      endof
      [char] q  of                 ( adr len )
         2drop                     ( )
      endof                        ( adr len )
      ( default )                  ( adr len char )
         -rot  program-bytes       ( char )
   endcase                         ( )
;

\ Decoder for Intel HEX format file
\needs parse-ihex-record fload ${BP}/forth/lib/intelhex.fth

0 value ihex-hi-adr
: ihex-handle-line  ( adr len -- )
   dup 0=  if  2drop cr exit  then                ( adr len )
   \ 2dup type cr
   parse-ihex-record                           ( data-adr data-len offset type )
   case
      0 of   \ Data                            ( data-adr data-len offset )
         ihex-hi-adr +                         ( data-adr dat-len absaddr )
	 \ the BSL protocol needs even lengths, so
	 \ force the record length to even
	 \ (yes, this may program write garbage to the extra byte.)
         swap dup 1 and if 1 + then swap       ( data-adr evenlen absaddr )
         rx-data-block                         ( )
      endof
      1 of   \ End of file                     ( data-adr data-len offset )
         3drop                                 ( )
      endof
      2 of   \ Segment address                 ( data-adr data-len offset )
         2drop le-w@ 4 lshift  to ihex-hi-adr  ( )
      endof
      3 of   \ Start segment address           ( data-adr data-len offset )
         3drop
      endof
      4 of   \ Extended linear address         ( data-adr data-len offset )
         2drop le-w@ d# 16 lshift  to ihex-hi-adr  ( )
      endof
      5 of   \ Start address                   ( data-adr data-len offset )
         3drop
      endof
      ( default )  true abort" Bogus ihex record type"
   endcase
;

defer bsl-handle-line

: set-bsl-file-format  ( -- )
   ifd @ fgetc  case
      [char] : of
         ['] ihex-handle-line  to bsl-handle-line
      endof
      [char] @ of
         ['] ti-txt-handle-line  to bsl-handle-line
      endof
      ( default )
      ifd @ fclose
      true abort" Unsupported file format for BSL programming"
   endcase

   0 ifd @ fseek
;

d# 100 buffer: bsl-line-buf
: $flash-bsl  ( filename$ -- )
   $read-open           ( )
   set-bsl-file-format  ( )
   ." Resetting/erasing" cr
   force-erase          ( )
   ." Programming" cr
   begin                ( )
      bsl-line-buf d# 100 ifd @ read-line abort" Read line failed"
   while                               ( len )
      bsl-line-buf swap                ( adr len )
      ['] bsl-handle-line  catch  ?dup  if  ( x x throw-code )
         ifd @ fclose  throw           ( ?? -- )
      then                             ( )
   repeat                              ( len )
   drop                                ( )
   ifd @ fclose                        ( )
;

\ This is a destructive test in that it erases whatever firmware happens
\ to already be in the device.


h# 70 value /bsl-chunk
/bsl-chunk buffer: bsl-buf
: bsl-write  ( adr len device-adr -- )
   to next-address             ( adr len )
   begin  dup  while           ( adr len )
      dup /bsl-chunk min       ( adr len thislen )
      third over next-address rx-data-block  ( adr len thislen )
      dup next-address + to next-address     ( adr len thislen )
      /string                  ( adr' len' )
   repeat                      ( adr 0 )
   2drop                       ( )
;
: bsl-verify  ( adr len device-adr -- okay? )
   to next-address                    ( adr len )
   begin  dup  while                  ( adr len )
      dup /bsl-chunk min              ( adr len thislen )
      bsl-buf over next-address tx-data-block  ( adr len thislen )
      third bsl-buf third  comp  if   ( adr len thislen )
         3drop false exit             ( -- false )
      then                            ( adr len thislen )
      dup next-address + to next-address     ( adr len thislen )
      /string                         ( adr' len' )
   repeat                             ( adr 0 )
   2drop                              ( )
   true                               ( true )
;
h# 3000 constant /bsl-test-buf
/bsl-test-buf buffer: bsl-test-buf
0 value bsl-test-init?
: bsl-test-data  ( -- adr len )
   bsl-test-init? 0=  if
      bsl-test-buf  /bsl-test-buf  bounds  ?do
         random-long  i l!
     /l +loop
     true to bsl-test-init?
   then
   bsl-test-buf /bsl-test-buf
;
: test-msp430   ( -- )
   ." Erasing ..." force-erase cr
   ." Writing ..." bsl-test-data h# 8000 bsl-write  cr  ( )
   ." Verifying ..."  bsl-test-data h# 8000 bsl-verify  cr  ( okay? )
   if  ." Good"  else  ." FAILED!"  then  cr
;

\ LICENSE_BEGIN
\ Copyright (c) 2012 FirmWorks
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
