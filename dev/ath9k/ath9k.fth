purpose: ATH9K driver
\ See license at end of file

hex
external

: enable-rsn   ( -- ok? )  true  ;
: disable-rsn  ( -- ok? )  false to gkey-enabled?
                           false to pkey-enabled? true  ;
: disable-wep  ( -- ok? )  false to wep-enabled? true  ;
: set-ptk  ( ptk$ -- )
   /aes =  if  p-aes /aes  else  p-tkip /tkip  then  move
   set-key-cache
   true to pkey-enabled?
;
: set-gtk-idx  ( idx -- )  debug?  if  dup ." GTK idx = " . cr  then  to grp-idx  ;
: set-gtk  ( gtk$ -- )  
   /aes =  if  g-aes /aes  else  g-tkip /tkip  then  move
   set-key-cache
   true to gkey-enabled?
;
: enforce-protection  ( -- )  ;
: disable-protection  ( -- )
   reset-key-cache 
   false to gkey-enabled?
   false to pkey-enabled?
   false to wep-enabled?
;
: ?set-wep  ( -- )  ;

headers
: make-mac-address-property  ( -- )
   " mac-address"  get-my-property  if   ( )
      mac-adr$ encode-bytes  " local-mac-address" property
      mac-address encode-bytes " mac-address" property
   else                                  ( adr len )
      2drop
   then
;

d# 200 constant rx-detect-time-limit
0 value last-rx-time
: timeout-wait-for-resp?  ( -- timeout? )
   get-msecs last-rx-time - rx-detect-time-limit >=
;
\  0 = got response
\ -1 = timeout waiting for response or disconnected
\ -2 = timeout waiting for transmit after retries
: wait-for-resp  ( resp-type -- -2|-1|0 )
   to resp-type  get-msecs to last-rx-time
   wait-tx-done 0=  if  -2 exit  then  \ Fail to transmit
   false to got-response?
   resp-wait 0  do
      queue-rx
      deque-rx  if            ( node adr len )
         2 pick >r            ( node adr len )  ( R: node )
         process-rx           ( node )  ( R: node )
         r> over <>  if  debug-me  then
         free-rx              ( )
         got-response?  if  leave  then
         disconnected?  if  leave  then
         get-msecs to last-rx-time
      else
         timeout-wait-for-resp?  if  leave  then
      then
      1 ms
   loop
   got-response?  if  0  else  -1  then
;

defer process-resp          ' noop to process-resp
: wait-for-more  ( resp-type -- )
   to resp-type
   resp-wait-xlong 0  do
      queue-rx
      deque-rx  if
         process-rx
         free-rx
         got-response?  if  process-resp  then
         disconnected?  if  leave  then
      then
      1 ms
   loop
;

: (probe-ssid)  ( -- found? )
   debug?  if  ." Scan channel: " curchan >ch-hw-val @ .d cr  then
   scan-ssid count broadcast-mac$ make-probe-req
   xmit-data  50 wait-for-resp 0=  if  add-scan-response  then
   get-scan-actual 3 >
;
: probe-ssid-chs  ( ch hi lo -- found? )
   false -rot  ?do                ( ch flag )
      over i <>  if               \ Not the default channel
         i re-set-channel         ( ch flag )
         (probe-ssid)  if  drop true leave  then
      then                        ( ch flag )
   loop  nip                      ( flag )
;
\ XXX Channel range depends on the domain
: probe-ssid-2GHz  ( ch -- found? )  d# 11 0 probe-ssid-chs  ;
: probe-ssid-5GHz  ( ch -- found? )
   dup d# 18 d# 14 probe-ssid-chs  if  drop true exit  then
   dup d# 22 d# 18 probe-ssid-chs  if  drop true exit  then
\   dup d# 33 d# 22 probe-ssid-chs  if  drop true exit  then
       d# 38 d# 33 probe-ssid-chs
;
: probe-ssid  ( adr len -- actual )
   " ---- probe-ssid ----" vtype
   start-scan-response
   (probe-ssid)  if  get-scan-actual exit  then
   curchan >ch-hw-val @
   dup probe-ssid-2GHz  if  drop get-scan-actual exit  then
       probe-ssid-5GHz  drop  get-scan-actual
;

