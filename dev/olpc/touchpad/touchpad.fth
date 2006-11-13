\ See license at end of file
\ Add this code to the existing mouse driver
dev /pci/isa/8042@i60/mouse

\ This program depends on the following routines from the
\ existing Open Firmware mouse driver:

\ open            initializes the port and resets the device
\ cmd             sends a command byte and waits for the ack
\ read1           reads 1 response byte
\ read2           reads 2 response bytes
\ mouse1:1        command e6
\ mouse2:1        command e7
\ stream-on       command f4
\ stream-off      command f5
\ mouse-status    command e9 and reads 3 response bytes
\ set-resolution  command e8 then sends another command byte
\ get-data?       reads a data byte if one is available
\ get-data        waits for and reads a data byte


\ The normal mouse driver uses remote mode, but this device
\ doesn't support remote mode, so patch the mouse driver
\ "open" routine to substitute "noop" for "remote-mode".

patch noop remote-mode open


\ Runs the special Device ID command and checks for the ALPS return code
\ Ref: 5.2.10 (1) of Hybrid-GP2B-T-1.pdf

\ The old version is 0a.00.67  -  It doesn't support, e.g. advanced status
\ The new version is 14.00.67  -  It matches the Hybrid-GP2B-T-1.pdf spec

: olpc-touchpad?  ( -- flag )
   mouse2:1 mouse2:1 mouse2:1 mouse-status  ( 67 0 a|14 )
   0 bljoin  dup  h# a0067 =  swap h# 140067 =  or
;

\ Ref: 5.2.10 (2-1) of Hybrid-GP2B-T-1.pdf
: advanced-mode  ( -- )  4 0 do  stream-off  loop  ;  \ 4 f5 commands

\ Ref: 5.2.10 (2-2) of Hybrid-GP2B-T-1.pdf
: mouse-mode  ( -- )  h# ff read2 drop drop  ;  \ Response is 0,aa

\ Send the common "three f2 commands" prefix.  "f2" is normally the
\ "identify" command; the response (for a mouse-like device) is 0x00
: alps-prefix  ( -- )  3 0  do  h# f2 read1 drop  loop  ;

\ Ref: 5.2.10 (3) of Hybrid-GP2B-T-1.pdf
: pt-only  ( -- )  alps-prefix mouse2:1  ;  \ f2 f2 f2 e7
: gs-only  ( -- )  alps-prefix mouse1:1  ;  \ f2 f2 f2 e6
: gs-first  ( -- )  alps-prefix 0 set-resolution  ;
: pt-first  ( -- )  alps-prefix 1 set-resolution  ;
: simultaneous-mode  ( -- )  alps-prefix 2 set-resolution  ;

\ I have been unable to get this to work.  The response is always
\ 64 0 <something>, which doesn't agree with the spec.
\ Perhaps the touchpad version that I have doesn't implement the,
\ advanced version, but instead returns traditional mouse status?

: advanced-status  ( -- b1 b2 b3 )  alps-prefix mouse-status  ;

\ The following code receives and decodes touchpad packets in the
\ various special formats

\ Wait up to "ms" milliseconds for a data byte
\ This is used to get the first byte of a packet, if there is one.
: timed-get-data  ( ms -- true | b false )
   get-msecs +   ( time-limit )
   begin
      get-data?  if  nip false exit  then  ( time-limit )
      dup get-msecs - 0<                   ( time-limit )
   until                                   ( time-limit )
   drop true
;

\ This is used to get subsequent packet bytes, after the first
\ byte of a packet has already been received.
\ : quick-byte  ( -- b )
\    d# 2 timed-get-data abort" Touchpad timeout"
\ ;
: quick-byte  get-data  ;


\ Variable used during packet decoding
0 value px    \ Pen mode x value
0 value py    \ Pen mode y value
0 value gx    \ Glide pad x value
0 value gy    \ Glide pad y value
0 value gz    \ Glide pad z value, also used fo pen mode x
0 value taps      \ Bitmask of tap flags
0 value switches  \ Bitmask of switch flags

