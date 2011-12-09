purpose: ATH9K MAC layer
\ See license at end of file

headers
hex

\ =======================================================================
\ Driver variables
\ =======================================================================

\ driver-state definitions
0 constant ds-ready                  \ Initial state, can probe/scan/authenticate
1 constant ds-associated             \ Associated and WPA key handshake ok
2 constant ds-disconnected           \ Disconnected

ds-ready instance value driver-state

: set-driver-state    ( state -- )  to driver-state  ;
: reset-driver-state  ( -- )  ds-ready to driver-state  ;
: process-disconnect  ( -- )
   ds-disconnected set-driver-state  
   reset-key-cache
   false to wep-enabled?
   false to gkey-enabled?
   false to pkey-enabled?
;

\ bss-type values
1 constant bss-type-managed
2 constant bss-type-adhoc
bss-type-managed value bss-type

0 value currate
0 value basic-rate
0 value basic-rate-hw-val
0 value pkt-type
true value basic-rate-erp?

d# 256 buffer: ssid
0 value /ssid
: ssid$  ( -- $ )  ssid /ssid  ;
d# 34 instance buffer: scan-ssid

0 value tx-tkip-iv16           0 value rx-tkip-iv16
0 value tx-tkip-iv32           0 value rx-tkip-iv32
6 constant /pn
/pn buffer: tx-pn              /pn buffer: rx-pn   \ Big endian

0 value atim
d# 11 value channel
d# 80 buffer: wpa-ie            \ WPA IE saved for EAPOL phases
0 value /wpa-ie

external
: wpa-ie$  ( -- adr len )  wpa-ie /wpa-ie  ;
headers

\ Miscellaneous
0 value preamble                \ 0=long, 2=short, 4=auto
0 value auth-mode               \ 0: open; 1: shared key; 2: EAP
h# 401 value cap                \ Capabilities
false value passive-scan?
defer setup-data-series         ' noop to setup-data-series

: currate>bitrate  ( -- rate )  currate 'legacy-rates >br-bitrate @  ;
: bitrate>idx  ( bitrate -- idx )
   0 swap #legacy-rates 0  do             ( hw-val bitrate )
      i 'legacy-rates >br-bitrate @ over =  if
         nip i swap leave
      then
   loop  drop
;
: bitrate>hw-val  ( bitrate -- hw-val )
   bitrate>idx
   'legacy-rates preamble  if  >br-hw-val-short  else  >br-hw-val  then  @
;
: is-common-rate?  ( bitrate -- common? )
   5 /  0 swap                         ( common? rate )
   #rates 0  do
      common-rates i + c@ 7f and over =  if  nip true swap leave  then
   loop  drop
