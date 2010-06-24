purpose: Analyze WIFI spectrum to find good channels for NANDblaster
\ See license at end of file

0 value wlan-ih
d# 2048 buffer: scan-buf

: $call-wlan  ( args method$ -- res )  wlan-ih $call-method  ;
: stop-mesh  ( -- )  " mesh-stop" $call-wlan drop  ;
: start-mesh  ( channel# -- )
   " mesh-start" $call-wlan drop
   d# 100 0 " set-beacon" $call-wlan
;

: open-wlan  ( -- )
   " /wlan:force" open-dev to wlan-ih
   wlan-ih 0= abort" Can't open wireless LAN"
   " " " set-ssid" $call-wlan
;
: close-wlan  ( -- )  wlan-ih  ?dup if  close-dev  0 to wlan-ih  then  ;

: analyze-beacons  ( -- total-rssi max-rssi #beacons )
   0 0                 ( tot-rssi  max-rssi )

   \ Byte 2 of the scan result is the number of beacons
   scan-buf 2 + c@ >r  ( tot-rssi  max-rssi        r: #beacons )

   \ The first AP structure begins at offset 3 within the scan result
   scan-buf 3 +        ( tot-rssi  max-rssi 'ap    r: #beacons )

   r@  0  ?do          ( tot-rssi  max-rssi 'ap    r: #beacons )

      \ The RSSI is in byte 8 of the AP structure
      >r r@ 8 + c@     ( tot-rssi  max-rssi  rssi  r: #beacons 'ap )

      \ Update max-rssi
      2dup <  if       ( tot-rssi  max-rssi  rssi  r: #beacons 'ap )
         nip dup       ( tot-rssi  max-rssi' rssi  r: #beacons 'ap )
      then             ( tot-rssi  max-rssi  rssi  r: #beacons 'ap )

      \ Update tot-rssi
      rot + swap       ( tot-rssi' max-rssi        r: #beacons 'ap )

      \ Skip to the next AP structure
      r@ le-w@         ( tot-rssi  max-rssi  len   r: #beacons 'ap )
      r> + wa1+        ( tot-rssi  max-rssi 'ap'   r: #beacons )

   loop                ( tot-rssi  max-rssi 'ap    r: #beacons )
   drop r>             ( tot-rssi  max-rssi #beacons )
;

0 value this-rssi
0 0 2value this-ssid
0 value this-channel
: brief-.ap  ( adr -- adr' )
   dup 8 + c@ to this-rssi              ( adr )
   dup le-w@                            ( adr len )
   swap 2 + swap  d# 19 /string         ( adr' len' )
   begin  dup 0>  while			( adr len )
      over c@  case                     ( adr len )
         0 of  over 2+ dup 1- c@ to this-ssid  endof
         3 of  over 2+ c@ to this-channel  endof
      endcase                           ( adr len )
      over 1+ c@ 2 + /string		( adr' len' )
   repeat  drop			        ( adr )

   push-decimal
   ."  Channel: " this-channel 2 u.r      ( adr )
   ."    Strength: " this-rssi 2 u.r        ( adr )
   pop-base
   ."    SSID: " this-ssid  type          ( adr )
   cr                                   ( adr )
;

0 value this-#beacons

d# 14 constant max-channel#
max-channel# 1+ array >#beacons
max-channel# 1+ array >channel-speed

1 1 lshift  1 6 lshift or  1 d# 11 lshift or  constant def-channel-mask

: channel-bounds  ( -- limit start )  max-channel# 1+  1  ;

: channel-avail?  ( channel# -- flag )  1 swap lshift  def-channel-mask  and  ;

: show-beacons  ( -- #beacons )
   \ The first AP structure begins at offset 3 within the scan result
   scan-buf 3 +              ( 'ap  )
   scan-buf 2 + c@ dup >r    ( 'ap  #beacons )
   0  ?do   ( 'ap  )  \ Byte 2 is number of beacons
      brief-.ap              ( 'ap' )
   loop                      ( 'ap  )
   drop  r>                  ( #beacons )
;

: scan-channel  ( channel# -- actual )
   1 swap lshift  " set-channel-mask" $call-wlan
   scan-buf d# 2048 " scan" $call-wlan  ( actual )
;

: channel-stats  ( channel# -- total-rssi max-rssi #beacons )
   scan-channel  if
      analyze-beacons
   else
      0 0 0
   then
;

\ Keep the rssi,chan pair with the lowest max-rssi value
: lowest-rssi  ( max-rssiN chanN max-rssiM chanM -- max-rssiP P )
   3 pick  2 pick                    ( max-rssiN chanN max-rssiM chanM max-rssiN max-rssiM )
   u>  if  2nip  else  2drop  then   ( max-rssiP chanP )
;

: try-channel  ( max-rssiN N chan# -- max-rssiN' N' no-beacons? )
   >r r@  channel-stats  0=  if      ( max-rssiN N total-rssi max-rssi r: chan# )
      \ No beacons - this one is an automatic winner
      4drop  0 r> true               ( max-rssiN' N' no-beacons? )
   else                              ( max-rssiN N total-rssi max-rssi r: chan# )
      \ Some activity on this channel - keep it if it's the quietest so far
      nip r>  lowest-rssi  false     ( max-rssiN' N' no-beacons? )
   then                              ( max-rssiN' N' no-beacons? )
;

: quietest-mesh-channel  ( -- max-rssi chan# )
   open-wlan
   h# ffffffff 0  \ High RSSI for starters     ( max-rssi0 0 )
   channel-bounds  do                          ( max-rssiN chanN )
      i channel-avail?  if                     ( max-rssiN chanN )
         i try-channel  ?leave                 ( max-rssiN chanN )
      then
   loop
   close-wlan
;

d# 10 constant rssi-threshold
: quietest-auto-channel  ( -- chan# )
   quietest-mesh-channel             ( rssi chan# )
   swap rssi-threshold >  if         ( chan# )
      ." No wireless channels are quiet.  The quietest is channel " dup .d cr  ( chan# )
      " Do you want to use that channel" confirmedn?   ( chan# proceed? )
      0= abort" Stopping."
   then                              ( chan# )
;

: multinand-traffic?  ( channel# -- flag )
   start-mesh
   " "(01 00 5e 7e 01 02)" " set-multicast" $call-wlan
   d# 300 0  do
      scan-buf d# 2048 " read" $call-wlan            ( actual )
      0>  if                                         ( )
         scan-buf d# 12 + " XO" comp 0=  if          ( )
            stop-mesh                                ( )
            true unloop exit
         then
      then
      1 ms
   loop
   stop-mesh
   false
;

: search-channels  ( -- true | chan# false )
   channel-bounds  do                          ( )
      i channel-avail?  if                     ( )
         i multinand-traffic?  if              ( )
            i unloop false exit
         then                                  ( )
      then                                     ( )
   loop                                        ( )
   true
;

: find-multinand-server  ( -- true | chan# false )
   open-wlan
   search-channels
   close-wlan
;

d# 1514 buffer: mesh-test-buf

: (channel-speed)  ( channel# -- kb/sec )
   dup >r  start-mesh
   " enable-multicast" $call-wlan
   1 " mesh-set-ttl" $call-wlan
   h# b " mesh-set-bcast" $call-wlan

   " "(00 00 00 00 00 00 01 00 5e 7e 01 01)XO" mesh-test-buf swap move

   tsc@
   d# 1000 0 do
      mesh-test-buf d# 1514 " write" $call-wlan drop
   loop
   tsc@ 2swap d- ms-factor um/mod nip   ( ms )
   d# 1,514,000 swap /                  ( kb/sec )
   stop-mesh                            ( kb/sec )
   dup r> >channel-speed !              ( kb/sec )
;
: channel-speed  ( channel# -- kb/sec )
   open-wlan (channel-speed) close-wlan
;

: ?faster  ( chan# kb/sec this-chan# -- chan#' kb/sec )
   dup (channel-speed)                 ( chan# kb/sec this-chan# this-kb/sec )
   2 pick over u<   if  2swap  then   ( chan# kb/sec this-chan# this-kb/sec )
   2drop
;

: (.channel-speed)  ( channel# -- )
   push-decimal
   ."  Channel: " dup 2 u.r  ."    "
   (channel-speed)
   <# u# u# u# [char] . hold u# u#> type  ."  Mbytes/sec" cr
   pop-base
;

: .wifi-speeds  ( -- )
   open-wlan
   channel-bounds  do
      i channel-avail?  if
         i (.channel-speed)
      then
   loop
   close-wlan
;

: (.channel-beacons)  ( channel# -- )
   dup >r              ( r: channel# )
   scan-channel  if    ( r: channel# )
      show-beacons     ( #beacons r: channel# )
   else                ( r: channel# )
      0                ( #beacons r: channel# )
   then                ( #beacons r: channel# )
   r> >#beacons !      ( )
;

: .wifi-beacons  ( -- )
   open-wlan
   channel-bounds  do
      i channel-avail?  if
         i (.channel-beacons)
      then
   loop
   close-wlan
;

: .wifi  ( -- )
   ." Beacons: "  cr
   .wifi-beacons
   cr
   ." Max transmit speeds: (congestion dependent)" cr
   .wifi-speeds
;

d# 2000 constant wifi-speed-threshold
: quiet&fast?  ( channel# -- flag )
   dup >#beacons @  if  drop false exit  then  ( channel# )
   >channel-speed @  wifi-speed-threshold >
;

: quiet-channel-mask  ( -- mask )
   0                                  ( mask )
   channel-bounds  do                 ( mask )
      i channel-avail?  if            ( mask )
         i >#beacons @  0=  if        ( mask )
            1 i lshift or             ( mask' )
         then                         ( mask )
      then                            ( mask )
   loop                               ( mask )
;

: fastest-of  ( mask -- chan# )
   0 0
   channel-bounds  do                     ( mask chan# speed )
      2 pick  1 i lshift  and  if         ( mask chan# speed )
         dup  i >channel-speed @ <   if   ( mask chan# speed )
            2drop  i  i >channel-speed @  ( mask chan#' speed' )
         then                             ( mask chan# speed )
      then                                ( mask chan# speed )
   loop                                   ( mask chan# speed )
   rot 2drop
;

: nb-auto-channel  ( -- chan# )
   ." Analyzing WIFI spectrum" cr
   cr
   .wifi

   quiet-channel-mask  ?dup 0=  if  def-channel-mask  then
   fastest-of
   cr
   ." Using channel " dup .d cr
   d# 4000 ms
;

: nb-clone    ( -- )  nb-auto-channel  #nb-clone  ;
: nb-secure   ( -- )  nb-auto-channel  #nb-secure-def  ;
: nb-update   ( -- )  nb-auto-channel  #nb-update-def  ;

\ LICENSE_BEGIN
\ Copyright (c) 2008 FirmWorks
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
