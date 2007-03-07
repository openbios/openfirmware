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

: send-cmd  ( cmd -- )  " put-data" $call-parent  ;
: cmd  ( cmd -- )  " put-get-data" $call-parent ?ack  ;

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
: stream-mode    h# ea cmd  ;

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

\ Translate RML to RML
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
: timed-read  ( #ms -- true | data false )
   0  do
      get-data?  if  unloop false exit  then
      1 ms
   loop
   true
;
: no-event  ( -- 0 0 0 )  clear-queue  0 0 0  ;

headers
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
   h# f2  send-cmd

   apex-timeout timed-read  if  true exit  else  drop  then
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

headers
: open  ( -- flag )
   1 set-port

   \ The "force" argument causes the open to succeed even if no mouse
   \ is present
   my-args  [char] , left-parse-string  2swap 2drop  " force"  $=  if
      true exit
   then

   find-mouse  if  false exit  then

   \ Reset the mouse and check the response codes
   h# ff read2  0<>  swap h# aa <>  or  if  false exit  then

   remote-mode
   true
;
: close  ( -- )  ;

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
