purpose: ATH9K initialization
\ See license at end of file

headers
hex

0 value rfkill-gpio
0 value rfkill-polarity

\ cfg-output type definitions
0 constant GPIO_OUTPUT_MUX_AS_OUTPUT 
1 constant GPIO_OUTPUT_MUX_AS_PCIE_ATTENTION_LED
2 constant GPIO_OUTPUT_MUX_AS_PCIE_POWER_LED    
3 constant GPIO_OUTPUT_MUX_AS_TX_FRAME          
4 constant GPIO_OUTPUT_MUX_AS_RX_CLEAR_EXTERNAL 
5 constant GPIO_OUTPUT_MUX_AS_MAC_NETWORK_LED   
6 constant GPIO_OUTPUT_MUX_AS_MAC_POWER_LED     

: cfg-gpio-input  ( gpio -- )  0 1 rot 2* << 4050 reg@!  ;
: cfg-output  ( gpio type -- )
   over 6 mod 5 * tuck << 1f rot <<  ( gpio type' mask )
   2 pick d# 11 >  if  4070  else  2 pick 5 >  if  4064  else  4060  then  then  reg@!
   3 swap 2* << dup 4050 reg@!       ( )
;
: set-gpio  ( value gpio -- )  swap 1 and over << 1 rot << 4048 reg@!  ;
: get-gpio  ( gpio -- value )  404c reg@  1 rot << and  ;

\ bt hardware settings
0 value bt-scheme
0 value bt-wlanactive-gpio
0 value bt-active-gpio
0 value bt-priority-gpio
0 value bt-coex-mode      \ Register setting for AR_BT_COEX_MODE
0 value bt-coex-weights   \ Register setting for AR_BT_COEX_WEIGHT
0 value bt-coex-mode2     \ Register setting for AR_BT_COEX_MODE2

\ bt-scheme
0 constant BTCOEX_CFG_NONE,
1 constant BTCOEX_CFG_2WIRE
2 constant BTCOEX_CFG_3WIRE

\ bt-mode definitions
0 constant BT_COEX_MODE_LEGACY        \ legacy rx_clear mode
1 constant BT_COEX_MODE_UNSLOTTED     \ untimed/unslotted mode
2 constant BT_COEX_MODE_SLOTTED       \ slotted mode
3 constant BT_COEX_MODE_DISALBED      \ coexistence disabled

\ bt configuration
BT_COEX_MODE_SLOTTED value bt-mode
0 value bt-time-extend
true value bt-txstate-extend?
true value bt-txframe-extend?
true value bt-quiet-collision?
true value bt-hold-rx-clear?
true value bt-rxclear-polarity?
2 value bt-priority-time
5 value bt-first-slot-time

: init-btcoex-hw  ( qnum -- )
   d# 13 << 2.1300 or
   bt-mode d# 10 << or bt-priority-time d# 18 << or
   bt-first-slot-time d# 24 << or  to  bt-coex-mode

   1.0032 to bt-coex-mode2
; 
: init-btcoex-2wire  ( -- )
   1000 100c 405c reg@!                       \ Connect bt_active to baseband
   bt-active-gpio d# 16 << f.0000 4060 reg@!  \ Input mux bt_active to GPIO
   bt-active-gpio cfg-gpio-input
;
: init-btcoex-3wire  ( -- )
   1400 dup 405c reg@!   \ Connect bt_priority_async and bt_active_async to baseband
   bt-active-gpio d# 16 << bt-priority-gpio 8 << or
   f.0f00 4060 reg@!     \ Input mux for bt_priority_async and bt_active_async to GPIO
   bt-active-gpio   cfg-gpio-input
   bt-priority-gpio cfg-gpio-input
;
: enable-btcoex-2wire  ( -- )
   bt-wlanactive-gpio GPIO_OUTPUT_MUX_AS_TX_FRAME cfg-output
;
: enable-btcoex-3wire  ( -- )
   bt-coex-mode    8170 reg!
   bt-coex-weights 8174 reg!
   bt-coex-mode2   817c reg!
   2.0000 dup      80fc reg@!
   0      10.0000  8120 reg@!
   bt-wlanactive-gpio GPIO_OUTPUT_MUX_AS_RX_CLEAR_EXTERNAL cfg-output
;

: enable-btcoex  ( -- )
   bt-scheme BTCOEX_CFG_2WIRE =  if  enable-btcoex-2wire  then
   bt-scheme BTCOEX_CFG_3WIRE =  if  enable-btcoex-3wire  then
   2 bt-active-gpio 2* <<  3 bt-active-gpio 2* << 4090 reg@!
;

: disable-btcoex  ( -- )
   0 bt-wlanactive-gpio set-gpio
   bt-wlanactive-gpio GPIO_OUTPUT_MUX_AS_OUTPUT cfg-output
   bt-scheme BTCOEX_CFG_3WIRE =  if
      1c00  8170 reg!
      0 8174 reg!
      0 817c reg!
   then
;

: set-clockrate  ( -- )
   curchan 0=  if  CLOCK_RATE_CCK
   else
   curchan >ch-band @ BAND_2GHZ =  if  CLOCK_RATE_2GHZ_OFDM
   else
   hw-caps HW_CAP_FASTCLOCK and  if  CLOCK_FAST_RATE_5GHZ_OFDM
   else  CLOCK_RATE_5GHZ_OFDM
   then  then  then

   conf-is-ht40?  if  2*  then  to clockrate
;

: mac>clks  ( us -- clks )  clockrate *  ;
: flip-bits  ( val n -- val' )  0 swap  0  do  1 << over i >> 1 and or  loop  nip  ;

: get-ch-edges  ( flag -- false | lo hi true )
   dup CH_5GHZ and  if  drop d# 4920  d# 6100  true  exit  then
       CH_2GHZ and  if  d# 2312  d# 2372  true  exit  then
   false
;

: get-nic-rev  ( -- )  \ ath9k_hw_read_revisions
   \ macVersion and macRev
   4020 reg@ dup h# fffc.0000 and d# 12 >> to macVersion
   h# f00 and 8 >> to macRev
   macVersion h# 1c0 =  macRev 2 >=  and  not  if
      ." WARNING: driver may not support this version of Atheros chip"  cr
   then
;

: roundup/  ( x y -- x/y )  /mod swap  if  1+  then  ;
: compute-txtime  ( kbps framelen shortpre? phy -- txtime )
   3 pick 0=  if  4drop 0 exit  then
   case
      WLAN_RC_PHY_CCK  of                 ( kbps framelen shortpre? )
            d# 192 swap  if  1 >>  then   ( kbps framelen phytime )
            -rot 3 << d# 1000 * swap /    ( phytime frametime )
            + d# 10 +                     ( txtime )
         endof
      WLAN_RC_PHY_OFDM  of                ( kbps framelen shortpre? )
            drop                          ( kbps framelen )
            3 << d# 22 + swap             ( numbits kbps )
            curchan 0=  if                ( numbits kbps )
               2 << d# 1000 /             ( numbits bits/symbol )
               roundup/                   ( numsymbols )
               2 << d# 36 +               ( txtime )
            else
            curchan is-quarter-rate?  if  ( numbits kbps )
               4 << d# 1000 /             ( numbits bits/symbol )
               roundup/                   ( numsymbols )
               4 << d# 144 +              ( txtime )
            else
            curchan is-half-rate?  if     ( numbits kbps )
               3 << d# 1000 /             ( numbits bits/symbol )
               roundup/                   ( numsymbols )
               3 << d# 72 +               ( txtime )
            else                          ( numbits kbps )
               2 << d# 1000 /             ( numbits bits/symbol )
               roundup/                   ( numsymbols )
               2 << d# 36 +               ( txtime )
            then  then  then
         endof
      ( otherwise )  3drop 0 swap
   endcase
;
: (test-chip)  ( data reg -- error? )  2dup reg!  reg@ <>  ;
: test-chip  ( -- error? )
   8000 reg@                         \ Save register content
   0 h# 100 0  do  i d# 16 << 8000 (test-chip) or  loop
   h# 5555.5555 8000 (test-chip) or
   h# aaaa.aaaa 8000 (test-chip) or
   h# 6666.6666 8000 (test-chip) or
   h# 9999.9999 8000 (test-chip) or
   swap 8000 reg!                    \ Restore register content
   d# 100 us
;

: init-defaults  ( -- )
   regulatory /regulatory erase
   CTRY_DEFAULT regulatory >reg-country   !
   d# 63        regulatory >reg-max-power !

   d# 20 to slottime
;

: init-post  ( -- )
   init-edata
   init-ani
;

\ reset types
1 constant RESET_WARM
3 constant RESET_COLD

: WARegVal!  ( -- )  WARegVal 4004 reg!  d# 10 us  ;
: set-reset  ( reset-type -- )
   WARegVal!  3 704c reg!
   4028 reg@ 3000 and  if
      0 402c reg!
      100 4000 reg!
   then
   ( reset-type )  7000 reg!
   d# 50 us
   0 7000 reg!
   0 3 7000 wait-hw drop
   0 4000 reg!
;
: set-reset-power-on  ( -- )
   WARegVal!  3 704c reg!
   0 7040 reg!
   1 7040 reg!
   2 f 7044 wait-hw  drop
   RESET_WARM set-reset
;

: set-power-awake  ( -- )
   WARegVal!
   7044 reg@ f and 1 =  if  set-reset-power-on  then
   d# 200 0  do
      1 1 704c reg@!  d# 50 us
      7044 reg@ f and 2 =  if  leave  then
   loop
   0 4.0000 8004 reg@!
;

: fill-cap-info  ( -- )
   eeprom >baseEepHeader >r
   r@ >regDmn0 le-w@  regulatory >reg-cur-rd !
   r@ >regDmn1 le-w@ 1f or  regulatory >reg-cur-rd-ext !
   r@ >txrxmask c@ dup f and  to rx-chainmask
                       4 >>   to tx-chainmask
   r@ >deviceCap c@
   f000 and ?dup  if  d# 12 >>  else  d# 128  then  to keymax

[ifdef] CONFIG_RFKILL
   r@ >rfSilent c@ dup  to rfsilent
   dup 1 and  if
      dup 1c and 2 >> to rfkill-gpio
      dup  2 and 1 >> to rfkill-polarity
      hw-caps HW_CAP_RFSILENT or to hw-caps
   then  drop
[then]

   regulatory >reg-cur-rd-ext @ 2 and  if  b80  else  880  then  to reg-cap
   6 to bt-active-gpio
   5 to bt-wlanactive-gpio
   BTCOEX_CFG_2WIRE to bt-scheme

   40d8 reg@ to ent-mode
   r> >miscConfiguration c@ 8 and  if  hw-caps HW_CAP_APM or to hw-caps then
   tx-chainmask get-streams to max-txchains
;

: init-hw  ( -- )
   get-nic-rev
   4004 reg@ 2.4000 or to WARegVal
   set-reset-power-on
   init-defaults
   set-power-awake
   9818 reg@ to phyRev
   0 config-pci-powersave
   init-post
   init-mode-gain-tables
   fill-cap-info
;

: init-qos  ( -- )
   0001.00aa 8118 reg!
   0000.3210 811c reg!
   0000.0052 8108 reg!
   0000.00ff 81ec reg!
   8200 81f0  do  ffff.ffff i reg!  4 +loop
;

: init-pll  ( ch -- )
   compute-pll-control  7014 reg!
   d# 100 us
   2 7048 reg!
;

: init-intr-masks  ( -- )
   8180.0965  ap-mode?  if  1000 or  then  a0 reg!
   80.0000 ac reg!
   0 40d4 reg!  0 40c8 reg!  0 40c4 reg!  0  40cc reg!
;

: set-slottime     ( us -- )  mac>clks ffff min  1070 reg!  ;
: set-ack-timeout  ( us -- )  mac>clks 3fff min  3fff 8014 reg@!  ;
: set-cts-timeout  ( us -- )  mac>clks 3fff min  d# 16 << 3fff.0000 8014 reg@!  ;

: init-global-settings  ( -- )
   misc-mode ?dup  if  dup 8120 reg@!  then

   curchan ?dup  if
      >ch-band @ BAND_5GHZ =  if  d# 16  else  d# 10  then
   else  d# 10  then                   ( sifstime )
   dup slottime coverage-class 3 * + + ( sifstime acktimeout )
   curchan ?dup  if
      >ch-band @ BAND_2GHZ =  if
          d# 64 + over - slottime -    ( sifstime acktimeout' )
      then
   then  nip                           ( acktimeout )
   slottime set-slottime
   dup set-ack-timeout
       set-cts-timeout
;

defer reset-txstatus-ring   ' noop to reset-txstatus-ring
: set-dma  ( -- )
   5 7 30 reg@!        \ MAC DMA read in 128 byte chunks
   5 7 34 reg@!        \ MAC DMA write in 128 byte chunks
   200 8114 reg!       \ Setup rx FIFO
   101 3f0f 18 reg@!   \ Setup rx threshold
   rx-bufsize rx-status-len - fff and 60 reg!  \ Setup rx bufsize
   700 8340 reg!       \ Setup usable entries in PCU txbuf
   reset-txstatus-ring
;

: set-opmode  ( -- )
   8004 reg@ fffc.ffff and    ( val )
   opmode  case
      IFTYPE_AP          of  1001.0000 or 8004 reg!   0 20 14 reg@!  endof
      IFTYPE_ADHOC       of  1002.0000 or 8004 reg!  20 20 14 reg@!  endof
      IFTYPE_MESH_POINT  of  1002.0000 or 8004 reg!  20 20 14 reg@!  endof
      IFTYPE_STATION     of  1000.0000 or 8004 reg!  endof
      IFTYPE_MONITOR     of  1000.0000 or 8004 reg!  endof
   endcase
;

: reset-chip  ( ch -- )
   RESET_WARM set-reset
   dup init-pll
       set-rfmode
;

: change-channel  ( ch -- error? )
   rfbus-req? 0=  if  drop true exit  then
   dup set-ch-regs
   dup set-channel
   set-clockrate
   dup false set-txpower
   rfbus-done
   dup is-ofdm?  over is-ht? or  if  dup set-delta-slope  then
   spur-mitigate
   false
;

: set-bssidmask  ( -- )
   bssidmask le-l@  80e0 reg!
   bssidmask 4 + le-w@  80e4 reg!
;
: write-associd  ( -- )
   curbssid le-l@  8008 reg!
   curbssid 4 + le-w@  curaid 3fff and wljoin  800c reg!
;
: reset-bssidmask  ( -- )
   mac-adr      @ curbssid      @ xor invert            bssidmask      !
   mac-adr 4 + w@ curbssid 4 + w@ xor invert  ffff and  bssidmask 4 + w!
   set-bssidmask
;

defer reset-txqueue    ' noop to reset-txqueue

: reset-hw  ( ch ch-change? -- )
   tx-chainmask to txchainmask
   rx-chainmask to rxchainmask

   curchan ?dup  if  get-nf drop   then
   over >ch-freq @ caldata >cd-ch @ <>
   2 pick >ch-flags @ CH_CW_INT not and caldata >cd-chFlags @ CH_CW_INT not and <>  or  if
      caldata /caldata erase
      over init-nfcal-hist
   then                         ( ch ch-change? )

   ( ch-change? )  if
      curchan  if
         dup >ch-freq @ curchan >ch-freq <>
         over >ch-flags @ CH_ALL and curchan >ch-flags @ CH_ALL and =  and  if
            dup change-channel 0=  if
               curchan load-nf
 	       true start-nfcal
               drop exit
            then
         then
      then
   then

   1f04 reg@ ff8 and            ( ch led )
   8058 reg@ 1 max              ( ch led defAnt )
   8004 reg@ 200.0000 and       ( ch led defAnt macStaId1 )

   mark-phy-inactive
   false to paprd-table-write-done?
   3 pick reset-chip

   2.0000 dup 405c reg@!
   3 pick process-ini

   c7ff.0000 ffff.0000 8060 reg@!   \ Setup MFP options for CMP
   3 pick is-ofdm?  4 pick is-ht? or  if  3 pick set-delta-slope  then
   3 pick spur-mitigate
   3 pick set-board-values
                                ( ch led defAnt macStaId1 )
   mac-adr le-l@ 8000 reg!
   mac-adr 4 + le-w@ or 8880.0000 or 8004 reg!
   set-bssidmask
                                ( ch led defAnt )
   8058 reg!                    ( ch led )
   write-associd
   ffff.ffff 80 reg!
   700 8018 reg!

   set-opmode
   over set-channel
   set-clockrate

   d# 10 0  do  1 i << 1000 i na+ reg!  loop

   reset-txqueue

   init-intr-masks
   cache-ani-ini-regs
   init-qos

   hw-caps HW_CAP_RFSILENT and  if  rfkill-gpio cfg-gpio-input  then
   init-global-settings

   2000.0000 dup 8004 reg@!
   set-dma
   8 4088 reg!
   7d0.01f4 2c reg!

   over init-bb
        init-cal

   ( led ) 3 or 1f04 reg!

   in-little-endian? 0=  if  5 14 reg!  then

   enable-btcoex
   config-bb-watchdog
;

: reset-tsf  ( -- )
   0 20.0000 8244 wait-hw  drop
   100.0000 8020 reg!
;

[ifdef] notyet
struct
   /n field >bs-nexttbtt
   /n field >bs-nextdtim
   /n field >bs-intval
   /n field >bs-dtimperiod
   /n field >bs-cfpperiod
   /n field >bs-cfpmaxduration
   /n field >bs-cfpnext
   /n field >bs-timoffset
   /n field >bs-bmissthreshold
   /n field >bs-sleepduration
   /n field >bs-tsfoor-threshold
constant /beacon-state

/beacon-state buffer: bstate

: tu>us  ( tu -- us )  d# 10 <<  ;
: init-beacon  ( period next -- )
   opmode IFTYPE_ADHOC =  opmode IFTYPE_MESH_POINT = or  if
      800 dup 30 reg@!
      1+ tu>us 821c reg!
      80
   else
   opmode IFTYPE_AP =  if
      dup tu>us 8200 reg!
      dup 2 - tu>us 8204 reg!
          d# 10 - tu>us 8208 reg!
      7
   else
      2drop exit
   then  then  swap         ( flags period )

   dup tu>us dup  8220 reg!  dup 8224 reg!  dup 8228 reg!  823c reg!
   100.0000 and if  reset-tsf  then
   dup 8240 reg@!                ( )
;

: set-beacon-timers  ( -- )
   bstate >bs-nexttbtt @ tu>us  8200 reg!
   bstate >bs-intval @ ffff and tu>us dup  8220 reg!  8224 reg!
   bstate >bs-bmissthreshold @ ff and 8 <<  8018 reg!
   bstate >bs-nextdtim @ 3 - tu>us  8214 reg!
   bstate >bs-intval @ ffff and  bstate >bs-sleepduration @ max
   bstate >bs-dtimperiod @  bstate >bs-sleepduration @ max
   2dup =  if  bstate >bs-nextdtim  else  bstate >bs-nexttbtt  then
   @ ( nextTbtt ) 3 - tu>us  8210 reg!
   0a08.0000 80d4 reg!
   hw-caps HW_CAP_AUTOSLEEP and  if  a00.0000  else  20.0000  then  80d8 reg!
   ( dtimperiod )   tu>us  8234 reg!
   ( beaconintval ) tu>us  8230 reg!
   31 dup 8240 reg@!
   bstate >bs-tsfoor-threshold @  813c reg!
;
[then]

: get-defant  ( -- ant )  8054 reg@ 7 and  ;
: set-defant  ( ant -- )  7 and 8054 reg!  ;

\ rxfilter bit definitions
0001 constant RX_FILTER_UCAST              \ Always on
0002 constant RX_FILTER_MCAST              \ Always on     
0004 constant RX_FILTER_BCAST              \ Always on
0008 constant RX_FILTER_CONTROL
0010 constant RX_FILTER_BEACON             \ On for AP
0020 constant RX_FILTER_PROM               \ On if use-promiscuous?
0080 constant RX_FILTER_PROBEREQ           \ On for AP
0100 constant RX_FILTER_PHYERR 
0200 constant RX_FILTER_MYBEACON           \ On for station
0400 constant RX_FILTER_COMP_BAR           \ On if HT
0800 constant RX_FILTER_COMP_BA 
1000 constant RX_FILTER_UNCOMP_BA_BAR
4000 constant RX_FILTER_PSPOLL		   \ On for PSpoll
2000 constant RX_FILTER_PHYRADAR
8000 constant RX_FILTER_MCAST_BCAST_ALL    \ On for other BSS

: get-rxfilter  ( -- bits )
   810c reg@
   803c reg@
   over       20 and  if  RX_FILTER_PHYRADAR or  then
   swap 202.0000 and  if  RX_FILTER_PHYERR   or  then
;
: set-rxfilter  ( bits -- )
   dup 803c reg!
   0 over RX_FILTER_PHYRADAR and  if        20 or  then
   swap   RX_FILTER_PHYERR   and  if  202.0000 or  then
   dup 810c reg!
   if  10 dup  else  0 10  then  34 reg@!
;

: disable-phy  ( -- )
   RESET_WARM set-reset
   0 init-pll
;

: disable-hw  ( -- )
   RESET_COLD set-reset
   0 init-pll
;

: set-txpower-limit  ( test? limit -- )
   d# 63 min  regulatory >reg-power-limit !
   curchan swap set-txpower
;

: set-mcastfilter  ( filter0 filter1 -- )  8044 reg!  8040 reg!  ;

: get-tsf64  ( -- lo hi )
   8050 reg@              ( hi1 )
   d# 10 0  do
      804c reg@           ( hi1 lo )
      8050 reg@           ( hi1 lo hi2 )
      rot over =  if  swap leave   then
      swap                ( hi1' lo )
   loop  swap             ( lo hi )
;

: set-tsf64  ( lo hi -- )  swap 804c reg!  8050 reg!  ;

: set-tsfadjust  ( setting -- )
   misc-mode swap  if  8  or  else  ffff.fff7 and  then
   to misc-mode 
;

: set-led-brightness  ( brightness -- )  LED_OFF = led-pin  set-gpio  ;

: deinit-leds         ( -- )  LED_OFF set-led-brightness  ;

: init-leds  ( -- )
   1 to led-pin
   led-pin GPIO_OUTPUT_MUX_AS_OUTPUT cfg-output
   LED_OFF set-led-brightness
;

: setup-ht-cap  ( 'band -- )
   >r
   true r@ >band-ht? !
   HT_CAP_SUP_WIDTH_20_40 HT_CAP_SM_PS or HT_CAP_SGI_40 or HT_CAP_DSSSCCK40 or
   HT_CAP_TX_STBC or 100 or
   hw-caps HW_CAP_LDPC and  if  HT_CAP_LDPC_CODING or  then
   hw-caps HW_CAP_SGI_20 and  if  HT_CAP_SGI_20 or  then
   r@ >band-ht-cap !
   HT_MAX_AMPDU_64K r@ >band-ampdu-factor !
   HT_MPDU_DENSITY_8 r@ >band-ampdu-density !
   0 r@ >band-rx-highest !
   r@ >band-rx-mask d# 10 erase
   tx-chainmask get-streams       ( #txstreams )
   rx-chainmask get-streams       ( #txstreams #rxstreams )
   2dup <>  if                    ( #txstreams #rxstreams )
      over 1- 2 << HT_MCS_TX_RX_DIFF or HT_MCS_TX_DEFINED or
   else
      HT_MCS_TX_DEFINED
   then
   r@ >band-tx-params !           ( #txstreams #rxstreams )
   nip                            ( #rxstreams )
   r> >band-rx-mask swap ff fill
;

: init-crypto  ( -- )
   keymax 0  do  i reset-key  loop
   misc-mode 4 and  if  crypt-caps CRYPT_CAP_MIC_COMBINED or to crypt-caps  then
;

: init-btcoex  ( -- )
   bt-scheme BTCOEX_CFG_2WIRE =  if  init-btcoex-2wire  then
   \ XXX Do not support 3wire
;

defer setup-descdma          ' noop to setup-descdma
defer init-queues            ' noop to init-queues

: init-ch-rates  ( -- )
   band-2GHz sband !
   band-5GHz sband na1+ !

   band-2GHz >r
   BAND_2GHZ      r@ >band-type     !
   ch-2GHz        r@ >band-channel  !
   #ch-2GHz       r@ >band-#chan    !
   legacy-rates   r@ >band-bitrates !
   #legacy-rates  r> >band-#rate    !

   band-5GHz >r
   BAND_5GHZ      r@ >band-type     !
   ch-5GHz        r@ >band-channel  !
   #ch-5GHz       r@ >band-#chan    !
   legacy-rates   4 +  r@ >band-bitrates !
   #legacy-rates  1-   r> >band-#rate    !
;

: init-misc  ( -- )
   \ XXX kick off timer for ath_ani_calibrate
   hw-caps HW_CAP_HT and  if  sc-flags SC_OP_TXAGGR or SC_OP_RXAGGR or to sc-flags  then
   true set-diversity
   get-defant 1 max to rx-defant
;

: init-softc  ( -- )
   0 to curaid
   curbssid /mac-adr erase
   init-hw
   init-queues
   init-btcoex
   init-ch-rates
   init-crypto
   init-misc
;

: get-extchanmode  ( type -- ch-mode )
   curchan >ch-band @ dup BAND_2GHZ =  if
      drop  case
         NL80211_CHAN_NO_HT     of  CH_G_HT20   endof
         NL80211_CHAN_HT20      of  CH_G_HT20   endof
         NL80211_CHAN_HT40PLUS  of  CH_G_HT40+  endof
         NL80211_CHAN_HT40MINUS of  CH_G_HT40-  endof
         ( otherwise )  0 swap
      endcase
   else
   BAND_5GHZ =  if
      case
         NL80211_CHAN_NO_HT     of  CH_A_HT20   endof
         NL80211_CHAN_HT20      of  CH_A_HT20   endof
         NL80211_CHAN_HT40PLUS  of  CH_A_HT40+  endof
         NL80211_CHAN_HT40MINUS of  CH_A_HT40-  endof
         ( otherwise )  0 swap
      endcase
   else
      drop 0
   then  then
;

: update-ichannel  ( type -- )
   curchan >ch-band @ BAND_2GHZ =  if
      CH_G curchan >ch-mode !
      CH_2GHZ CH_OFDM or CH_G or curchan >ch-flags !
   else
      CH_A curchan >ch-mode !
      CH_5GHZ CH_OFDM or curchan >ch-flags !
   then
   dup NL80211_CHAN_NO_HT <>  if
      get-extchanmode curchan >ch-mode !
   else  drop  then
;

: init-band-txpower  ( band -- )
   dup >band-#chan @ 0  do                     ( band )
      dup i 'band-ch to curchan                ( band )
      NL80211_CHAN_HT20 update-ichannel        ( band )
      true d# 63 set-txpower-limit             ( band )
      regulatory >reg-max-power @ 2/ curchan >ch-max-power !  ( band )
   loop  drop                                  ( )
;

: init-txpower-limits  ( -- )
   curchan                       \ Save
   band-2GHz init-band-txpower
   band-5GHz init-band-txpower
   to curchan                    \ Restore
;

: set-hw-cap  ( -- )
   band-2GHz setup-ht-cap
   band-5GHz setup-ht-cap
;

: is-world-regd?  ( -- flag )
   regulatory >reg-cur-rd @ ffff.bfff and  is-wwr-sku?
;

create def-reg-pair FCC3_FCCA , CTL_FCC , CTL_FCC ,
: default-init-regd  ( -- )
   \ XXX US: channels 1-11 are valid, no mid-band channels in 5GHz band
   CTRY_UNITED_STATES regulatory >reg-country !
   def-reg-pair regulatory >reg-pair !
   ascii U regulatory >reg-alpha2 c!
   ascii S regulatory >reg-alpha2 1+ c!
;
defer init-regd              ' default-init-regd to init-regd

defer init-tx                ' noop to init-tx
defer init-rx                ' noop to init-rx

: init-le  ( -- )
   \ Determine processor's endianness
   opencount @                \ Save opencount
   h# 12345678 dup opencount !
   opencount le-l@ =  to in-little-endian?
   opencount !                \ Restore opencount
;

: init-device  ( -- )
   init-le
   init-softc
   set-hw-cap
   init-regd
   init-tx
   init-rx
   init-txpower-limits
   dummy-rssi to last-rssi
   init-leds
;

: disable-interrupts  ( -- )
   0   24 reg!  24   reg@ drop
   0 403c reg!  403c reg@ drop
   0 402c reg!  402c reg@ drop
;
: set-interrupts  ( -- )
   \ XXX
;

defer start-receive                ' noop to start-receive
defer stop-tx                      ' noop to stop-tx
defer stop-rx                      ' noop to stop-rx

: re-set-channel  ( ch# -- )       \ 0 based
   'channel
   stop-tx
   stop-rx
   ( ch ) true reset-hw
   start-receive
   false regulatory >reg-power-limit @ set-txpower-limit
   set-interrupts
;

: reset  ( -- )
   disable-interrupts
   stop-tx
   stop-rx
   curchan false reset-hw
   start-receive
   false regulatory >reg-power-limit @ set-txpower-limit
   set-interrupts
;

: start  ( -- )
   0 config-pci-powersave
   defch 'channel false reset-hw
   false regulatory >reg-power-limit @ set-txpower-limit
   start-receive
   set-interrupts
   ff55 a8a8 wljoin to bt-coex-weights
   enable-btcoex
   80 my-b@ fc and 80 my-b!      \ Disable ASPM
;

: stop  ( -- )
   disable-btcoex
   disable-interrupts
   stop-rx
   disable-phy
   disable-hw
   1 config-pci-powersave
;

[ifdef] notyet
: set-coverage-class  ( cc -- )
   to coverage-class
   init-global-settings
;
[then]

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
