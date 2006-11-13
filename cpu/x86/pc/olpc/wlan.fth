\ See license at end of file

\ Command header:  w.cmd  w.size  w.seq#  w.result

0 instance value seq#

: start-cmd  ( -- )  cmdbuf 4 wa+ to cmdp  ;  \ Leave space for header
: cmdb,  ( b -- )  cmdp c!  cmdp 1+ to cmdp  ;
: cmdw,  ( b -- )  cmdp le-w!  cmdp 2+ to cmdp  ;
: cmd$,  ( adr len -- )  tuck  cmdp swap move  cmdp + to cmdp  ;

0 value rspbufp
0 value rspbufend
: rsp-b  ( -- b )
   rspbufend rspbufp u<=  if  0 exit  then
   rspbufp c@
   rspbufp 1+ to rspbufp
;
: rsp-w  ( -- w )  rsp-b rsp-b bwjoin  ;

\ Response header:  w.cmd  w.size  w.seq#  w.result
: rsp-init  ( -- )
   rspbuf to rspbufp
   rspbuf 8 + to rspbufend
   rsp-w  drop   ( )       \ Could check the command
   rsp-w         ( size )
   rsp-w seq# <> abort" Bad Sequence #"   ( size )
   rsp-w  abort" Failure Response"  ( size )
   rspbufp +  to rspbufend
   seq# 1+ to seq#
;

: param-w@  ( offset -- w )  rspbuf /cmd-hdr +  +  le-w@  ;

: handle-event?  ( -- cmd-response? )
   XXX implement me
   bulk-in or something
   check the type and handle non-responses autonomously
;

: get-response  ( -- )
   begin  handle-event?  until
   rsp-init
;

