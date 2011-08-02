purpose: USB Hub Probing Code
\ See license at end of file

hex

[ifndef] set-usb20-char
: set-usb20-char  ( port dev -- )  2drop  ;
[then]

8 buffer: hub-buf                       \ For hub probing

: power-hub-port   ( port -- )  PORT_POWER  DR_PORT " set-feature" $call-parent drop  ;
: reset-hub-port   ( port -- )  PORT_RESET  DR_PORT " set-feature" $call-parent drop  d# 20 ms  ;
\ Test modes: 1:J 2:K 3:SE0_NAK 4:Packet 5:ForceEnable
: test-hub-port    ( port test-mode -- )  wljoin  PORT_TEST   DR_PORT " set-feature" $call-parent drop  ;
: untest-hub-port  ( port -- )  PORT_TEST   DR_PORT " clear-feature" $call-parent drop  ;
: clear-status-change  ( port -- )  C_PORT_CONNECTION  DR_PORT " clear-feature" $call-parent drop  ;
: parent-set-target  ( dev -- )  " set-target" $call-parent  ;
: hub-error?  ( -- error? )
   hub-buf 4  0  DR_HUB " get-status" $call-parent    ( actual usberror )
   nip  if                                   ( )
      ." Failed to get hub status" cr
      true                                   ( true )
   else                                      ( )
      hub-buf 2+ c@ 2 and  if                ( )
         ." USB Hub shut down due to over-current" cr      ( )
         true                                ( true )
      else                                   ( )
         false                               ( false )
      then                                   ( error? )
   then                                      ( error? )
;

: get-port-status  ( port -- error? )
   hub-buf 4  2 pick   DR_PORT " get-status" $call-parent    ( port actual usberror )
   nip  if                                   ( port )
      ." Failed to get port status for port " u. cr
      true                                   ( true )
   else                                      ( port )
      drop false                             ( false )
   then                                      ( )
;
: port-status-changed?  ( hub-dev port -- false | connected? true )
   swap parent-set-target       ( port )
   dup get-port-status  if      ( port )
      drop false exit           ( -- false )
   then                         ( port )

   hub-buf c@ 8 and  if         ( port )
      ." Hub port " . ." is over current" cr
      false  exit               ( -- false )
   then

   hub-buf 2+ c@  1 and  if     ( port )
      \ Status changed
      clear-status-change       ( )
      hub-buf c@ 1 and  0<>     ( connected? )
      true                      ( connected? true )
   else                         ( port )
      drop false                ( false )
   then
;

: probe-hub-port  ( hub-dev port -- )
   \ Reset the port to determine the speed
   swap parent-set-target			( port )
   dup reset-hub-port				( port )

   \ get-port-status fills hub-buf with connection status, speed, and other information
   dup get-port-status  			( port error? )
   over clear-status-change              	( port error? )
   if  drop exit  then				( port )

   dup disable-old-nodes			( port ) 
   hub-buf c@ 1 and 0=  if  drop exit  then	( port )  \ No device connected
   hub-buf le-w@ h# 600 and 9 >>  		( port speed )

   \ hub-port and hub-dev route USB 1.1 transactions through USB 2.0 hubs
   over get-hub20-port  get-hub20-dev		( port speed hub-port hub-dev )

   \ Execute setup-new-node in root context and make-device-node in hub node context
   " setup-new-node" $call-parent  if  execute  then  ( )
;

