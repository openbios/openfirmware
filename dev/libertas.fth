purpose: Marvel "Libertas" wireless network driver common code
\ See license at end of file

headers
hex

\ **************** WPA and WPA2 are not functional yet ******************

\ =======================================================================
\ Usage:
\ 
\ Before probe-pci, reset-wlan.
\ Before using the driver, set wlan-* environment variables.
\ =======================================================================

\ Interface to /supplicant support package
0 value supplicant-ih
: $call-supplicant  ( ...$ -- ... )  supplicant-ih $call-method  ;
: supplicant-associate   ( -- flag )  " do-associate" $call-supplicant  ;
: supplicant-process-eapol  ( adr len -- )  " process-eapol" $call-supplicant  ;
: .scan  ( adr -- )  " .scan" $call-supplicant  ;
: .ssids  ( adr -- )  " .ssids" $call-supplicant  ;

defer load-all-fw  ( -- error? )   ' false to load-all-fw
defer ?process-eapol		['] 2drop to ?process-eapol

0 value outbuf
d# 2048 value /outbuf   \ Power of 2 larger than max-frame-size
                        \ Override as necessary

d# 2048 value /inbuf    \ Power of 2 larger than max-frame-size
                        \ Override as necessary

: init-buf  ( -- )
   outbuf 0=  if  /outbuf dma-alloc to outbuf  then
;
: free-buf  ( -- )
   outbuf  if  outbuf /outbuf dma-free  0 to outbuf  then
;

\ =======================================================================
\ Driver variables
\ =======================================================================

\ driver-state bit definitions
0000 constant ds-not-ready		\ Initial state
0001 constant ds-ready			\ Firmware has been downloaded
0010 constant ds-connected-mask		\ Associated or joined
0010 constant ds-associated
8000 constant ds-disconnected		\ Disconnected

ds-not-ready value driver-state

: set-driver-state    ( bit-mask -- )  driver-state or to driver-state  ;
: reset-driver-state  ( bit-mask -- )  invert driver-state and to driver-state  ;

\ bss-type values
1 constant bss-type-managed
2 constant bss-type-adhoc
bss-type-managed value bss-type

\ WPA/WPA2 keys
0 value ktype			\ Key type
0 value ctype-g			\ Group (multicast) cipher type
0 value ctype-p			\ Pairwise (unicast) cipher type

\ ktype values
0 constant kt-wep
1 constant kt-wpa
2 constant kt-wpa2
h# ff constant kt-none

\ ctype-x values
0 constant ct-none
1 constant ct-tkip
2 constant ct-aes

\ WEP keys
1 constant TYPE_WEP_40_BIT
2 constant TYPE_WEP_104_BIT

0 value wep-idx
d# 13 buffer: wep1  0 constant /wep1
d# 13 buffer: wep2  0 constant /wep2
d# 13 buffer: wep3  0 constant /wep3
d# 13 buffer: wep4  0 constant /wep4
: wep1$  ( -- $ )  wep1 /wep1  ;
: wep2$  ( -- $ )  wep2 /wep2  ;
: wep3$  ( -- $ )  wep3 /wep3  ;
: wep4$  ( -- $ )  wep4 /wep4  ;

/mac-adr buffer: target-mac
: target-mac$  ( -- $ )  target-mac /mac-adr  ;

0              value    #mc-adr         \ Actual number of set multicast addresses
d# 32      dup constant #max-mc-adr	\ Maximum number of multicast addresses
/mac-adr * dup constant /mc-adrs
               buffer:  mc-adrs		\ Buffer of multicast addresses

d# 256 buffer: ssid
0 value /ssid
: ssid$  ( -- $ )  ssid /ssid  ;

0 value channel

d# 80 buffer: wpa-ie		\ WPA IE saved for EAPOL phases
0 value /wpa-ie

external
: wpa-ie$  ( -- adr len )  wpa-ie /wpa-ie  ;
headers

\ Data rates
d# 14 constant #rates
\ create supported-rates 82 c, 84 c, 8b c, 96 c, 0c c, 12 c, 18 c, 24 c,
\ 		       30 c, 48 c, 60 c, 6c c, 00 c, 00 c,
create supported-rates 82 c, 84 c, 8b c, 96 c, 8c c, 92 c, 98 c, a4 c,
		       b0 c, c8 c, e0 c, ec c, 00 c, 00 c,
#rates buffer: common-rates

external
: supported-rates$  ( -- adr len )  supported-rates #rates  ;
: set-common-rates  ( adr len -- )
   common-rates #rates erase
   #rates min common-rates swap move
;
headers

\ Miscellaneous
0 value preamble		\ 0=long, 2=short, 4=auto
0 value auth-mode		\ 0: open; 1: shared key; 2: EAP
h# 401 value cap		\ Capabilities
3 instance value mac-ctrl	\ MAC control

external
: set-preamble  ( preamble -- )  to preamble  ;
: set-cap  ( cap -- )  to cap  ;
: set-auth-mode  ( amode -- )  to auth-mode  ;
headers

: marvel-link-up?  ( -- flag )  driver-state ds-ready >  ;

' marvel-link-up? to link-up?

\ =========================================================================
\ Firmware Command
\ =========================================================================

struct
   /fw-transport +
   2 field >fw-cmd		\ Start of command header
   2 field >fw-len
   2 field >fw-seq
   2 field >fw-result
dup constant /fw-cmd
dup 4 - constant /fw-cmd-hdr	\ Command header len (less /fw-transport)
   0 field >fw-data		\ Command payload starts here
drop

: outbuf-out  ( -- error? )
   outbuf  dup >fw-len le-w@ /fw-transport +  cmd-out
;


0 constant ACTION_GET
1 constant ACTION_SET
2 constant ACTION_ADD
3 constant ACTION_HALT
4 constant ACTION_REMOVE
8 constant ACTION_USE_DEFAULT

-1 value fw-seq

: fw-seq++  ( -- seq )  fw-seq 1+ dup to fw-seq  ;

d#     30 constant resp-wait-tiny
d#  1,000 constant resp-wait-short
d# 10,000 constant resp-wait-long
resp-wait-short instance value resp-wait

/inbuf instance buffer: respbuf
0 instance value /respbuf

\ =========================================================================
\ Transmit Packet Descriptor
\ =========================================================================

struct
   /fw-transport +
   4 field >tx-stat
   4 field >tx-ctrl
   4 field >tx-offset
   2 field >tx-len
   6 field >tx-mac
   1 field >tx-priority
   1 field >tx-pwr
   1 field >tx-delay		\ in 2ms
   1+
   0 field >tx-pkt-no-mesh
dup constant /tx-hdr-no-mesh
   1+  \ tx-mesh must be 0
   1+  \ tx-mesh must be 0
   1 field >tx-mesh-ttl
   1+                    \ Just for alignment
   0 field >tx-pkt
constant /tx-hdr

0 constant tx-ctrl		\ Tx rates, etc
: set-tx-ctrl  ( n -- )  to tx-ctrl  ;

\ The Libertas FW is currently abusing the WDS flag to mean "send on the mesh".
\ At some point a separate mesh flag might be defined ...
h# 20000 constant TX_WDS

: mesh-on?  ( -- flag )  tx-ctrl TX_WDS and 0<>  ;

: (wrap-msg-thin)  ( adr len dst-mac-adr -- adr' len' )
   outbuf  /tx-hdr  erase			( adr len dst-mac-adr )
         outbuf >tx-mac  /mac-adr  move		( adr len )
   dup   outbuf >tx-len  le-w!			( adr len )
   tuck  outbuf >tx-pkt-no-mesh  swap  move		( len )

   /tx-hdr-no-mesh 4 -  outbuf >tx-offset le-l!	( len )  \ Offset from >tx-ctrl field
   tx-ctrl        outbuf >tx-ctrl   le-l!	( len )

   outbuf  swap /tx-hdr-no-mesh +		( adr' len' )
;
: (wrap-msg)  ( adr len dst-mac-adr -- adr' len' )
   outbuf  /tx-hdr  erase			( adr len dst-mac-adr )
         outbuf >tx-mac  /mac-adr  move		( adr len )
   dup   outbuf >tx-len  le-w!			( adr len )
   tuck  outbuf >tx-pkt  swap  move		( len )

   /tx-hdr 4 - outbuf >tx-offset le-l!	( len )  \ Offset from >tx-ctrl field
   tx-ctrl        outbuf >tx-ctrl   le-l!	( len )

   mesh-on?  if  1 outbuf >tx-mesh-ttl c!  then	( len )

   outbuf  swap /tx-hdr +			( adr' len' )
;
: wrap-802.11  ( adr len -- adr' len' )  over 4 +  (wrap-msg-thin)  ;
: wrap-msg  ( adr len -- adr' len' )  over (wrap-msg)  ;

\ =========================================================================
\ Receive Packet Descriptor
\ =========================================================================

true instance value got-data?
0 instance value /data
0 instance value data

\ Receive packet descriptor
struct
   /fw-transport +
   2 field >rx-stat
   1 field >rx-snr
   1 field >rx-ctrl
   2 field >rx-len
   1 field >rx-nf
   1 field >rx-rate
   4 field >rx-offset
   1 field >rx-type
   3 +
   1 field >rx-priority
   3 +
\ dup constant /rx-desc
\   6 field >rx-dst-mac
\   6 field >rx-src-mac
\   0 field >rx-data-no-snap
\   2 field >rx-pkt-len		\ pkt len from >rx-snap-hdr
\   6 field >rx-snap-hdr
\   0 field >rx-data
d# 22 +  \ Size of an Ethernet header with SNAP
constant /rx-min

\ >rx-stat constants
1 constant rx-stat-ok
2 constant rx-stat-multicast

: snap-header  " "(aa aa 03 00 00 00)"  ;

: rx-rate$  ( -- adr len )  "   1  25.5 11  ?  6  9 12 18 24 36 48 54  ?  ?  ?"  ;
: .rx-rate  ( rate -- )  h# f and 3 * rx-rate$ drop + 3 type  ;

: .rx-desc  ( adr -- )
   debug? 0=  if  drop exit  then
   ?cr
   ." Rx status:       " dup >rx-stat    le-w@ u. cr
   ." Rx offset:       " dup >rx-offset  le-l@ u. cr
   ." Rx len:          " dup >rx-len     le-w@ u. cr
   ." Rx SNR:          " dup >rx-snr        c@ .d ." dB" cr
   ." Rx noise floor: -" dup >rx-nf         c@ .d ." dBm" cr
   ." Rx rate:         " dup >rx-rate       c@ .rx-rate ."  Mbps" cr
   ." Rx priority:     " dup >rx-priority   c@ u. cr
   drop
;

: unwrap-pkt  ( adr len -- data-adr data-len )
   /rx-min <  if  drop 0 0  then	\ Invalid packet: too small

   \ Go to the payload, skipping the descriptor header
   dup  dup >rx-offset le-l@ + la1+	( adr data-adr )
   swap >rx-len le-w@			( data-adr data-len )

   \ Remove snap header by moving the MAC addresses up
   \ That's faster than moving the contents down
   over d# 14 + snap-header comp 0=  if	( data-adr data-len )
      over  dup 8 +  d# 12  move	( data-adr data-len )
      8 /string				( adr' len' )
   then
;

: process-data  ( adr len -- )
   2dup vdump				( adr len )
   over .rx-desc			( adr len )

   over >rx-stat le-w@ rx-stat-ok <>  if  2drop exit  then

   unwrap-pkt  to /data  to data	( )

   true to got-data?	\ do-process-eapol may unset this

   \ Check the Ethernet type field for EAPOL messages
   data d# 12 + be-w@ h# 888e =  if	\ Pass EAPOL messages to supplicant
      data /data ?process-eapol
   then
;

: do-process-eapol  ( adr len -- )  false to got-data?  supplicant-process-eapol  ;

\ =========================================================================
\ Generic commands & responses
\ =========================================================================

0 value x			\ Temporary variables to assist command creation
0 value /x

: set-fw-data-x  ( -- )  outbuf >fw-data to x  /fw-cmd-hdr to /x  ;
: 'x   ( -- adr )  x /x +  ;
: +x   ( n -- )  /x + to /x  ;
: +x$  ( $ -- )  'x swap dup +x move  ;
: +xl  ( n -- )  'x le-l!  /l +x  ;
: +xw  ( n -- )  'x le-w!  /w +x  ;
: +xb  ( n -- )  'x c!     /c +x  ;
: +xbl ( n -- )  'x be-l!  /l +x  ;
: +xerase  ( n -- )  'x over erase  +x  ;

: .cmd  ( cmd -- )
   debug? 0=  if  drop exit  then
   ?cr
   case
      0003  of  ." CMD_GET_HW_SPEC"			endof
      0005  of  ." CMD_802_11_RESET"			endof
      0006  of  ." CMD_802_11_SCAN"			endof
      000b  of  ." CMD_802_11_GET_LOG"			endof
      0010  of  ." CMD_MAC_MULTICAST_ADR"		endof
      0011  of  ." CMD_802_11_AUTHENTICATE"		endof
      0013  of  ." CMD_802_11_SET_WEP"			endof
      0016  of  ." CMD_802_11_SNMP_MIB"			endof
      0019  of  ." CMD_MAC_REG_ACCESS"			endof
      001a  of  ." CMD_BBP_REG_ACCESS"			endof
      001b  of  ." CMD_RF_REG_ACCESS"			endof
      001c  of  ." CMD_802_11_RADIO_CONTROL"		endof
      001d  of  ." CMD_802_11_RF_CHANNEL"		endof
      001e  of  ." CMD_802_11_TX_POWER"			endof
      001f  of  ." CMD_802_11_RSSI"			endof
      0020  of  ." CMD_802_11_RF_ANTENNA"		endof
      0021  of  ." CMD_802_11_PS_MODE"			endof
      0022  of  ." CMD_802_11_DATA_RATE"		endof
      0024  of  ." CMD_802_11_DEAUTHENTICATE"		endof
      0026  of  ." CMD_802_11_DISASSOCIATE"             endof
      0028  of  ." CMD_MAC_CONTROL"			endof
      002b  of  ." CMD_802_11_AD_HOC_START"		endof
      002c  of  ." CMD_802_11_AD_HOC_JOIN"		endof
      002f  of  ." CMD_802_11_ENABLE_RSN"		endof
      003e  of  ." CMD_802_11_DEEP_SLEEP"		endof
      0040  of  ." CMD_802_11_AD_HOC_STOP"		endof
      0043  of  ." CMD_802_11_HOST_SLEEP_CFG"		endof
      0044  of  ." CMD_802_11_WAKEUP_CONFIRM"		endof
      004c  of  ." CMD_802_11_RGN_CODE"			endof
      004d  of  ." CMD_802_11_MAC_ADDR"			endof
      0050  of  ." CMD_802_11_ASSOCIATE"		endof
      0058  of  ." CMD_802_11_BAND_CONFIG"		endof
      0059  of  ." CMD_EEPROM_ACCESS"			endof
      005a  of  ." CMD_GSPI_BUS_CONFIG"			endof
      005b  of  ." CMD_802_11D_DOMAIN_INFO"		endof
      005c  of  ." CMD_WMM_ACK_POLICY"			endof
      005e  of  ." CMD_802_11_KEY_MATERIAL"		endof
      005f  of  ." CMD_802_11H_TPC_INFO"		endof
      0060  of  ." CMD_802_11H_TPC_ADAPT_REQ"		endof
      0061  of  ." CMD_802_11H_CHAN_SW_ANN"		endof
      0062  of  ." CMD_802_11H_MEASUREMENT_REQUEST"	endof
      0063  of  ." CMD_802_11H_GET_MEASUREMENT_REPORT"	endof
      0066  of  ." CMD_802_11_SLEEP_PARAMS"		endof
      0068  of  ." CMD_802_11_SLEEP_PERIOD"		endof
      0069  of  ." CMD_802_11_BCA_CONFIG_TIMESHARE"	endof
      006b  of  ." CMD_802_11_BG_SCAN_CONFIG"		endof
      006c  of  ." CMD_802_11_BG_SCAN_QUERY"		endof
      006d  of  ." CMD_802_11_CAL_DATA_EXT"		endof
      0071  of  ." CMD_WMM_GET_STATUS"			endof
      0072  of  ." CMD_802_11_TPC_CFG"			endof
      0073  of  ." CMD_802_11_PA_CFG"			endof
      0074  of  ." CMD_802_11_FW_WAKE_METHOD"		endof
      0075  of  ." CMD_802_11_SUBSCRIBE_EVENT"		endof
      0076  of  ." CMD_802_11_RATE_ADAPT_RATESET"	endof
      007f  of  ." CMD_TX_RATE_QUERY"			endof
      00a5  of  ." CMD_SET_BOOT2_VER"			endof  \ Thin firmware only
      00b0  of  ." CMD_802_11_BEACON_CTRL"		endof  \ Thin firmware only
      00cb  of  ." CMD_802_11_BEACON_SET"		endof  \ Thin firmware only
      00cc  of  ." CMD_802_11_SET_MODE"			endof  \ Thin firmware only
      ( default )  ." Unknown command: " dup u.
   endcase
   cr   
;

\ Use prepare-cmd when the length is well known in advance
\ or longer than the outgoing argument fields
: prepare-cmd  ( len cmd -- )
   dup .cmd                              ( len cmd )
   resp-wait-short to resp-wait          ( len cmd )
   outbuf /outbuf erase                  ( len cmd )
   outbuf /fw-transport + to x  0 to /x  ( len cmd )
   ( len cmd )      +xw    \ fw-cmd      ( len )
   /fw-cmd-hdr +    +xw	   \ fw-len 	 ( )  
   fw-seq++         +xw    \ fw-seq      ( )
   0                +xw    \ fw-result   ( )
;

\ Use start-cmd when determining the length in advance is tricky
: start-cmd  ( cmd -- )  0 swap prepare-cmd  ;    \ Will set actual len later
: finish-cmd  ( -- )  /x outbuf >fw-len le-w!  ;  \ Set len field

true value got-response?
true value got-indicator?

: process-disconnect  ( -- )  ds-disconnected set-driver-state  ;
: process-wakeup  ( -- )  ;
: process-sleep  ( -- )  ;
: process-pmic-failure  ( -- )  ;
: process-gmic-failure  ( -- )  ;

: .event  ?cr  ." Event: "  type  cr ;
0 instance value last-event
0 instance value backlog
0 value debug-tx-feedback?
: process-ind  ( adr len -- )
   drop
   true to got-indicator?
   4 + le-l@  dup to last-event
   dup h# 10000 u>=  if              ( event-code )
      \ TX feedback from thin firmware
      backlog 1- 0 max  to backlog   ( event-code )
      debug-tx-feedback?  if
         \ Cozybit asked for this test to help debug the thin firmware
         lbsplit  2swap 2drop           ( retrycnt failure )
         ?dup  if                       ( retrycnt failure )
            cr ." Failure code 0x" base @ hex  swap .  base ! cr
         then                           ( retrycnt )
         dup d# 10 <>  if               ( retrycnt )
            cr ." Retry count (decimal) " base @ decimal  over .  base !  cr
         then                           ( retrycnt )
      then
      drop
      exit
   then
   case
      h# 37  of   endof  \ Beacon sent - Handle this silently
      h# 00  of  " Tx PPA Free" .event  endof  \ n
      h# 01  of  " Tx DMA Done" .event  endof  \ n
      h# 02  of  " Link Loss with scan" .event  process-disconnect  endof
      h# 03  of  " Link Loss no scan" .event  process-disconnect  endof
      h# 04  of  " Link Sensed" .event  endof
      h# 05  of  " CMD Finished" .event  endof
      h# 06  of  " MIB Changed" .event  endof
      h# 07  of  " Init Done" .event  endof
      h# 08  of  " Deauthenticated" .event  process-disconnect  endof
      h# 09  of  " Disassociated" .event  process-disconnect  endof
      h# 0a  of  " Awake" .event  process-wakeup  endof
      h# 0b  of  " Sleep" .event  process-wakeup  endof
      h# 0d  of  " Multicast MIC error" .event  process-gmic-failure  endof
      h# 0e  of  " Unicast MIC error" .event  process-pmic-failure  endof
      h# 0e  of  " WM awake" .event  endof \ n
      h# 11  of  " HWAC - adhoc BCN lost" .event  endof
      h# 19  of  " RSSI low" .event  endof
      h# 1a  of  " SNR low" .event  endof
      h# 1b  of  " Max fail" .event  endof
      h# 1c  of  " RSSI high" .event  endof
      h# 1d  of  " SNR high" .event  endof
      h# 23  of  endof  \ Suppress this; the user doesn't need to see it
      \ h# 23  of  ." Mesh auto-started"  endof
      h# 30  of   endof  \ Handle this silently
\      h# 30  of  " Firmware ready" .event  endof
      ( default )  ." Unknown " dup u.
   endcase
;

: process-request  ( adr len -- )
   2dup vdump			( adr len )
   to /respbuf			( adr )
   respbuf  /respbuf  move	( )
   true to got-response?	( )
;

: process-rx  ( adr len -- )
   over packet-type  case
      \ Encoding must agree with packet-type
      0  of  process-request  endof	\ Response & request
      1  of  process-data     endof	\ Data
      2  of  process-ind      endof	\ Indication
      ( default )  >r vdump r>
   endcase
;

: check-for-rx  ( -- )
   got-packet?  if		( error | buf len 0 )
      0= if  process-rx	 then	( )
      recycle-packet		( )
   then				( )
;

\ -1 error, 0 okay, 1 retry
: wait-cmd-resp  ( -- -1|0|1 )
   false to got-response?
   resp-wait 0  do
      check-for-rx
      got-response?  if  leave  then
      1 ms
   loop
   got-response?  if
      respbuf >fw-result le-w@  case
         0 of  0  endof  \ No error
         4 of  1  endof  \ Busy, so retry
         ( default )  ." Result = " dup u. cr  dup
      endcase
   else
\      ." Timeout or error" cr
      true
   then
;
: wait-event  ( -- true | event false )
   false to got-indicator?
   d# 1000 0  do
      check-for-rx
      got-indicator?  if  last-event false unloop exit  then
      1 ms
   loop
   true
;
: outbuf-wait  ( -- error? )
   outbuf-out  ?dup  if  exit  then
   wait-cmd-resp
;


\ =========================================================================
\ Dumps
\ =========================================================================

: .fw-cap  ( cap -- )
   ."  802.11"
   dup h# 400 and  if  ." a"  then
   dup h# 100 and  if  ." b"  then
   dup h# 200 and  if  ." g"  then  ." ;"
   dup h#   1 and  if  ."  WPA;" then
   dup h#   2 and  if  ."  PS;" then
   dup h#   8 and  if  ."  EEPROM does not exit;"  then
   dup h#  30 and  case
                      h# 00  of  ."  TX antanna 0;"  endof
                      h# 10  of  ."  TX antenna 1;"  endof
                      ( default )  ."  TX diversity; "
                   endcase
       h#  c0 and  case
                      h# 00  of  ."  RX antenna 0;"  endof
                      h# 40  of  ."  RX antenna 1;"  endof
                      ( default )  ."  RX diversity;"
                   endcase
;

: .log  ( adr -- )
   dup >fw-len le-w@ /fw-cmd-hdr =  if  drop exit  then
   ." Multicast txed:       " dup >fw-data le-l@ u. cr
   ." Failed:               " dup >fw-data 4 + le-l@ u. cr
   ." Retry:                " dup >fw-data 8 + le-l@ u. cr
   ." Multiple retry:       " dup >fw-data h# c + le-l@ u. cr
   ." Duplicate frame rxed: " dup >fw-data h# 10 + le-l@ u. cr
   ." Successful RTS:       " dup >fw-data h# 14 + le-l@ u. cr
   ." Failed RTS:           " dup >fw-data h# 18 + le-l@ u. cr
   ." Failed ACK:           " dup >fw-data h# 1c + le-l@ u. cr
   ." Fragment rxed:        " dup >fw-data h# 20 + le-l@ u. cr
   ." Multicast rxed:       " dup >fw-data h# 24 + le-l@ u. cr
   ." FCS error:            " dup >fw-data h# 28 + le-l@ u. cr
   ." Frame txed:           " dup >fw-data h# 2c + le-l@ u. cr
   ." WEP undecryptable:    " dup >fw-data h# 30 + le-l@ u. cr
   drop
;


\ =========================================================================
\ Reset
\ =========================================================================

: reset-wlan  ( -- )
   " wlan-reset" evaluate
   ds-not-ready to driver-state
   reset-host-bus
;

: marvel-get-hw-spec  ( -- true | adr false )
   d# 38 h# 03 ( CMD_GET_HW_SPEC ) prepare-cmd
   outbuf-out  ?dup  if  true exit  then
   resp-wait-tiny to resp-wait
   wait-cmd-resp  if  true exit  then

   respbuf >fw-data  false
;

\ The purpose of this is to work around a problem that I don't fully understand.
\ For some reason, when you reopen the device without re-downloading the
\ firmware, the first command silently fails - you don't get a response.
\ This is a "throwaway" command to handle that case without a long timeout
\ or a warning message.

: nonce-cmd  ( -- )  marvel-get-hw-spec  0=  if  drop  then  ;

\ =========================================================================
\ MAC address
\ =========================================================================

\ This command has an annoying tendency to fail to sometimes - wait-cmd-resp
\ times out.  Retrying usually fixes it.
: (marvel-get-mac-address)  ( -- error? )
   8 h# 4d ( CMD_802_11_MAC_ADDRESS ) prepare-cmd
   ACTION_GET +xw
   outbuf-wait  if  true exit  then
   respbuf >fw-data 2 + mac-adr$ move
   false
;
: marvel-get-mac-address  ( -- error? )
   4 0 do
      (marvel-get-mac-address) 0=  if  false unloop exit  then
   loop  
   ." marvel-get-mac-address failed" cr
   true
;

: marvel-set-mac-address  ( -- )
   8 h# 4d ( CMD_802_11_MAC_ADDRESS ) prepare-cmd
   ACTION_SET +xw
   mac-adr$ +x$
   outbuf-wait drop
;

: marvel-get-mc-address  ( -- )
   4 /mc-adrs + h# 10 ( CMD_MAC_MULTICAST_ADR ) prepare-cmd
   ACTION_GET +xw
   outbuf-wait  if  exit  then
   respbuf >fw-data 2 + le-w@ to #mc-adr
   respbuf >fw-data 4 + mc-adrs #mc-adr /mac-adr * move
;

: marvel-set-mc-address  ( adr len -- )
   4 /mc-adrs + h# 10 ( CMD_MAC_MULTICAST_ADR ) prepare-cmd
   ACTION_SET +xw
   dup /mac-adr / dup +xw			\ Number of multicast addresses
   to #mc-adr
   ( adr len ) 2dup +x$				\ Multicast addresses
   mc-adrs swap move
   outbuf-wait drop
;

\ =========================================================================
\ Register access
\ =========================================================================

: reg-access@  ( reg cmd -- n )
   8 swap prepare-cmd
   ACTION_GET +xw
   ( reg ) +xw
   outbuf-wait  if  0 exit  then
   respbuf >fw-data 4 + le-l@
;

: bbp-reg@  ( reg -- n )
   1a ( CMD_BBP_REG_ACCESS ) reg-access@  h# ff and
;
: rf-reg@  ( reg -- n )
   1b ( CMD_RF_REG_ACCESS ) reg-access@  h# ff and
;
: mac-reg@  ( reg -- n )
   19 ( CMD_MAC_REG_ACCESS ) reg-access@
;
: eeprom-l@  ( idx -- n )
   a 59 ( CMD_EEPROM_ACCESS ) prepare-cmd
   ACTION_GET +xw
   ( idx ) +xw
   4 +xw
   outbuf-wait  if  0 exit  then
   respbuf >fw-data 6 + le-l@
;

\ =========================================================================
\ Miscellaneous control settings
\ =========================================================================

: set-boot2-version  ( version -- )  \ Thin firmware only
   4 h# a5 ( CMD_SET_BOOT2_VER ) prepare-cmd
   0 +xw       ( version )
   +xw         ( )
   outbuf-wait drop
;
: set-boot2-from-usb  ( -- )  \ Thin firmware only
   " release" get-my-property 0=  if
      decode-int nip nip  set-boot2-version
   then
;
: set-mode  ( mode -- )  \ Thin firmware only - 0 is passive, 1 is sta, 2 is ap
   2 h# cc ( CMD_SET_MODE ) prepare-cmd
   +xw
   outbuf-wait drop
;
0 value ap-mode?
: set-fullmac-mode  ( -- )  3 set-mode  false to ap-mode?  ;  \ Thin firmware only
: set-ap-mode  ( -- )  2 set-mode  true to ap-mode?  ;  \ Thin firmware only
: set-sta-mode  ( -- )  1 set-mode  false to ap-mode?  ;  \ Thin firmware only
: set-passive-mode  ( -- )  0 set-mode  false to ap-mode?  ;  \ Thin firmware only

: broadcast-mac$  ( -- adr len )  " "(ff ff ff ff ff ff)"  ;

: make-beacon  ( -- )
   h# cb ( CMD_802_11_BEACON_SET ) start-cmd  ( )
   ssid$ nip d# 66 +  +xw  \ Length of the following, including SSID len

   h# 0080        +xw  \ Frame type/subtype - management, beacon
   0              +xw  \ duration
   broadcast-mac$ +x$  \ destination MAC
   mac-adr$       +x$  \ source MAC
   mac-adr$       +x$  \ BSS MAC
   0              +xw  \ Sequence number
   0 +xl        0 +xl  \ 8-byte timestamp
   d# 100         +xw  \ Beacon interval
   cap            +xw  \ Capability mask

   0              +xb  \ element ID = SSID
   ssid$ dup      +xb  \ length  ( adr len )
   ( adr len )    +x$  \ SSID

   1              +xb  \ element ID = Supported rates
   8              +xb  \ length
   2     +xb  4     +xb  d# 11 +xb  d# 22 +xb  \ 1 2 5.5 11 Mb/sec
   d# 12 +xb  d# 18 +xb  d# 24 +xb  d# 36 +xb  \ 6 9 12 18 Mb/sec
   
   3              +xb  \ element ID = DS parameter set
   1              +xb  \ length
   channel        +xb  \ Channel number

   5              +xb  \ element ID = TIM (Traffic Indicator Map) parameter set
   4              +xb  \ length
   1              +xb  \ DTIM Count
   2              +xb  \ DTIM Period
   0              +xb  \ Bitmap control
   0              +xb  \ Bitmap

   d# 42          +xb  \ element ID = ERP info
   1              +xb  \ length
   0              +xb  \ no non-ERP stations, do not use protection, short or long preambles

   d# 50          +xb  \ element ID = Extended supported rates
   4              +xb  \ length
   d# 48 +xb  d# 72 +xb  d# 96 +xb  d# 108 +xb  \ 24 36 48 54 Mb/sec
   finish-cmd

   outbuf-wait drop
;

: (set-radio-control)  ( arg -- )
   4 h# 1c ( CMD_802_11_RADIO_CONTROL ) prepare-cmd
   ACTION_SET +xw
   ( arg ) +xw
   outbuf-wait drop
;   

\ Preamble, RF on
: set-radio-control ( -- )  preamble 1 or (set-radio-control)  ;
: radio-off  ( -- )  0 (set-radio-control)  ;

: (set-bss-type)  ( bsstype -- ok? )
   6 d# 128 + h# 16 ( CMD_802_11_SNMP_MIB ) prepare-cmd
   ACTION_SET +xw
   0 +xw		\ Object = desiredBSSType
   1 +xw		\ Size of object
   ( bssType ) +xb	
   outbuf-wait 0=
;

external
: set-bss-type  ( bssType -- ok? )  dup to bss-type (set-bss-type)  ;
headers

: (set-mac-control)  ( -- error? )
   4 h# 28 ( CMD_MAC_CONTROL ) prepare-cmd
   mac-ctrl +xw		\ WEP type, WMM, protection, multicast, promiscous, WEP, tx, rx
   outbuf-wait
;

: set-mac-control  ( -- )
   (set-mac-control)  if
     (set-mac-control) drop
   then
;

: set-domain-info  ( adr len -- )
   dup 6 + h# 5b ( CMD_802_11D_DOMAIN_INFO ) prepare-cmd
   ACTION_SET +xw
   7 +xw				\ Type = MrvlIETypes_DomainParam_t
   ( len ) dup +xw			\ Length of payload
   ( adr len ) +x$			\ Country IE
   outbuf-wait drop
;

: enable-11d  ( -- )
   6 d# 128 + h# 16 ( CMD_802_11_SNMP_MIB ) prepare-cmd
   ACTION_SET +xw
   9 +xw		\ Object = enable 11D
   2 +xw		\ Size of object
   1 +xw		\ Enable 11D
   outbuf-wait drop
;

external
: enforce-protection  ( -- )
   mac-ctrl h# 400 or to mac-ctrl	\ Enforce protection
   set-mac-control
;

: disable-protection  ( -- )
   mac-ctrl h# 400 invert and  to mac-ctrl
   set-mac-control
;

: set-key-type  ( ctp ctg ktype -- )  to ktype  to ctype-g  to ctype-p  ;

: set-country-info  ( adr len -- )	\ IEEE country IE
   set-domain-info
   enable-11d
;

: enable-promiscuous  ( -- )
   mac-ctrl h# 80 or to mac-ctrl
   set-mac-control
;
: disable-promiscuous  ( -- )
   mac-ctrl h# 80 invert and to mac-ctrl
   set-mac-control
;

: enable-multicast  ( -- )
   mac-ctrl h# 20 or to mac-ctrl
   set-mac-control
;
: disable-multicast  ( -- )
   mac-ctrl h# 20 invert and  to mac-ctrl
   set-mac-control
;
: set-multicast  ( adr len -- )  enable-multicast  marvel-set-mc-address  ;

: mac-off  ( -- )
   0 to mac-ctrl  set-mac-control  3 to mac-ctrl
;
headers

\ =========================================================================
\ Scan
\ =========================================================================

1 constant #probes

d# 14 constant #channels

[ifdef] notdef
struct
   2 field >type-id
   2 field >/payload
dup constant /marvel-IE-hdr
   2 field >probes
constant /probes-IE

struct
   1 field >radio-type
   1 field >channel#
   1 field >scan-type
   2 field >min-scan-time
   2 field >max-scan-time
constant /chan-list

struct
   /marvel-IE-hdr +
   #channels /chan-list * field >chan-list
constant /chan-list-IE

struct
   /marvel-IE-hdr +
   d# 34 field >ssid
constant /ssid-IE

struct
   1 field >bss-type
   6 field >bss-id
   /chan-list-IE field >chan-list-IE
   /probes-IE    field >probes-IE
constant /cmd_802_11_scan
[then]

1 constant BSS_INDEPENDENT
2 constant BSS_INFRASTRUCTURE
3 constant BSS_ANY

\ OUI values (big-endian)
h# 0050.f201 constant wpa-tag			\ WPA tag
h# 0050.f202 constant moui-tkip			\ WPA cipher suite TKIP
h# 0050.f204 constant moui-aes			\ WPA cipher suite AES
h# 000f.ac02 constant oui-tkip			\ WPA2 cipher suite TKIP
h# 000f.ac04 constant oui-aes			\ WPA2 cipher suite AES
h# 000f.ac02 constant aoui			\ WPA2 authentication suite
h# 0050.f202 constant amoui			\ WPA authentication suite


d# 34 instance buffer: scan-ssid

0 instance value scan-type
: active-scan  ( -- )  0 to scan-type  ;
: passive-scan  ( -- )  1 to scan-type  ;

[ifdef] notdef
: make-chan-list-param  ( adr -- )
   #channels 0  do
      dup i /chan-list * +
      0 over >radio-type c!
      i 1+ over >channel# c!
      scan-type over >scan-type c!
      d# 100 over >min-scan-time le-w!
      d# 100 swap >max-scan-time le-w!
   loop  drop
;

: (oldscan)  ( -- error? | adr len 0 )
   /cmd_802_11_scan  scan-ssid c@  if
      /marvel-IE-hdr +  scan-ssid c@ +
   then
   6 ( CMD_802_11_SCAN ) prepare-cmd              ( )
   resp-wait-long to resp-wait                    ( )
   BSS_ANY outbuf >fw-data tuck >bss-type c!      ( 'fw-data )

   dup >chan-list-IE                              ( 'fw-data 'chan-list )
   h# 101 over >type-id le-w!                     ( 'fw-data 'chan-list )
   #channels /chan-list * over >/payload le-w!    ( 'fw-data 'chan-list )
   >chan-list make-chan-list-param                ( 'fw-data )

   dup >probes-IE                                 ( 'fw-data 'probes )
   h# 102 over >type-id le-w!                     ( 'fw-data 'probes )
   2 over >/payload le-w!                         ( 'fw-data 'probes )
   #probes swap >probes le-w!                     ( 'fw-data )

   scan-ssid c@  if                               ( 'fw-data )
      \ Attach an SSID TLV to filter the result
      /cmd_802_11_scan +                               ( 'ssid )
      h# 000 over >type-id le-w!                       ( 'ssid )
      scan-ssid c@   over >/payload le-w!              ( 'ssid )
      scan-ssid count  rot /marvel-IE-hdr +  swap move      ( )
   else                                           ( 'fw-data )
      drop
   then                                           ( )

   outbuf-wait					  ( error? )
   dup  0=  if 				          ( error? )
      respbuf /respbuf /fw-cmd /string  rot       ( adr len 0 )
   then
;
[then]

h# 7ffe instance value channel-mask

: +chan-list-tlv  ( -- )
   h# 101 +xw
   0 +xw  'x >r       ( r: 'payload )
   #channels 1+  1  do
      1 i lshift  channel-mask  and  if
         0 +xb            \ Radio type
         i +xb            \ Channel #
         scan-type +xb    \ Scan type - 0:active  or  1:passive
         d# 100 +xw       \ Min scan time
         d# 100 +xw       \ Max scan time
      then
   loop
   'x r@ -  r> 2- le-w!
;

: +probes-tlv  ( -- )
   h# 102 +xw        \ Probes TLV
   2 +xw             \ length
   #probes +xw       \ #probes
;

: +ssid-tlv  ( -- )
   scan-ssid c@  if
      0 +xw        \ SSID TLV
      scan-ssid c@ +xw  \ length
      scan-ssid count +x$
   then
;

: (scan)  ( -- error? | adr len 0 )
   6 ( CMD_802_11_SCAN ) start-cmd
   resp-wait-long to resp-wait

   BSS_ANY +xb
   6 +xerase           \ BSS ID

   +chan-list-tlv
   +probes-tlv
   +ssid-tlv

   finish-cmd outbuf-wait  dup  0=  if 	       ( error? )
      respbuf /respbuf /fw-cmd /string  rot    ( adr len 0 )
   then
;


external
: set-channel-mask  ( n -- )
   h# 7ffe and   to channel-mask
;

\ Ask the device to look for the indicated SSID.
: set-ssid  ( adr len -- )
   \ This is an optimization for NAND update over the mesh.
   \ It prevents listening stations, of which there can be many,
   \ from transmitting when they come on-line.
   2dup  " olpc-mesh"  $=  if  passive-scan  then
   2dup  " olpc-NANDblaster"  $=  if  passive-scan  then

   h# 32 min  scan-ssid pack drop
;

: scan  ( adr len -- actual )
\   (scan)
   begin  (scan)  dup 1 =  while  drop d# 1000 ms  repeat  \ Retry while busy
   if  2drop 0 exit  then               ( adr len scan-adr scan-len )
   rot min >r                           ( adr scan-adr r: len )
   swap r@ move			        ( r: len )
   r>
;
headers

\ =========================================================================
\ WEP
\ =========================================================================

: set-wep-type  ( len -- )
   ?dup  if
      5 =  if  TYPE_WEP_40_BIT 8  else  TYPE_WEP_104_BIT h# 8008  then
      mac-ctrl or to mac-ctrl	\ WEPxx on
   else
      0
   then
   +xb
;

external
: (set-wep)  ( wep4$ wep3$ wep2$ wep1$ idx -- ok? )
   d# 72 h# 13 ( CMD_802_11_SET_WEP ) prepare-cmd
   ACTION_ADD +xw
   ( idx ) +xw				\ TxKeyIndex
   dup set-wep-type
   2 pick set-wep-type
   4 pick set-wep-type
   6 pick set-wep-type
   4 0  do
      ?dup  if  x /x + swap move  else  drop  then
      d# 16 /x + to /x
   loop
   outbuf-wait 0=
;
: set-wep  ( wep4$ wep3$ wep2$ wep1$ idx -- ok? )
   to wep-idx
   dup to /wep1 wep1 swap move
   dup to /wep2 wep2 swap move
   dup to /wep3 wep3 swap move
   dup to /wep4 wep4 swap move
   true
;
: ?set-wep  ( -- )
   ktype kt-wep =  if
      wep4$ wep3$ wep2$ wep1$ wep-idx (set-wep) drop
   then
;

: disable-wep  ( -- ok? )
   mac-ctrl h# 8008 invert and to mac-ctrl	\ Disable WEP
   d# 72 h# 13 ( CMD_802_11_SET_WEP ) prepare-cmd
   ACTION_REMOVE +xw
   0 +xw				\ TxKeyIndex
   outbuf-wait 0=
;
headers

\ =========================================================================
\ WPA and WPA2
\ =========================================================================

: set-rsn  ( enable? -- ok? )
   4 h# 2f ( CMD_802_11_ENABLE_RSN ) prepare-cmd
   ACTION_SET +xw
   ( enable? ) +xw		\ 1: enable; 0: disable
   outbuf-wait 0=
;

external
: enable-rsn   ( -- ok? )  1 set-rsn  ;
: disable-rsn  ( -- ok? )  0 set-rsn  ;
headers

: set-key-material  ( key$ kinfo ct -- )
   h# 5e ( CMD_802_11_KEY_MATERIAL ) start-cmd
   ACTION_SET +xw
   h# 100     +xw			\ Key param IE type
   2 pick 6 + +xw			\ IE payload length
   ( ct )     +xw			\ Cipher type
   ( kinfo )  +xw			\ Key info
   dup        +xw			\ Key length
   ( key$ )   +x$			\ key$
   finish-cmd outbuf-wait drop
;

external
: set-gtk  ( gtk$ -- )  5 ctype-g  set-key-material  ;
: set-ptk  ( ptk$ -- )  6 ctype-p  set-key-material  ;
headers

\ =======================================================================
\ Adhoc join
\ =======================================================================

0 value adhoc-started?
0 value atim

: save-associate-params  ( ch ssid$ target-mac$ -- ch ssid$ target-mac )
   over target-mac$ move
   2over dup to /ssid
   ssid swap move
   4 pick to channel
;

: adhoc-start  ( ch ssid$ -- ok? )
   set-mac-control

   h# 2b ( CMD_802_11_AD_HOC_START ) start-cmd
   resp-wait-long to resp-wait

   ( ssid$ ) tuck +x$			\ SSID
   ( ssid-len ) d# 32 swap - +x		\ 32 bytes of SSID (zero-padded because buffer is pre-erased)
   2 +xb				\ BssType: BSS_INDEPENDENT
   d# 100 +xw				\ Beacon period
   0      +xb				\ DTIM period (only for versions < 9)

   \ IBSS param set
   6 +xb				\ Elem ID = IBSS param set
   2 +xb				\ Length
   atim +xw				\ ATIM window
   4 +x					\ Reserved bytes

   \ DS param set
   3 +xb				\ Elem ID = DS param set
   1 +xb				\ Length
   ( channel ) +xb			\ Channel
   4 +x					\ Reserved bytes

   0 +xw				\ Probe delay in uS (only for versions < 9)

   2 +xw				\ Capability info: IBSS (WEP/WPA would add h# 10)

   \ XXX 14 bytes for 802.11g, 8 bytes for 802.11b
   supported-rates$ +x$			\ Common supported data rates

   d# 100 +x				\ Padding as present in libertas Linux driver

   finish-cmd outbuf-wait  if  ." Failed to start adhoc network" cr false exit  then
   true to adhoc-started?
   \ We could get the bssid from offsets 3..8 of the response buf if we needed it
   true
   ds-associated set-driver-state
;
: adhoc-stop  ( -- )
   h# 40 ( CMD_802_11_AD_HOC_STOP ) start-cmd
   finish-cmd outbuf-wait  if  ." Failed to stop adhoc network" cr  then
   ds-associated reset-driver-state
;

: (join)  ( ch ssid$ target-mac$ -- ok? )
   save-associate-params
   h# 2c ( CMD_802_11_AD_HOC_JOIN ) start-cmd
   resp-wait-long to resp-wait

   ( target-mac$ ) +x$			\ Peer MAC address
   ( ssid$ ) tuck +x$			\ SSID
   ( ssid-len ) d# 32 swap - +x		\ 32 bytes of SSID (zero-padded because buffer is pre-erased)
   bss-type-adhoc +xb			\ BSS type
   d# 100 +xw				\ Beacon period
   1      +xb				\ DTIM period

   8 +x					\ 8 bytes of time stamp
   8 +x					\ 8 bytes of local time

   \ DS param set
   3 +xb				\ Elem ID = DS param set
   1 +xb				\ Length
   ( channel ) +xb			\ Channel
   4 +x					\ Reserved bytes

   \ IBSS param set
   6 +xb				\ Elem ID = IBSS param set
   2 +xb				\ Length
   atim +xw				\ ATIM window
   4 +x					\ Reserved bytes

\  cap    +xw				\ Capability info: ESS, short slot, WEP
   2 +xw				\ Capability info: IBSS (WEP/WPA would add h# 10)

   \ XXX 14 bytes for 802.11g, 8 bytes for 802.11b
   common-rates #rates +x$		\ Common supported data rates
   d# 255 +xw				\ Association timeout
   0 +xw				\ Probe delay time

   finish-cmd outbuf-wait  if  ." Failed to join adhoc network" cr false exit  then
   true
;

external
: set-atim-window  ( n -- )  d# 50 min  to atim  ;
headers

\ =========================================================================
\ Authenticate
\ =========================================================================

: authenticate  ( target-mac$ -- )
   dup 1+ h# 11 ( CMD_802_11_AUTHENTICATE ) prepare-cmd
   ( target-mac$ ) +x$		\ Peer MAC address
   auth-mode +xb		\ Authentication mode
   outbuf-wait drop
;

: deauthenticate  ( mac$ -- )
   dup 2+ h# 24 ( CMD_802_11_DEAUTHENTICATE ) prepare-cmd
   ( mac$ ) +x$			\ AP MAC address
   3 +xw			\ Reason code: station is leaving
   outbuf-wait  if  exit  then
   ds-disconnected set-driver-state
;

\ Mesh

: mesh-access!  ( value cmd -- )
   h# 82 h# 9b ( CMD_MESH_ACCESS ) prepare-cmd  ( value cmd )
   +xw  +xl                                     ( )

   outbuf-wait drop
;
: mesh-access@  ( cmd -- value )
   h# 82 h# 9b ( CMD_MESH_ACCESS ) prepare-cmd  ( value cmd )
   +xw                                          ( )

   outbuf-wait  if  -1 exit  then
   respbuf >fw-data wa1+ le-l@
;

: mesh-config-set  ( adr len type channel action -- error? )
   h# 88 h# a3 ( CMD_MESH_CONFIG ) prepare-cmd  ( adr len type channel action )
   +xw +xw +xw                                  ( adr len )
   dup +xw +x$                                  ( )

   outbuf-wait
;
: mesh-config-get  ( -- true | buf false )
   h# 88 h# a3 ( CMD_MESH_CONFIG ) prepare-cmd  ( )
   3 +xw 0 +xw 5 +xw                            ( )

   outbuf-wait  if  true exit  then
   respbuf >fw-data   false
;
: (mesh-start)  ( channel tlv -- error? )
   " "(dd 0e 00 50 43 04 00 00 00 00 00 04)mesh"  ( channel tlv adr len )
   2swap swap  1  ( adr len tlv channel action )  \ 1 is CMD_ACT_MESH_CONFIG_START
   mesh-config-set
;

: mesh-stop  ( -- error? )
   mesh-on?  if
      " "  0 0 0 mesh-config-set                ( error? )
      tx-ctrl  TX_WDS invert and  set-tx-ctrl   ( error? )
      ds-associated reset-driver-state          ( error? )
   else
      false                                     ( error? )
   then
;

: mesh-start  ( channel -- error? )
   \ h# 223 (0x100 + 291) is an old value
   \ h# 125 (0x100 + 37) is an "official" value that doesn't work
   dup h# 223 (mesh-start)  if        ( channel )
      \ Retry once
      h# 223 (mesh-start)             ( error? )
   else
      drop false                      ( error? )
   then
     
   dup 0=  if                         ( error? )
      tx-ctrl  TX_WDS or set-tx-ctrl  ( error? )
      ds-associated set-driver-state  ( error? )
   then                               ( error? )
;

instance variable mesh-param
: mesh-set-bootflag  ( bootflag -- error? )
   mesh-param le-l!  mesh-param 4  1 0 3 mesh-config-set
;
: mesh-set-boottime  ( boottime -- error? )
   mesh-param le-w!  mesh-param 2  2 0 3 mesh-config-set
;
: mesh-set-def-channel  ( boottime -- error? )
   mesh-param le-w!  mesh-param 2  3 0 3 mesh-config-set
;
: mesh-set-ie  ( adr len -- error? )  4 0 3 mesh-config-set  ;
: mesh-set-ttl  ( ttl -- )  2 mesh-access!  ;
: mesh-get-ttl  ( -- ttl )  1 mesh-access@  ;
: mesh-set-bcast  ( index -- )  8 mesh-access!  ;
: mesh-get-bcast  ( -- index )  9 mesh-access@  ;

[ifdef] notdef
: mesh-set-anycast  ( mask -- )  5 mesh-access!  ;
: mesh-get-anycast  ( -- mask )  4 mesh-access@  ;

: mesh-set-rreq-delay  ( n -- )  d# 10 mesh-access!  ;
: mesh-get-rreq-delay  ( -- n )  d# 11 mesh-access@  ;

: mesh-set-route-exp  ( n -- )  d# 12 mesh-access!  ;
: mesh-get-route-exp  ( -- n )  d# 13 mesh-access@  ;

: mesh-set-autostart  ( n -- )  d# 14 mesh-access!  ;
: mesh-get-autostart  ( -- n )  d# 15 mesh-access@  ;

: mesh-set-prb-rsp-retry-limit  ( n -- )  d# 17 mesh-access!  ;
[then]

\ =========================================================================
\ Associate/disassociate
\ =========================================================================

0 value assoc-id

\ The source IE is in the Marvel format: id and len are 2 bytes long.
\ The destination IE is in the 802.11 format: id and len are 1 byte long.
: save-wpa-ie  ( boffset eoffset -- )
   over - 2 - to /wpa-ie			\ Less extra bytes
   x + dup c@ wpa-ie c!				\ Copy IE id
   2 + dup c@ wpa-ie 1+ c!			\ Copy len
   2 + wpa-ie /wpa-ie 2 /string move		\ Copy body of IE
;

: moui  ( ct -- )  ct-tkip =  if  moui-tkip  else  moui-aes  then  ;
: oui   ( ct -- )  ct-tkip =  if  oui-tkip   else  oui-aes   then  ;

: (associate)  ( ch ssid$ target-mac$ -- ok? )
   save-associate-params

   set-radio-control			\ In case of changes to preamble

   h# 50 ( CMD_802_11_ASSOCIATE ) start-cmd
   resp-wait-long to resp-wait

   ( target-mac$ ) +x$			\ Peer MAC address
   cap    +xw				\ Capability info: ESS, short slot, WEP
   d# 300 +xw				\ Listen interval
   d# 100 +xw				\ Beacon period
   1      +xb				\ DTIM period

   \ SSID
   0   +xw				\ element ID = SSID 
   dup +xw				\ len
   ( ssid$ ) +x$			\ SSID

   \ DS param
   3      +xw				\ element ID = DS param set
   1      +xw				\ len
   ( ch ) +xb				\ channel

   \ CF param
   4 +xw				\ element ID = CF param set
   0 +xw				\ len

   \ Common supported rates
   1      +xw				\ element ID = rates
   #rates +xw				\ len
   common-rates #rates +x$		\ common supported data rates

   \ RSN (WPA2)
   ktype kt-wpa2 =  if
      /x 				\ Save beginning offset
      d# 48  +xw			\ element ID = RSN
      d# 20  +xw			\ len
      1      +xw			\ version
      ctype-g oui +xbl			\ group cipher suite
      1      +xw			\ count of pairwise cipher suite
      ctype-p oui +xbl			\ pairwise cipher suite
      1      +xw			\ count of authentication suite
      aoui   +xbl			\ authentication suite
      h# 28  +xw			\ RSN capabilities
      /x save-wpa-ie			\ Save IE in wpa-ie
   then

   \ WPA param
   ktype kt-wpa =  if
      /x				\ Save beginning offset
      d# 221  +xw			\ element ID = WPA
      d# 24   +xw			\ len
      wpa-tag +xbl			\ WPA-specific tag
      1 +xw				\ version
      ctype-g moui +xbl			\ group cipher suite
      1       +xw			\ count of pairwise cipher suite
      ctype-p moui +xbl			\ pairwise cipher suite
      1       +xw			\ count of authentication suite
      amoui   +xbl			\ authentication suite
      ctype-p ct-tkip =  if  h# 2a  else  h# 28  then
      ( cap ) +xw			\ WPA capabilities
      /x save-wpa-ie			\ Save IE in wpa-ie
   then

   \ XXX power (optional)
   \ XXX supported channels set (802.11h only)
   \ XXX pass thru IEs (optional)

   finish-cmd outbuf-wait  if  false exit  then

   respbuf >fw-data 2 + le-w@ ?dup  if \ This is the IEEE Status Code
      ." Failed to associate: " u. cr
      false
   else
      respbuf >fw-data 4 + le-w@ to assoc-id
      ds-disconnected ds-connected-mask or reset-driver-state
      true
   then
;

external
instance defer mesh-default-modes
' noop to mesh-default-modes
: nandcast-mesh-modes  ( -- )
   1 mesh-set-ttl
   d# 12 mesh-set-bcast
;
' nandcast-mesh-modes to mesh-default-modes

\ The supplicant package invokes this via call-parent after setting up
\ various parameters via methods like set-atim .
: associate  ( ch ssid$ target-mac$ -- ok? )
   2over  " olpc-mesh" $=  if       ( ch ssid$ target-mac$ )
      2drop 2drop mesh-start 0=     ( ok? )
      dup  if  mesh-default-modes  then
      exit
   then                             ( ch ssid$ target-mac$ )
   ?set-wep				\ Set WEP keys again, if ktype is WEP
   set-mac-control
   2dup authenticate                ( ch ssid$ target-mac$ )
   d# 10 0 do                       ( ch ssid$ target-mac$ )
      4 pick  4 pick  4 pick  4 pick  4 pick  ( ch ssid$ target-mac$  ch ssid$ target-mac$ )
      bss-type bss-type-managed =  if  (associate)  else  (join)  then  ( ch ssid$ target-mac$ ok? )
      if  2drop 3drop true unloop  exit  then
   loop
   2drop 3drop
   false
;
headers

: do-associate  ( -- ok? )
   ['] 2drop to ?process-eapol  \ Don't reenter the supplicant while associating
   supplicant-associate dup  if
      ds-disconnected reset-driver-state
      ds-associated set-driver-state
   then
   ['] do-process-eapol to ?process-eapol
;

: ?reassociate  ( -- )
   driver-state ds-disconnected and  if  do-associate drop  then
;
' ?reassociate to start-nic

: disassociate  ( mac$ -- )
   dup 2+ h# 26 ( CMD_802_11_DISASSOCIATE ) prepare-cmd
   ( mac$ ) +x$			\ AP MAC address
   3 +xw			\ Reason code: station is leaving
   outbuf-wait  if  exit  then
   ds-disconnected set-driver-state
;


\ =======================================================================
\ Miscellaneous
\ =======================================================================

: get-rf-channel  ( -- )
   d# 40 h# 1d ( CMD_802_11_RF_CHANNEL ) prepare-cmd
   ACTION_GET +xw
   outbuf-wait  if  exit  then
   ." Current channel = " respbuf >fw-data 2 + le-w@ .d cr
;

: set-rf-channel  ( -- )
   d# 40 h# 1d ( CMD_802_11_RF_CHANNEL ) prepare-cmd
   ACTION_SET +xw
   channel +xw
   0 +xw   \ rftype
   0 +xw   \ reserved
   " "(00 88 cc cb 20 8c 6d cc 60 40 25 cc 44 ce 76 cc 29 8e 42 c0 f2 ff ff ff 00 00 00 00 4c ce 76 cc)" +x$ \ channel list
   outbuf-wait drop
;

: get-beacon  ( -- interval enabled? )
   6 h# b0 ( CMD_802_11_BEACON_CTRL ) prepare-cmd
   ACTION_GET +xw
   outbuf-wait  if  exit  then
   respbuf >fw-data  dup 2 wa+ le-w@  swap wa1+ le-w@
;

: set-beacon  ( interval enabled? -- )
   6 h# b0 ( CMD_802_11_BEACON_CTRL ) prepare-cmd
   ACTION_SET +xw     ( interval enabled? )
   0<> 1 and +xw  +xw ( )
   outbuf-wait drop
;

d# 24 constant /802.11-header
d# 1600 constant /packet-buf
/packet-buf buffer: packet-buf
0 instance value seq#

\ The low byte of the frame type word is:
\ ssssTTpp
\ pp is protocol, always 00
\ TT is type, 00 for management, 01 (i.e. 4) control, 10 (i.e. 8) data, 11 reserved
\ ssss is subtype
\ Management subtypes are:
\ 0000 (00) Association request
\ 0001 (10) Association response
\ 0010 (20) Reassociation request
\ 0011 (30) Reassociation response
\ 0100 (40) Probe request
\ 0101 (50) Probe response
\ 0110-0111 (60-70) Reserved
\ 1000 (80) Beacon
\ 1001 (90) ATIM
\ 1010 (a0) Disassociation
\ 1011 (b0) Authentication
\ 1100 (c0) Deauthentication
\ 1101-1111 (d0-f0) Reserved
\ Control subtypes are (other codes are reserved):
\ 1010 (a4) PS-Poll
\ 1011 (b4) RTS
\ 1100 (c4) CTS
\ 1101 (d4) ACK
\ 1110 (e4) CF End
\ 1111 (f4) CF End-ACK
\ Data subtypes are (other codes are reserved):
\ 0000 (08) Data
\ 0001 (18) Data+CF-ACK
\ 0010 (28) Data+CF-Poll
\ 0011 (38) Data+CF-ACK+CF-Poll
\ 0100 (48) Null (no data)
\ 0101 (58) CF-ACK (no data)
\ 0110 (68) CF-Poll (no data),
\ 0111 (78) CF-ACK+CF-Poll (no-data)

: set-802.11-header  ( adr3$ adr2$ adr1$ duration frame-type -- )
   packet-buf le-w!                ( adr3$ adr2$ adr1$ duration )
   packet-buf 2+ le-w!             ( adr3$ adr2$ adr1$ )
   packet-buf 4 +  swap move       ( adr3$ adr2$ )
   packet-buf d# 10 +  swap move   ( adr3$ )
   packet-buf d# 16 +  swap move   ( )
   seq#  packet-buf d# 22 +  le-w! ( )
   seq# h# 10 +  to seq#           ( )  \ The 4 LSBs are the fragment number
;
: +pkt-data  ( offset -- adr )  packet-buf +  /802.11-header +  ;
: send-deauth  ( -- )
   tx-ctrl >r  h# 10 set-tx-ctrl
   mac-adr$  mac-adr$  broadcast-mac$  0  h# c0  set-802.11-header
   h# 0002  0 +pkt-data  le-w!  \ Reason code: auth no longer valid
   packet-buf  /802.11-header 2 +   wrap-802.11    ( adr len )
   data-out
   r> set-tx-ctrl
;

\ adr len is the BSSID (MAC ADDRESS) of the wlan when acting as an access point.
: set-bssid  ( adr len -- )
   7 h# cd  ( CMD_802_11_SET_MODE ) prepare-cmd  ( adr len )
   +x$                                           ( )
   1 +xb    \ activate                           ( )
   outbuf-wait drop
;
: deactivate-bssid  ( -- )
   7 h# cd  ( CMD_802_11_SET_MODE ) prepare-cmd  ( adr len )
   " "(00 00 00 00 00 00)" +x$                   ( )
   0 +xb    \ deactivate                         ( )
   outbuf-wait drop
;

\ Howto set up access point:
\   ok setenv wlan-fw u:\usb8388t.bin       \ Thin firmware
\   ok select /wlan:force
\   ok 1 " xoAP" start-ap

: start-ap  ( channel ssid$ -- )
   rot to channel   ( ssid$ )
   to /ssid         ( ssid-adr )
   ssid$ move       ( )
   set-boot2-from-usb
   marvel-get-mac-address drop
   set-mac-control
   4 set-preamble  set-radio-control   \ auto preamble
   set-rf-channel
   set-ap-mode   
   marvel-set-mac-address
   send-deauth
   make-beacon
   mac-adr$ set-bssid
   d# 100 1 set-beacon
;

: stop-ap  ( -- )
   radio-off
   0 0 set-beacon
   set-fullmac-mode
   deactivate-bssid
   4 set-preamble  set-radio-control

\ This is a heavy-handed way to force the device back into baseline state
\ The recipe above is nicer.
\   ds-not-ready  to driver-state  \ Forces firmware reload on next open
\   reset-host-bus                 \ Primes module to accept new firmware
\   false to ap-mode?
;

: get-log  ( -- )
   0 h# b ( CMD_802_11_GET_LOG ) prepare-cmd
   outbuf-wait  if  exit  then
   respbuf .log
;

: get-rssi  ( -- )
   2 h# 1f ( CMD_802_11_RSSI ) prepare-cmd
   8 +xw			\ Value used for exp averaging
   outbuf-wait  drop
   \ XXX What to do with the result?
;

: .hw-spec  ( -- )
   marvel-get-hw-spec  if
      ." marvel-get-hw-spec command failed" cr
   else
      ." HW interface version: " dup le-w@ u. cr
      ." HW version: " dup 2 + le-w@ u. cr
      ." Max multicast addr: " dup 6 + le-w@ .d cr
      ." MAC address: " dup 8 + .enaddr cr
      ." Region code: " dup d# 14 + le-w@ u. cr
      ." # antenna: " dup d# 16 + le-w@ .d cr
      ." FW release: " dup d# 18 + le-l@ u. cr
      ." FW capability:" d# 34 + le-l@ .fw-cap cr
   then
;

: set-data-rate  ( rate-code -- )
   #rates 4 +  h# 22 ( CMD_802_11_DATA_RATE ) prepare-cmd

   1 ( CMD_ACT_SET_TX_FIX_RATE ) +xw
   0 +xw  \ reserved field
   ( rate-code ) +xb

   outbuf-wait  drop
;
: auto-data-rate  ( -- )
   #rates 4 +  h# 22 ( CMD_802_11_DATA_RATE ) prepare-cmd

   0 ( CMD_ACT_SET_TX_FIX_RATE ) +xw
   0 +xw  \ reserved field

   outbuf-wait  drop
;


: get-data-rates  ( -- )
   #rates 4 + h# 22 ( CMD_802_11_DATA_RATE ) prepare-cmd
   2 ( HostCmd_ACT_GET_TX_RATE ) +xw
   outbuf-wait  drop
;

2 constant gpio-pin 
d# 20 constant wake-gap 
1 constant wake-on-broadcast
2 constant wake-on-unicast
4 constant wake-on-mac-event 
-1 constant remove-wakeup 

\ LED_GPIO_CTRL 

: host-sleep-activate  ( -- )
   0 h# 45 ( CMD_802_11_HOST_SLEEP_ACTIVATE ) prepare-cmd
   outbuf-wait  drop
;

: host-sleep-config  ( conditions -- )
   >r
   6 h# 43 ( CMD_802_11_HOST_SLEEP_CFG ) prepare-cmd
\   ACTION_SET +xw
   
   r> +xl
   gpio-pin +xb
   wake-gap +xb

   outbuf-wait  drop
;

: unicast-wakeup  ( -- )  wake-on-unicast host-sleep-config  ;
: broadcast-wakeup  ( -- )  wake-on-unicast wake-on-broadcast or  host-sleep-config  ;
: sleep ( -- ) host-sleep-activate  ;

[ifdef] notdef
  CMD_ACT_MESH_...
 1 GET_TTL   2 SET_TTL   3 GET_STATS   4 GET_ANYCAST   5 SET_ANYCAST
 6 SET_LINK_COSTS  7 GET_LINK_COSTS   8 SET_BCAST_RATE   9 GET_BCAST_RATE
10 SET_RREQ_DELAY  11 GET_RREQ_DELAY  12 SET_ROUTE_EXP  13 GET_ROUTE_EXP
14 SET_AUTOSTART_ENABLED  15 GET_AUTOSTART_ENABLED  16 not used
17 SET_PRB_RSP_RETRY_LIMIT

CMD_TYPE_MESH_
1 SET_BOOTFLAG  2 SET_BOOTTIME  3 SET_DEF_CHANNEL  4 SET_MESH_IE
5 GET_DEFAULTS  6 GET_MESH_IE /* GET_DEFAULTS is superset of GET_MESHIE */

CMD_ACT_MESH_CONFIG_..  0 STOP  1 START  2 SET  3 GET

struct cmd_ds_mesh_config {
        struct cmd_header hdr;
        __le16 action; __le16 channel; __le16 type; __le16 length;
        u8 data[128];   /* last position reserved */
}
struct mrvl_meshie_val {
        uint8_t oui[P80211_OUI_LEN];
        uint8_t type;
        uint8_t subtype;
        uint8_t version;
        uint8_t active_protocol_id;
        uint8_t active_metric_id;
        uint8_t mesh_capability;
        uint8_t mesh_id_len;
        uint8_t mesh_id[IW_ESSID_MAX_SIZE];  32
}
struct ieee80211_info_element {
        u8 id;  u8 len;  u8 data[0];
}
struct mrvl_meshie {
        struct ieee80211_info_element hdr;
        struct mrvl_meshie_val val;
}
        memset(&cmd, 0, sizeof(cmd));
        cmd.channel = cpu_to_le16(chan);
        ie = (struct mrvl_meshie *)cmd.data;

        switch (action) {
        case CMD_ACT_MESH_CONFIG_START:
0.b      221    ie->hdr.id = MFIE_TYPE_GENERIC;
2.b      h# 00  ie->val.oui[0] = 0x00;
3.b      h# 50  ie->val.oui[1] = 0x50;
4.b      h# 43  ie->val.oui[2] = 0x43;
5.b      4      ie->val.type = MARVELL_MESH_IE_TYPE;
6.b      0      ie->val.subtype = MARVELL_MESH_IE_SUBTYPE;
7.b      0      ie->val.version = MARVELL_MESH_IE_VERSION;
8.b      0      ie->val.active_protocol_id = MARVELL_MESH_PROTO_ID_HWMP;
9.b      0      ie->val.active_metric_id = MARVELL_MESH_METRIC_ID;
10.b     0      ie->val.mesh_capability = MARVELL_MESH_CAPABILITY;
11.b  ssid_len  ie->val.mesh_id_len = priv->mesh_ssid_len;
12              memcpy(ie->val.mesh_id, priv->mesh_ssid, priv->mesh_ssid_len);
1  10+ssid_len  ie->hdr.len = sizeof(struct mrvl_meshie_val) - IW_ESSID_MAX_SIZE + priv->mesh_ssid_len;

    42 (32+10)  cmd.length = cpu_to_le16(sizeof(struct mrvl_meshie_val));

config_start:  action is 1 (...CONFIG_START), type = mesh_tlv which is either h# 100 d# 291 +  or h# 100 d# 37 +
[then]

[ifdef] notdef
create mesh_start_cmd
   \ MFIE_TYPE_GENERIC  ielen (10 + sizeof("mesh"))
   d# 221 c,            d# 14 c,

   \  OUI....................  type  subtyp vers  proto metric cap
   h# 00 c, h# 50 c, h# 43 c,  4 c,  0 c,   0 c,  0 c,  0 c,   0 c,

   \ ssidlen   ssid (set@12)
   d# 04 c,   here 4 allot  " mesh" rot swap move
here mesh_start_cmd - constant /mesh_start_cmd
[then]

[ifdef] wlan-wackup  \ This is test code that only works with a special debug version of the Libertas firmware
: autostart  ( -- )
   h# 700000 h# 5 mesh-access!
;
[then]

hex
headers

" wlan" device-name
" wireless-network" device-type

variable opencount 0 opencount !

headers

: ?make-mac-address-property  ( -- error? )
   driver-state ds-ready <  if  false exit  then
   " mac-address"  get-my-property  if   ( )
      marvel-get-mac-address  if  true exit  then
      mac-adr$ encode-bytes  " local-mac-address" property
      mac-address encode-bytes " mac-address" property
      false
   else                                  ( adr len )
      2drop  false
   then
;
: set-frame-size  ( -- )
   " max-frame-size" get-my-property  if   ( )
      max-frame-size encode-int  " max-frame-size" property
   else                                    ( prop$ )
      2drop
   then
;

: init-net  ( -- )
   ?make-mac-address-property drop
;

: ?load-fw  ( -- error? )
   driver-state ds-not-ready =  if
      load-all-fw  if
         ." Failed to download firmware" cr
         true exit
      then
      ds-ready to driver-state
   then
   ?make-mac-address-property
;

false instance value use-promiscuous?

external

\ Set to true to force open the driver without association.
\ Designed for use by application to update the Marvel firmware only.
\ Normal operation should have force-open? be false.
false instance value force-open?
				
: parse-args  ( $ -- )
   false to use-promiscuous?
   begin  ?dup  while
      ascii , left-parse-string
      2dup " debug" $=  if  debug-on  then
      2dup " promiscuous" $=  if  true to use-promiscuous?  then
           " force" $=  if  true to force-open?  then
   repeat drop
;

: open  ( -- ok? )
   my-args parse-args
   set-parent-channel
   " " set-ssid  \ Instance buffers aren't necessarily initially 0
   opencount @ 0=  if
      init-buf
      /inbuf /outbuf setup-bus-io  if  free-buf false exit  then
      ?load-fw  if  release-bus-resources free-buf false exit  then
      my-args " supplicant" $open-package to supplicant-ih
      supplicant-ih 0=  if  release-bus-resources free-buf false exit  then
      nonce-cmd
      force-open?  if
         ds-disconnected reset-driver-state
      else
         link-up? 0=  if
            do-associate 0=  if  free-buf false exit  then
         then
         start-nic
      then
   then
   force-open?  0=  if
      use-promiscuous?  if  enable-promiscuous  else  disable-promiscuous  then
   then
   opencount @ 1+ opencount !
   true
;

: close  ( -- )
   opencount @ 1-  0 max  opencount !
   opencount @ 0=  if
      ap-mode?  if  stop-ap  then
      adhoc-started?  if  adhoc-stop  then
      disable-multicast
      mesh-stop drop
      link-up?  if  target-mac$ deauthenticate  then
      ['] 2drop to ?process-eapol
      stop-nic
      mac-off
      supplicant-ih ?dup  if  close-package 0 to supplicant-ih  then
      release-bus-resources
   then
;

\ Read and write ethernet messages regardless of the associate state.
\ Used by the /supplicant support package to perform key handshaking.
: write-force  ( adr len -- actual )
   tuck					( actual adr len )
   wrap-msg				( actual adr' len' )
   data-out                             ( actual )
;

: read-force  ( adr len -- actual )
   got-packet?  0=  if  		( adr len )
      2drop  -2  exit
   then                                 ( adr len [ error | buf actual 0 ] )

   if	\ receive error			( adr len )
      recycle-packet			( adr len )
      2drop  -1  exit
   then					( adr len buf actual )

   false to got-data?			( adr len buf actual )
   process-rx				( adr len )

   got-data?  if			( adr len )
      /data min tuck data -rot move	( actual )
   else					( adr len )
      2drop -2				\ No data
   then					( actual )

   recycle-packet			( actual )
;

0 instance value /packet
: find-tag  ( tag-id #fixed-params -- false | tag-adr tag-len true )
   +pkt-data                    ( tag-id adr )
   /packet  over packet-buf - - ( tag-id adr len )
   begin  dup  while            ( tag-id adr len )
      2 pick  2 pick c@  =  if  ( tag-id adr len )
         drop nip               ( adr )
         dup 2+ swap 1+ c@      ( tag-adr tag-len )
         true exit              ( -- tag-adr tag-len true )
      then                      ( tag-id adr len )
      over 1+ c@ 2+ /string     ( tag-id adr' len' )
   repeat                       ( tag-id adr len )
   3drop false
;

1 value association-id#
: associate-reply  ( -- )
   0 4 find-tag  0=  if  exit  then   ( adr len )  \ Exit if SSID parameter is missing
   ssid$ $=  0=  if  exit  then   ( )  \ Exit if SSID is wrong
   
   mac-adr$ mac-adr$  packet-buf d# 10 + 6  d# 314  h# 10  set-802.11-header

   cap        0 +pkt-data  le-w!   \ Capability mask
   0          2 +pkt-data  le-w!   \ Status - okay
   association-id# h# 3fff and  h# c000 or   4 +pkt-data  le-w!   \ 
   association-id# 1+ to association-id#
   
   " "(01 08 02 04 0b 16 0c 12 18 24 32 04 30 48 e0 ec)"   ( tags-adr tags-len )
   tuck   6 +pkt-data  swap  move                          ( tags-size )
   packet-buf  swap /802.11-header +  6 +   wrap-802.11    ( adr len )
   data-out
;

: authenticate-reply  ( -- )
   mac-adr$ mac-adr$  packet-buf d# 10 + 6  d# 314  h# b0  set-802.11-header
   0          0 +pkt-data  le-w!   \ Open system auth code
   2 +pkt-data  le-w@   1+  2 +pkt-data  le-w!   \ auth seq#
   0          4 +pkt-data  le-w!   \ Status - okay
   
   packet-buf  /802.11-header 6 +   wrap-802.11    ( adr len )
   data-out
;

defer handle-data  ' noop is handle-data
: process-mgmt-frame  ( -- )
   packet-buf /packet-buf  read-force   ( len )
   dup -2 =  if  drop exit  then        ( len )
   to /packet                           ( )

   packet-buf c@  case     ( type )
      h#  0  of  associate-reply    exit  endof   \ Association
      h# 40  of                     exit  endof   \ Probe request
      h# 48  of                     exit  endof   \ Null function
      h# 50  of                     exit  endof   \ Probe response
      h# b0  of  authenticate-reply exit  endof   \ Authenticate
      h# c0  of                     exit  endof   \ Deauthenticate
      h# d4  of                     exit  endof   \ Acknowledgment
   endcase

   handle-data
;
: dump-pkt  ( -- )
   packet-buf /packet  " no-page dump" evaluate
;
: run-ap  ( -- )
   begin  process-mgmt-frame  key? until
;
: do-ap  ( -- )
   ['] dump-pkt to handle-data
   1 " xxAP" start-ap
   run-ap
;

1 value delay
: throttle delay ms  ;
\ Convert an 802.3 frame to an 802.11 frame and send it
: thin-send-data-frame  ( adr len -- len )
   tuck over >r         ( len adr len  r: adr )
   \ In 208, 200 is the fromDS bit, indicating that the frame is ostensibly coming
   \ from an AP, and 8 is the code for a non-acked Data frame.
   mac-adr$  r@ 6 + 6  r> 6  0  h# 208  set-802.11-header    ( len adr len )
   d# 12 /string                                        ( len adr' elen )
   " "(aa aa 03 00 00 00)"  0 +pkt-data  swap move      ( len adr' elen )
   tuck  6 +pkt-data swap move                          ( len elen )
   packet-buf  swap /802.11-header +  6 +  wrap-802.11  ( len padr plen )
   begin  backlog 8 >=  while  process-mgmt-frame  repeat
   backlog 1+ to backlog
   data-out                                             ( len )
   throttle
;

d# 1600 buffer: test-buf
: send-test-pkt  ( -- )
   h# 1c set-tx-ctrl
   " "(01 00 5e 7f 01 02)" test-buf  swap  move
   mac-adr$ test-buf 6 +  swap  move
   " XO" test-buf d# 12 +  swap  move
   test-buf d# 1440 thin-send-data-frame drop
;

\ Normal read and write methods.
: write  ( adr len -- actual )
   ap-mode?  if
      thin-send-data-frame
   else
      link-up? 0=  if  2drop 0 exit  then	\ Not associated yet.
      ?reassociate				\ In case if the connection is dropped
      write-force
   then
;
: read  ( adr len -- actual )
   \ If a good receive packet is ready, copy it out and return actual length
   \ If a bad packet came in, discard it and return -1
   \ If no packet is currently available, return -2

   link-up? 0=  if  2drop 0 exit  then	\ Not associated yet.
   ?reassociate				\ In case if the connection is dropped
   read-force
;

: load  ( adr -- len )
   link-up? 0=  if  drop 0 exit  then	\ Not associated yet.

   " obp-tftp" find-package  if		( adr phandle )
      my-args rot  open-package		( adr ihandle|0 )
   else					( adr )
      0					( adr 0 )
   then					( adr ihandle|0 )

   dup  0=  if  ." Can't open obp-tftp support package" stop-nic abort  then
					( adr ihandle )

   >r
   " load" r@ ['] $call-method	catch   ( len false | x x x true )
   r> close-package
   throw
;

: reset  ( -- flag )  reset-nic  ;

: test-association  ( -- error? )
   passive-scan
   " OLPCOFW" " scan-ssid?" $call-supplicant  if
      " (do-associate)" $call-supplicant  if
	 \ Success
         " target-mac$" $call-supplicant disassociate
         true to ssid-reset?
	 false
      else
	 true
      then
   else
      \ There is no OLPCOFW access point, so we don't try associating
      false
   then
   active-scan
;

: (scan-wifi)  ( -- error? )
   true to force-open?
   open
   false to force-open?
   0=  if  ." Can't open Marvell wireless" cr true close  exit  then

   (scan)  if
      ." Failed to scan" true cr
   else    ( adr len )
\     drop .scan false
      diagnostic-mode?  if  ( adr len )
         drop 2+ c@  if     ( )
            false
         else
            ." ERROR: No access points seen" cr
            true
         then
      else                  ( adr len )
         drop .ssids        ( )
         test-association   ( error? )
      then
   then

   close
;

: scan-wifi  ( -- )  (scan-wifi) drop  ;

: selftest  ( -- error? )  (scan-wifi)  ;

headers


\ LICENSE_BEGIN
\ Copyright (c) 2007 FirmWorks
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
