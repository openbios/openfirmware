\ See license at end of file
purpose: Support package for serial ports compatible with 16550 code

: clock-frequency  ( -- n )
   " clock-frequency"  my-parent ihandle>phandle  get-package-property  if
      d# 1843200
   else                ( adr len )
      get-encoded-int
   then
;

0 instance value uart-base	\ Virtual address of UART; set later

: uart-base-adr  ( -- adr )
   uart-base
\ The following code is a PowerPC-specific hack that 
\ handles the case where memory mapping is turned off
\ (in which case the 0x30 bit in MSR is 0).  Note that
\ the PowerPC msr@ is not compatible with the x86 msr@.
\ [ifdef] msr@
\   msr@ h# 30 and 0=  if  h# fff and io-base +  then
\ [then]
;
: uart@  ( reg# -- byte )  uart-base-adr +  rb@  ; \ Read from a UART register
: uart!  ( byte reg# -- )  uart-base-adr +  rb!  ; \ Write to a UART register

\ Integer division which rounds to nearest instead of truncating
: rounded-/  ( dividend divisor -- rounded-result )
   swap 2*  swap /  ( result*2 )
   dup 1 and +      \ add 1 to the result if it is odd
   2/               ( rounded-result )
;
: baud-to-divisor  ( baud-rate -- divisor )
   clock-frequency d# 16 /  swap rounded-/    ( baud-rate-divisor )
;
: divisor-to-baud  ( divisor -- baud-rate )
   clock-frequency d# 16 /  swap rounded-/    ( baud-rate-divisor )
;

\ The break-detect bit in the line status register is cleared when you
\ read the line status register, not when you read the garbage character
\ that accompanies the break through the FIFO.  Consequently, we must
\ check the break detect bit every time that we read the line status
\ register, using break? to remember that we saw it.
0 instance value break?
: (line-stat@)  ( -- n )  5 uart@  ;
: line-stat@  ( -- n )
   (line-stat@)  dup h# 10 and  if  " set-break" $call-parent  then
;

: get-divisor  ( -- divisor )
   3 uart@  dup >r  h# 80 or  3 uart!		\ divisor latch access bit on
   0 uart@  1 uart@  bwjoin	( divisor )	\ Read lsb and msb
   r> 3 uart!					\ Restore old state
;
: set-divisor  ( divisor -- )
   \ If the divisor is 0, then this is first access after power on.  We
   \ can safely plow on with out checking the transmitter status
   get-divisor  if
      begin  line-stat@ h# 40 and  until	\ Wait until transmit done
   then

   3 uart@  dup >r  h# 80 or  3 uart!		\ divisor latch access bit on
   wbsplit swap  0 uart!  1 uart!		\ Write lsb and msb
   r> 3 uart!					\ Restore old state
;
: baud  ( baud-rate -- )  baud-to-divisor set-divisor  ;

\ Parses the arguments to the serial port driver, which are in the
\ form, e.g. 9600,8,n,1 , and sets the UART parameters (baudrate,
\ # data bits, parity, #stop bits, handshake) accordingly.
\
\ Fields are (in order, left to right):
\         <baud rate>, <data bits>, <parity>, <stop bits>, <handshake>
\ Fields with empty values are not changed.
\ Values for fields are whatever the hardware will support:
\ baud rates: various,including  110, 300, 1200, 2400, 4800, 9600, 19200, 38400
\ character bits: 5,6,7,8
\
\ parity:
\         char   means
\         --------------------
\         n       none
\         e       even
\         o       odd
\         m       mark
\         s       space
\
\ stop bits:
\         char    means
\         --------------------
\         1       1 stop bit
\         .       1.5 stop bits
\         2       2 stop bits
\
\ handshake:
\         char    means
\         --------------------
\         -       none
\         h       hardware (rts/cts)	\ Not supported
\         s       software (xon/xoff)   \ Not supported
\
\ The default mode is 9600,8,n,1,-
\

hex
headerless

0 instance value divisor
0 instance value mode

: .uart-error  ( -- )
   ."  error in tty mode."  cr
   -1 throw
;

0 instance value current-baudrate
: set-baudrate  ( adr len -- )
   dup  if
      base @ >r  decimal  $number  r> base !  if
         ." Baud rate" .uart-error
      then
   else
      2drop  current-baudrate
   then
   baud-to-divisor to divisor
;


[ifndef] c@+
: c@+  ( adr -- adr+ char )  dup 1+ swap c@  ;  \ In the kernel
[then]

: do-table  ( adr len table-adr -- )
   over 0=  if  3drop exit  then          ( adr len table-adr )
   over 1 u>  if                          ( adr len table-adr )
      drop
      ascii " emit  type  ascii " emit
      ." : syntax" .uart-error
   then                                   ( adr len table-adr )
   nip                                    ( adr table-adr )
   c@+ invert                             ( adr table-adr' mask )
   mode  and  to mode                     ( adr table-adr' )
   swap c@  swap c@+                      ( char entries-adr #entries )
   true -rot                              ( char true entries-adr #ent )
   2* bounds  ?do                         ( char true )
      over i c@ =  if                     ( char true )
         i 1+ c@  mode  or  to mode       ( char true )
         0= leave                         ( char false )
      then                                ( char true )
   2 +loop                                ( char not-found? )
   if  ." '" emit ." ': "  ." syntax" .uart-error  then   ( char )
   drop
;
: table:  \ name  values c, ..  ( -- )
   create  does> do-table
;


\  character   value     mask  #entries

table: set-handshake     00 c,   1 c,
   ascii - c,  00 c,

table: set-stop-bits     04 c,   2 c,
   ascii 1 c,  00 c,
   ascii 2 c,  04 c,

table: set-parity        38 c,   5 c,
   ascii n c,  00 c,
   ascii o c,  08 c,
   ascii e c,  18 c,
   ascii m c,  28 c,
   ascii s c,  38 c,

table: set-data-bits     03 c,   4 c,
   ascii 5 c,  00 c,
   ascii 6 c,  01 c,
   ascii 7 c,  02 c,
   ascii 8 c,  03 c,

: get-field  ( adr len -- rem-adr,len field-adr,len )
   ascii , left-parse-string
;
: (set-mode)  ( adr len -- )
   get-field set-baudrate    ( adr len )

   3 uart@ to mode
   get-field set-data-bits   ( adr len )
   get-field set-parity      ( adr len )
   get-field set-stop-bits   ( adr len )
             set-handshake   ( )

   \ Commit the changes
   divisor set-divisor       ( )
   mode 3 uart!              ( )
;
headers
: set-mode  ( adr len -- )
   get-divisor divisor-to-baud to current-baudrate (set-mode)
;
: set-modem-control  ( mask -- )  4 uart!  ;

: consume  ( -- )  0 uart@ drop  ;
\ Test for rcv character.  While consuming (discarding) break characters.
: ukey?    ( -- flag )
   line-stat@  dup h# 10 and  if  drop consume false exit  then   ( lstat )
   1 and  0<>
;
: uemit?   ( -- flag )  line-stat@  h# 20 and  0<>  ;  \ Test for xmit ready

: ubreak?  ( -- flag )                  \ Test for received break
   \ Previously-detected break
   " get-break" $call-parent  if  true exit  then

   \ Checked for a break in the FIFO
   \ If the FIFO error summary bit (h#80) indicates that there is an
   \ error (break, framing error, or parity error) somewhere in the
   \ FIFO, we unload the FIFO until we have either seen the break or
   \ have discarded the character in error.  This can cause loss of
   \ good characters that are already in the FIFO, but it is necessary
   \ in order to be able to interrupt runaway programs that are not
   \ polling the serial port.  We don't want previously-queued
   \ characters to "block" the appearance of the break.  The general
   \ solution would be to put the good characters in a software queue,
   \ but that is probably not worth the effort, especially since you
   \ usually want to flush the queue when you get a break anyway.

   begin
      (line-stat@)  dup h# 10  and  if	     ( lstat )		\ New break?
         drop                                ( )
         consume			     ( )	\ Consume the break
         true  exit                          ( true )
      then                                   ( lstat )
      h# 80 and
   while						\ Break in FIFO?
      consume						\ Consume a character
   repeat
   false
;

: ukey   ( -- char )  begin  ukey?   until  0 uart@  ;  \ Receive a character
: uemit  ( char -- )  begin  uemit?  until  0 uart!  ;  \ Transmit a character

\ poll-tty is called periodically to see if the user has tried to
\ interrupt us by sending a "break" character.

: poll-tty  ( -- )  ubreak?  if  user-abort  then  ;

external	\ The following routines are visible as package methods
d# 9600 value default-baudrate

\ Queues for collecting received bytes
d# 1024 constant /q

struct
/n field >head
/n field >tail
/q field >qdata
constant /qstruct

/qstruct instance buffer: read-q
\ /qstruct buffer: write-q

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

\ false instance value q-lock
: read-all  ( -- )
   \ Upon entry, we believe that there is at least one character to read
   \ I have seen conditions where a UART will report, via an interrupt,
   \ that a character is available, but the line status register won't
   \ report it.
   begin  0 uart@ read-q enque  ukey? 0=  until
;
: try-read  ( -- )  ukey?  if  read-all  then  ;

\ : (wpoll)  ( -- )  true to q-lock  try-read false to q-lock  ;
: (rpoll)  ( -- )  ( q-lock 0=  if )  try-read  ( then )  ;

instance defer rpoll  ' (rpoll) to rpoll
\ instance defer wpoll  ' (wpoll) to wpoll

0 instance value rx-error
false instance value lost-carrier?
\ : rx-irq  ( -- )  ( q-lock 0=  if )  read-all  ( then )  ;
: rx-status-irq  ( -- )  5 uart@  h# 1f and  to rx-error  ;
: modem-status-irq  ( -- )
   6 uart@  dup  8 and  if
      dup h# 80 and 0=  to lost-carrier?
   then
   drop
;

: decode-irq  ( -- )
   2 uart@        ( iir )
   dup 1 and  if  ( ." Spurious UART IRQ" cr )  drop exit  then
\ XXX we could probably make use of this bit to help with PPP framing
\  dup 8 and  if  ( ." UART FIFO timeout" cr )  drop exit  then
   1 rshift 3 and  case
      0 of  modem-status-irq       endof
      1 of  ." UART Tx IRQ" cr     endof
      2 of  ( rx-irq ) read-all    endof
      3 of  rx-status-irq          endof
   endcase
;

-1 instance value irq#
0 instance value saved-handler

: get-irq  ( -- irq# )  " irq#" $call-parent  ;

: use-irqs  ( -- )
   get-irq to irq#

   irq# interrupt-handler@ to saved-handler
   ['] decode-irq  irq#  interrupt-handler!

   h# d 1 uart!		\ Enable Rx(1), Rx Status(4), Modem Status(8) ints

   h# 01 2 uart!	\ Enable FIFO (1), triggering Rx IRQ at 1 bytes in FIFO
   4 uart@  h# c or  4 uart!	\ Enable IRQ (8), OUT1 (4)

   ['] noop to rpoll
\   ['] noop to wpoll

   6 uart@ drop       \ Read the Modem Status Register to clear the delta bits
   false to lost-carrier?

   irq# enable-interrupt
;
: use-polling  ( -- )
   irq# -1 <>  if
      0 1 uart!		\ Disable Rx (1) and Rx Status (4) interrupts
      4 uart@  h# c invert and  4 uart!		\ Disable IRQ (8), OUT1 (4)
      irq# disable-interrupt
      saved-handler  irq#  interrupt-handler!
      -1 to irq#
      false to lost-carrier?
   then
   ['] (rpoll) to rpoll
\   ['] (wpoll) to wpoll
;

: install-abort  ( -- )  ['] poll-tty d# 100 alarm  ;	\ Check for break
: remove-abort  ( -- )  ['] poll-tty 0 alarm  ;

\ Read at most "len" characters into the buffer at adr, stopping when
\ no more characters are immediately available.
: read  ( adr len -- #read )   \ -2 for none available right now
   rpoll
   dup  0=  if  nip exit  then                   ( adr len )
   read-q deque?  0=  if                         ( adr len )
      2drop                                      ( )
      lost-carrier?  if  -1  false to lost-carrier?  else  -2  then
                                                 ( -2:none | -1:down )
      exit
   then                                          ( adr len char )
   over >r                                       ( adr len char r: len )
   begin                                         ( adr len char r: len )
      2 pick c!                                  ( adr len r: len )
      1 /string                                  ( adr' len' )
      dup 0=  if  2drop r> exit  then            ( adr' len' )
   read-q deque? 0=  until                       ( adr len r: len )
   nip r> swap -                                 ( actual )
;

: write  ( adr len -- #written )
   tuck  bounds ?do
\      wpoll
      uemit?  if  i c@ 0 uart!  1  else  0  then
   +loop
;

: rts-dtr-on   ( -- )  4 uart@  3 or          4 uart!  ;
: rts-dtr-off  ( -- )  4 uart@  3 invert and  4 uart!  ;

: inituart  ( -- )
   3 3 uart!  		\ 8 bits, no parity
   7 2 uart!		\ Clear and enable FIFOs
   d# 9600 baud
;

: open  ( -- okay? )
   " base-adr" $call-parent  to uart-base
   use-polling
   inituart
   default-baudrate to current-baudrate
   read-q init-q

   my-args  ['] (set-mode)  catch  if  2drop false exit  then

   rts-dtr-on
   true
;

: close  ( -- )  use-polling  rts-dtr-off  ;

: selftest  ( -- )  h# 7f  bl  ?do  i uemit  loop  ;
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
