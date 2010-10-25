\ See license at end of file
purpose: Host to EC SPI protocol

\ See http://wiki.laptop.org/go/XO_1.75_HOST_to_EC_Protocol

\ Interface from pckbd.fth to i8042.fth:
\   set-port  ( port# -- )  \ Selects keyboard (port#=0) or mouse (port#=1)
\   get-data  ( -- data | -1 )  \ Returns a keyboard or mouse byte, or -1 if none after one second
\   get-data?  ( -- false | data true )  \ Non-blocking version of get-data
\   clear-out-buf  ( -- )  \ Drains pending data, waiting until 120 ms elapses with no data.  Built from get-data?
\   put-get-data  ( cmd -- data | -1 )   \ Sends cmd and waits for one response byte
\         Used only by "echo?", which is not called on OLPC.
\   put-data  ( data -- )  \ Sends a byte to the keyboard or mouse
\         Used only by "cmd".  "cmd" is used by set-scan-set, default-disable-kbd, enable-scan, set-leds, toggle-leds,
\         kbd-reset, (obsolete) olpc-set-ec-keymap.  set-scan-set is used only by commented-out code guarded by
\         the non-defined ifdef "fix-keyboard".  default-disable-kbd is called only by get-initial-state (NC on OLPC).
\         enable-scan is NC on OLPC.  set-leds is called by toggle-leds with is called when you press numlock or
\         scrolllock or capslock, none of which the OLPC keyboard has.
\   enable-intf  ( -- )  \ Sends "ae" to the keyboard controller (not the keyboard).  Not called on OLPC with current FW.
\   test-lines  ( -- error? )  \ Tests the keyboard clock and data lines.  Not called on OLPC.

0 0  " d4037000"  " /" begin-package   	\ EC-SPI interface using SSP3

headerless

" ec-spi"     device-name

0 0 encode-bytes
   " olpc,ec-spi"  encode-string encode+
" compatible" property

my-address      my-space  h# 1000  encode-reg
" reg" property

1 " #address-cells"  integer-property
0 " #size-cells"     integer-property

3 /n* buffer: port-data
: init-queue  ( -- )  port-data  3 na+  bounds  ?do  -1 i !  /n +loop  ;
: enque  ( data port# -- )
   port-data swap na+ !    ( data adr )
;
: deque?  ( port# -- false | data true )
   port-data swap na+      ( adr )
   dup @                   ( adr data )
   dup -1 =  if            ( adr data )
      2drop false          ( false )
   else                    ( adr data )
      -1 rot !             ( data )
      true                 ( data true )
   then
;

h# d4037000 value ssp-base  \ Default to SSP3
: ssp-sscr0  ( -- adr )  ssp-base  ;
: ssp-sscr1  ( -- adr )  ssp-base  la1+  ;
: ssp-sssr   ( -- adr )  ssp-base  2 la+  ;
: ssp-ssdr   ( -- adr )  ssp-base  4 la+  ;

: enable  ( -- )
   h# 87 ssp-sscr0 rl!   \ Enable, 8-bit data, SPI normal mode
;
: disable  ( -- )
   h# 07 ssp-sscr0 rl!   \ 8-bit data, SPI normal mode
;
\ Switch to master mode, for testing
: master  ( -- )
   disable
   h# 0000.0000 ssp-sscr1 rl!  \ master mode
   enable
;

: ssp1-clk-on  7 h# d4015050 l!   3 h# d4015050 l!  ;
: ssp2-clk-on  7 h# d4015054 l!   3 h# d4015052 l!  ;
: ssp3-clk-on  7 h# d4015058 l!   3 h# d4015058 l!  ;
: ssp4-clk-on  7 h# d401505c l!   3 h# d401505c l!  ;

: wb  ( byte -- )  ssp-ssdr rl!  ;
: rb  ( -- byte )  ssp-ssdr rl@ .  ;

\ Wait until the CSS (Clock Synchronization Status) bit is 0
: wait-clk-sync  ( -- )
   begin  ssp-sssr rl@ h# 400.0000 and  0=  until
;

\ Choose alternate function 4 (SSP3) for the pins we use
: select-ssp3-pins
   h# c4 h# d401e170 rl!  \ GPIO74
   h# c4 h# d401e174 rl!  \ GPIO75
   h# c4 h# d401e178 rl!  \ GPIO76
   h# c4 h# d401e17c rl!  \ GPIO77
;
: init-ssp-in-slave-mode  ( -- )
   select-ssp3-pins
   ssp3-clk-on
   h# 07 ssp-sscr0 rl!   \ 8-bit data, SPI normal mode
   h# 1380.0010 ssp-sscr1 rl!  \ SCFR=1, slave mode, Rx w/o Tx, early phase
   \ The enable bit must be set last, after all configuration is done
   h# 87 ssp-sscr0 rl!   \ Enable, 8-bit data, SPI normal mode
   wait-clk-sync
;
: set-ssp-receive-w/o-transmit  ( -- )
   ssp-sscr1 rl@  h# 0080.0000 or  ssp-sscr1 rl!
;
: clr-ssp-receive-w/o-transmit  ( -- )
   ssp-sscr1 rl@  h# 0080.0000 invert and  ssp-sscr1 rl!
;
0 value ssp-rx-threshold
: set-ssp-fifo-threshold  ( n -- )  to ssp-rx-threshold  ;
\ tx fifo trigger threshold?

: .ssr  ssp-sssr rl@  .  ;
: ssp-ready?  ( -- flag )
   ssp-sssr rl@ d# 12 rshift h# f and  ssp-rx-threshold  =
;

\ Set the direction on the ACK and CMD GPIOs
d# 151 constant cmd-gpio#
d# 125 constant ack-gpio#
: init-ec-spi-gpios  ( -- )
   cmd-gpio# gpio-dir-out
   ack-gpio# gpio-dir-out
;
: clr-cmd  ( -- )  cmd-gpio# gpio-clr  ;
: set-cmd  ( -- )  cmd-gpio# gpio-set  ;
: clr-ack  ( -- )  ack-gpio# gpio-clr  ;
: set-ack  ( -- )  ack-gpio# gpio-set  ;
: fast-ack  ( -- )  set-ack clr-ack  ;
: slow-ack  ( -- )  d# 10 ms  set-ack d# 10 ms  clr-ack  ;
defer pulse-ack  ' slow-ack to pulse-ack  \ FIXME !!!

0 value ec-spi-cmd-done  \ 0 - still waiting, 1 - successful send, 2 - timeout

6 buffer: ec-cmdbuf
d# 16 buffer: ec-respbuf
: expected-response-length  ( -- n )  ec-cmdbuf 1+ c@ h# f and  ;

: write-cmd-to-ssp-fifo  ( -- )
   6 0  do
      ec-cmdbuf i + c@  ssp-ssdr rl!
   loop
;

0 value ec-cmd-time-limit
: ec-cmd-timeout?   ( -- flag )
   ec-cmd-time-limit 0=  if  false exit  then
   get-msecs  ec-cmd-time-limit  -  0>=
;
: cancel-cmd-timeout  ( -- )  0 to ec-cmd-time-limit  ;
: set-cmd-timeout  ( -- )
   get-msecs d# 1000 +  to ec-cmd-time-limit
   ec-cmd-time-limit 0=  if  1 to ec-cmd-time-limit  then  \ Avoid reserved value
;

defer ec-spi-state  ' noop to ec-spi-state

defer ec-spi-upstream
: ec-spi-response  ( -- )
   cancel-cmd-timeout
   expected-response-length  0  ?do
      ssp-ssdr rl@  ec-respbuf i + c!
   loop
   1 to ec-spi-cmd-done
   2 set-ssp-fifo-threshold
   clr-cmd
   ['] ec-spi-upstream to ec-spi-state
;
: ec-spi-switched  ( -- )
   set-ssp-receive-w/o-transmit
   expected-response-length  if
      expected-response-length set-ssp-fifo-threshold
      ['] ec-spi-response to ec-spi-state
   else
      ec-spi-response
   then
;
: (ec-spi-upstream)  ( -- )
   ssp-ssdr rl@  ssp-ssdr rl@             ( channel# data )
   over 3 =  if  \ Switched               ( channel# data )
      2drop                               ( )
      write-cmd-to-ssp-fifo               ( )
      clr-ssp-receive-w/o-transmit        ( )
      ['] ec-spi-switched to ec-spi-state ( )
   else                                   ( channel# data )
      swap enque                          ( )
   then
;
' (ec-spi-upstream) to ec-spi-upstream
: init-ec-spi  ( -- )
   init-ec-spi-gpios
   init-ssp-in-slave-mode
   set-ssp-receive-w/o-transmit
   clr-cmd
   clr-ack  \ Tell EC that it is okay to send
   ['] ec-spi-upstream to ec-spi-state
;

: ec-spi-handle-message  ( -- )
   ec-spi-state
   pulse-ack
;
: poll-ec-spi  ( -- )
   ssp-ready?  if
      exit
   then
   ec-cmd-timeout?  if
      clr-cmd
      cancel-cmd-timeout
      2 to ec-spi-cmd-done   \ Timeout
      ['] ec-spi-upstream to ec-spi-state      
      exit
   then
   ec-spi-handle-message
;

: ec-command  ( [ args ] #args #results cmd-code -- [ results ] error? )
   ec-cmdbuf 6 erase       ( [ args ] #args #results cmd-code )
   ec-cmdbuf c!            ( [ args ] #args #results )
   over 4 lshift or        ( [ args ] #args #args|#results )
   ec-cmdbuf 1+ c!         ( [ args ] #args )
   dup 4 >  abort" Too many EC command arguments"
   0  ?do                  ( ... arg )
      ec-cmdbuf 2+ i + c!  ( ... )
   loop                    ( )

   set-cmd-timeout
   set-cmd

   0 to ec-spi-cmd-done
   begin
      poll-ec-spi
      ec-spi-cmd-done
   until

   ec-spi-cmd-done  2 =  if  true  exit  then

   ec-cmdbuf 1+ c@  0 ?do  \ XXX maybe this loop should go backwards?
      ec-respbuf i + c@
   loop
   false
;

0 instance value port#
: set-port  ( port# -- )  to port#  ;
: put-data  ( byte -- )  port# 2 0 d# 99 ec-command  ;  \ XXX
: get-data?  ( -- false | data true )
   port# deque?     ( false | data true )
   poll-ec-spi
;
: get-data  ( -- data | -1 )  \ Wait for data from our device
   d# 1000 0  do
      get-data?  if  unloop exit  then		( data )
      1 ms
   loop
   true \ abort" Timeout waiting for data from device" 
;
: put-get-data  ( cmd -- data | -1 )  put-data get-data  ;
\ Wait until the device stops sending data
: clear-out-buf  ( -- )  begin  d# 120 ms  get-data?  while  drop  repeat  ;

0 value open-count
: open  ( -- flag )
   open-count  0=  if
      my-address my-space  h# 1000  " map-in" $call-parent  is ssp-base
\     setup-pin-mux
      init-ec-spi
   then
   open-count 1+ to open-count
   true
;
: close  ( -- )
   open-count 1 =  if
      ssp-base h# 1000  " map-in" $call-parent  0 is ssp-base
   then
   open-count 1- 0 max to open-count
;
end-package

\ LICENSE_BEGIN
\ Copyright (c) 2010 FirmWorks
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