: hub-#ports  ( -- #ports )
   hub-buf 8 0 0 HUB DR_HUB " get-desc" $call-parent nip  if
      ." Failed to get hub descriptor" cr
      0 exit
   then
   hub-buf 2 + c@ 		( #ports )
;
: hub-delay  ( -- #2ms )  hub-buf 5 + c@  ;

: power-hub-ports  ( #ports -- )
   1+  1  ?do  i power-hub-port  loop       ( )
   
   hub-delay 2* ms                          ( )

   " usb-delay" ['] evaluate catch  if      ( )
      2drop  d# 100                         ( ms )
   then                                     ( ms )
   ms
;

: safe-probe-hub-port  ( hub-dev port -- )
   tuck ['] probe-hub-port catch  if    ( port x x )
      2drop  ." Failed to probe hub port " . cr  ( )
   else                                 ( port )
      drop                              ( )
   then                                 ( )
;
external
: probe-hub  ( dev -- )
   dup parent-set-target		( hub-dev )
   hub-#ports  dup  0=  if		( hub-dev #ports )
      2drop exit			( -- )
   then					( hub-dev #ports )

   " configuration#" get-int-property	( hub-dev #ports config# )
   " set-config" $call-parent           ( hub-dev #ports usberr )
   if  drop  ." Failed to set config for hub at " u. cr exit  then  ( hub-dev #ports )

   dup power-hub-ports			( hub-dev #ports )

   hub-error?  if  2drop exit  then	( hub-dev #ports )

   1+ 1  ?do				( hub-dev )
      dup i safe-probe-hub-port		( hub-dev )
   loop					( hub-dev )
   drop					( )
;

: probe-hub-xt  ( -- adr )  ['] probe-hub  ;

: do-reprobe-hub  ( dev -- )
   dup parent-set-target			( hub-dev )
   
   hub-#ports  dup 0=  if                       ( hub-dev #ports )
      2drop exit                                ( -- )
   then                                         ( hub-dev #ports )

   hub-error?  if  2drop exit  then		( hub-dev #ports )

   1+  1  ?do                                   ( hub-dev )
      dup i port-status-changed?  if            ( hub-dev connected? )
         i disable-old-nodes                    ( hub-dev connected? )
         if                                     ( hub-dev )
            d# 100 ms                           ( hub-dev )  \ Time for device to wake up
            dup i safe-probe-hub-port           ( hub-dev )
         then                                   ( hub-dev )
      else                                      ( hub-dev )
         i port-is-hub?  if                     ( hub-dev phandle )
            reprobe-hub-node                    ( hub-dev )
         then                                   ( hub-dev )
      then                                      ( hub-dev )
   loop                                         ( hub-dev )
   drop                                         ( )
;

: reprobe-hub-xt  ( -- adr )  ['] do-reprobe-hub  ;

: hub-port-connected?  ( port# -- flag )
   get-port-status  if  false exit  then
   hub-buf c@ 1 and  0<>
;
0 value hub-dev
: wait-hub-connect  ( port# -- error? )
   begin                            ( port# )
      dup hub-port-connected?  0=   ( port# unconnected? )
   while                            ( port# )
      key?  if                      ( port# )
         key h# 1b =  if            ( port# )   \ ESC aborts
            drop true exit          ( -- true )
         then                       ( port# )
      then                          ( port# )
   repeat                           ( port# )
   ." Device connected - probing ... "
   d# 150 ms                        ( port# )   \ Wakeup time
   probe-setup                      ( port# )
   hub-dev swap ['] probe-hub-port  catch  if  ( x x  )
      2drop                         ( )
      ." Failed" cr                 ( )
      true                          ( true )
   else                             ( )
      ." Done" cr                   ( )
      false                         ( false )
   then                             ( error? )
   probe-teardown                   ( error? )
;

: (hub-selftest)  ( port -- stop? )
   >r
   hub-dev parent-set-target              ( )
   r@ get-port-status  if                 ( )
      ." Get-port-status failed for hub port " r@ u. cr
      r> drop true exit                   ( -- true )
   then                                   ( )
   hub-buf c@ 8 and  if   \ Connected     ( )
      ." Hub port " r@ u. ." in over current" cr
      r> drop true exit                   ( -- true )
   then                                   ( )
   hub-buf c@ 1 and  if   \ Connected     ( )
      ." Hub port " r@ u. ." in use" cr   ( )
   else                                   ( )
      diagnostic-mode?  if                ( )
         ." Please connect a device to USB hub port " r@ u.  cr   ( )
         r@ wait-hub-connect  if  r> drop true exit  then         ( )
      else                                                        ( )
         ." Fisheye pattern out to USB hub port " r@ u. cr        ( )
         r@ 4 test-hub-port                                       ( )
         d# 2,000 ms                                              ( )
         r@ untest-hub-port                                       ( )
         r@ reset-hub-port  r@ power-hub-port                     ( )
      then                                                        ( )
   then                                                           ( )
   r> drop false
;

: hub-selftest  ( hub-dev -- error? )
   to hub-dev                                           ( )

   " hub-port-seq" get-inherited-property  if           ( )
      hub-#ports 1+  1  ?do                             ( )
         i (hub-selftest)  if  true unloop exit  then
      loop                                              ( )
   else                                                 ( propval$ )
      decode-int nip nip                                ( seq )

      4 0 do
         dup h# ff000000 and d# 24 rshift h# ff and     ( seq port )
         dup if                                         ( seq port )
            (hub-selftest)  if  drop true exit  then
         else                                           ( seq port )
            drop                                        ( seq )
         then                                           ( seq )
         d# 8 lshift                                    ( seq' )
      loop                                              ( seq )
      drop                                              ( )
   then                                                 ( )

   \ Maybe need to reset the entire hub here
   false                                        ( false )
;
: hub-selftest-xt  ( -- xt )  ['] hub-selftest  ;

headers

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
