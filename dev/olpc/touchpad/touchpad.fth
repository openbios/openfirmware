\ See license at end of file
\ Add this code to the existing mouse driver
dev /mouse

variable 'get-data  'get-data  off
variable 'get-data? 'get-data? off

: setup  ( -- )
   'get-data @  0=  if
      " get-data" my-parent ihandle>phandle find-method  if
         'get-data !
      then
   then
   'get-data? @  0=  if
      " get-data?" my-parent ihandle>phandle find-method  if
         'get-data? !
      then
   then
;


h# f800 constant red
h# 07e0 constant green
h# 001f constant blue
h# ffe0 constant yellow
h# f81f constant magenta
h# 07ff constant cyan
h# ffff constant white
h# 0000 constant black

variable pixcolor

h# 4 value y-offset
0 value screen-w
0 value screen-h
0 value /line
2 value /pixel


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


variable ptr
0 value show-raw?

\ Runs the special Device ID command and checks for the ALPS return code
\ Ref: 5.2.10 (1) of Hybrid-GP2B-T-1.pdf

\ The old version is 0a.00.67  -  It doesn't support, e.g. advanced status
\ The new version is 14.00.67  -  It matches the Hybrid-GP2B-T-1.pdf spec

: touchpad-id  ( -- n )
   mouse2:1 mouse2:1 mouse2:1 mouse-status  ( 67 0 a|14|28 )
   0 bljoin
;

: olpc-touchpad?  ( -- flag )
   touchpad-id  h# ffff and  h# 0067 =
;

\ Ref: 5.2.10 (2-1) of Hybrid-GP2B-T-1.pdf
: advanced-mode  ( -- )  stream-off stream-off stream-off stream-off  ;  \ 4 f5 commands

\ Ref: 5.2.10 (2-2) of Hybrid-GP2B-T-1.pdf
: mouse-mode  ( -- )  h# ff read2 drop drop  ;  \ Response is 0,aa

\ Send the common "three f2 commands" prefix.  "f2" is normally the
\ "identify" command; the response (for a mouse-like device) is 0x00
: alps-prefix  ( -- )  3 0  do  h# f2 read1 drop  loop  ;

variable mode  \ 0 - unknown  1 - GS  2 - PT  3 - mouse
0 instance value packet-type

\ Ref: 5.2.10 (3) of Hybrid-GP2B-T-1.pdf
: gs-only  ( -- )
   mode @  3 =  if  exit  then
   alps-prefix mouse1:1    \ f2 f2 f2 e6
   1 mode !
;
: pt-only  ( -- )
   mode @  3 =  if  exit  then
   alps-prefix mouse2:1    \ f2 f2 f2 e7
   2 mode !
;
\ : gs-first  ( -- )  alps-prefix 0 set-resolution  ;
\ : pt-first  ( -- )  alps-prefix 1 set-resolution  ;
\ : simultaneous-mode  ( -- )  alps-prefix 2 set-resolution  ;

\ Put the device into advanced mode and enable it
: start  ( -- )
   setup
   olpc-touchpad?  if
      0 mode !  advanced-mode stream-on
   else
      remote-mode  3 mode !
   then
;

\ The normal mouse driver uses remote mode, but this device
\ doesn't support remote mode, so patch the mouse driver
\ "open" routine to substitute "noop" for "remote-mode".

patch start remote-mode open


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
      'get-data? @  my-parent  call-package  if  nip false exit  then  ( time-limit )
      dup get-msecs - 0<                   ( time-limit )
   until                                   ( time-limit )
   drop true
;

: record-byte  ( b -- b )  dup ptr @ c!  1 ptr +!  ;

\ This is used to get subsequent packet bytes, after the first
\ byte of a packet has already been received.
\ : quick-byte  ( -- b )
\    d# 2 timed-get-data abort" Touchpad timeout"
\ ;
: quick-byte
   'get-data @  my-parent  call-package
   record-byte
   show-raw?  if  dup .  then
   dup h# 80 and  if  ." *" dup .  then
;

: show-packets  ( adr len -- )
   push-hex
   bounds  ?do
      i 6  bounds  ?do  i c@  3 u.r  loop  cr
   6 +loop
   pop-base
