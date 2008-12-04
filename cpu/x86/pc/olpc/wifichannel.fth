

0 value wlan-ih
d# 2048 buffer: scan-buf

: open-wlan  ( -- )
   " /wlan:force" open-dev to wlan-ih
   wlan-ih 0= abort" Can't open wireless LAN"
   " " " set-ssid" wlan-ih $call-method
;

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

: channel-stats  ( channel# -- total-rssi max-rssi #beacons )
   1 swap lshift  " set-channel-mask" wlan-ih $call-method
   scan-buf d# 2048 " scan" wlan-ih $call-method  ( actual )
   if                
      analyze-beacons
   else
      0 0 0
   then
;

d# 15 constant rssi-limit

: scan-mesh-channels  ( -- chan# max-rssi )
   d# 11 channel-stats  0=  if   ( total-rssi max-rssi )
      2drop  d# 11 0  exit
   then                          ( total-rssi max-rssi )
   nip  d# 11                    ( max-rssi chan# )

   d# 6 channel-stats  0=  if    ( max-rssi11 chan11 total-rssi max-rssi )
      4drop  6 0  exit
   then                          ( max-rssi11 chan11 total-rssi max-rssi )
   nip                           ( max-rssi11 chan11 max-rssi6 )
   rot over >  if                ( max-rssi11 chan11 max-rssi6 )
      nip nip 6                  ( max-rssi6 chan6 )
   else                          ( max-rssi11 chan11 max-rssi6 )
      drop                       ( max-rssi11 chan11 )
   then                          ( max-rssiN chan# )

   d# 1 channel-stats  0=  if    ( max-rssiN chan# total-rssi1 max-rssi1 )
      4drop  1 0  exit
   then                          ( max-rssiN chan# total-rssi1 max-rssi1 )
   nip                           ( max-rssiN chan# max-rssi1 )
   rot over >  if                ( max-rssiN chan# max-rssi1 )
      nip nip 1                  ( max-rssi1 chan1 )
   else                          ( max-rssiN chan# max-rssi1 )
      drop                       ( max-rssiN chan# )
   then                          ( max-rssiN chan# )
   swap                          ( chan# max-rssi )
;

: quietest-mesh-channel  ( -- chan# max-rssi )
   open-wlan
   scan-mesh-channels
   wlan-ih close-dev
;


: multinand-traffic?  ( channel# -- flag )
   " mesh-start" wlan-ih $call-method drop
   d# 100 0 " set-beacon" wlan-ih $call-method
   " "(01 00 5e 7e 01 02)" " set-multicast" wlan-ih $call-method
   d# 300 0  do
      scan-buf d# 2048 " read" wlan-ih $call-method  ( actual )
      0>  if                                         ( )
         scan-buf d# 12 + " XO" comp 0=  if          ( )
            " mesh-stop" wlan-ih $call-method drop   ( )
            true unloop exit
         then
      then
      1 ms
   loop
   " mesh-stop" wlan-ih $call-method drop
   false
;
: search-channels  ( -- true | chan# false )
   d# 11 multinand-traffic?  if  d# 11 false exit  then
   d#  6 multinand-traffic?  if  d#  6 false exit  then
   d#  1 multinand-traffic?  if  d#  1 false exit  then
   true
;
: find-multinand-server  ( -- true | chan# false )
   open-wlan
   search-channels
   wlan-ih close-dev
;
: enand  ( -- )
   find-multinand-server abort" No multicast NAND server"  ( chan# )
   #enand
;

d# 10 constant rssi-threshold
: ether-clone  ( -- )
   quietest-mesh-channel  ( chan# rssi )
   rssi-threshold > abort" No quiet channels"  ( chan# )
   #ether-clone
;
