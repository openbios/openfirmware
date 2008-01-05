purpose: Marvel USB 8388 wireless ethernet driver
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

\ =======================================================================
\ Wireless environment variables
\    wlan-fw             e.g., rom:usb8388.bin, disk:\usb8388.bin
\ =======================================================================

: wlan-fw  ( -- $ )
   " wlan-fw" " $getenv" evaluate  if  " rom:usb8388.bin"  then  
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
create supported-rates 82 c, 84 c, 8b c, 96 c, 0c c, 12 c, 18 c, 24 c,
		       30 c, 48 c, 60 c, 6c c, 00 c, 00 c,
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
3 value mac-ctrl		\ MAC control

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
   4 field >fw-req		\ Command request type
   2 field >fw-cmd		\ Start of command header
   2 field >fw-len
   2 field >fw-seq
   2 field >fw-result
dup constant /fw-cmd
dup 4 - constant /fw-cmd-hdr	\ Command header len (less >fw-req)
   0 field >fw-data		\ Command payload starts here
drop

\ >fw-req constants
h# f00d.face constant CMD_TYPE_REQUEST
h# bead.c0de constant CMD_TYPE_DATA
h# beef.face constant CMD_TYPE_INDICATION

0 constant ACTION_GET
1 constant ACTION_SET
2 constant ACTION_ADD
3 constant ACTION_HALT
4 constant ACTION_REMOVE
8 constant ACTION_USE_DEFAULT

-1 value fw-seq

: fw-seq++  ( -- )  fw-seq 1+ to fw-seq  ;

d#  1,000 constant resp-wait-short
d# 10,000 constant resp-wait-long
resp-wait-short value resp-wait

/inbuf buffer: respbuf
0 value /respbuf

\ =========================================================================
\ Transmit Packet Descriptor
\ =========================================================================

struct
   4 +				\ >fw-req
   4 field >tx-stat
   4 field >tx-ctrl
   4 field >tx-offset
   2 field >tx-len
   6 field >tx-mac
   1 field >tx-priority
   1 field >tx-pwr
   1 field >tx-delay		\ in 2ms
   1+
   0 field >tx-pkt
dup constant /tx-hdr
4 - constant /tx-desc

0 constant tx-ctrl		\ Tx rates, etc

