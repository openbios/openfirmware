\ See license at end of file
purpose: Driver for PS/2 mouse

" mouse"          device-name
" mouse"          device-type
" pnpPNP,f03" " compatible" string-property
1 " reg" integer-property

headerless
: get-data  ( -- byte )  " get-data" $call-parent  ;
: get-data?  ( -- false | byte true )  " get-data?" $call-parent  ;

\ I think this is supposed to work as follows:
\ If the command succeeds, the mouse responds with "fa"
\ Otherwise, it responds with "fe", meaning "retry"
\ The next ack after a retry is "fc".

d# 20 constant apex-timeout

: ?ack  ( response -- )
   begin h# fa <> while get-data repeat
;	\ Could check against h# fe

\ : maybe-get-ack  ( -- )
\    apex?  0=  if  " get-data" $call-parent  ?ack  then
\ ;

: timed-read  ( #ms -- true | data false )
   0  do
      get-data?  if  unloop false exit  then
      1 ms
   loop
   true
;

: put-get-data  ( cmd -- data )  " put-get-data" $call-parent  ;
: send-cmd  ( cmd -- )  " put-data" $call-parent  ;

0 instance variable #retries
: cmd?  ( cmd -- error? )
   dup put-get-data                   ( cmd response )
   begin                              ( cmd response )
      case                            ( cmd response )
         h# fa of  drop false exit   endof   \ ACK
         h# fe of                     ( cmd )  \ RESEND - try again
            -1 #retries +!            ( cmd )
            #retries @ 0<  if         ( cmd )
               drop true exit
            then                      ( cmd )
            dup put-get-data          ( cmd response )
         endof
         ( cmd response )
            d# 10 timed-read  if      ( cmd response )
               2drop true exit
            then                      ( cmd response new-response )
            swap                      ( cmd new-response response )
      endcase                         ( cmd new-response )
   again
;
: cmd  ( cmd -- )  d# 20 #retries !  cmd? drop  ;

\ : cmd  ( cmd -- )  " put-get-data" $call-parent ?ack  ;

\ This serves the same purpose as "cmd", but it handles a bug in the
\ Apex concentrator in which said device neglects to acknowledge certain
\ commands.
\ : cmd-?ack  ( cmd -- )  send-cmd maybe-get-ack  ;

: cmd2  ( data cmd -- )  cmd cmd  ;
: clear-out-buf  ( -- )  " clear-out-buf" $call-parent  ;

: mouse1:1       h# e6 cmd  ;
: mouse2:1       h# e7 cmd  ;
: stream-on      h# f4 cmd  ;
: stream-off     h# f5 cmd  ;
: stream-mode    h# ea cmd  stream-on  ;

\ The Apex concentrator refuses to send motion and button events
\ unless stream data is enabled!
: remote-mode    h# f0 cmd  stream-on  ;

: loopback-on    h# ee cmd  ;  \ Mouse echos commands and data
: loopback-off   h# ec cmd  ;
: standard-mode  h# f6 cmd  ;  \ 100/second, 1:1, stream mode, 4/mm, off

: read1  ( -- n )      cmd   get-data  ;
: read2  ( -- n n )    read1 get-data  ;
: read3  ( -- n n n )  read2 get-data  ;

: mouse-reset  ( -- aa 00 )    ;

: mouse-status  ( -- n n n )  h# e9 read3  ;

\ : mx  mstat get-kbd-data  2swap swap . . swap . .  ;
: set-resolution  ( 0..3 -- )  h# e8 cmd2  ;

\ Valid values for "n" are (decimal) 10, 20, 40, 60, 80, 100, and 200 samp/sec
: set-sample-rate  ( n -- )  h# f3 cmd2  ;


[ifdef] debug-mouse
: m.
   64 pc@
   dup 1 and  if
      dup 20 and if ." Mouse" else ." Kbd" then ." DataAvail  "
   then
   dup 2 and  0=  if
      ." ReadyFor"  dup 8 and  if  ." Cmd"  else  ." Data"  then
   then
   drop cr
;
[then]

\ Translate MRL to RML
create buttons  0 c,  1 c,  4 c,  5 c,  2 c,  3 c,  6 c,  7 c,

\ create Mitsumi	\ Comment out this line if you don't support Mitsumi mouse

: ?negative  ( val stat mask -- val' )
\ Check over flow flag	
   2dup 2 << and  if		( val stat mask )
      and nip  if h#  -ff  else  h# ff  then  exit
   then				( val stat mask )
   and  if			( val )
[ifdef] Mitsumi
      dup h# 80 and 0=  if	( val )
         negate
      then
[then]
      h# ffff.ff00 or
   then
;
\ PS2 mouse packets have no framing information, so we must depend on
\ timing information for framing
: clear-queue  ( -- )  begin  get-data?  while  drop  repeat  ;
: no-event  ( -- 0 0 0 )  clear-queue  0 0 0  ;

0 instance value mouse-byte#
instance variable mouse-bytes
0 instance value mouse-timestamp
2 instance value poll-delay

: save-byte  ( byte -- )
   mouse-bytes @  8 lshift or  mouse-bytes !  ( )
   mouse-byte# 1+ to mouse-byte#              ( )
   get-msecs to mouse-timestamp
   2 to poll-delay
;
: out-of-packet  ( -- )
   0 to mouse-byte#
   0 to mouse-timestamp
;

: stream-event  ( byte -- false | x y buttons true )
   mouse-byte#  case                          ( byte )
      0  of
         \ Discard if framing error
         dup 8 and  if  save-byte  else  drop  then  ( )
         false exit
      endof

      1  of  save-byte  false exit  then
   endcase                                    ( byte3 )

   \ Fall through if already have 2 mouse bytes (this is the third)
   out-of-packet

   mouse-bytes @ wbsplit  ( byte3-ylow byte2-xlow byte1-stat )

   dup 7 and buttons + c@ >r              ( ylow xlow stat )
   swap   over h# 10 ?negative  -rot      ( x ylow stat )
   h# 20 ?negative r>                     ( x y buttons )

   true exit
;

\ Time-based resynchronization.  If we are in the middle of a packet,
\ but we poll and see no bytes and the interval since the last byte
\ was longer than the possible time between bytes within a packet,
\ we discard the queued-up bytes.
: ?reframe  ( -- )
   mouse-byte#  if
      \ We don't trust time intervals <= ms/tick because the timestamp
      \ could have happened just before a tick and the next sample
      \ right after a tick, so the actual elapsed time could be almost
      \ zero, but the reported time difference would be ms/tick .
      get-msecs mouse-timestamp - ms/tick - 0 max  d# 5  >  if
         out-of-packet
       then
   then
;
headers

: stream-poll?  ( -- false | x y buttons true )
   begin  get-data?  while     ( byte )
      \ If we have a packet, retry soon because there is likely to be another
      \ right on its heels.  The packet generation rate is 100/sec, but some
      \ could be queued up, so we don't wait a full 10 ms
      stream-event  ?dup  if  exit  then
   repeat                      ( )

   ?reframe
   false
;

\ delay-ms is a suggested delay until the next poll.  It tells you when
\ a call to stream-poll? is likely to have something worthwhile to do.
\ In the middle of an incoming mouse packet, delay-ms will be a couple of
\ milliseconds, a bit longer than the interval between successive PS/2 bytes.
\ Just after receiving a packet, it will be a bit more than 10 mS, since
\ another packet is likely to follow (the standard mouse packet rate is
\ 100 packets/second).  When idle, the delay is 56 milliseconds, just
\ longer than a worst-case PC tick interval, but short enough that a
\ human won't notice a delay.
\ This strikes a good balance between responsive, accurate mouse tracking
\ and minimal polling overhead.

: adaptive-poll?  ( -- false delay-ms | x y buttons true delay-ms )
   begin  get-data?  while     ( byte )
      \ If we have a packet, retry soon because there is likely to be another
      \ right on its heels.  The packet generation rate is 100/sec, but some
      \ could be queued up, so we don't wait a full 10 ms
      stream-event  ?dup  if  poll-delay  exit  then
   repeat                      ( )

   ?reframe
   false  poll-delay                 ( false delay-ms )

   dup 2 = if  9  else  d# 32  then  to poll-delay  ( false delay-ms )
;
0 [if]
: adaptive-track  ( -- )
   stream-mode
   begin
      adaptive-poll?  >r  if   ( x y stat r: next-poll )
         (cr . 4 .r 4 .r     ( r: next-poll )
      then                   ( r: next-poll )
      r> ms                  ( )
   key? until                ( )
   stream-off
;
: stream-track  ( -- )
   stream-mode
   begin
      stream-poll?  if       ( x y stat )
         (cr . 4 .r 4 .r     ( )
      then                   ( )
      5 ms                   ( )
   key? until                ( )
   stream-off
;

[then]

: poll  ( -- x y buttons )
   clear-queue

   h# eb cmd
   0 0 0				( xlow ylow stat )

   \ The Apex concentrator sends 2 3-byte packets after acknowledging
   \ the "read data" command.  The first packet always says "no buttons
   \ down, no motion", so we discard it.
   3 0 do
      apex-timeout timed-read  if  3drop unloop no-event exit  then
      nip rot
   loop					( xlow ylow stat )

   \ Reserved bit 3 is set by some mice and Apex.
   3dup h# f7 and or or 0=  if
      3 0 do
         apex-timeout
         timed-read  if  3drop unloop  no-event exit  then
         nip rot
      loop                                   ( xlow ylow stat )
   then
   dup 7 and buttons + c@ >r              ( xlow ylow stat )
   rot   over h# 10 ?negative  -rot       ( x ylow stat )
   h# 20 ?negative r>                     ( x y buttons )
;

headerless
0 instance value my-port
: set-port  ( port# -- )
   dup to my-port  " set-port" $call-parent  clear-out-buf
;

\ The mouse responds with one byte of 00.  The keyboard responds with
\ two bytes, such as ab 83.

: identify  ( -- true | char false )
\   h# f2  ['] read1  catch  dup  if  nip  then
   3 #retries !
   h# f2  cmd?  if  true exit  then
   apex-timeout timed-read
;

: find-mouse  ( -- error? )
   lock[
   identify  if
      \ This port is unresponsive; try the other
      0 set-port  identify  if  ]unlock  true exit  then
   then                                   ( id )

   dup  h# ab =  if                       ( id )

      \ The keyboard appears to be connected to this port
      drop                                ( )
      clear-out-buf		\ Eat the second keyboard ID byte

      \ If we are already looking at the alternate port, give up
      my-port 0=  if  ]unlock  true exit  then

      \ Otherwise look for the mouse on the keyboard port
      0 set-port  identify  if  ]unlock  true exit  then  ( id )
   then                                   ( id )
   ]unlock                                ( id )

   \ The mouse ID is supposed to be zero.
   \ If the ID is still non-zero, read the second ID byte and give up
   dup  if  clear-out-buf  then           ( error? )
;

0 value open-count

headers
: open  ( -- flag )
   1 set-port

   open-count 0<>  if  true exit  then

   \ The "force" argument causes the open to succeed even if no mouse
   \ is present
   my-args  [char] , left-parse-string  2swap 2drop  " force"  $=  0=  if

      find-mouse  if  false exit  then

      \ Reset the mouse and check the response codes
      h# ff read2  0<>  swap h# aa <>  or  if  false exit  then

      remote-mode
   then

   open-count  1+ to open-count
   true
;
: close  ( -- )
   open-count 1 =  if  stream-off  then
   open-count 1- 0 max  to open-count
;

headerless
\ Filter out large negative motions; they're probably spurious
: hack-filter  ( x y buttons -- false | x y buttons true )
   2 pick  h# -40 <  if  3drop false  exit  then
   over    h# -40 <  if  3drop false  exit  then
   true
;

0 instance value last-buttons
: poll-event  ( -- false | x y buttons true )
   poll  3dup last-buttons <> or or   ( x y buttons flag )
   over to last-buttons               ( x y buttons flag )
   if  hack-filter  else  3drop false  then
;
headers
: get-event  ( #msecs -- false | x y buttons true )
   ?dup  0=  if   begin  poll-event  until  true exit  then

   get-msecs +   >r   ( r: target-msecs )
   begin
      poll-event  if  r> drop  true exit  then
      get-msecs r@ - 0> 
   until
   r> drop  false
;
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