;
: last-10  ( -- )
   ptr @  load-base -  d# 60  >  if
      ptr @  d# 60 -  d# 60
   else
      load-base  ptr @  over -
   then
   show-packets
;

\ Variable used during packet decoding
\ variable px    \ Pen mode x value
\ variable py    \ Pen mode y value
variable gx    \ Glide pad x value
variable gy    \ Glide pad y value
variable gz    \ Glide pad z value, also used for pen mode x
variable taps      \ Bitmask of tap flags
variable switches  \ Bitmask of switch flags

variable exit-pt

\ Extract bits 7-9 from a packet byte and move them into place
: bits7-9  ( n -- n' )   4 rshift 7 lshift  ;

\ Extract bits 7-10 from a packet byte and move them into place
: bits7-10  ( n -- n' )  3 rshift 7 lshift  ;

\ Reads the next packet byte, extracts the tap bits, returns the rest
: tapbits   ( -- byte tapbit )  quick-byte dup 3 and   ;

\ Reads the next packet byte, extracts the switch bits, returns the rest
: set-switches  ( -- b )  quick-byte dup 3 and  switches !  ;

0 [if]
\ Ref: 5.2.9 (2) (3) of Hybrid-GP2B-T-1.pdf
: decode-simultaneous  ( -- )
   quick-byte gx !                  \ byte 2

   quick-byte                        ( byte3 )
   dup  bits7-10  gx @  or  gx !     ( byte3 )
   7 and  7 lshift px !              ( )

   tapbits taps !                    ( byte4 )
   bits7-9                           ( gy.high )
   quick-byte or  gy !               \ byte 5

   quick-byte  gz !                  \ byte 6

   quick-byte                        ( byte7 )
   set-switches  bits7-9             ( py.high )

   quick-byte  or  py !              \ byte 8

   quick-byte  px @  or  px !        \ byte 9
;
[then]

\ This lookup table intechanges the 2 low bits.  The PT and GS
\ data formats have the low 2 bits of byte 3 swapped.
create swbits  0 c,  2 c,  1 c,  3 c,

: decode-common  ( -- )
   quick-byte                  ( x.low )

   tapbits  taps !             ( x.low byte3 )
   bits7-10 or  gx !           ( )

   set-switches bits7-9        ( y.high )
   quick-byte or  gy !         ( )

   quick-byte gz !
;

\ Ref: 5.2.9 (2) (1) of Hybrid-GP2B-T-1.pdf
: decode-pt  ( -- )
   show-raw?  if  ." P "  then
   2 to packet-type
   decode-common
   taps @ 0=  if  d# 10 exit-pt !  then
;

\ Ref: 5.2.9 (2) (2) of Hybrid-GP2B-T-1.pdf
: decode-gs  ( -- )
   show-raw?  if  ." G "  then
   1 to packet-type  \ In case we get out of sync
   decode-common
   taps @  1 and  if  pt-only  then   \ Switch to pen mode
;

\ Wait up to 20 milliseconds for a new touchpad packet to arrive.
\ If one arrives, decode it.
variable miss?
: poll-touchpad  ( -- got-packet? )
   miss? off
   begin
      d# 20 timed-get-data  if
         exit-pt @  if
            -1 exit-pt +!
            exit-pt @  0=  if  gs-only  then
         then
         false exit
      then  ( byte )  record-byte

      case
         h# cf  of  decode-pt  true exit  endof
         h# ff  of  decode-gs  true exit  endof
\        h# eb  of  decode-simultaneous exit  endof
         h# aa  of
            0 d# 26 at-xy red-screen white-letters
            ." Unexpected touchpad reset"
            white-screen black-letters
            cr
            start gs-only   false exit
         endof
         ( default )
            \ If the high bit is set it means it's the first byte
            \ of a packet.  Complain if we don't recognize the type.
            dup h# 80 and  if ." Protocol botch"  then

            \ If the high bit is not set, we have missed a start of packet
            miss? @ 0=  if  ." miss "  then
            miss? on         \ Display miss only once per frame
            \ ." x" dup u.   \ Display the out-of-sync data
      endcase
   again
;

variable mouse-x
variable mouse-y

: mouse-xy  ( -- x y )  mouse-x @  mouse-y @  ;

: clipx  ( delta -- x )  mouse-x @ +  0 max  screen-w 1- min  dup mouse-x !  ;
: clipy  ( delta -- y )  mouse-y @ +  0 max  screen-h 1- min  dup mouse-y !  ;

\ Try to receive a GS-format packet.  If one arrives within
\ 20 milliseconds, return true and the decoded information.
\ Otherwise return false.
: pad?  ( -- false | x y z tap? true )
   mode @ 3 =  if
      poll-event   if    ( dx dy buttons )
         >r                                ( dx dy )
         swap clipx  swap negate clipy  0  ( x y z )
         0  r@ 1 and or                    ( x y z tap )
         r> 4 and 0<> 2 and or             ( x y z tap' )
         8 or                              ( x y z tap' )
         true
      else
         false
      then
      exit
   then

   poll-touchpad  0=  if  false exit  then

   gx @ gy @ gz @  taps @ 2 lshift  switches @  or   true
;

0 [if]
\ Try to receive a PT-format packet.  If one arrives within
\ 20 milliseconds, return true and the decoded information.
\ Otherwise return false.
: pt?  ( -- false | px py tap? true )
   poll-touchpad  0=  if  false exit  then
   px @ py @  gz @  taps @  2 lshift  switches @ or  true
;

\ Switch the device to pen tablet format and display
\ the data that it sends.  Stop when a key is typed.
: show-pt  ( -- )
   start
   pt-only
   begin
      pt?  if  . . . . cr  then
   key? until
;
[then]

\ Switch the device to glide format and display
\ the data that it sends.  Stop when a key is typed.
: show-pad  ( -- )
   start
   gs-only
   begin
      pad?  if  . . . . cr  then
   key? until
;

: button  ( color x -- )
   screen-h d# 50 -  d# 200  d# 30  fill-rectangle-noff
;
d# 300 d# 300 2constant target-wh
: left-target   ( -- x y w h )  0 0  target-wh  ;
: right-target  ( -- x y w h )  screen-w screen-h  target-wh  xy-  target-wh  ;
false value left-hit?
false value right-hit?
: inside?  ( mouse-x,y  x y w h -- flag )
   >r >r         ( mouse-x mouse-y  x y  r: h w )
   xy-           ( dx dy )
   swap r> u<    ( dy x-inside? )
   swap r> u<    ( x-inside? y-inside? )
   and           ( flag )
;

: draw-left-target  ( -- )  green  left-target   fill-rectangle-noff  ;
: draw-right-target ( -- )  red    right-target  fill-rectangle-noff  ;
: ?hit-target  ( but -- but )
   dup 1 and  if  \ Left                          ( but )
      mouse-xy  left-target  inside?  if          ( but )
         yellow left-target  fill-rectangle-noff  ( but )
         true to left-hit?                        ( but )
         exit
      then                                        ( but )
   then                                           ( but )
   dup 2 and  if  \ Right                         ( but )
      mouse-xy  right-target  inside?  if         ( but )
         yellow right-target  fill-rectangle-noff ( but )
         true to right-hit?                       ( but )
         exit
      then                                        ( but )
   then                                           ( but )
;

: track-init  ( -- )
   " dimensions" $call-screen  to screen-h  to screen-w
   screen-w 2/ mouse-x !  screen-h 2/ mouse-y !
   screen-ih package( bytes/line )package  to /line
   load-base ptr !
;

: dot  ( x y -- )
   swap screen-w 3 - min  swap y-offset + screen-h 3 - min  ( x' y' )
   pixcolor @  -rot   3 3                   ( color x y w h )
   fill-rectangle-noff                      ( )
;

: background  ( -- )
   black  0 0  screen-w screen-h  fill-rectangle-noff
   final-test?  if
      false to left-hit?
      false to right-hit?
      draw-left-target
      draw-right-target
   else
      0 d# 27 at-xy  ." Touchpad test.  Both buttons clears screen.  Type a key to exit" cr
      mode @ 3 <>  if  0 d# 20 at-xy  ." Pressure: "  then
   then
   mouse-xy dot
;

: show-up  ( x y z -- )  3drop  d# 10 d# 20 at-xy  ." UP "  ;

: show-pressure  ( z -- )
   mode @ 3 =  if
      drop
   else
      push-decimal  d# 10 d# 20 at-xy  3 u.r  pop-base
   then
;

false value relative?
true value up?
d# 600 d# 512 2value last-rel
d# 600 d# 512 2value last-abs

\ This is only for the ALPS touchpad
: abs>rel  ( x y -- x' y' )
   up?  if                                ( x y )
      \ This is a touch
      2dup to last-abs  false to up?      ( x y )
   then                                   ( x y )

   last-abs                               ( x y x0 y0 )
   2over to last-abs                      ( x y x0 y0 )
   xy-  last-rel xy+                      ( x' y' )
   swap 0 max  screen-w 1- min
   swap 0 max  screen-h 1- min            ( x' y' )
   2dup to last-rel                       ( x y )
;

: track  ( x y z buttons -- )
   packet-type 2 =  if  yellow  else  cyan  then  pixcolor !  ( x y z but )

   dup 3 and 3 =  if  background  load-base ptr !  then
   final-test?  if                ( x y z but )
      ?hit-target                 ( x y z but )
   else                           ( x y z but )
      dup  1 and  if  green  else  black  then  d# 100 button
      dup  2 and  if  red    else  black  then  d# 350 button  ( x y z but )
   then                           ( x y z but )

   \ Filter out events where the pen or finger in the current mode is not down
   8 and  0=  if  show-up  true to up?  exit  then   ( x y z )

   show-pressure                          ( x y )

   relative?  if             ( x y )
      abs>rel                ( x' y' )
   else                      ( x y )
      \ Display cyan dots (GS) in the center of the screen
      \ The offset attempts to register the GS with the PT.
      \ The offset should be 333, but the PT is expanded,
      \ so we have to scale the 333 to match.
      packet-type 1 =  if    ( x y )
         swap  d# 400 +      ( y x' )  \ GS
         swap                ( x' y )
      then                   ( x y )
      \ Expand the PT (0..999) to the screen width (1200)
      packet-type 2 =  if    ( x y )
         swap d# 1200 d# 1000 */
         swap d# 1200 d# 1000 */
      then                   ( x y )
   then                      ( x y )

   dot
;

: handle-key  ( -- exit? )
   key upc  case
      [char] P  of
         cursor-on
         cr last-10
         key drop
         background
         false
      endof

      [char] S  of  suspend stream-on false  endof

      ( key )  true swap
   endcase
;

false value selftest-failed?  \ Success/failure flag for final test mode
: exit-test?  ( -- flag )
   final-test?  if                    ( )
      \ If the targets have been hit, we exit with successa
      left-hit? right-hit? and  if    ( )
         false to selftest-failed?    ( )
         true                         ( flag )
         exit
      then                            ( )

      \ Otherwise we give the tester a chance to bail out by typing a key,
      \ thus indicating failure
      key?  0=  if  false exit  then  ( )
      key drop                        ( )
      true to selftest-failed?        ( )
      true                            ( flag )
      exit
   then                               ( )

   \ If not final test mode, we only exit via a key - no targets
   key?  if  handle-key  else  false  then  ( exit ? )
;
: selftest  ( -- error? )
   open  0=  if  ." PS/2 Mouse (trackpad) open failed"  true exit  then

   \ Being able to open the touchpad is good enough in SMT mode
   smt-test?  if  close false exit  then

   final-test? 0=  if
      ." Touchpad test will start in 4 seconds" cr
      d# 4000 ms
   then

   my-args  " relative" $=  to relative?

   cursor-off  track-init  start

   \ Consume already-queued keys to prevent premature exit
   begin  key?  while  key drop  repeat

   background
   gs-only
   begin
      ['] pad? catch  ?dup  if  .error  close true exit  then
      if  track  then
   exit-test?  until

   close
   cursor-on
   page
   final-test?  if  selftest-failed?  else  false  then
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