: prepare-header  ( cmd# -- )
   cmdbuf le-w!              ( )   \ Set command number
   cmdp cmdbuf -  8 -        ( payload-len )
   ( len ) cmdbuf 1 wa+ le-w!      \ Set length
   seq#    cmdbuf 2 wa+ le-w!      \ Set sequence number
   0       cmdbuf 3 wa+ le-w!      \ Zero result field
;
: send-cmd  ( cmd# -- )
   prepare-header
   cmdp cmdbuf over -  (do-send-cmd)   \ Bulk out or something
   get-response                        \ Bulk in or something
;


0 value channel-mask
d# 14 constant channel#-max

: add-scan-channel  ( channel# -- )
   \ This is struct ChanScanParamSet
   0 cmdb,      \ 0: HostCmd_SCAN_RADIO_TYPE_BG
   cmdb,        \ ChanNumber
   0 cmdb,      \ 0x01 bit: PassiveScan, 0x02 bit: DisableChanFilt
   d# 100 cmdb, \ MinScanTime
   d# 100 cmdb, \ MaxScanTime
;

: add-tlvs  ( chan ... #chans -- )                  \ See pScanCfg->tlvBuffer
   h# 101 cmdw,          \ TLV_TYPE_CHANLIST
   dup 5 * cmdw,         \ Length; 5 is sizeof(struct ChanScanParamSet)
   0  ?do  add-scan-channel  then
;

\ Scan cmd response:
\ Standard 4-short header
\ w.bsssize
\ b.#bssdescs
\ Bss descriptors
\ TLV descriptors

d# 5000 instance buffer: scan-results  \ XXX fine tune this number
0 value scan-bufp
0 value #bss

: init-scan-results  ( -- )
   scan-results to scan-bufp
   0 to #bss
;
: append-scan-results  ( -- )
   \ send-cmd has already parsed the standard response header
   rsp-w  rsp-b     ( bsssize #bss-entries )
   #bss +  to #bss  ( bsssize )

   rspbufp  scan-bufp  2 pick  move  ( bsssize )
   scan-bufp + to scan-bufp          ( )

   \ We don't need to parse the TLVs because the only expected
   \ one is a timestamp, which we don't care about
;

\ Scan cmd: 0: b.BSSType, 1: barray.BSSID[6]  7: b.TlvBuffer

: scan-some  ( chan ... #chans  -- error? )
   start-cmd
   1 cmdb,                 \ 1: Infrastructure  2: Ad Hoc  3: Either
   6 0 do  0 cmdb,  loop   \ No BSSID filter for now
   add-tlvs
   6 send-cmd   
   append-scan-results  ( error? )
;

: scan  ( -- )
   init-scan-results
   0                                    ( #chans )
   channel#-max  0  ?do                 ( #chans )
      1 i lshift  channel-mask and  if  ( chans.. #chans )
         i swap 1+                      ( chans..' #chans' )
         dup 4 =  if                    ( chans.. #chans )
            scan-some  0                ( 0chans )
         then                           ( chans.. #chans )
      then                              ( chans.. #chans )
   loop                                 ( chans.. #chans )
   ?dup  if  scan-some  then            ( )

   \ At the end of this process, #bss is set to the number of BSS
   \ entries that the scan found, and the memory from scan-results
   \ to scan-bufp contains those (variable-length) entries
;

\  CapInfo bits:
\   0: Ess          1: IBss            2: CfPollable     3: CfPollRqst
\   4: Privacy      5: ShortPreamble   6: Pbcc           7: ChanAgility
\   8: SpectrumMgmt 9: Reserved       10: ShortSlotTime 11: Apsd
\  12: Reserved    13: DSSSOFDM       14: Reserved      15: Reserved

0 value preamble-type  \ 5: auto  3: short  1: long

: start-get  ( -- )  start-cmd  0 cmdw,  ;
: start-set  ( -- )  start-cmd  1 cmdw,  ;
: radio-on  ( preamble-type -- )  start-set  cmdw,   h# 1c send-cmd  ;

: tlv,  ( adr len type -- )  cmdw,  dup cmdw,  cmd$,  ;
  
0 value wpa-type  \ d# 221 for wpa, d# 48 for wpa2
0 value wpa-key
0 value /wpa-key
0 value cap-info  \ 16-bit mask

d# 14 constant #rates
#rates buffer: card-rates
#rates buffer: BSSDesc-supported-rates  \ Should be name ap-rates

\ struct HostCmd_DS_802_11_ASSOCIATE {
\     0: PeerStaAddr[6 bytes], 6.w: CapInfo, 8.w: ListenInterval, a.w BcnPeriod, c.b: DtimPeriod
\ }
: prepare-associate  ( -- )
   start-cmd

   mac-address 6 cmd$,
   cap-info cmdw,            \ Capability Info
   listen-interval cmdw,     \ Listen interval
   0 cmdw,                   \ BcnPeriod
   0 cmdb,                   \ DtimPeriod

   \ Offset is now 0xd
   ssid /ssid 0 tlv,  \ TLV_TYPE_SSID
   phy  1  3 tlv,     \ TLV_TYPE_PHY_DS  data is "CurrentChan"

   \ struct CfParamSet: b.CfpCnt b.CfpPeriod w.CfpMaxDuration w.CfpDurationRemaining
   cfparams 6 4 tlv,  \ TLV_TYPE_CF

   BSSDesc-supported-rates #rates 1 tlv, \ TLV_TYPE_RATES 
   BSSDesc-supported-rates  card-rates  common-rates?  0= abort" No common rates"

   wpa? wpa2? or  if  wpa-key /wpa-key wpa-type tlv,  then
;

0 instance value max-rss
0 instance value chan-ptr

\ Find the scan buffer entry for the open network with the
\ strongest signal.
: choose-ap  ( -- )
   0 to max-rss
   0 to chan-ptr
   scan-results  ( adr )
   #bss 0  ?do   ( bss-desc-adr )
      \ Looking for CapInfo values with privacy==0 and IBss=1
      dup d# 19 le-w@   h# 12 and  2 =  if  \ 19 is CapInfo offset
         \ Is this one stronger?
         dup 8 + c@  dup max-rss >  if   ( adr rss )
            to max-rss  dup to chan-ptr  ( adr )
         else                            ( adr rss )
            drop                         ( adr )
         then                            ( adr )
      then                               ( adr )
      dup le-w@ + /w -                   ( bss-desc-adr' )
   loop                                  ( adr )
   drop
   chan-ptr 0= abort" No suitable networks found"
;

: associate  ( -- error? )
   preamble-type  radio-on

   prepare-associate

   h# 50 send-cmd  \ The return code is h# 8012; don't know why

   \ response: Generic cmd hdr (4 shorts),then
   \ 0:w.CapInfo 2:w.StatusCode 4:w.AId 6:b.IEBuffer

   rsp-w drop  rsp-w  \ Nonzero StatusCode is error
;

\ struct FWData:  l.DnldCmd l.BaseAddr l.DataLength l.CRC l.seq# bytes[600]
\                 -------- fwheader ---------------------        ---data---
d# 620 buffer: fwbuf
4 /w* constant /fw-header

: handle-fw-response  ( adr len -- adr' done? )
   response-buf response-buf-phys /response-buf
   bulk-in-pipe#  /bulk-in-pipe  bulk-in  if  ( adr len rsp-len )
      2drop false exit                        ( adr' done? )
   then                                       ( adr len rsp-len )

   drop  response-buf le-l@  if            ( adr len )  \ CRC error
      drop  false  exit                    ( adr done? )
   then                                    ( adr len )

   over le-l@  4 =  >r               ( adr len r: done? )
   +                                 ( adr' )
   seq# 1+ to seq#                   ( adr )
   r>                                ( adr done? )
;
: load-firmware  ( -- )
   0 to seq#
   firmware-adr        ( adr )
   begin               ( adr )
      dup fwbuf /fw-header move            ( adr )
      seq# fwbuf /fw-header + le-l!        ( adr )
      dup 2 la+ le-l@                      ( adr len )
      2dup  fwbuf /fw-header + la1+  swap  move  ( adr len )
      /fw-header + la1+                    ( adr len' )
      fwbuf fwbuf-phys  2 pick  bulk-out-pipe# /bulk-out-pipe bulk-out  ( adr len error )
      abort" Bulk-out failed"              ( adr len )
      handle-fw-response                   ( adr done? )
   until                                   ( adr )
   drop                                    ( )

   d# 200 ms  \ Give the firmware time to come alive
;

: open  ( -- flag )
   load-firmware
   set-mac-filter
   get-data-rates
   scan
   choose-ap
   associate
   true
;

\ The rest is just commentary - capsule summaries of the various data structures
\ that the device uses.
0 [if]
Scan response:

Common response fields, then
w.bsslen  (number of bytes in bss descriptor list)
b.#bss_descriptors
N bss_descriptors as below (total len bsslen)
tlvs as below


BSS descriptors:  I'm not sure about this...

0: w.Len(not_counting_this_short)
2: 6.macaddr
8: b.rss
9: 8.timestamp
d# 17: w.beacon_interval
d# 19: w.capinfo   (a bit therein is for WEP, another for infra/adhoc)
taglist: { b.element_id b.element_len n.data }
    element_ids are
    0 SSID            string (max32)

    1 SUPPORTED_RATES byte_array (variable length, element_len bytes)

    133 EXTRA_IE        no_data

    2 FH_PARAM_SET    struct IEEEtypes_FhParamSet
       presence implies that network type is Wlan802_11FH
       frequency hopping - w.dwelltime b.hopset b.hoppattern b.hopindex

    3 DS_PARAM_SET    struct IEEEtypes_DsParamSet  b.CurrentChan is all
       presence implies that network type is Wlan802_11DS

    4 CF_PARAM_SET    struct IEEEtypes_CfParamSet
       b.cfpCnt  b.cfpPeriod w.cfpMaxDuration w.CfpDurationRemaining

    6 IBSS_PARAM_SET  struct IEEEtypes_IbssParamSet just w.AtimWindow
       
    7 COUNTRY_INFO    contains b.countrycode, b.len, variable length <= 254

    50 EXTENDED_SUPPORTED_RATES  bytes
       tacked onto the end of SUPPORTED_RATES

    221 WPA_IE == VENDOR_SPECIFIC_221  bytes  stored at wpa_supplicant->Wpa_ie

    48 WPA2_IE         bytes  stored at wpa2_supplicant->Wpa_ie

    5 TIM             ignored

    
    16 CHALLENGE_TEXT  ignored

TLV entry:

w.type
w.len
data

types:

0 TLV_TYPE_SSID    Used by associate (ssid)         Used by setup_scan_config for filtered scan
   data: mac_address[6 bytes]
1 TLV_TYPE_RATES   Used by associate (data rates)
   data: up to 14 rate bytes
2 TLV_TYPE_PHY_FH
3 TLV_TYPE_PHY_DS  Used by associate (channel)
   data: current_channel (1 byte)
4 TLV_TYPE_CF      Used by associate (cnt, period, maxduration, durremaining)
   data:   b.cnt, b.period, w.maxduration, w.durremaining
6 TLV_TYPE_IBSS
7 TLV_TYPE_DOMAIN  Used by 11d
h# 21 TLV_TYPE_POWER_CAPABILITY
h# 100 TLV_TYPE_KEY_MATERIAL  used by key_material (for security)
h# 101 TLV_TYPE_CHANLIST      used by wlan_scan_channel_list
   data: 
     ChanScanParamSet:  b.RadioType  b.ChanNumber  b.ChanScanMode  b.MinScanTime  b.MaxScanTime
     ChanScanMode bits: 0x01 PassiveScan  0x02 DisableChanFilt
     RadioType is 0 for HostCmd_SCAN_RADIO_TYPE_BG
     ChanScanMode is 0 for active
     Min and Max are both 100 for active
h# 102 TLV_TYPE_NUMPROBES     used by setup_scan_config for limited number of probes
   data: w.NumProbes
h# 104 TLV_TYPE_RSSI_LOW
h# 105 TLV_TYPE_SNR_LOW
h# 106 TLV_TYPE_FAILCOUNT
h# 107 TLV_TYPE_BCNMISS
h# 108 TLV_TYPE_LED_GPIO     Used by ioctl
h# 109 TLV_TYPE_LEDBEHAVIOR
h# 110 TLV_TYPE_PASSTHROUGH
h# 111 TLV_TYPE_REASSOCAP
h# 112 TLV_TYPE_POWER_TBL_2_4GHZ
h# 113 TLV_TYPE_POWER_TBL_5GHZ
h# 114 TLV_TYPE_BCASTPROBE
h# 115 TLV_TYPE_NUMSSID_PROBE
h# 116 TLV_TYPE_WMMQSTATUS
h# 117 TLV_TYPE_CRYPTO_DATA
h# 118 TLV_TYPE_WILDCARDSSID
h# 119 TLV_TYPE_TSFTIMESTAMP   This is the only one the response parser code looks for
h# 122 TLV_TYPE_RSSI_HIGH
h# 123 TLV_TYPE_SNR_HIGH

ChanScanParamSet:  b.RadioType  b.ChanNumber  b.ChanScanMode  b.MinScanTime  b.MaxScanTime
  ChanScanMode bits: 0x01 PassiveScan  0x02 DisableChanFilt
[then]
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