\ Probe with broadcast ssid
: probe-broadcast-ssid  ( adr len -- actual )   \ Gather all responses within channel
   start-scan-response
   ['] add-scan-response to process-resp
   0 0 broadcast-mac$ make-probe-req
   xmit-data  50 wait-for-resp  case
      0  of  add-scan-response
             50 wait-for-more    endof  \ Got one already, maybe more
     -1  of  50 wait-for-more    endof  \ Didn't get one last time, maybe more
     ( otherwise )  \ Didn't even manage to send the request
   endcase
   get-scan-actual
;
: authenticate  ( target-mac$ -- ok? )
   " ---- authenticate ----" vtype
   2dup 1 -rot make-authenticate-req
   xmit-data  b0 wait-for-resp 0<>  if  ." auth 1 failed to get response" cr 2drop false exit  then
   respbuf dup /802.11n-data-hdr + 4 + le-w@ 0<>  if  ." auth 1 rejected" cr 2drop false exit  then

   /respbuf respbuf /802.11n-data-hdr 88 + >=  if
      key-wep? not  if  ." Shared key expected by the AP" cr 2drop false exit  then
      respbuf dup /802.11n-data-hdr + 6 + dup c@ d# 16 <>  if  ." auth 2 challenge missing" cr 3drop false exit  then
      " ---- authenticate 3 ----" vtype
      dup 2 + swap 1+ c@                  ( target-mac$ challenge$ )
      2swap 3 -rot make-authenticate-req  ( adr len )
      xmit-data  b0 wait-for-resp 0<>  if  ." auth 3 failed to get response" cr false false to wep-enabled? exit  then
      respbuf dup /802.11n-data-hdr + 4 + le-w@ 0=
      dup 0=  if  ." auth 3 rejected" cr false to wep-enabled?  then
   else
      2drop true
   then
;

: deauthenticate  ( target-mac$ -- )
   " ---- deauthenticate ----" vtype
   make-deauthenticate-req
   xmit-data  wait-tx-done  drop
   reset-driver-state
;
: (associate)  ( ch ssid$ target-mac$ -- ok? )
   " ---- (associate) ----" vtype
   make-associate-req                 ( adr len )
   xmit-data  10 wait-for-resp 0= dup  if
      respbuf dup /802.11n-data-hdr 4 + + le-w@ 3fff and to curaid
      dummy-rssi dup to last-rssi to avgbrssi
   then
;

external
: get-mac-address  ( -- adr len )  mac-adr$  ;

: associate  ( ch ssid$ target-mac$ -- ok? )
   " ---- associate ----" vtype
   4 pick 1- curchan >ch-hw-val @ <>  if
      4 pick  debug?  if  ." Set to channel: " dup .d cr  then
      1- dup to defch       \ Save for next open
      re-set-channel
   then

   ?set-wep
   2dup authenticate 0=  if  2drop 3drop false exit  then
                                    ( ch ssid$ target-mac$ )
   d# 10 0 do                       ( ch ssid$ target-mac$ )
      4 pick  4 pick  4 pick  4 pick  4 pick  ( ch ssid$ target-mac$  ch ssid$ target-mac$ )
      (associate)                   ( ch ssid$ target-mac$ ok? )
      if  2drop 3drop true unloop  exit  then
   loop
   2drop 3drop
   false
;

: scan  ( adr len -- actual )
   passive-scan?  ap-mode? or  if
      scan-passive
   else
      scan-ssid c@  if  probe-ssid  else  probe-broadcast-ssid  then
   then
;

headers

: do-associate  ( -- ok? )
   reset-driver-state
   ['] 2drop to ?process-eapol  \ Don't reenter the supplicant while associating
   supplicant-associate dup  if
      ds-associated set-driver-state
      target-mac curbssid /mac-adr move
      write-associd
      key-wep?  if
         set-key-cache
         true to wep-enabled?
      then
   then
   ['] do-process-eapol to ?process-eapol
;

: ?reassociate  ( -- ok? )
   link-up? 0=  if  do-associate  else  true  then
;

: disassociate  ( mac$ -- )
   " ---- disassociate ----" vtype
   make-disassociate-req
   xmit-data  wait-tx-done
   reset-driver-state
;

external
: write-force  ( adr len -- actual )
   queue-rx
   tuck  make-data-frame         ( len adr' len' )
   xmit-data  wait-tx-done 0=  if  drop 0  then
   queue-rx
;

: write  ( adr len -- actual )
   " ---- write ---- " vtype
   ap-mode?  if
      write-force
   else
      queue-rx
      ?reassociate 0=  if  2drop 0 exit  then   \ In case if the connection is dropped
      write-force
   then
;

: read-force  ( adr len -- actual )
   queue-rx
   deque-rx  if                          ( adr len node buf blen )
      process-rx  -rot                   ( node adr len )
      got-data?  if
         debug?  if  ." Got data" cr  data 20 cdump cr  then
         /data min tuck  data -rot move  ( node actual )
      else  2drop 0  then                ( node actual )
      swap free-rx                       ( actual )
   else
      2drop 0                            ( actual )
   then
   queue-rx
;

: read  ( adr len -- actual )
   \ If a good receive packet is ready, copy it out and return actual length
   \ If a bad packet came in, discard it and return -1
   \ If no packet is currently available, return -2

   queue-rx
   ?reassociate 0=  if  2drop 0 exit  then  \ In case if the connection is dropped
   read-force
;

headers

\ Set to true to force open the driver without association.
\ Normal operation should have force-open? be false.
false instance value force-open?
: debug-on  ( -- )  true to debug?  enable-emit  ;
				
: parse-args  ( $ -- )
   false to use-promiscuous?
   begin  ?dup  while
      ascii , left-parse-string
      2dup " debug" $=  if  debug-on  then
      2dup " promiscuous" $=  if  true to use-promiscuous?  then
           " force" $=  if  true to force-open?  then
   repeat drop
;
: init-buf  ( -- )
   init-buf
   alloc-packet init-rx-bufs  init-tx-bufs
   broadcast-mac$ bssidmask swap move  
;
: free-buf  ( -- )  free-packet  free-tx-bufs  free-rx-bufs  ;

\ Enable non-beacon broadcast plus other people's unicast packets
: set-bssid-regs  ( -- )
   \ Enable non-beacon broadcast from the AP
   target-mac le-l@ 8008 reg!
   target-mac 4 + le-w@ curaid 10 << or  800c reg!  
;

external
: open  ( -- ok? )
   my-args parse-args
   map-regs
   " " set-ssid
   opencount @ 0=  if
      init-buf  init-device
      make-mac-address-property
      start  d# 100 ms
      my-args " supplicant" $open-package to supplicant-ih
      supplicant-ih 0=  if  free-buf false exit  then
      force-open?  if
         reset-driver-state
      else
         link-up? 0=  if
            do-associate 0=  if
               supplicant-ih close-package  0 to supplicant-ih
               free-buf false exit
            then
         then
      then
   then
   opencount @ 1+ opencount !
   true
;
: close  ( -- )
   opencount @ 1- 0 max  opencount !
   opencount @ 0=  if
      link-up?  if  target-mac$ deauthenticate  then
      reset-driver-state
      ['] 2drop to ?process-eapol
      stop
      supplicant-ih ?dup  if  close-package 0 to supplicant-ih  then
      free-buf
      unmap-regs
   then
;

: load  ( adr -- len )
   link-up? 0=  if  drop 0 exit  then   \ Not associated yet.

   " obp-tftp" find-package  if         ( adr phandle )
      my-args rot  open-package         ( adr ihandle|0 )
   else                                 ( adr )
      0                                 ( adr 0 )
   then                                 ( adr ihandle|0 )

   dup  0=  if  ." Can't open obp-tftp support package" stop abort  then
                                        ( adr ihandle )

   >r
   " load" r@ ['] $call-method  catch   ( len false | x x x true )
   r> close-package
   throw
;

800 constant /tmp-buf
0 value tmp-buf
: (scan-wifi)  ( -- error? )
   true to force-open?
   open
   false to force-open?
   0=  if  ." Can't open Atheros wireless" cr true close  exit  then

   /tmp-buf alloc-mem to tmp-buf
   tmp-buf /tmp-buf  scan-passive
   tmp-buf /tmp-buf free-mem

   close  false
;
: scan-wifi  ( -- )  (scan-wifi) drop  ;
: selftest  ( -- error? )  (scan-wifi)  ;

\ LICENSE_BEGIN
\ Copyright (c) 2011 FirmWorks
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