: wrap-pkt  ( adr len -- adr' len' )
   dup /tx-hdr + -rot			( len' adr len )
   outbuf /tx-hdr erase			( len' adr len )
   2dup outbuf >tx-pkt swap move	( len' adr len )
   CMD_TYPE_DATA outbuf >fw-req le-l!	( len' adr len )
   ( len )  outbuf >tx-len le-w!	( len' adr )
   /tx-desc outbuf >tx-offset le-l!	( len' adr )
   tx-ctrl  outbuf >tx-ctrl le-l!	( len' adr )
   ( adr )  outbuf >tx-mac /mac-adr move	( len' )
   outbuf swap				( adr' len' )
;
' wrap-pkt to wrap-msg

\ =========================================================================
\ Receive Packet Descriptor
\ =========================================================================

true value got-data?
0 value /data
0 value data

struct
   4 +				\ >fw-req
   2 field >rx-stat
   1 field >rx-snr
   1 field >rx-ctrl
   2 field >rx-len
   1 field >rx-nf
   1 field >rx-rate
   4 field >rx-offset
   4 +
   1 field >rx-priority
   3 +
dup constant /rx-desc
   6 field >rx-dst-mac
   6 field >rx-src-mac
   0 field >rx-data-no-snap
   2 field >rx-pkt-len		\ pkt len from >rx-snap-hdr
   6 field >rx-snap-hdr
   0 field >rx-data
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

: unwrap-pkt  ( adr len -- adr' len' )
   /rx-min <  if  drop 0 0  then	\ Invalid packet: too small
   dup >rx-snap-hdr snap-header comp 0=  if	\ Remove snap header
      dup >rx-data over >rx-data-no-snap 2 pick >rx-pkt-len be-w@ move
      dup >rx-len le-w@ 8 -		\ Less snap-header and len field
   else
      dup >rx-len le-w@ 		( adr len' )
   then
   swap dup >rx-offset le-l@ + 4 + swap	( adr' len' )
;

: process-data  ( adr len -- )
   2dup vdump
   over .rx-desc
   over >rx-stat le-w@ rx-stat-ok <>  if  2drop exit  then
   true to got-data?
   unwrap-pkt				( adr' len' )
   to /data to data
   data d# 12 + be-w@ h# 888e =  if	\ Pass EAPOL messages to supplicant
      data /data ?process-eapol
   then
;

: do-process-eapol  ( adr len -- )  false to got-data?  process-eapol  ;

\ =========================================================================
\ Generic commands & responses
\ =========================================================================

0 value x			\ Temporary variables to assist command creation
0 value /x

: set-fw-data-x  ( -- )  outbuf >fw-data to x  0 to /x  ;
: 'x   ( -- adr )  x /x +  ;
: +x   ( n -- )  /x + to /x  ;
: +x$  ( $ -- )  'x swap dup +x move  ;
: +xl  ( n -- )  'x le-l!  /l +x  ;
: +xw  ( n -- )  'x le-w!  /w +x  ;
: +xb  ( n -- )  'x c!     /c +x  ;
: +xbl ( n -- )  'x be-l!  /l +x  ;

: outbuf-bulk-out  ( dlen -- error? )
   /fw-cmd + outbuf swap 2dup vdump bulk-out-pipe bulk-out  
;

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
      ( default )  ." Unknown command: " dup u.
   endcase
   cr   
;

: prepare-cmd  ( len cmd -- )
   dup .cmd
   resp-wait-short to resp-wait
   outbuf 2 pick /fw-cmd + erase
   bulk-in? ?dup  if
      nip
      USB_ERR_INV_OP =  if
         inbuf /inbuf bulk-in-pipe begin-bulk-in
      else
         restart-bulk-in			\ USB error
      then
   else
      if  restart-bulk-in  then
   then
   fw-seq++
   CMD_TYPE_REQUEST      outbuf >fw-req    le-l!
   ( cmd )               outbuf >fw-cmd    le-w!
   ( len ) /fw-cmd-hdr + outbuf >fw-len    le-w!
   fw-seq                outbuf >fw-seq    le-w!
   0                     outbuf >fw-result le-w!
   set-fw-data-x
;

true value cmd-resp-error?
true value got-response?

: process-disconnect  ( -- )  ds-disconnected set-driver-state  ;
: process-wakeup  ( -- )  ;
: process-sleep  ( -- )  ;
: process-pmic-failure  ( -- )  ;
: process-gmic-failure  ( -- )  ;

: .event  ?cr  ." Event: "  type  cr ;
: process-ind  ( adr len -- )
   drop
   4 + le-l@  case
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
      h# 30  of  " Firmware ready" .event  endof
      ( default )  ." Unknown " dup u.
   endcase
;

: process-request  ( adr len -- )
   2dup vdump
   drop
   true to got-response?
   >fw-result le-w@  to cmd-resp-error?
;

: process-rx  ( adr len -- )
   over >fw-req le-l@  case
      CMD_TYPE_REQUEST     of  process-request  endof	\ Response & request
      CMD_TYPE_DATA        of  process-data     endof	\ Data
      CMD_TYPE_INDICATION  of  process-ind      endof	\ Indication
      ( default )  >r vdump r>
   endcase
;

: check-for-rx  ( -- )
   bulk-in?  if
      restart-bulk-in exit		\ USB error
   else
      ?dup  if
         inbuf respbuf rot dup to /respbuf move
         restart-bulk-in
         respbuf /respbuf process-rx
      then
   then
;
\ -1 error, 0 okay, 1 retry
: wait-cmd-resp  ( -- -1|0|1 )
   false to got-response?
   false to got-data?
   resp-wait 0  do
      check-for-rx
      got-response?  if  leave  then
      1 ms
   loop
   got-response?  if
      cmd-resp-error?  case
         0 of  0  endof  \ No error
         4 of  1  endof  \ Busy, so retry
         ( default )  ." Result = " dup u. cr  dup
      endcase
   else
      ." Timeout or USB error" cr
      true
   then
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

: .hw-spec  ( adr -- )
   ." HW interface version: " dup >fw-data le-w@ u. cr
   ." HW version: " dup >fw-data 2 + le-w@ u. cr
   ." Max multicast addr: " dup >fw-data 6 + le-w@ .d cr
   ." MAC address: " dup >fw-data 8 + .enaddr cr
   ." Region code: " dup >fw-data d# 14 + le-w@ u. cr
   ." # antenna: " dup >fw-data d# 16 + le-w@ .d cr
   ." FW release: " dup >fw-data d# 18 + le-l@ u. cr
   ." FW capability:" >fw-data d# 34 + le-l@ .fw-cap cr
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

: reset-wlan  ( -- )  " wlan-reset" evaluate  ;

\ =========================================================================
\ MAC address
\ =========================================================================

: marvel-get-mac-address  ( -- )
   8 h# 4d ( CMD_802_11_MAC_ADDRESS ) prepare-cmd
   ACTION_GET +xw
   8 outbuf-bulk-out
   ?dup if  ." Failed to send get mac address command: " u. cr exit  then
   wait-cmd-resp  if  exit  then
   respbuf >fw-data 2 + mac-adr$ move
;

: marvel-set-mac-address  ( -- )
   8 h# 4d ( CMD_802_11_MAC_ADDRESS ) prepare-cmd
   ACTION_SET +xw
   mac-adr$ +x$
   8 outbuf-bulk-out  if  exit  then
   wait-cmd-resp  if  exit  then
;

: marvel-get-mc-address  ( -- )
   4 /mc-adrs + h# 10 ( CMD_MAC_MULTICAST_ADR ) prepare-cmd
   ACTION_GET +xw
   4 /mc-adrs + outbuf-bulk-out  if  exit  then
   wait-cmd-resp  if  exit  then
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
   4 /mc-adrs + outbuf-bulk-out  if  exit  then
   wait-cmd-resp  if  exit  then
;

\ =========================================================================
\ Register access
\ =========================================================================

: reg-access@  ( reg cmd -- n )
   8 swap prepare-cmd
   ACTION_GET +xw
   ( reg ) +xw
   8 outbuf-bulk-out  if  0 exit  then
   wait-cmd-resp  if  0 exit  then
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
   a outbuf-bulk-out  if  0 exit  then
   wait-cmd-resp  if  0 exit  then
   respbuf >fw-data 6 + le-l@
;

\ =========================================================================
\ Miscellaneous control settings
\ =========================================================================

: set-radio-control  ( -- )
   4 h# 1c ( CMD_802_11_RADIO_CONTROL ) prepare-cmd
   ACTION_SET +xw
   preamble 1 or +xw	\ Preamble, RF on
   4 outbuf-bulk-out  if  exit  then
   wait-cmd-resp  if  exit  then
;

: (set-bss-type)  ( bsstype -- ok? )
   6 d# 128 + h# 16 ( CMD_802_11_SNMP_MIB ) prepare-cmd
   ACTION_SET +xw
   0 +xw		\ Object = desiredBSSType
   1 +xw		\ Size of object
   ( bssType ) +xb	
   6 d# 128 + outbuf-bulk-out  if  false exit  then
   wait-cmd-resp 0=
;

external
: set-bss-type  ( bssType -- ok? )  dup to bss-type (set-bss-type)  ;
headers

: set-mac-control  ( -- )
   4 h# 28 ( CMD_MAC_CONTROL ) prepare-cmd
   mac-ctrl +xw		\ WEP type, WMM, protection, multicast, promiscous, WEP, tx, rx
   4 outbuf-bulk-out  if  exit  then
   wait-cmd-resp  if  exit  then
;

: set-domain-info  ( adr len -- )
   dup 6 + h# 5b ( CMD_802_11D_DOMAIN_INFO ) prepare-cmd
   ACTION_SET +xw
   7 +xw				\ Type = MrvlIETypes_DomainParam_t
   ( len ) dup +xw			\ Length of payload
   ( adr len ) tuck +x$			\ Country IE
   ( len ) 6 + outbuf-bulk-out  if  exit  then
   wait-cmd-resp  if  exit  then
;

: enable-11d  ( -- )
   6 d# 128 + h# 16 ( CMD_802_11_SNMP_MIB ) prepare-cmd
   ACTION_SET +xw
   9 +xw		\ Object = enable 11D
   2 +xw		\ Size of object
   1 +xw		\ Enable 11D
   6 d# 128 + outbuf-bulk-out  if  exit  then
   wait-cmd-resp  if  exit  then
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
: set-multicast  ( adr len -- )   marvel-set-mc-address  enable-multicast  ;
headers

\ =========================================================================
\ Scan
\ =========================================================================

1 constant #probes

struct
   2 field >type-id
   2 field >/payload
dup constant /marvel-IE-hdr
   2 field >probes
constant /probes-IE

d# 14 constant #channels

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


d# 34 instance buffer: ssid

: make-chan-list-param  ( adr -- )
   #channels 0  do
      dup i /chan-list * +
      0 over >radio-type c!
      i 1+ over >channel# c!
      0 over >scan-type c!
      d# 100 over >min-scan-time le-w!
      d# 100 swap >max-scan-time le-w!
   loop  drop
;

: (scan)  ( -- error? )
   /cmd_802_11_scan  ssid c@  if
      /marvel-IE-hdr +  ssid c@ +
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

   ssid c@  if                                    ( 'fw-data )
      \ Attach an SSID TLV to filter the result
      /cmd_802_11_scan +                               ( 'ssid )
      h# 000 over >type-id le-w!                       ( 'ssid )
      ssid c@   over >/payload le-w!                   ( 'ssid )
      ssid count  rot /marvel-IE-hdr +  swap move      ( )
      /cmd_802_11_scan  /marvel-IE-hdr ssid c@ +  +    ( cmdlen )
   else                                           ( 'fw-data )
      drop
      /cmd_802_11_scan                            ( cmdlen )
   then                                           ( cmdlen )

   outbuf-bulk-out  if  true exit  then
   wait-cmd-resp
;

external
\ Ask the device to look for the indicated SSID.
: set-ssid  ( adr len -- )  h# 32 min  ssid pack drop  ;

: scan  ( adr len -- actual )
   begin  (scan)  dup 1 =  while  drop d# 1000 ms  repeat  \ Retry while busy
   if  2drop 0 exit  then
   respbuf /respbuf /fw-cmd /string	( adr len radr rlen )
   rot min -rot swap 2 pick move	( actual )
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
   d# 72 outbuf-bulk-out  if  false exit  then
   wait-cmd-resp 0=
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
   d# 72 outbuf-bulk-out  if  false exit  then
   wait-cmd-resp 0=
;
headers

\ =========================================================================
\ WPA and WPA2
\ =========================================================================

: set-rsn  ( enable? -- ok? )
   4 h# 2f ( CMD_802_11_ENABLE_RSN ) prepare-cmd
   ACTION_SET +xw
   ( enable? ) +xw		\ 1: enable; 0: disable
   4 outbuf-bulk-out  if  false exit  then
   wait-cmd-resp 0=
;

external
: enable-rsn   ( -- ok? )  1 set-rsn  ;
: disable-rsn  ( -- ok? )  0 set-rsn  ;
headers

: set-key-material  ( key$ kinfo ct -- )
   /outbuf h# 5e ( CMD_802_11_KEY_MATERIAL ) prepare-cmd
   ACTION_SET +xw
   h# 100     +xw			\ Key param IE type
   2 pick 6 + +xw			\ IE payload length
   ( ct )     +xw			\ Cipher type
   ( kinfo )  +xw			\ Key info
   dup        +xw			\ Key length
   ( key$ )   +x$			\ key$
   /x dup /fw-cmd-hdr + outbuf >fw-len le-w!	\ Finally set the length
   outbuf-bulk-out  if  exit  then
   wait-cmd-resp  if  exit  then
;

external
: set-gtk  ( gtk$ -- )  5 ctype-g  set-key-material  ;
: set-ptk  ( ptk$ -- )  6 ctype-p  set-key-material  ;
headers

\ =======================================================================
\ Adhoc join
\ =======================================================================

0 value atim

: save-associate-params  ( ch ssid$ target-mac$ -- ch ssid$ target-mac )
   over target-mac$ move
   2over dup to /ssid
   ssid swap move
   4 pick to channel
;

: (join)  ( ch ssid$ target-mac$ -- ok? )
   save-associate-params
   /outbuf h# 2c ( CMD_802_11_AD_HOC_JOIN ) prepare-cmd
   resp-wait-long to resp-wait

   ( target-mac$ ) +x$			\ Peer MAC address
   ( ssid$ ) tuck +x$			\ SSID
   ( ssid-len ) d# 32 swap - +x		\ 32 bytes of SSID
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

   cap    +xw				\ Capability info: ESS, short slot, WEP

   \ XXX 14 bytes for 802.11g, 8 bytes for 802.11b
   common-rates #rates +x$		\ Common supported data rates
   d# 255 +xw				\ Association timeout
   0      +xw				\ Probe delay time

   /x dup /fw-cmd-hdr + outbuf >fw-len le-w!	\ Finally set the length
   outbuf-bulk-out  if  false exit  then
   wait-cmd-resp  if  ." Failed to join adhoc network" cr false exit  then
   true
;

external
: set-atim-window  ( n -- )  d# 50 min  to atim  ;
headers

\ =========================================================================
\ Authenticate
\ =========================================================================

: authenticate  ( target-mac$ -- )
   7 h# 11 ( CMD_802_11_AUTHENTICATE ) prepare-cmd
   ( target-mac$ ) +x$		\ Peer MAC address
   auth-mode +xb		\ Authentication mode
   7 outbuf-bulk-out  if  exit  then
   wait-cmd-resp  if  exit  then
;

: deauthenticate  ( mac$ -- )
   8 h# 24 ( CMD_802_11_DEAUTHENTICATE ) prepare-cmd
   ( mac$ ) +x$			\ AP MAC address
   3 +xw			\ Reason code: station is leaving
   8 outbuf-bulk-out  if  exit  then
   wait-cmd-resp  if  exit  then
   ds-disconnected set-driver-state
;

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

   /outbuf h# 50 ( CMD_802_11_ASSOCIATE ) prepare-cmd
   resp-wait-long to resp-wait

   ( target-mac$ ) +x$			\ Peer MAC address
   cap    +xw				\ Capability info: ESS, short slot, WEP
   d#  10 +xw				\ Listen interval
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

   /x dup /fw-cmd-hdr + outbuf >fw-len le-w!	\ Finally set the length
   outbuf-bulk-out  if  false exit  then
   wait-cmd-resp  if  false exit  then

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
: associate  ( ch ssid$ target-mac$ -- ok? )
   ?set-wep				\ Set WEP keys again, if ktype is WEP
   set-mac-control
   2dup authenticate
   bss-type bss-type-managed =  if  (associate)  else  (join)  then
;
headers

: do-associate  ( -- ok? )
   do-associate dup  if
      ds-disconnected reset-driver-state
      ds-associated set-driver-state
   then
;

: ?reassociate  ( -- )
   driver-state ds-disconnected and  if  do-associate drop  then  ;
' ?reassociate to start-nic

: disassociate  ( mac$ -- )
   8 h# 26 ( CMD_802_11_DISASSOCIATE ) prepare-cmd
   ( mac$ ) +x$			\ AP MAC address
   3 +xw			\ Reason code: station is leaving
   8 outbuf-bulk-out  if  exit  then
   wait-cmd-resp  if  exit  then
   ds-disconnected set-driver-state
;


\ =======================================================================
\ Miscellaneous
\ =======================================================================

: get-rf-channel  ( -- )
   d# 40 h# 1d ( CMD_802_11_RF_CHANNEL ) prepare-cmd
   ACTION_GET +xw
   d# 40 outbuf-bulk-out  if  exit  then
   wait-cmd-resp  if  exit  then
   ." Current channel = " respbuf >fw-data 2 + le-w@ .d cr
;

: get-log  ( -- )
   0 h# b ( CMD_802_11_GET_LOG ) prepare-cmd
   0 outbuf-bulk-out  if  exit  then
   wait-cmd-resp  if  exit  then
   respbuf .log
;

: get-rssi  ( -- )
   2 h# 1f ( CMD_802_11_RSSI ) prepare-cmd
   8 +xw			\ Value used for exp averaging
   2 outbuf-bulk-out  if  exit  then
   wait-cmd-resp  if  exit  then
   \ XXX What to do with the result?
;

: get-hw-spec  ( -- )
   d# 38 3 ( CMD_802_11_GET_HW_SPEC ) prepare-cmd
   ACTION_GET +xw
   d# 38 outbuf-bulk-out  if  exit  then
   wait-cmd-resp  if  exit  then
   respbuf .hw-spec
;

: get-data-rates  ( -- )
   #rates 4 + h# 22 ( CMD_802_11_DATA_RATE ) prepare-cmd
   2 ( HostCmd_ACT_GET_TX_RATE ) +xw
   #rates 4 + outbuf-bulk-out  if  exit  then
   wait-cmd-resp  if  exit  then
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
   0 outbuf-bulk-out  if  exit  then
   wait-cmd-resp  if  exit  then
;

: host-sleep-config  ( conditions -- )
   >r
   6 h# 43 ( CMD_802_11_HOST_SLEEP_CFG ) prepare-cmd
\   ACTION_SET +xw
   
   r> +xl
   gpio-pin +xb
   wake-gap +xb

   6 outbuf-bulk-out  if  exit  then
   wait-cmd-resp  if  exit  then
;

: unicast-wakeup  ( -- )  wake-on-unicast host-sleep-config  ;
: broadcast-wakeup  ( -- )  wake-on-unicast wake-on-broadcast or  host-sleep-config  ;
: sleep ( -- ) host-sleep-activate  ;

[ifdef] wlan-wackup  \ This is test code that only works with a special debug version of the Libertas firmware
: autostart  ( -- )
   h# 82 h# 9b ( CMD_MESH_ACCESS ) prepare-cmd
   5 +xw  \ CMD_ACT_SET_ANYCAST
   h# 700000 +xl

   h# 82 outbuf-bulk-out  if  exit  then
   wait-cmd-resp  if  exit  then
;
[then]

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
