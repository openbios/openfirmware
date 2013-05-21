purpose: Serial terminal emulator
\ See license at end of file

vocabulary serial-terminal
also serial-terminal definitions

d# 1 value break-ms

d# 80 constant /buf
/buf buffer: buf


\ queue implementation (adapted from dev/16550pkg/16550.fth)

\ size of queues, approx 10 seconds at 115200 baud
d# 144000 constant /q

struct
   /n field >head
   /n field >tail
   /q field >qdata
constant /qstruct

/qstruct buffer: read-q  \ for reading from serial
/qstruct buffer: emit-q  \ for showing to display

: init-q  ( q -- )  0 over >head !  0 swap >tail !   ;
: inc-q-ptr  ( pointer-addr -- )
   dup @  ca1+  dup /q  =  if  drop 0  then  swap !
;

: enque  ( new-entry q -- )
   >r
   r@ >tail @  r@ >head @  2dup >  if  - /q  then  1-     ( entry tail head )
   <>  if  r@ >qdata  r@ >tail @ ca+ c!  r@ >tail inc-q-ptr  else  drop  then
   r> drop
;

: deque?  ( q -- false | entry true )
   >r
   r@ >head @  r@ >tail @  <>  if
      r@ >qdata  r@ >head @  ca+ c@  r@ >head inc-q-ptr  true
   else
      false
   then
   r> drop
;

\ end of queue implementation


\ queued screen output

: >q  ( adr len )
   bounds  do  i c@  emit-q enque  loop
;

: q>  ( -- )
   emit-q deque?  if  emit  then
;

\ end of queued screen output


\ serial device independent interface

defer serial-open   ( -- )
defer serial-close  ( -- )
defer serial-emit   ( key -- )
defer serial-read   ( -- adr len )
defer serial-break  ( -- )

\ end of serial device independent interface


\ internal serial device implementation

\ interrupt enable register UART_IER, table 1993, page 1547
: ier@  ( -- b )  h# 1 uart@  ;
: ier!  ( b -- )  h# 1 uart!  ;

\ receiver data available interrupt enable
: ravie-on   ( -- )  ier@ h# 1 or ier!  ;
: ravie-off  ( -- )  ier@ h# 1 invert and ier!  ;

\ line control register UART_LCR, table 1998, page 1554
: ulcr@  ( -- b )  h# 3 uart@  ;
: ulcr!  ( b -- )  h# 3 uart!  ;

\ set break
: sb-on   ( -- )  ulcr@ h# 40 or ulcr!  ;
: sb-off  ( -- )  ulcr@ h# 40 invert and ulcr!  ;

\ modem control register UART_MCR, table 1999, page 1555
: mcr@  ( -- b )  h# 4 uart@  ;
: mcr!  ( b -- )  h# 4 uart!  ;

\ OUT2 signal control, enable UART interrupts
: out2-on   ( -- )  mcr@ h# 8 or mcr!  ;
: out2-off  ( -- )  mcr@ h# 8 invert and mcr!  ;

: uart-break
   begin  uemit?  until
   sb-on
   break-ms ms
   sb-off
;

\ IRQ number of console UART varies by platform
\ FIXME: find a better way to store or find these
[ifdef] olpc-cl1
   d# 4 value irq#
[then]
[ifdef] mmp2
   d# 24 value irq#
[then]
[ifdef] mmp3
   d# 28 value irq#
[then]

\ serial interrupt handler for received data
: si ( -- )  ukey read-q enque  ;

