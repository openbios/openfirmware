purpose: ATH9K global variables
\ See license at end of file

headers
hex

\ Global variables
0 value macVersion
0 value macRev
0 value phyRev

0 value WARegVal            \ AR_WA register value
1000.0004 value misc-mode   \ AR_PCU_MISC register value
0 value ent-mode            \ Value of reg 40d8, enterprise mode

\ opmode values
1 constant IFTYPE_ADHOC
2 constant IFTYPE_STATION
3 constant IFTYPE_AP
6 constant IFTYPE_MONITOR
7 constant IFTYPE_MESH_POINT

IFTYPE_STATION value opmode
: ap-mode?  ( -- AP? )  opmode IFTYPE_AP =  ;

\ (d# 3840 + 4 + (3 + 1 + 4)) / 2 + /rx-stat
d# 1926 d# 12 + value rx-bufsize

\ ieee80211_rate
struct
   /n field >br-bitrate
   /n field >br-hw-val
   /n field >br-hw-val-short
   /n field >br-flags
constant /rates

\ >br-flags bit definitions
01 constant br-spream
02 constant br-mand-a
04 constant br-mand-b
08 constant br-mand-g
10 constant br-erp-g

create legacy-rates
here
   d#  10 , 1b ,  0 , 0c ,  \ CCK 1MB
   d#  20 , 1a , 1e , 09 ,  \ CCK 2MB
   d#  55 , 19 , 1d , 09 ,  \ CCK 5.5MB
   d# 110 , 18 , 1c , 09 ,  \ CCK 11MB
   d#  60 , 0b ,  0 , 19 ,  \ OFDM 6MB
   d#  90 , 0f ,  0 , 10 ,  \ OFDM 9MB
   d# 120 , 0a ,  0 , 1b ,  \ OFDM 12MB
   d# 180 , 0e ,  0 , 10 ,  \ OFDM 18MB
   d# 240 , 09 ,  0 , 1b ,  \ OFDM 24MB
   d# 360 , 0d ,  0 , 10 ,  \ OFDM 36MB
   d# 480 , 08 ,  0 , 10 ,  \ OFDM 48MB
   d# 540 , 0c ,  0 , 10 ,  \ OFDM 54MB
here swap - /rates / constant #legacy-rates

: 'legacy-rates  ( i -- adr )  /rates * legacy-rates +  ;

\ ieee80211_supported_band
struct
   /n field >band-type            \ Band type
   /n field >band-channel         \ Pointer to array of channels structures
   /n field >band-bitrates        \ Pointer to array of bitrates structures
   /n field >band-#chan
   /n field >band-#rate
   /n field >band-ht-cap
   /n field >band-ht?
   /n field >band-ampdu-factor
   /n field >band-ampdu-density
   /n field >band-tx-params
   /n field >band-rx-highest
   10 field >band-rx-mask
constant /band

\ >band-type values
0 constant BAND_2GHZ
1 constant BAND_5GHZ

/band buffer: band-2GHz
/band buffer: band-5GHz
create sband band-2GHz , band-5GHz ,

\ >band-ht-cap definitions
0001 constant HT_CAP_LDPC_CODING     
0002 constant HT_CAP_SUP_WIDTH_20_40 
000c constant HT_CAP_SM_PS           
0010 constant HT_CAP_GRN_FLD         
0020 constant HT_CAP_SGI_20          
0040 constant HT_CAP_SGI_40          
0080 constant HT_CAP_TX_STBC         
0300 constant HT_CAP_RX_STBC         
0400 constant HT_CAP_DELAY_BA        
0800 constant HT_CAP_MAX_AMSDU       
1000 constant HT_CAP_DSSSCCK40       
2000 constant HT_CAP_RESERVED        
4000 constant HT_CAP_40MHZ_INTOLERANT
8000 constant HT_CAP_LSIG_TXOP_PROT  

\ >band-ampdu-factor values
0 constant HT_MAX_AMPDU_8K 
1 constant HT_MAX_AMPDU_16K
2 constant HT_MAX_AMPDU_32K
3 constant HT_MAX_AMPDU_64K
d# 13 constant HT_MAX_AMPDU_FACTOR

\ >band-ampdu-density values
0 constant HT_MPDU_DENSITY_NONE      \ No restriction
1 constant HT_MPDU_DENSITY_0_25      \ 1/4 usec
2 constant HT_MPDU_DENSITY_0_5       \ 1/2 usec
3 constant HT_MPDU_DENSITY_1         \ 1 usec
4 constant HT_MPDU_DENSITY_2         \ 2 usec
5 constant HT_MPDU_DENSITY_4         \ 4 usec
6 constant HT_MPDU_DENSITY_8         \ 8 usec
7 constant HT_MPDU_DENSITY_16        \ 16 usec

\ >band-tx-params value
01 constant HT_MCS_TX_DEFINED 
02 constant HT_MCS_TX_RX_DIFF 
10 constant HT_MCS_TX_UNEQUAL_MODULATION 

\ channel structure include the ieee fields
struct
   \ ieee80211_channel
   /n field >ch-band              \ >band-type
   /n field >ch-freq
   /n field >ch-hw-val            \ Index to channels
   /n field >ch-max-power
   /n field >ch-flags
   /n field >ch-max-antenna-gain
   /n field >ch-beacon?

   \ ath9k_channel
   /n field >ch-mode
   /n field >ch-noiseFloor

   \ ANI variables
   /n field >ani-listenTime
   /n field >ani-ofdmPhyErrCnt
   /n field >ani-cckPhyErrCnt
   /n field >ani-ofdmNoiseImmunityLevel
   /n field >ani-cckNoiseImmunityLevel
   /n field >ani-spurImmunityLevel
   /n field >ani-firstepLevel
   /n field >ani-noiseFloor
   /n field >ani-rssiThrHigh
   /n field >ani-rssiThrLow
   /n field >ani-ofdmWeakSigDetectOff
   /n field >ani-mrcCCKOff
   /n field >ani-ofdmsTurn

   \ Cached ANI register values
   /n field >ani-ini-sfcorr
   /n field >ani-ini-sfcorr-low
   /n field >ani-ini-sfcorr-ext
   /n field >ani-ini-firstep
   /n field >ani-ini-firstepLow
   /n field >ani-ini-cycpwrThr1
   /n field >ani-ini-cycpwrThr1Ext
constant /channel

: 'band-ch  ( bandadr i -- adr )  /channel * swap >band-channel @ +  ;

decimal
: ch-allot  ( -- )  here /channel 4 /n* - dup allot erase  ;
create channels
here
   0 , 2412 ,  0 , 20 , ch-allot   \ ch 1
   0 , 2417 ,  1 , 20 , ch-allot   \ ch 2
   0 , 2422 ,  2 , 20 , ch-allot   \ ch 3
   0 , 2427 ,  3 , 20 , ch-allot   \ ch 4
   0 , 2432 ,  4 , 20 , ch-allot   \ ch 5
   0 , 2437 ,  5 , 20 , ch-allot   \ ch 6 
   0 , 2442 ,  6 , 20 , ch-allot   \ ch 7
   0 , 2447 ,  7 , 20 , ch-allot   \ ch 8
   0 , 2452 ,  8 , 20 , ch-allot   \ ch 9
   0 , 2457 ,  9 , 20 , ch-allot   \ ch 10
   0 , 2462 , 10 , 20 , ch-allot   \ ch 11
   0 , 2467 , 11 , 20 , ch-allot   \ ch 12
   0 , 2472 , 12 , 20 , ch-allot   \ ch 13
   0 , 2484 , 13 , 20 , ch-allot   \ ch 14
here swap - /channel / ( constant #ch-2GHz )

here
   \ UNIT 1
   1 , 5180 , 14 , 20 , ch-allot   \ ch 36
   1 , 5200 , 15 , 20 , ch-allot   \ ch 40
   1 , 5220 , 16 , 20 , ch-allot   \ ch 44
   1 , 5240 , 17 , 20 , ch-allot   \ ch 48
   \ UNIT 2
   1 , 5260 , 18 , 20 , ch-allot   \ ch 52
   1 , 5280 , 19 , 20 , ch-allot   \ ch 56
   1 , 5300 , 20 , 20 , ch-allot   \ ch 60
   1 , 5320 , 21 , 20 , ch-allot   \ ch 64
   \ Middle band
   1 , 5500 , 22 , 20 , ch-allot   \ ch 100
   1 , 5520 , 23 , 20 , ch-allot   \ ch 104
   1 , 5540 , 24 , 20 , ch-allot   \ ch 108
   1 , 5560 , 25 , 20 , ch-allot   \ ch 112
   1 , 5580 , 26 , 20 , ch-allot   \ ch 116
   1 , 5600 , 27 , 20 , ch-allot   \ ch 120
   1 , 5620 , 28 , 20 , ch-allot   \ ch 124
   1 , 5640 , 29 , 20 , ch-allot   \ ch 128
   1 , 5660 , 30 , 20 , ch-allot   \ ch 132
   1 , 5680 , 31 , 20 , ch-allot   \ ch 136
   1 , 5700 , 32 , 20 , ch-allot   \ ch 140
   \ UNIT 3
   1 , 5745 , 33 , 20 , ch-allot   \ ch 149
   1 , 5765 , 34 , 20 , ch-allot   \ ch 153
   1 , 5785 , 35 , 20 , ch-allot   \ ch 157
   1 , 5805 , 36 , 20 , ch-allot   \ ch 161
   1 , 5825 , 37 , 20 , ch-allot   \ ch 165
here swap - /channel / constant #ch-5GHz  constant #ch-2GHz

#ch-5GHz #ch-2GHz + constant #channels

channels value ch-2GHz
channels #ch-2GHz /channel * + value ch-5GHz

0 value defch       \ 0 based index into channels
: 'channel  ( ch -- adr )  /channel * channels +  ;

create channel#  1 c, 2 c, 3 c, 4 c, 5 c, 6 c, 7 c, 8 c,
                 9 c, 10 c, 11 c, 12 c, 13 c, 14 c,
                 36 c, 40 c, 44 c, 48 c,
                 52 c, 56 c, 60 c, 64 c,
                 100 c, 104 c, 108 c, 112 c, 116 c, 120 c,
		 124 c, 128 c, 132 c, 136 c, 140 c,
                 149 c, 153 c, 157 c, 161 c, 165 c, 
: idx>ch  ( idx -- ch# )  channel# + c@  ;

hex
\ >ch-mode and >ch-flags bit definitions
0000.0002 constant CH_CW_INT
0000.0020 constant CH_CCK
0000.0040 constant CH_OFDM
0000.0080 constant CH_2GHZ
0000.0100 constant CH_5GHZ
0000.0200 constant CH_PASSIVE
0000.0400 constant CH_DYN
0000.4000 constant CH_HALF
0000.8000 constant CH_QUARTER
0001.0000 constant CH_HT20
0002.0000 constant CH_HT40+
0004.0000 constant CH_HT40-

CH_5GHZ CH_OFDM  or constant CH_A
CH_2GHZ CH_CCK   or constant CH_B
CH_2GHZ CH_OFDM  or constant CH_G
CH_2GHZ CH_HT20  or constant CH_G_HT20
CH_5GHZ CH_HT20  or constant CH_A_HT20
CH_2GHZ CH_HT40+ or constant CH_G_HT40+
CH_2GHZ CH_HT40- or constant CH_G_HT40-
CH_5GHZ CH_HT40+ or constant CH_A_HT40+
CH_5GHZ CH_HT40- or constant CH_A_HT40-
CH_OFDM CH_CCK or CH_2GHZ or CH_5GHZ or CH_HT20 or CH_HT40+ or CH_HT40- or constant CH_ALL

: is-g?     ( ch -- flag )
   >ch-flags @ dup CH_G and CH_G =
   over CH_G_HT20 and CH_G_HT20 = or
   over CH_G_HT40+ and CH_G_HT40+ = or
   swap CH_G_HT40- and CH_G_HT40- = or
;
: is-ofdm?  ( ch -- flag )  >ch-flags @ CH_OFDM and  ;
: is-5GHz?  ( ch -- flag )  >ch-flags @ CH_5GHZ and  ;
: is-2GHz?  ( ch -- flag )  >ch-flags @ CH_2GHZ and  ;
: is-half-rate?  ( ch -- flag )  >ch-flags @ CH_HALF and  ;
: is-quarter-rate?  ( ch -- flag )  >ch-flags @ CH_QUARTER and  ;
: is-a-fast?  ( ch -- flag )  >ch-flags @ CH_5GHZ and  ;
: is-b?     ( ch -- flag )  >ch-mode @  CH_B =  ;
: is-ht20?  ( ch -- flag )  >ch-mode @  CH_HT20 and  ;
: is-ht40?  ( ch -- flag )  >ch-mode @  CH_HT40+ CH_HT40- or and  ;
: is-ht?    ( ch -- flag )  dup is-ht20? swap is-ht40? or  ;

hex

\ Rate control phy values
0 constant WLAN_RC_PHY_OFDM
1 constant WLAN_RC_PHY_CCK
2 constant WLAN_RC_PHY_HT_20_SS
3 constant WLAN_RC_PHY_HT_20_DS
4 constant WLAN_RC_PHY_HT_20_TS
5 constant WLAN_RC_PHY_HT_40_SS
6 constant WLAN_RC_PHY_HT_40_DS
7 constant WLAN_RC_PHY_HT_40_TS
8 constant WLAN_RC_PHY_HT_20_SS_HGI
9 constant WLAN_RC_PHY_HT_20_DS_HGI
a constant WLAN_RC_PHY_HT_20_TS_HGI
b constant WLAN_RC_PHY_HT_40_SS_HGI
c constant WLAN_RC_PHY_HT_40_DS_HGI
d constant WLAN_RC_PHY_HT_40_TS_HGI
e constant WLAN_RC_PHY_MAX

\ hw-caps bit definitions
0000.0001 constant HW_CAP_HT
0000.0002 constant HW_CAP_RFSILENT
0000.0004 constant HW_CAP_CST     
0000.0008 constant HW_CAP_ENHANCEDPM
0000.0010 constant HW_CAP_AUTOSLEEP 
0000.0020 constant HW_CAP_4KB_SPLITTRANS
0000.0040 constant HW_CAP_EDMA		
0000.0080 constant HW_CAP_RAC_SUPPORTED	
0000.0100 constant HW_CAP_LDPC		
0000.0200 constant HW_CAP_FASTCLOCK	
0000.0400 constant HW_CAP_SGI_20	
0000.0800 constant HW_CAP_PAPRD		
0000.1000 constant HW_CAP_ANT_DIV_COMB	
0000.2000 constant HW_CAP_2GHZ		
0000.4000 constant HW_CAP_5GHZ		
0000.8000 constant HW_CAP_APM		
HW_CAP_HT HW_CAP_CST or HW_CAP_ENHANCEDPM or HW_CAP_AUTOSLEEP or
HW_CAP_4KB_SPLITTRANS or HW_CAP_EDMA or HW_CAP_FASTCLOCK or HW_CAP_LDPC or
HW_CAP_RAC_SUPPORTED or HW_CAP_SGI_20 or HW_CAP_5GHZ or HW_CAP_2GHZ or
value hw-caps

d# 12 /n* constant rx-status-len
d# 32 /n* constant tx-desc-len
h# 127 constant dummy-rssi

0 value curchan               \ Points to one of the channels
d# 20 value slottime
dummy-rssi value last-rssi
dummy-rssi value avgbrssi
0 value max-txchains

\ channel-type definitions
0 constant NL80211_CHAN_NO_HT
1 constant NL80211_CHAN_HT20
2 constant NL80211_CHAN_HT40MINUS
3 constant NL80211_CHAN_HT40PLUS
0 value channel-type

: conf-is-ht20?   ( -- flag )  channel-type NL80211_CHAN_HT20 =  ;
: conf-is-ht40-?  ( -- flag )  channel-type NL80211_CHAN_HT40MINUS =  ;
: conf-is-ht40+?  ( -- flag )  channel-type NL80211_CHAN_HT40PLUS  =  ;
: conf-is-ht40?   ( -- flag )  conf-is-ht40-?  conf-is-ht40+?  or  ;
: conf-is-ht?     ( -- flag )  channel-type  ;

0 value coverage-class

0 value txchainmask
0 value rxchainmask
0 value paprd-ratemask
0 value paprd-ratemask-ht40
0 value paprd-table-write-done?
0 value paprd-target-power

1 constant led-pin
0 constant LED_OFF

/mac-adr buffer: curbssid
/mac-adr buffer: bssidmask
0 value curaid

0 value tx-chainmask
0 value rx-chainmask

0 value clockrate
\ clockrate values
d# 22 constant CLOCK_RATE_CCK	
d# 40 constant CLOCK_RATE_5GHZ_OFDM
d# 44 constant CLOCK_RATE_2GHZ_OFDM
d# 44 constant CLOCK_FAST_RATE_5GHZ_OFDM

\ Regulatory
0 value reg-cap

struct
   /n field >reg-dmn-enum
   /n field >reg-5ghz-ctl
   /n field >reg-2ghz-ctl
constant /reg-dmn-pair

\ CTL constants
e0 constant SD_NO_CTL
0f constant CTL_MODE_M
00 constant CTL_11A   
01 constant CTL_11B   
02 constant CTL_11G   
05 constant CTL_2GHT20
06 constant CTL_5GHT20
07 constant CTL_2GHT40
08 constant CTL_5GHT40
CTL_11A 8000 or constant CTL_11A_EXT
CTL_11B 8000 or constant CTL_11B_EXT
CTL_11G 8000 or constant CTL_11G_EXT

struct
   /n field >reg-country
   /n field >reg-max-power
   /n field >reg-tp-scale
   /n field >reg-cur-rd
   /n field >reg-cur-rd-ext
   /n field >reg-power-limit
   /n field >reg-pair
   2  field >reg-alpha2
constant /regulatory

/regulatory buffer: regulatory

0 value sc-flags
\ sc-flags bit definitions
0001 constant SC_OP_INVALID
0002 constant SC_OP_BEACONS
0004 constant SC_OP_RXAGGR 
0008 constant SC_OP_TXAGGR 
0010 constant SC_OP_OFFCHANNEL
0020 constant SC_OP_PREAMBLE_SHORT
0040 constant SC_OP_PROTECT_ENABLE
0080 constant SC_OP_RXFLUSH
0100 constant SC_OP_LED_ASSOCIATED
0200 constant SC_OP_LED_ON 
0400 constant SC_OP_TSF_RESET
0800 constant SC_OP_BT_PRIORITY_DETECTED
1000 constant SC_OP_BT_SCAN
2000 constant SC_OP_ANI_RUN
4000 constant SC_OP_ENABLE_APM

0 value rx-defant
0 value rs-otherant-cnt

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