;
: find-fastest-rate  ( adr len -- rateidx )
   0 -rot  bounds  do  i c@ 7f and max  loop    ( rate )
   0 swap                                       ( rateidx rate )
   #rates 0  do  supported-rates i + c@ over =  if  nip i swap leave  then loop
   drop                                         ( rateidx' )
;
: (find-basic-rate)  ( br-flag -- rate )
   0 swap
   #legacy-rates 0  do                ( rate br-flag )
      dup i 'legacy-rates >br-flags @ and  if
         i 'legacy-rates >br-bitrate @ dup is-common-rate?  if
	    currate>bitrate over >=  if
               rot max swap
            else  drop  then
         else  drop  then
      then                            ( rate' br-flag )
   loop
   drop
   ?dup 0=  if
      curchan is-2GHz?  if  band-2GHz  else  band-5GHz  then
      >band-channel @ >br-bitrate @
   then
;
: find-basic-rate  ( -- rate )
   curchan is-5GHz?  if  br-mand-a
   else
      curchan is-b?  if  br-mand-b  else  br-mand-g  then
   then
   (find-basic-rate)
;

external
: set-atim-window  ( n -- )  d# 50 min  to atim  ;
: set-preamble  ( preamble -- )  ( XXX to preamble ) drop  ;
: set-cap  ( cap -- )  to cap  ;
: set-auth-mode  ( amode -- )  to auth-mode  ;
: set-bss-type  ( bssType -- ok? )  to bss-type true  ;
: set-country-info  ( adr len -- )  2drop  ;  \ XXX Country IE, affect regulatory
: set-ssid  ( adr len -- )
   2dup  " mesh" $=  if  true to passive-scan?  then

   h# 32 min scan-ssid pack drop  
;
: supported-rates$  ( -- adr len )  supported-rates #rates  ;
: set-common-rates  ( adr len -- )
   2dup find-fastest-rate to currate
   common-rates #rates erase
   #rates min common-rates swap move
   find-basic-rate to basic-rate
   basic-rate bitrate>hw-val to basic-rate-hw-val
   basic-rate bitrate>idx 'legacy-rates >br-flags @ br-erp-g and to basic-rate-erp?
   setup-data-series
;
: disconnected?  ( -- flag )  driver-state ds-disconnected =  ;

headers
: link-up?  ( -- flag )  driver-state ds-associated =  ;

: null$  ( -- adr len )  " "  ;
: zero$  ( -- adr len )  " "(00 00 00 00 00 00)"  ;
: broadcast-mac$  ( -- adr len )  " "(ff ff ff ff ff ff)"  ;

0 value supplicant-ih
: $call-supplicant  ( ...$ -- ... )  supplicant-ih $call-method  ;
: supplicant-associate   ( -- flag )  " do-associate" $call-supplicant  ;
: supplicant-process-eapol  ( adr len -- )  " process-eapol" $call-supplicant  ;
: .scan  ( adr -- )  " .scan" $call-supplicant  ;
: .ssids  ( adr -- )  " .ssids" $call-supplicant  ;
: rc4  ( data$ key$ -- )  " rc4" $call-supplicant  ;

: invalid-rssi  ( -- rssi )  80  ;
defer rx-rssi         ( -- rssi )         ['] invalid-rssi to rx-rssi
defer ?process-eapol  ( adr len -- )      ['] 2drop to ?process-eapol

d# 24 constant /802.11-data-hdr      \ Basic data frame header len
rx-bufsize constant /packet-buf
0 value packet-buf
0 instance value seq#

: alloc-packet  ( -- )
   packet-buf 0=  if  /packet-buf dma-alloc to packet-buf  then
;
: free-packet  ( -- )
   packet-buf  if
      packet-buf /packet-buf dma-free
      0 to packet-buf
   then
;

true instance value got-data?
true instance value got-response?
0 instance value /respbuf
/packet-buf instance buffer: respbuf
0 instance value /data
0 instance value data

/802.11-data-hdr d# 22 + constant /rx-min  \ MAC header + ethernet header with SNAP

false value HT-mode?

: seq#++  ( -- )  seq# h# 20 +  to seq#  ;  \ The 4 LSBs are the fragment number
: addr4-present?  ( adr -- present? )  le-w@  h# 300 and  h# 300 =  ;
: QoS-present?    ( adr -- present? )  le-w@  h# 88 and  h# 88 =  ;
: HT-present?     ( adr -- present? )  dup QoS-present? swap le-w@ h# 8000 and or  ;

: /802.11n-data-hdr  ( adr -- len )
   /802.11-data-hdr
   over  addr4-present?  if  6 +  then
   swap  QoS-present?    if  HT-mode?  if  6  else  2  then  +  then
;

: snap-header  " "(aa aa 03 00 00 00)"  ;

\ MAC frame format:
\ Frame header
\   2-byte frame control
\   2-byte duration/id
\   6-byte address 1
\   6-byte address 2
\   6-byte address 3
\   2-byte sequence control
\   6-byte address 4
\   2-byte QoS control
\   4-byte HT control
\ 0-7955 bytes frame body
\ 4-byte FCS

\ The low byte of the frame control word is:
\ ssssTTpp
\ pp is protocol version, always 00
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
\ 1101 (d0) Action
\ 1110 (e0) Action No Ack
\ 1111 (f0) Reserved
\ Control subtypes are (other codes are reserved):
\ 0111 (74) Control Wrapper
\ 1000 (84) Block Ack Request
\ 1001 (94) Block Ack
\ 1010 (a4) PS-Poll
\ 1011 (b4) RTS
\ 1100 (c4) CTS
\ 1101 (d4) ACK
\ 1110 (e4) CF End
\ 1111 (f4) CF End + CF ACK
\ Data subtypes are (other codes are reserved):
\ 0000 (08) Data
\ 0001 (18) Data+CF-ACK
\ 0010 (28) Data+CF-Poll
\ 0011 (38) Data+CF-ACK+CF-Poll
\ 0100 (48) Null (no data)
\ 0101 (58) CF-ACK (no data)
\ 0110 (68) CF-Poll (no data),
\ 0111 (78) CF-ACK+CF-Poll (no-data)

\ The upper byte of the frame control word is:
\ bit 7  Order: set to 1 in a non-QoS STA transmits using the StrictlyOrdered service class;
\               set to 1 in a QoS data or management frame, it indicates that the HT Control field exists
\ bit 6  Protected Frame: set if the frame body is encrypted
\ bit 5  More Data: set to indicate to a STA in PS mode that more data are buffered for that STA
\ bit 4  Power Management: set if STA is to be in PS mode with a frame exchange
\ bit 3  Retry: set if the frame is a retransmission
\ bit 2  More Fragment
\ bit 1  From DS
\ bit 0  To DS
\
\ From/TO DS
\  00  All management and control frames, data frames within an IBSS
\  01  Data frames transmitted from a STA in an infrastructure network
\  10  Data frames received for a STA in an infrastructure network
\  11  Data frames on a "wireless bridge"

\ Duration/ID
\   0-7fff    Duration (in us) used to set the NAV (network allocation vector)
\   8000      Contention free transmission, NAV=8000
\   c001-c7d7 AID (BSS associated ID) in PS-Poll frames
\
\ Sequence control
\   ssss.ssss.ssss.ffff

\ QoS control
\   Applicable Frames                        bits 15-0
\   QoS CF-Poll, CF-ACK+Poll by HC           llll.llll.raae.tid
\   QoS Data+CF-Poll, Data+CF-ACK+Poll by HC llll.llll.paae.tid
\   QoS Data, Data+CF-ACK by HC              bbbb.bbbb.paae.tid
\   QoS Null by HC                           bbbb.bbbb.raae.tid
\   QoS Data, Data+CF-ACK by non-AP STA      dddd.dddd.paa0.tid
\                                            qqqq.qqqq.paa1.tid
\   QoS Null by non-AP STA                   dddd.dddd.raa0.tid
\                                            qqqq.qqqq.raa1.tid
\
\ tid: 0-7 user priority; 8-f transmit stream id
\ e: EOSP (end of service period)
\ aa: ACK policy
\     00 normal or implicit block ACK
\     01 no ACK
\     10 no explicit or PSMP ack (power save mult poll)
\     11 block ACK
\ r: reserved
\ p: A-MSDU present
\ l's: TXOP limit
\ b's: AP PS buffer state
\         llll.ppsr
\      llll:  total PS buffer size in units of 4096 bytes
\      pp:    AC of the highest priority traffic buffered at the AP
\      s:     buffered state, set if llll and pp are valid
\ d's: TXOP duration requested
\ q's: Queue size in units of 256 bytes

\ HT control: present for Control Wrapper Frame and Order=1 for Qos frames
\   bit 31    RDG/More PPDU, depends on RD initiator/responder
\   bit 30    AC constraint, 0=response may contain data frames from any TID
\             1=response may contain data frames only rom the same AC
\   bit 24    NDP Announcement, 1=null data packet will follow
\   bit 22:23 CSI/Steering
\             0=no feedback required, 1=CSI, 2=noncompressed beamforming, 3=compressed beamforming
\   bit 18:19 Calibration sequence
\   bit 16:17 Calibration position
\             0=not a calibration frame, 1=start, 2=sounding response, 3=complete
\   bit 0:15  Link Adaptation Control
\             bit 9:15 MFB/ASELC, 127=no feedback, if MAI<>e, recommended MFB
\                      if MAI=e, dddddccc
\                        ccc command                                        ddddd
\                         0  Transmit Antenna Selection Sounding Indication  0-15
\                         1  Transmit Antenna Selection Sounding Request     0
\                            Transmit ASEL Sounding Resumption               1-15
\                         2  Receive Antenna Selection Sounding Indication   0-15
\                         3  Receive Antenna Selection Sounding Request      0-15
\                         4  Sounding Label                                  0-15
\                         5  No feedback due to ASEL training failure        0-15
\                         6  TXASSI-request feedback of explicit CSI         0-15
\             bit 6:8  MFSI, MSI value, 7=unsolicited MFB
\             bit 2:5  MAI, e=ASELI, iiiq: MRQ sequence id (MSI) & MCS request
\             bit 1    TRQ Training request

\ =================================================================================
\ Process received MAC frames
\ =================================================================================

struct
   /n field >dadr
   /n field >dlen
constant /qentry
0 instance value qhead        \ Retrieve from qhead
0 instance value qend         \ Insert to qend
0 instance value queue
d# 128 constant /queue

: qend++   ( -- )
   qend 1+ dup /queue =  if  drop 0 then
   dup qhead =  if  ." WARNING: queue overflow" cr drop  else  to qend  then
;
: qhead++  ( -- )  qhead 1+ dup /queue =  if  drop 0  then  to qhead  ;
: queue-adr  ( idx -- adr )  /qentry * queue +  ;
: qhead-adr  ( -- adr )  qhead queue-adr  ;
: qend-adr   ( -- adr )  qend queue-adr  ;
: init-queue  ( -- )
   queue 0=  if
      /qentry /queue * alloc-mem  to queue
   then
   0 to qhead  0 to qend
;
: enque  ( adr len -- )
   \ Remove snap header
   over d# 14 + snap-header comp 0=  if       ( adr len )
      8 - dup alloc-mem dup qend-adr >dadr !  ( adr len' qadr )
      over qend-adr >dlen !                   ( adr len qadr )
      rot 2dup d# 12 move                     ( len qadr adr ) \ Copy MAC addresses
      d# 20 + -rot swap d# 12 /string         ( adr qadr len )
   else
      dup alloc-mem dup qend-adr >dadr !      ( adr len qadr )
      over qend-adr >dlen ! swap              ( adr qadr len )
   then
   move                                       \ Copy the rest
   qend++
;
: deque  ( adr len -- actual )
   qhead qend =  if  2drop 0  exit  then
   qhead-adr >dadr @                        ( adr len qadr )
   qhead-adr >dlen @                        ( adr len qadr qlen )
   rot min rot swap                         ( qadr adr actual )
   dup >r  move                             ( qadr qlen )  ( R: actual )
   free-mem  r>                             ( actual )
;

: skip-802.11n-data-hdr  ( adr len -- adr' len' )
   \ Go to the payload, skipping the MAC frame header
   over /802.11n-data-hdr  /string          ( adr' len' )
;

: skip-802.11n-mgr-hdr  ( adr len -- adr' len' )
   \ Go to the payload, skipping the MAC frame header
   over  HT-present?   if  4  else  0  then
   /802.11-data-hdr +  /string         ( adr' len' )
;

0 value rs-rssi
: compute-avgbrssi  ( -- )
   rx-rssi sign-c dup  to rs-rssi
   -80 <>  if
      rs-rssi d# -20 >=  if
         rs-rssi 7 <<
         last-rssi dummy-rssi <>  if
            last-rssi 9 * + d# 10 /
         then  to last-rssi
      then
   then
   last-rssi dummy-rssi =  if
      rs-rssi
   else
      last-rssi 7 >>  last-rssi 7f and 40 >=  if  1+  then
   then  0 max 
   dup to rs-rssi to avgbrssi
;
: ?compute-avgbrssi  ( adr -- )
   d# 16 + target-mac$ comp 0=  if  compute-avgbrssi  then
;
: (process-mgt)  ( adr len -- )
   drop dup >r c@  case
      80  of  r@ ?compute-avgbrssi  endof
      90  of  " ATIM" vtype  endof
      a0  of  " Disassociated"   vtype  process-disconnect  endof
      c0  of  " Deauthenticated" vtype  process-disconnect  endof
      d0  of  " ACTION" vtype  endof
   endcase
   r> drop
;

0 instance value resp-type
: process-mgt  ( adr len -- )
   over c@  resp-type =  to got-response?
   2dup (process-mgt)
   got-response?  if
      dup to /respbuf
      respbuf swap move
   else
      2drop
   then
;

: process-ctl  ( adr len -- )  " Got a control frame" vtype vcdump  ;

\ XXX For TKIP and AES, should check duplicate sequence number
: 802.11n>ethernet  ( adr len -- adr' len' )
   over >r                              ( adr len )  ( R: adr )
   \ Skip 802.11n header
   r@ /802.11n-data-hdr                 ( adr len slen )  ( R: adr )
   r@ le-w@ 4000 and  if                \ Skip IV or CCMP header
      key-wep?  if  4  else  8  then  +
   then
   \ Skip snap header, if any
   dup r@ + snap-header comp 0=  if  6 +  then  ( adr len slen' )  ( R: adr )
   \ Recreate ethernet header
   d# 12 - /string                      ( adr' len' )  ( R: adr )
   \ Move source mac
   r@ d# 16 + 2 pick /mac-adr + /mac-adr move   ( adr' len' )  ( R: adr )
   \ Move destination mac
   r>     4 + 2 pick            /mac-adr move   ( adr' len' )
;

: (process-data)  ( adr len -- )
   802.11n>ethernet  to /data  to data      ( )
   true to got-data?
   data d# 12 + be-w@  h# 888e =  if  \ Pass EAPOL messages to supplicant
      data /data ?process-eapol
   then

;
: do-process-eapol  ( adr len -- )  false to got-data?  supplicant-process-eapol  ;

: process-subframe  ( adr len -- )
   over d# 12 + le-w@  min            ( adr len' )
   swap d# 14 + swap                  ( adr' len )
   enque                              ( )
;
: process-a-msdu  ( adr len -- )
   \ A-MSDU subframe 1, A-MSDU subframe 2, ...
   \ A-MSDU subframe header: 6-byte DA, 6-byte SA, 2-byte length
   \ 0-2304 bytes of MSDU, 0-3 padding bytes

   \ XXX unpack, return first packet, queue the rest
   dup /rx-min <  if  exit  then      \ Invalid data packet: too small
   skip-802.11n-data-hdr              \ Skip to the subframes
                                      ( adr len )
   begin  ?dup  while                 ( adr len )
      2dup  process-subframe          ( adr len )
      over d# 12 + le-w@  4 round-up d# 14 +  /string  ( adr' len' )
      0 min                           ( adr len )
   repeat  drop
;
\ XXX Need to be able to process QoS data...
: process-data  ( adr len -- )
   over le-w@ h# f0 and 0=  if
      (process-data)
   else
      2drop
   then
;

\ XXX Take care of multicast packets.
: rx-for-me?  ( adr -- mine? )
   4 + dup broadcast-mac$ comp 0=  if
      d# 12 + mac-adr$ comp            \ Filter out msg I send
      dup  if  ascii b  else  ascii x  then  vemit
      exit
   then
   dup c@ 1 and  if  ascii m vemit drop false  exit  then
   mac-adr$ comp 0= dup  if  ascii u  else  ascii o  then  vemit
;
: process-rx  ( adr len -- )
   false to got-data?
   false to got-response?
   over rx-for-me? 0=  if  2drop exit  then
   over le-w@ h# c and  case          \ Frame control type
     0  of  process-mgt   endof       \ Management
     4  of  process-ctl   endof       \ Control
     8  of  process-data  endof       \ Data
     ( otherwise )  debug-me nip nip
   endcase
;

\ =================================================================================
\ Create MAC frames
\ =================================================================================

0 value x                       \ Temporary variables to assist frame creation
0 value /x

: set-x  ( offset adr -- )  to x  to /x  ;
: 'x   ( -- adr )  x /x +  ;
: +x   ( n -- )  /x + to /x  ;
: +x$  ( $ -- )  'x swap dup +x move  ;
: +xl  ( n -- )  'x le-l!  /l +x  ;
: +xw  ( n -- )  'x le-w!  /w +x  ;
: +xb  ( n -- )  'x c!     /c +x  ;
: +xbl ( n -- )  'x be-l!  /l +x  ;
: +xerase  ( n -- )  'x over erase  +x  ;

: set-802.11-data-hdr  ( adr3$ adr2$ adr1$ duration frame-type -- )
   0 packet-buf set-x
   dup to pkt-type
   +xw                             ( adr3$ adr2$ adr1$ duration )
   +xw                             ( adr3$ adr2$ adr1$ )
   +x$                             ( adr3$ adr2$ )
   +x$                             ( adr3$ )
   +x$                             ( )
   seq# +xw seq#++                 ( )
   resp-wait-short to resp-wait
;

: set-802.11n-data-hdr  ( HT QoS adr4$ adr3$ adr2$ adr1$ duration frame-type -- )
   set-802.11-data-hdr                           ( HT QoS adr4$ )
   x addr4-present?  if  +x$  else  2drop  then  ( HT QoS )
   x QoS-present?    if  +xw  else  drop   then  ( HT )
   HT-mode?          if  +xw  else  drop   then  ( )
;

: set-802.11n-mgr-hdr  ( BSSID$ DA$ duration frame-type -- )
   0 packet-buf set-x
   dup to pkt-type
   ( frame-type ) +xw           \ Frame control
   ( duration )   +xw           \ Duration
   ( DA$ )        +x$           \ Destination MAC
   mac-adr$       +x$           \ Source MAC
   ( BSSID$ )     +x$           \ BSSID
   seq# +xw  seq#++             \ Sequence #
   resp-wait-long to resp-wait
   
;

\ Time in us for one ACK and one SIFS interval; management frame only
: nav  ( -- duration )
   curchan is-2GHz?  if
      preamble  if  d# 218  else  d# 314  then
   else
      d# 55                   \ 5GHz band
   then
;

\ Time in us for one ACK and one SIFS interval; unicast data frame only
: data-nav  ( len -- duration )
   4 +  basic-rate swap                          ( rate len' )
   curchan is-5GHz?  basic-rate-erp? or  if
      8 * d# 22 + d# 10 * swap 2 << /mod swap  if  1+  then  2 << ( duration )
      d# 36 +                                    ( duration' )
   else
      d# 80 * swap /mod swap  if  1+  then       ( duration )
      preamble  if  d# 106  else  d# 202  then + ( duration' )
   then
;

: get-iv  ( -- iv )
   804c reg@                  \ Timestamp
   dup ff00 and ff00 =  if    ( iv )
      dup d# 16 >> ff and     ( iv iv.hi )
      dup 3 >=  swap /wep1 3 + <  and  if  100 +  then
   then                       ( iv' )

   8 << wep-idx 6 << or       ( iv' )  \ In big endian
;
d# 16 buffer: rc4key
: make-rc4key  ( iv.lo iv.mi iv.hi -- )
   rc4key d# 16 erase
   rc4key c!  rc4key 1+ c!  rc4key 2 + c!
   wep-idx wep-key$ rc4key 3 + swap move
;
: compute-icv  ( adr len -- icv )  " $crc" evaluate  ;
: encrypt-wep  ( adr len -- )  rc4key /wep1 3 + rc4  ;
0 value au-dt-adr
0 value /au-dt
: make-authenticate-req  ( [challenge$] seq target-mac$ -- adr len )
   over target-mac$ move
   2dup nav
   5 pick 3 =  if h# 40b0  else  h# b0  then  set-802.11n-mgr-hdr

   dup 1 =  if
      auth-mode +xw                     \ Authentication algorithm
      ( seq ) +xw                       \ Authentication sequence number
      0 +xw                             \ Status code
   else
      get-iv lbsplit 3dup make-rc4key   \ Generate iv and rc4key
      +xb +xb +xb +xb                   \ IV
      'x to au-dt-adr  /x to /au-dt     \ Save data adr/len to be encrypted
      auth-mode +xw                     ( challenge$ seq )
      ( seq ) +xw                       \ Authentication sequence number
      0 +xw                             \ Status code
      d# 16 +xb dup +xb +x$             \ Challenge text
      /x /au-dt - to /au-dt             \ Update data len
      au-dt-adr /au-dt compute-icv +xl  \ ICV
      au-dt-adr /au-dt 4 + encrypt-wep  \ Encrypt data + ICV
   then
   x /x                         ( adr len )
;

: make-deauthenticate-req  ( target-mac$ -- adr len )
   2dup nav h# c0 set-802.11n-mgr-hdr
   3 +xw                        \ Reason code: station is leaving
   x /x
;

: make-disassociate-req  ( target-mac$ -- adr len )
   2dup nav h# a0 set-802.11n-mgr-hdr
   3 +xw                        \ Reason code: station is leaving
   x /x
;

: save-associate-params  ( ch ssid$ target-mac$ -- ch ssid$ target-mac$ )
   over target-mac$ move
   2over dup to /ssid
   ssid swap move
   4 pick to channel
;
: save-wpa-ie  ( boffset eoffset -- )
   over - to /wpa-ie            \ Len of wpa-ie
   x + wpa-ie /wpa-ie move      \ Copy IE
;
: moui  ( ct -- )  ct-tkip =  if  moui-tkip  else  moui-aes  then  ;
: oui   ( ct -- )  ct-tkip =  if  oui-tkip   else  oui-aes   then  ;

: make-associate-req  ( ch ssid$ target-mac$ -- adr len )
   save-associate-params
   2dup nav 0 set-802.11n-mgr-hdr

   cap    +xw                           \ Capability info: ESS, short slot, WEP
   d# 300 +xw                           \ Listen interval

   \ SSID
   0   +xb                              \ element ID = SSID 
   dup +xb                              \ len
   ( ssid$ ) +x$                        \ SSID

   \ DS param
   3      +xb                           \ element ID = DS param set
   1      +xb                           \ len
   ( ch ) +xb                           \ channel

   \ Common supported rates
   1      +xb                           \ element ID = rates
   #rates 8 min +xb                     \ len
   common-rates #rates 8 min +x$        \ common supported data rates

   \ Extended common supported rates
   #rates 8 >  if
      d# 50       +xb                   \ element ID = Extended rates
      #rates 8 -  +xb                   \ len
      common-rates 8 + #rates 8 - +x$   \ common supported data rates
   then

   \ RSN (WPA2)
   ktype kt-wpa2 =  if
      /x                                \ Save beginning offset
      d# 48  +xb                        \ element ID = RSN
      d# 20  +xb                        \ len
      1      +xw                        \ version
      ctype-g oui +xbl                  \ group cipher suite
      1      +xw                        \ count of pairwise cipher suite
      ctype-p oui +xbl                  \ pairwise cipher suite
      1      +xw                        \ count of authentication suite
      aoui   +xbl                       \ authentication suite
      0      +xw                        \ RSN capabilities
      /x save-wpa-ie                    \ Save IE in wpa-ie
   then

   \ WPA param
   ktype kt-wpa =  if
      /x                                \ Save beginning offset
      d# 221  +xb                       \ element ID = WPA
      d# 22   +xb                       \ len
      wpa-tag +xbl                      \ WPA-specific tag
      1 +xw                             \ version
      ctype-g moui +xbl                 \ group cipher suite
      1       +xw                       \ count of pairwise cipher suite
      ctype-p moui +xbl                 \ pairwise cipher suite
      1       +xw                       \ count of authentication suite
      amoui   +xbl                      \ authentication suite
      /x save-wpa-ie                    \ Save IE in wpa-ie
   then

   x /x
;

: make-probe-req  ( ssid$ target-mac$ -- )
   2dup 0 h# 40 set-802.11n-mgr-hdr

   0 +xb dup +xb ( ssid$ ) +x$
   1 +xb #rates 8 min dup +xb supported-rates swap  +x$
   #rates 8 >  if
      d# 50 +xb #rates 8 - dup +xb supported-rates over + swap  +x$
   then

   x /x
;

: +wep-iv  ( -- )  get-iv lbsplit +xb +xb +xb +xb  ;
: tx-tkip-iv++  ( -- )
   tx-tkip-iv16 1+ dup to tx-tkip-iv16
   0=  if  tx-tkip-iv32 1+ to tx-tkip-iv32  then
;
: +tkip-iv   ( -- )
   tx-tkip-iv++  
   tx-tkip-iv16 wbsplit dup +xb 20 or 7f and +xb +xb 20 +xb
   tx-tkip-iv32 +xl
;
: tx-pn++  ( -- )
   tx-pn 2 + be-l@ 1+ dup tx-pn 2 + be-l!
   0=  if  tx-pn be-w@ 1+ tx-pn be-w!  then
;
: +ccmp-hdr  ( -- )
   tx-pn++
   tx-pn 4 + be-w@ +xw
   0 +xb
   20 +xb
   tx-pn     be-l@ +xl
;
: protect-data?  ( -- flag )  key-enabled? ?dup 0=  if  key-wpax?  then  ;
\ XXX Right now, support only managed mode; adhoc in the future
: make-data-frame  ( adr len -- adr' len' )
   over /mac-adr mac-adr$ target-mac$ d# 10 data-nav
   108  key-enabled?  if  4000 or  then  set-802.11-data-hdr
   key-enabled?  if
      key-wep?  if
         +wep-iv
      else
         pkey-tkip?  if  +tkip-iv  else  +ccmp-hdr  then
      then
   then
   snap-header +x$
   ( adr len ) d# 12 /string +x$
   x /x
;

\ =================================================================================
\ Create "libertas" like scan results to match supplicant package expectation:
\    - 2 bytes of ??
\    - 1 byte of # of APs scanned
\    - AP[#AP]
\
\ Each AP[] has:
\    - 2 bytes of length (does not include these 2 bytes)
\    - 6 bytes AP ethernet address
\    - 1 byte of RSSI
\    - frame body of probe request or beacon
\
\ Assumption: respbuf /respbuf has the data to be put here
\ =================================================================================

0 instance value scanbuf             \ Save original buffer address
0 instance value /scanbuf            \ Save original buffer size
0 value /tsbuf                       \ Current size of data in scanbuf
: scanbuf-have-room?  ( -- ok? )
   /respbuf respbuf /802.11n-data-hdr - 9 +  \ Space needed
   /scanbuf /tsbuf -                         \ Space available
   <=                         ( ok? )
;
: add-scan-response  ( -- )
   scanbuf-have-room? 0=  if  ." Run out of scan buffer space" cr exit  then
   scanbuf 2 + c@ 1+ scanbuf 2 + c!  \ Increment #APs
   /tsbuf scanbuf set-x              \ Get to the next buffer location for the new AP
   respbuf /respbuf skip-802.11n-mgr-hdr  ( rbuf' rlen' )
   dup 7 + +xw                       \ length of AP data
   respbuf d# 10 + /mac-adr +x$      \ AP mac address
   rx-rssi +xb                       \ RSSI
   +x$                               \ AP data
   /x to /tsbuf
;
: start-scan-response  ( target-adr target-len -- )
   to /scanbuf  to scanbuf
   0 scanbuf set-x
   0   +xw                  \ 2 unknown bytes
   0   +xb                  \ #APs
   /x to /tsbuf
;
: restart-scan-response  ( -- )  scanbuf /scanbuf start-scan-response  ;
: get-scan-actual  ( -- actual )  /tsbuf  ;

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

