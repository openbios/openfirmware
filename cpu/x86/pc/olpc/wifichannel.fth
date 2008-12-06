

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

: scan-mesh-channels  ( -- max-rssi chan# )
   h# ffffffff 0                       ( max-rssi0 0 )  \ This high rssi always loses
   d# 11 try-channel  if  exit  then   ( max-rssiN chanN )
   d#  6 try-channel  if  exit  then   ( max-rssiN chanN )
   d#  1 try-channel  drop             ( max-rssi chan# )
;

: quietest-mesh-channel  ( -- max-rssi chan# )
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
: nandblaster  ( -- )
   find-multinand-server abort" No multicast NAND server"  ( chan# )
   #nb
;
alias nb nandblaster

d# 10 constant rssi-threshold
: nb-auto-channel  ( -- chan# )
   quietest-mesh-channel  ( rssi chan# )
   swap rssi-threshold > abort" No quiet channels"  ( chan# )
;

: nb-clone  ( -- )  nb-auto-channel #nb-clone  ;

: nb-update  " u:\fs.plc" " u:\fs.img" nb-auto-channel #nb-update  ;
: nb-secure  " u:\fs.zip" " u:\fs.img" nb-auto-channel #nb-secure  ;
