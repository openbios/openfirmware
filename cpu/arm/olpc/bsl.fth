\ See license at end of file
purpose: Downloader for TI MSP430 BootStrap Loader (BSL) protocol

\ devalias bsl /uart@NNNN:9600,8,e,1//bsl-protocol

h# fe016000 value bsl-uart-base \ Virtual address of UART; set later

: bsl-baud  ( baud-rate -- )   \ 9600,8,e,1
   uart-base >r  bsl-uart-base to uart-base  baud  h# 1b 3 uart!  r> to uart-base
;

: send  ( char -- )  uart-base >r  bsl-uart-base to uart-base  uemit  r> to uart-base  ;

: receive?  ( -- false | char true )
   uart-base >r  bsl-uart-base to uart-base
   ukey?  if  ukey true  else  false  then
   r> to uart-base
;

0 value rst-gpio#
0 value test-gpio#
\ : bsl-config-test  ( -- )
: init-gpios
   fallback-in-ih  ?dup  if  dup remove-input  close-dev  0 to fallback-in-ih   then
   fallback-out-ih ?dup  if  dup remove-output close-dev  0 to fallback-out-ih  then

   d# 115 to test-gpio#
   d# 116 to rst-gpio#

   test-gpio#   0 swap af!  
   rst-gpio#    0 swap af!  
;

: bsl-open  ( -- )
   init-gpios

   rst-gpio# gpio-clr
   test-gpio# gpio-clr
   rst-gpio# gpio-dir-out
   test-gpio# gpio-dir-out
   h# 16000 +io to bsl-uart-base   

   d# 9600 bsl-baud
;
: bsl-close  ( -- )
   rst-gpio# gpio-dir-in
   test-gpio# gpio-dir-in
;
: msp430-off  ( -- )
   rst-gpio# gpio-clr
   test-gpio# gpio-clr
;

: dly  ( -- )  d# 10 ms  ;
: start-bsl  ( -- )
   bsl-open
   d# 250 ms
   test-gpio# gpio-set
   dly
   test-gpio# gpio-clr
   dly
   test-gpio# gpio-set
   dly
   rst-gpio# gpio-set
   dly
   test-gpio# gpio-clr
;
: flush-bsl  ( -- )  begin  receive?  while  drop  repeat  ;
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
               ." NAK!"
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
      h# 80 send  ack?  if  unloop exit  then
   loop
   true abort" BSL unresponsive"
;

0 value checksum

: +sum  ( w -- )  checksum xor to checksum ;
: send-summed  ( w -- )
   dup +sum  wbsplit swap send  send
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
   checksum h# ffff xor  wbsplit swap send send
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
   )frame
;
: ff-password  ( -- )
   " "(ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff)"
   rx-password
;
: 00-password  ( -- )
   " "(00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 ff)"
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
: erase-main  ( device-adr -- )  h# a504 (erase)  ;
: mass-erase  ( -- )  0 h# a506 (erase)  ;
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
: handle-line  ( adr len -- )
   dup 0=  if  2drop exit  then    ( adr len )
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
: force-erase  ( -- )
   ." Resetting/erasing" cr
   rst-bsl
   ['] 00-password catch drop
   rst-bsl
   ff-password
;
d# 100 buffer: line-buf
: $bsl-ti-text-file  ( filename$ -- )
   $read-open       ( )
   force-erase      ( )
   ." Programming" cr
   begin            ( )
      line-buf d# 100 ifd @ read-line abort" Read line failed"
   while                          ( len )
      line-buf swap handle-line   ( )
   repeat                         ( len )
   drop
   ifd @ fclose   
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
