\ See license at end of file
purpose: Driver for 8042 PC keyboard/mouse controller

headerless

" INTC,80c42" model
" 8042"       device-name
" 8042"       device-type

0 0 encode-bytes
   " ps2-keyboard-controller" encode-string encode+
   " INTC,80c42"              encode-string encode+
" compatible" property

my-address      my-space  1  encode-reg
my-address 4 +  my-space  1  encode-reg  encode+
" reg" property

1 " #address-cells"  integer-property
0 " #size-cells"     integer-property

0 value debug?
also forth definitions
: debug-ps2    ( -- )  true  to debug?  ;
: undebug-ps2  ( -- )  false to debug?  ;
previous definitions

hex

[ifndef] $=
: $=   rot tuck <> if  3drop false exit  then  comp 0=  ; 
[then]

\ 0 means the keyboard port, 1 means the aux port
: encode-unit  ( n -- adr len )  if  " aux"  else  " kbd"  then  ;
: decode-unit  ( adr len -- n )  " aux"  $=  0=  if  0  else  1  then  ;

\ Queues for distributing bytes sent from the two devices
d# 100 constant /q

struct
/n field >head
/n field >tail
/q field >qdata
constant /qstruct

/qstruct buffer: q0
/qstruct buffer: q1

: init-q  ( q -- )  0 over >head !  0 swap >tail !   ;
: inc-q-ptr  ( pointer-addr -- )
   dup @  ca1+  dup /q  =  if  drop 0  then  swap !
;

\ This is only called for the queue opposite from "port"
: enque  ( new-entry q -- )
   >r
   r@ >tail @  r@ >head @  2dup >  if  - /q  then  1-     ( entry tail head )
   <>  if  r@ >qdata  r@ >tail @ ca+ c!  r@ >tail inc-q-ptr  else  drop  then
   r> drop
;

\ This is only called for the queue for "port"
: deque?  ( q -- false | entry true )
   >r
   r@ >head @  r@ >tail @  <>  if
      r@ >qdata  r@ >head @  ca+ c@  r@ >head inc-q-ptr  true
   else
      false
   then
   r> drop
;

0 instance value port

0 value data-port
0 value cmd-status-reg


\ Keyboard controller command constants
\  a7 constant disable-aux
\  aa constant selftest
\  ab constant intf-test
\  ad constant disable-intf
\  ae constant enable-intf
\  d0 constant read-out-port
\  d1 constant write-out-port

\ Keyboard controller status constants
   01 constant out-buf-full
   02 constant in-buf-full
  out-buf-full in-buf-full +
      constant io-bufs-full
\  40 constant general-timeout
\  80 constant parity-error
\  55 constant passed

\ Output port constants
\  c0 constant clk-data-high
 