\ Extract bits 7-9 from a packet byte and move them into place
: bits7-9  ( n -- n' )   4 rshift 7 lshift  ;

\ Extract bits 7-10 from a packet byte and move them into place
: bits7-10  ( n -- n' )  3 rshift 7 lshift  ;

\ Reads the next packet byte, extracts the tap bits, returns the rest
: tapbits   ( -- byte tapbit )  quick-byte dup 3 and   ;

\ Reads the next packet byte, extracts the switch bits, returns the rest
: set-switches  ( -- b )  quick-byte dup 3 and to switches  ;

\ Ref: 5.2.9 (2) (3) of Hybrid-GP2B-T-1.pdf
: decode-simultaneous  ( -- )
   quick-byte to gx                  \ byte 2

   quick-byte                        ( byte3 )
   dup  bits7-10  gx or  to gx       ( byte3 )
   7 and  7 lshift to px             ( )

   tapbits to taps                   ( byte4 )
   bits7-9                           ( gy.high )
   quick-byte or  to gy              \ byte 5

   quick-byte  to gz                 \ byte 6

   quick-byte                        ( byte7 )
   set-switches  bits7-9             ( py.high )

   quick-byte  or  to py             \ byte 8

   quick-byte  px or  to px          \ byte 9
;

\ This lookup table intechanges the 2 low bits.  The PT and GS
\ data formats have the low 2 bits of byte 3 swapped.
create swbits  0 c,  2 c,  1 c,  3 c,

\ Ref: 5.2.9 (2) (1) of Hybrid-GP2B-T-1.pdf
: decode-pt  ( -- )
   quick-byte                        ( px.low )

   tapbits swbits + c@  to taps      ( px.low byte3 )
   bits7-9 or  to px                 ( )

   set-switches bits7-9              ( py.high )
   quick-byte or to py

   quick-byte to gz
;

\ Ref: 5.2.9 (2) (2) of Hybrid-GP2B-T-1.pdf
: decode-gs  ( -- )
   quick-byte                  ( gx.low )

   tapbits  to taps            ( gx.low byte3 )
   bits7-10 or  to gx          ( )

   set-switches bits7-9        ( gy.high )
   quick-byte or  to gy        ( )

   quick-byte to gz
;

\ Wait up to 20 milliseconds for a new touchpad packet to arrive.
\ If one arrives, decode it.
: poll-touchpad  ( -- got-packet? )
   begin
      d# 20 timed-get-data  if  false exit  then  ( byte )

      case
         h# eb  of  decode-simultaneous exit  endof

         h# cf  of
            decode-pt
            \ Check for an immediately-following gs report
            d# 2 timed-get-data  0=  if  ( byte )
               h# ff =  if  decode-gs  then
            then
            true exit
         endof

         h# ff  of
            decode-gs
            \ Check for an immediately-following pt report
            d# 2 timed-get-data  0=  if  ( byte )
               h# cf =  if  decode-pt  then
            then
            true  exit
         endof

         ( default )
            \ If the high bit is set it means it's the first byte
            \ of a packet.  Abort if we don't recognize the type.
            dup h# 80 and dup u.  abort" Touchpad protocol botch"
      endcase
   again
;

\ Try to receive a GS-format packet.  If one arrives within
\ 20 milliseconds, return true and the decoded information.
\ Otherwise return false.
: gs?  ( -- false | gx gy gz tap? true )
   poll-touchpad  0=  if  false exit  then
   gx gy gz  taps 3 and   true
;

\ Try to receive a PT-format packet.  If one arrives within
\ 20 milliseconds, return true and the decoded information.
\ Otherwise return false.
: pt?  ( -- false | px py tap? true )
   poll-touchpad  0=  if  false exit  then
   px py  taps 3 and   true
;

\ Put the device into advanced mode and enable it
: start  ( -- )  advanced-mode  stream-on  ;

\ Switch the device to pen tablet format and display
\ the data that it sends.  Stop when a key is typed.
: show-pt  ( -- )
   start
   pt-only
   begin
      pt?  if  . . . cr  then
   key? until
;

\ Switch the device to glide format and display
\ the data that it sends.  Stop when a key is typed.
: show-gs  ( -- )
   start
   gs-only
   begin
      gs?  if  . . . . cr  then
   key? until
;

\ We are finished adding code to the mouse driver.
\ Go back to the main forth context
device-end

\ Now the new driver is ready to use.

\ To use the new driver interactively, execute (without the \):
\ select /pci/isa/8042@i60/mouse
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