\ enable serial interrupt
: esi
   ['] si irq# interrupt-handler!
   irq# enable-interrupt
   ravie-on
   out2-on
;

\ disable serial interrupt
: dsi
   out2-off
   ravie-off
   irq# disable-interrupt
;

\ on XO-1.5, enable-serial disables the camera and adds the serial
\ instance handles to the multiplexor.  on other models it is absent.
[ifndef] enable-serial  \ present on XO-1.5
: enable-serial ;
[then]

false value uart-console-off?  \ did we turn our uart console off?

\ stop using the uart as console
\ (necessary to avoid noise from interconnected hosts)
: uart-console-off
   fallback-out-ih remove-output
   fallback-in-ih remove-input
   true to uart-console-off?
;

\ resume using the uart as console
: uart-console-on
   uart-console-off? if
      fallback-out-ih add-output
      fallback-in-ih add-input
      false to uart-console-off?
   then
;

: uart-open
   enable-serial
   uart-console-off
   read-q init-q
   esi
;

: uart-close
   dsi
;

: uart-read  ( -- adr len )
   buf 0  ( adr len )
   read-q deque?  0=  if  exit  then   ( adr len char )
   begin                               ( adr len char )
      >r 2dup + r> swap c! 1+          ( adr len' )
      dup /buf =  if  exit  then  ( adr len' )
      read-q deque?  0=
   until                               ( adr len' )
;

\
\ FIXME: XO-1, seen only once, ukey? did stop returning true, and ukey
\ therefore hung waiting for ukey?
\
\ condition was cleared by  0 uart@  despite ukey? returning false
\
\ when it occurs again, try looking at fifo error summary bit, and
\ line status reg, and consider comment from 16550.fth:
\
\ "I have seen conditions where a UART will report, via an interrupt,
\ that a character is available, but the line status register won't
\ report it."
\

: use-uart
   uart-console-off
   ['] uart-open   to  serial-open
   ['] uart-close  to  serial-close
   ['] uemit       to  serial-emit
   ['] uart-read   to  serial-read
   ['] uart-break  to  serial-break
;

\ end of internal serial device implementation


\ USB serial device implementation

0 value serial-ih

: usb-open  ( -- )
   " /usb/serial" open-dev ?dup if  to serial-ih  exit  then
   [ifdef] olpc-cl1
      \ XO-1.5
      " /usb@10/serial" open-dev ?dup if  to serial-ih  exit  then
      \ XO-1
      " /usb@f,4/serial" open-dev ?dup if  to serial-ih  exit  then
      " /usb@f,5/serial" open-dev ?dup if  to serial-ih  exit  then
   [then]
   true abort" can't open USB serial adapter"
;

: usb-close  ( -- )
   serial-ih close-dev
   0 to serial-ih
;

: usb-emit  ( key -- )
   buf c! buf 1 " write" serial-ih $call-method  drop
;

: usb-read  ( -- adr len )
   buf /buf " read" serial-ih $call-method      ( len )
   dup -2 =  if  drop buf 0 exit  then          ( len )
   buf swap                                     ( adr len )
;

: usb-break
   " ftdi-break-on" serial-ih $call-method
   1 ms
   " ftdi-8n1" serial-ih $call-method
;

: use-usb
   uart-console-on
   ['] usb-open   to  serial-open
   ['] usb-close  to  serial-close
   ['] usb-emit   to  serial-emit
   ['] usb-read   to  serial-read
   ['] usb-break  to  serial-break
;

use-usb

\ end of USB serial device implementation


\ key bindings
\ (match the screen(1) defaults)
defer key-state  ( key -- )
defer key-state-default  ( key -- )

: reset-key-state  ['] key-state-default >data token@  to key-state  ;

: key-state-exit  ( key -- )  serial-emit  ;  \ is not called

: key-state-exit?  ( -- exit? )
   ['] key-state >data token@  ['] key-state-exit  =
;

: key-state-c-a  ( key -- )  \ list of recognised c-a sequences
   case
      1 ( c-a )  of  1 serial-emit  reset-key-state   endof
      2 ( c-b )  of  serial-break   reset-key-state   endof
      [char] b   of  serial-break   reset-key-state   endof
      [char] C   of  page           reset-key-state   endof
      4 ( c-d )  of  ['] key-state-exit to key-state  endof
      [char] k   of  ['] key-state-exit to key-state  endof
      [char] K   of  ['] key-state-exit to key-state  endof
      ( default )                   reset-key-state
   endcase
;

: key-state-run  ( key -- )
   dup 1 =  if  ['] key-state-c-a to key-state  drop exit  then  \ c-a
   serial-emit ( )
;

' key-state-run to key-state-default

\ end of key bindings


\ main program

: serial-help-0  ( -- )
   green-letters
   ." serial terminal:" cr
   ."     use  c-a k  to exit," cr
   ."     use  c-a c-b  to send break," cr
   ."     use  c-a c-a  to send a c-a." cr
   cancel cr
;

: serial-help-1  ( -- )
   cr green-letters ." serial terminal: stopped." cancel cr
;

: outgoing  ( -- )  \ data leaving this host
   key?  if  key  key-state  then
;

: incoming  ( -- )  \ data arriving at this host
   serial-read  dup  if  >q  else  2drop  q>  then
;

: serial{
   emit-q init-q  serial-open  reset-key-state  serial-help-0
;

: {serial}
   begin  outgoing  incoming  key-state-exit?  until
;

: }serial
   serial-close  serial-help-1
;

previous definitions  also serial-terminal

: serial  serial{  {serial}  }serial  ;

[ifdef] log-ih
: serial-log  ( "filename" -- )
   serial{
   safe-parse-word
   2dup ['] $delete  catch  if  2drop  then
   $create-file to log-ih
   log-ih add-output
   {serial}
   log-ih remove-output
   log-ih close-dev
   }serial
;
[then]

: use-uart  use-uart  ;
: use-usb   use-usb   ;

previous

\ LICENSE_BEGIN
\ Copyright (c) 2013 FirmWorks
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