headers
: set-port  ( port# -- )  to port  ;
headerless

: stat@  ( -- byte )  cmd-status-reg rb@  ;
: data@  ( -- byte )  data-port rb@  debug?  if  ." <" dup .  then  ;
: data!  ( byte -- )  debug?  if  ." >" dup .  then   data-port rb!  ;

\ *** Following delay can be reduced after testing ***

: in-wait  ( -- ) \ Wait for input buffer to empty
   d# 1000 0  do
      stat@  in-buf-full and 0=  if  unloop exit  then
      1 ms
   loop
   true abort" Keyboard input buffer full timeout"
;

: (get-data?)  ( -- false | data true )
   \ Exit immediately if a byte is waiting
   port  if  q1  else  q0  then  deque?  if  true exit  then

   begin
      stat@  dup out-buf-full and                        ( stat flag )
   while                                                 ( stat )
      data@  swap                                        ( data stat )
      5 >>  port  =  if  true  exit  then
      port  if  q0  else  q1  then  enque
   repeat                                                ( stat )
   drop  false
;

true value data-port-available?
headers
: get-data?  ( -- false | data true )
   data-port-available?  if			( )
      false to data-port-available?		( )
      (get-data?)			        ( false | data true )
      true to data-port-available?		( )
   else						( )
      false					( false )
   then						( false | data true )
;

: get-data  ( -- data | -1 )  \ Wait for data from our device
   d# 1000 0  do
      get-data?  if  unloop exit  then		( data )
      1 ms
   loop
   true \ abort" Timeout waiting for data from device" 
;
headerless

: put-ctlr-cmd   ( cmd -- )
   in-wait  debug?  if  ." ^" dup .  then  cmd-status-reg rb!
;

headers
: put-data  ( data -- )
   port  if
      lock[ h# d4 put-ctlr-cmd  in-wait  data! ]unlock
   else
      in-wait  data!
   then
;

headerless
: put-ctlr-cmd2  ( data cmd -- )  put-ctlr-cmd  put-data   ;

headers
: put-get-data  ( cmd -- data | -1 )  put-data get-data  ;

\ Wait until the device stops sending data
: clear-out-buf  ( -- )  begin  d# 120 ms  get-data?  while  drop  repeat  ;
headerless

: disable-intf  ( -- )  h# ad put-ctlr-cmd  ;
: enable-intf   ( -- )  h# ae put-ctlr-cmd  ;

: (ctlr-cmd)  ( cmd -- data | -1 )
   \ Controller commands return data as though it were from the keyboard port
   port >r  0 to port
   put-ctlr-cmd get-data
   r> to port
;

: cmd-reg!  ( b -- )  h# 60 put-ctlr-cmd2  ;
: cmd-reg@  ( -- b )  h# 20 (ctlr-cmd)  ;

\ Enable and disable scan set translation
: translation-on   ( -- )  cmd-reg@  h# 40 or          cmd-reg!  ;
: translation-off  ( -- )  cmd-reg@  h# 40 invert and  cmd-reg!  ;

: ctlr-cmd1  ( cmd -- data )
   \ Enable keyboard translate mode, enable aux device, enable
   \ keyboard, set system flag, disable aux and keyboard interrupts
   disable-intf  (ctlr-cmd)  h# 44 cmd-reg!  enable-intf
;
   
\ This takes 160 msecs on an IBM keyboard circa 1994
: ctlr-selftest  ( -- fail? )
   h# aa ctlr-cmd1  ( data )
   begin  h# 55 =  if  false exit  then  get-data? 0=  until
   true exit
;

: ack-reset  ( -- )
   \ Release the clock and data lines to acknowledge the ACK.
   \ This appears to be keyboard-specific; I find no mention
   \ of such a requirement for the mouse reset sequence.
   h# c0  h# d1  put-ctlr-cmd2
   clear-out-buf
;

: (test-lines)  ( -- error? )
   port  if  h# a9  else  h# ab  then      ( kbd-or-aux-interface-test-code )
   ctlr-cmd1
   d# 20 ms		\ Recovery time
;
headers
: test-lines  ( -- error? )
  (test-lines)  0=  if  false exit  then
  \ Retry in case we are not in sync with the keyboard
  (test-lines) enable-intf  dup 0=  if  exit  then    ( error-code )
   ." Failed keyboard interface test" cr
   case
      1  of  " low"  " Clock"  endof
      2  of  " high" " Clock"  endof
      3  of  " low"  " Data"   endof
      4  of  " high" " Data"   endof
      \ This probably means that we are out-of-sync with the keyboard
      >r " ?" 2dup  r>
   endcase
   ." The keyboard '" type  ." ' line is stuck " type  ." ."  cr
   false
;
headerless
0 value open-count
headers
: open  ( -- flag? )
   open-count 1+ to open-count
   data-port 0=  if
      my-address my-space  5  " map-in" $call-parent  is data-port
      data-port 4 + is cmd-status-reg

      ctlr-selftest  if
         ctlr-selftest  if	\ Retry in case we're out of sync
            ." Failed keyboard controller self test" cr
            false exit
         then
      then
      q0 init-q  q1 init-q
   then
   true
;
: close  ( -- )
   open-count 1- 0 max to open-count
   open-count 0=  if
      data-port 5 " map-out" $call-parent
      0 to data-port
      0 to cmd-status-reg
   then
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
