purpose: ATH9K PHY code
\ See license at end of file

headers

decimal
0   constant CTRY_DEFAULT
840 constant CTRY_UNITED_STATES
hex

0199 constant WORLD

3a constant FCC3_FCCA

10 constant CTL_FCC
ff constant NO_CTL   

\ targetPowerHTRates 
0  dup constant HT_TARGET_RATE_0_8_16
1+ dup constant HT_TARGET_RATE_1_3_9_11_17_19
1+ dup constant HT_TARGET_RATE_4
1+ dup constant HT_TARGET_RATE_5
1+ dup constant HT_TARGET_RATE_6
1+ dup constant HT_TARGET_RATE_7
1+ dup constant HT_TARGET_RATE_12
1+ dup constant HT_TARGET_RATE_13
1+ dup constant HT_TARGET_RATE_14
1+ dup constant HT_TARGET_RATE_15
1+ dup constant HT_TARGET_RATE_20
1+ dup constant HT_TARGET_RATE_21
1+ dup constant HT_TARGET_RATE_22
1+     constant HT_TARGET_RATE_23

\ targetPowerLegacyRates
0  dup constant LEGACY_TARGET_RATE_6_24
1+ dup constant LEGACY_TARGET_RATE_36
1+ dup constant LEGACY_TARGET_RATE_48
1+     constant LEGACY_TARGET_RATE_54

\ targetPowerCckRates
0  dup constant LEGACY_TARGET_RATE_1L_5L
1+ dup constant LEGACY_TARGET_RATE_5S
1+ dup constant LEGACY_TARGET_RATE_11L
1+     constant LEGACY_TARGET_RATE_11S

\ ar9300_Rates
0  dup constant ALL_TARGET_LEGACY_6_24
1+ dup constant ALL_TARGET_LEGACY_36
1+ dup constant ALL_TARGET_LEGACY_48
1+ dup constant ALL_TARGET_LEGACY_54
1+ dup constant ALL_TARGET_LEGACY_1L_5L
1+ dup constant ALL_TARGET_LEGACY_5S
1+ dup constant ALL_TARGET_LEGACY_11L
1+ dup constant ALL_TARGET_LEGACY_11S
1+ dup constant ALL_TARGET_HT20_0_8_16
1+ dup constant ALL_TARGET_HT20_1_3_9_11_17_19
1+ dup constant ALL_TARGET_HT20_4
1+ dup constant ALL_TARGET_HT20_5
1+ dup constant ALL_TARGET_HT20_6
1+ dup constant ALL_TARGET_HT20_7
1+ dup constant ALL_TARGET_HT20_12
1+ dup constant ALL_TARGET_HT20_13
1+ dup constant ALL_TARGET_HT20_14
1+ dup constant ALL_TARGET_HT20_15
1+ dup constant ALL_TARGET_HT20_20
1+ dup constant ALL_TARGET_HT20_21
1+ dup constant ALL_TARGET_HT20_22
1+ dup constant ALL_TARGET_HT20_23
1+ dup constant ALL_TARGET_HT40_0_8_16
1+ dup constant ALL_TARGET_HT40_1_3_9_11_17_19
1+ dup constant ALL_TARGET_HT40_4
1+ dup constant ALL_TARGET_HT40_5
1+ dup constant ALL_TARGET_HT40_6
1+ dup constant ALL_TARGET_HT40_7
1+ dup constant ALL_TARGET_HT40_12
1+ dup constant ALL_TARGET_HT40_13
1+ dup constant ALL_TARGET_HT40_14
1+ dup constant ALL_TARGET_HT40_15
1+ dup constant ALL_TARGET_HT40_20
1+ dup constant ALL_TARGET_HT40_21
1+ dup constant ALL_TARGET_HT40_22
1+ dup constant ALL_TARGET_HT40_23
1+     constant /RateTable

\ This function takes the channel value in MHz and sets
\ hardware channel value. Assumes writes have been enabled to analog bus.
\
\ Actual Expression,
\
\ For 2GHz channel,
\ Channel Frequency = (3/4) * freq_ref * (chansel[8:0] + chanfrac[16:0]/2^17)
\ (freq_ref = 40MHz)
\
\ For 5GHz channel,
\ Channel Frequency = (3/2) * freq_ref * (chansel[8:0] + chanfrac[16:0]/2^10)
\ (freq_ref = 40MHz/(24>>amodeRefSel))
\
\ For 5GHz channels which are 5MHz spaced,
\ Channel Frequency = (3/2) * freq_ref * (chansel[8:0] + chanfrac[16:0]/2^17)
\ (freq_ref = 40MHz)

: get-chan-centers  ( ch -- ctl-center ext-center synth-center )
   dup >ch-freq @  over is-ht40? not  if  nip dup dup  exit  then
   swap >ch-mode @ CH_HT40+ and  if     ( sc )
      d# 10 +                           ( sc' )
      dup d# 10 - swap                  ( cc sc )
      dup d# 10 + swap                  ( cc ec sc )
   else
      d# 10 -                           ( sc' )
      dup d# 10 + swap                  ( cc sc )
      dup d# 10 - swap                  ( cc ec sc )
   then  
;

: set-xpa-bias-level  ( is2GHz? -- )
   if  modalHeader2G  else  modalHeader5G  then  >xpaBiasLvl c@
   dup 8 << 300 16288 reg@!
   2 >> 4 or 7 16290 reg@!
;

: set-ant-ctrl  ( is2GHz? -- )
   if  modalHeader2G  else  modalHeader5G  then
   dup >antCtrlCommon le-l@  ffff and ffff a288 reg@!
   dup >antCtrlCommon2 le-l@  ff.ffff and ff.ffff a28c reg@!
   >antCtrlChain dup le-w@  fff and fff a284 reg@!
   wa1+ dup le-w@  fff and fff b284 reg@!
   wa1+ le-w@  fff and fff c284 reg@!
;

: set-drive-strength  ( -- )
   baseEepHeader >miscConfiguration c@ 1 and  0=  if  exit  then
   00b6.db40 00ff.ffc0 160c0 reg@!
   b6db.6da0 ffff.ffe0 160c4 reg@!
   b680.0000 ff80.0000 160cc reg@!
;

\ Arguments for interpolate-power
8 /n* buffer: px
8 /n* buffer: py
\ Local variables for interpolate-power
false value lhave  0 value lx  0 value ly
false value hhave  0 value hx  0 value hy
\ Returns the interpolated y value corresponding to the specified x value
\ from the np ordered pairs of data (px,py).
\ The pairs do not have to be in any order.
\ If the specified x value is less than any of the px,
\ the returned y value is equal to the py for the lowest px.
\ If the specified x value is greater than any of the px,
\ the returned y value is equal to the py for the highest px.
\
: set-hhave  ( idx -- )
   px over na+ @ to hx
   py swap na+ @ to hy
   true to hhave
;
: set-lhave  ( idx -- )
   px over na+ @ to lx
   py swap na+ @ to ly
   true to lhave
;
: interpolate-power  ( x #p -- y )
   \ identify best lower and higher x calibration measurement
   false to lhave  false to hhave
   0  do
      dup px i na+ @ -         ( x dx )
      dup 0<=  if
         hhave  if
            2dup swap hx - >  if  i set-hhave  then
         else
            i set-hhave
         then
      then
      dup 0>=  if
         lhave  if
            2dup swap lx - <  if  i set-lhave  then
         else
            i set-lhave
         then
      then  drop
   loop                         ( x )

   lhave  if
      hhave  if
         hx lx =  if  ly  else  dup lx hx ly hy interpolate  then
      else  ly  then
   else
      hhave  if  hy  else  c000.0000  then
   then  nip
;

: get-atten-chain  ( ch chain -- atten )
   over is-2ghz?  if
      modalHeader2G >xatten1DB + c@  nip
   else
      base_ext2 >xatten1DBLow over + c@  if
         base_ext2 >xatten1DBLow over + c@  py !
         modalHeader5G >xatten1DB over + c@ py na1+ !
         base_ext2 >xatten1DBHigh + c@ py 2 na+ !
         d# 5180 px !  d# 5500 px na1+ !  d# 5785 px 2 na+ !
         ( ch ) >ch-freq @ 3 interpolate-power
      else
         modalHeader5G >xatten1DB + c@  nip
      then
   then
;
: get-atten-chain-margin  ( ch chain -- atten )
   over is-2ghz?  if
      modalHeader2G >xatten1Margin + c@  nip
   else
      base_ext2 >xatten1MarginLow over + c@  if
         base_ext2 >xatten1MarginLow over + c@  py !
         modalHeader5G >xatten1Margin over + c@ py na1+ !
         base_ext2 >xatten1MarginHigh + c@ py 2 na+ !
         d# 5180 px !  d# 5500 px na1+ !  d# 5785 px 2 na+ !
         ( ch ) >ch-freq @ 3 interpolate-power
      else
         modalHeader5G >xatten1Margin + c@  nip
      then
   then
;

create ext-atten-reg  9e18 , ae18 , be18 ,
: set-atten  ( ch -- )
   3 0  do
      dup i get-atten-chain 3f and                          ( ch atten )
      over i get-atten-chain-margin 1f and d# 12 <<  or     ( ch atten' )
      1.f03f ext-atten-reg i na+ @ reg@!
   loop  drop
;

: set-internal-regulator  ( -- )
   baseEepHeader >featureEnable c@ 10 and  if
      0 1 700c reg@!
      baseEepHeader >swreg le-l@  7008 reg!
      1 1 700c reg@!
   else
      4 0 7048 reg@!   \ Force sw regulator
   then
;

: set-board-values  ( ch -- )
   dup is-2ghz?  set-xpa-bias-level
   dup is-2ghz?  set-ant-ctrl
   set-drive-strength
   ( ch ) set-atten
   set-internal-regulator
;

: get-tgt-pwr2G  ( freq idx -- power )
   3 0  do
      eeprom >calTarget_freqbin_2G i + c@ fbin2freq2G px i na+ !
      dup i calTargetPower2G@ py i na+ !
   loop  drop
   ( freq ) 3 interpolate-power
;
: get-tgt-pwr5G  ( freq idx -- power )
   8 0  do
      eeprom >calTarget_freqbin_5G i + c@ fbin2freq5G px i na+ !
      dup i calTargetPower5G@ py i na+ !
   loop  drop
   ( freq ) 8 interpolate-power
;
: get-tgt-pwr  ( freq idx is2Ghz? -- power )
   if  get-tgt-pwr2G  else  get-tgt-pwr5G  then  
;
: get-tgt-pwr-2Ght20  ( freq idx  -- power )
   3 0  do
      eeprom >calTarget_freqbin_2GHT20 i + c@ fbin2freq2G px i na+ !
      dup i calTargetPower2GHT20@ py i na+ !
   loop  drop
   ( freq ) 3 interpolate-power
;
: get-tgt-pwr-5Ght20  ( freq idx  -- power )
   8 0  do
      eeprom >calTarget_freqbin_5GHT20 i + c@ fbin2freq5G px i na+ !
      dup i calTargetPower5GHT20@ py i na+ !
   loop  drop
   ( freq ) 8 interpolate-power
;
: get-tgt-pwr-ht20  ( freq idx is2Ghz? -- power )  
   if  get-tgt-pwr-2Ght20  else  get-tgt-pwr-5Ght20  then  
;
: get-tgt-pwr-2Ght40  ( freq idx -- power )
   3 0  do
      eeprom >calTarget_freqbin_2GHT40 i + c@ fbin2freq2G px i na+ !
      dup i calTargetPower2GHT40@ py i na+ !
   loop  drop
   ( freq ) 3 interpolate-power
;
: get-tgt-pwr-5Ght40  ( freq idx -- power )
   8 0  do
      eeprom >calTarget_freqbin_5GHT40 i + c@ fbin2freq5G px i na+ !
      dup i calTargetPower5GHT40@ py i na+ !
   loop  drop
   ( freq ) 8 interpolate-power
;
: get-tgt-pwr-ht40  ( freq idx is2Ghz? -- power )
   if  get-tgt-pwr-2Ght40  else  get-tgt-pwr-5Ght40  then  
;
: get-tgt-pwr-cck  ( freq idx -- power )
   2 0  do
      eeprom >calTarget_freqbin_Cck i + c@ fbin2freq2G  px i na+ !
      dup i calTargetPowerCck@  py i na+ !
   loop  drop
   ( freq ) 2 interpolate-power
;

\ Variables local to tx-power* routines
/RateTable buffer: targetPowerValT2
/RateTable buffer: target_power_val_t2_eep

: pow@      ( idx -- val )  targetPowerValT2 + c@  ;
: pow-sm@   ( idx -- val )  pow@ 3f and  ;
: pow!      ( val idx -- )  targetPowerValT2 + c!  ;
: pow-eep@  ( idx -- val )  target_power_val_t2_eep + c@  ;
: pow-eep!  ( val idx -- )  target_power_val_t2_eep + c!  ;

: tx-power-reg!  ( -- )
   0 a458 reg!            \ Reset forced gain

   \ OFDM power per rate set
   ALL_TARGET_LEGACY_6_24 pow-sm@  dup dup dup bljoin  a3c0 reg! 
   ALL_TARGET_LEGACY_6_24 pow-sm@  ALL_TARGET_LEGACY_36 pow-sm@
   ALL_TARGET_LEGACY_48   pow-sm@  ALL_TARGET_LEGACY_54 pow-sm@
   bljoin a3c0 1 la+ reg!

   \ CCK power per rate set
   ALL_TARGET_LEGACY_1L_5L pow-sm@  0 over dup bljoin a3c0 2 la+ reg!
   ALL_TARGET_LEGACY_1L_5L pow-sm@  ALL_TARGET_LEGACY_5S  pow-sm@
   ALL_TARGET_LEGACY_11L   pow-sm@  ALL_TARGET_LEGACY_11S pow-sm@
   bljoin a3c0 3 la+ reg!

   \ Power for duplicated frames - HT40
   ALL_TARGET_LEGACY_1L_5L pow-sm@  ALL_TARGET_LEGACY_6_24 pow-sm@
   2dup bljoin a3e0 reg!

   \ HT20 power per rate set
   ALL_TARGET_HT20_0_8_16 pow-sm@  ALL_TARGET_HT20_1_3_9_11_17_19 pow-sm@
   ALL_TARGET_HT20_4      pow-sm@  ALL_TARGET_HT20_5              pow-sm@
   bljoin a3c0 4 la+ reg!

   ALL_TARGET_HT20_6  pow-sm@  ALL_TARGET_HT20_7  pow-sm@
   ALL_TARGET_HT20_12 pow-sm@  ALL_TARGET_HT20_13 pow-sm@
   bljoin a3c0 5 la+ reg!

   ALL_TARGET_HT20_14 pow-sm@  ALL_TARGET_HT20_15  pow-sm@
   ALL_TARGET_HT20_20 pow-sm@  ALL_TARGET_HT20_21 pow-sm@
   bljoin a3c0 9 la+ reg!

   \ Mixed HT20 and HT40 rates
   ALL_TARGET_HT20_22 pow-sm@  ALL_TARGET_HT20_23 pow-sm@
   ALL_TARGET_HT40_22 pow-sm@  ALL_TARGET_HT40_23 pow-sm@
   bljoin a3c0 d# 10 la+ reg!

   \ HT40 power per rate set
   ALL_TARGET_HT40_0_8_16 pow-sm@  ALL_TARGET_HT40_1_3_9_11_17_19 pow-sm@
   ALL_TARGET_HT40_4      pow-sm@  ALL_TARGET_HT40_5              pow-sm@
   bljoin a3c0 6 la+ reg!

   ALL_TARGET_HT40_6  pow-sm@  ALL_TARGET_HT40_7  pow-sm@
   ALL_TARGET_HT40_12 pow-sm@  ALL_TARGET_HT40_13 pow-sm@
   bljoin a3c0 7 la+ reg!

   ALL_TARGET_HT40_14 pow-sm@  ALL_TARGET_HT40_15  pow-sm@
   ALL_TARGET_HT40_20 pow-sm@  ALL_TARGET_HT40_21 pow-sm@
   bljoin a3c0 d# 11 la+ reg!
;

: set-target-power ( freq -- )
   dup d# 4000 <                      ( freq is2GHz? )
   ALL_TARGET_LEGACY_6_24 3dup swap get-tgt-pwr swap pow!
   ALL_TARGET_LEGACY_36   3dup swap get-tgt-pwr swap pow!
   ALL_TARGET_LEGACY_48   3dup swap get-tgt-pwr swap pow!
   ALL_TARGET_LEGACY_54   3dup swap get-tgt-pwr swap pow!

   over ALL_TARGET_LEGACY_1L_5L tuck get-tgt-pwr-cck swap pow!
   over LEGACY_TARGET_RATE_5S   tuck get-tgt-pwr-cck swap pow!
   over ALL_TARGET_LEGACY_11L   tuck get-tgt-pwr-cck swap pow!
   over ALL_TARGET_LEGACY_11S   tuck get-tgt-pwr-cck swap pow!

   ALL_TARGET_HT20_0_8_16         3dup swap get-tgt-pwr-ht20 swap pow!
   ALL_TARGET_HT20_1_3_9_11_17_19 3dup swap get-tgt-pwr-ht20 swap pow!
   ALL_TARGET_HT20_4              3dup swap get-tgt-pwr-ht20 swap pow!
   ALL_TARGET_HT20_5              3dup swap get-tgt-pwr-ht20 swap pow!
   ALL_TARGET_HT20_6              3dup swap get-tgt-pwr-ht20 swap pow!
   ALL_TARGET_HT20_7              3dup swap get-tgt-pwr-ht20 swap pow!
   ALL_TARGET_HT20_12             3dup swap get-tgt-pwr-ht20 swap pow!
   ALL_TARGET_HT20_13             3dup swap get-tgt-pwr-ht20 swap pow!
   ALL_TARGET_HT20_14             3dup swap get-tgt-pwr-ht20 swap pow!
   ALL_TARGET_HT20_15             3dup swap get-tgt-pwr-ht20 swap pow!
   ALL_TARGET_HT20_20             3dup swap get-tgt-pwr-ht20 swap pow!
   ALL_TARGET_HT20_21             3dup swap get-tgt-pwr-ht20 swap pow!
   ALL_TARGET_HT20_22             3dup swap get-tgt-pwr-ht20 swap pow!
   ALL_TARGET_HT20_23             3dup swap get-tgt-pwr-ht20 swap pow!

   ALL_TARGET_HT40_0_8_16         3dup swap get-tgt-pwr-ht40 swap pow!
   ALL_TARGET_HT40_1_3_9_11_17_19 3dup swap get-tgt-pwr-ht40 swap pow!
   ALL_TARGET_HT40_4              3dup swap get-tgt-pwr-ht40 swap pow!
   ALL_TARGET_HT40_5              3dup swap get-tgt-pwr-ht40 swap pow!
   ALL_TARGET_HT40_6              3dup swap get-tgt-pwr-ht40 swap pow!
   ALL_TARGET_HT40_7              3dup swap get-tgt-pwr-ht40 swap pow!
   ALL_TARGET_HT40_12             3dup swap get-tgt-pwr-ht40 swap pow!
   ALL_TARGET_HT40_13             3dup swap get-tgt-pwr-ht40 swap pow!
   ALL_TARGET_HT40_14             3dup swap get-tgt-pwr-ht40 swap pow!
   ALL_TARGET_HT40_15             3dup swap get-tgt-pwr-ht40 swap pow!
   ALL_TARGET_HT40_20             3dup swap get-tgt-pwr-ht40 swap pow!
   ALL_TARGET_HT40_21             3dup swap get-tgt-pwr-ht40 swap pow!
   ALL_TARGET_HT40_22             3dup swap get-tgt-pwr-ht40 swap pow!
   ALL_TARGET_HT40_23             3dup swap get-tgt-pwr-ht40 swap pow!

   2drop
;

: get-cal-pier  ( freq ipier ichain -- cor temp volt freq )
   rot d# 4000 >=  if                               ( ipier ichain )
      2dup refPower5G@ -rot                         \ cor
      2dup tempMeas5G@ -rot                         \ temp
      2dup voltMeas5G@ -rot                         \ volt
      drop eeprom >calFreqPier5G + c@ fbin2freq5G   \ freq
   else
      2dup refPower2G@ -rot                         \ cor
      2dup tempMeas2G@ -rot                         \ temp
      2dup voltMeas2G@ -rot                         \ volt
      drop eeprom >calFreqPier2G + c@ fbin2freq2G   \ freq
   then
;

\ Local calibration arrays
3 /n* buffer: lfreq      3 /n* buffer: hfreq
3 /n* buffer: lcorr      3 /n* buffer: hcorr      3 /n* buffer: corr
3 /n* buffer: ltemp      3 /n* buffer: htemp      3 /n* buffer: temp
3 /n* buffer: lvolt      3 /n* buffer: hvolt      3 /n* buffer: volt

: override-power-control  ( freq -- )
   corr @ ff and d# 16 << ff.0000 a420 reg@!
   tx-chainmask 2 and  if  corr 1 na+ @ ff and d# 16 << ff.0000 b420 reg@!  then
   tx-chainmask 4 and  if  corr 2 na+ @ ff and d# 16 << ff.0000 c420 reg@!  then

   \ Enable open loop power control on chip
   300.0000 dup a40c reg@!
   tx-chainmask 2 and  if  300.0000 dup b40c reg@!  then
   tx-chainmask 4 and  if  300.0000 dup c40c reg@!  then

   \ Enable temperature compensation
   dup d# 4000 <  if
      tempSlope2G@
   else
      tempSlopeLow@  if
         tempSlopeLow@  py !  tempSlope5G@ py na1+ !  tempSlopeHigh@ py 2 na+ !
         d# 5180 px !  d# 5500 px na1+ !  d# 5785 px 2 na+ !
         dup 3 interpolate-power
      else
         tempSlope5G@
      then
   then    ff a440 reg@!
   temp c@ ff a43c reg@!
   drop
;

: hfreq@  ( ichain -- hfreq )  hfreq swap na+ @  ;
: lfreq@  ( ichain -- lfreq )  lfreq swap na+ @  ;
: use-low  ( ichain -- )
   >r
   lcorr r@ na+ @ corr r@ na+ !
   lvolt r@ na+ @ volt r@ na+ !
   ltemp r@ na+ @ temp r> na+ !
;
: use-high  ( ichain -- )
   >r
   hcorr r@ na+ @ corr r@ na+ !
   hvolt r@ na+ @ volt r@ na+ !
   htemp r@ na+ @ temp r> na+ !
;
: set-calibration  ( freq -- )
   3 0  do  0 lfreq i na+ !  d# 10.0000 hfreq i na+ !  loop

   \ Identify best lower and higher frequency calibration measurements
   3 0  do
      dup d# 4000 >=  if  8  else  3  then  0  do
         dup i j get-cal-pier        ( freq cor temp volt pfreq )
         dup 5 pick >=  if           ( freq cor temp volt pfreq )
            dup j hfreq@ <=  if      ( freq cor temp volt pfreq )
               dup    hfreq j na+ !  over   hvolt j na+ !
               2 pick htemp j na+ !  3 pick hcorr j na+ !
            then
         then                        ( freq cor temp volt pfreq )
         dup 5 pick <=  if           ( freq cor temp volt pfreq )
            dup j lfreq@ >=  if      ( freq cor temp volt pfreq )
               dup    lfreq j na+ !  over   lvolt j na+ !
               2 pick ltemp j na+ !  3 pick lcorr j na+ !
            then
         then  4drop                 ( freq )
      loop                           ( freq )
   loop                              ( freq )

   \ Interpolate
   3 0  do
      i hfreq@ i lfreq@ =  if              \ Same, pick one
         i use-low
      else
         dup i lfreq@ - d# 1000 <  if      \ Low is good
            i hfreq@ over - d# 1000 <  if  \ High is good too
               dup i lfreq@ i hfreq@ lcorr i na+ @ hcorr i na+ @  interpolate  corr i na+ !
               dup i lfreq@ i hfreq@ lvolt i na+ @ hvolt i na+ @  interpolate  volt i na+ !
               dup i lfreq@ i hfreq@ ltemp i na+ @ htemp i na+ @  interpolate  temp i na+ !
            else                           \ Only low is good
               i use-low
            then
         else                              \ Low is not good
            i hfreq@ over - d# 1000 <  if  \ Only high is good
               i use-high
            else                           \ No good value
               0 corr i na+ !  0 volt i na+ !  0 temp na+ !
            then
         then
      then
   loop

   override-power-control
;

: get-direct-edge-power2G  ( ctl edge -- power )  ctlPowerData_2G@  ;
: get-direct-edge-power5G  ( ctl edge -- power )  ctlPowerData_5G@  ;

: get-indirect-edge-power2G  ( freq ctl edge -- power )
   d# 63  >r           \ Default to max power
   2dup ctlPowerData_2G@ c0 and  if
      2dup ctl_freqbin_2G@ fbin2freq2G 3 pick <  if
         2dup ctlPowerData_2G@ 3f and  r> drop  >r
      then
   then  3drop
   r>
;
: get-indirect-edge-power5G  ( freq ctl edge -- power )
   d# 63  >r           \ Default to max power
   2dup ctlPowerData_5G@ c0 and  if
      2dup ctl_freqbin_5G@ fbin2freq5G 3 pick <  if
         2dup ctlPowerData_5G@ 3f and  r> drop  >r
      then
   then  3drop
   r>
;
: get-max-edge-power2G  ( freq ctl -- power )
   d# 63 -rot                  ( power freq ctl )
   4 0  do
      dup i ctl_freqbin_2G@ fbin2freq2G 2 pick =  if
         rot drop
         dup i get-direct-edge-power2G  -rot    ( power' freq ctl )
         leave
      else
         i 0>  if
            dup i ctl_freqbin_2G@ fbin2freq2G 2 pick >  if
               rot drop
               2dup i 1- get-indirect-edge-power2G -rot  ( power' freq ctl )
               leave
            then
         then
      then
   loop  2drop
;
: get-max-edge-power5G  ( freq ctl -- power )
   d# 63 -rot                        ( power freq ctl )
   8 0  do
      dup i ctl_freqbin_5G@ fbin2freq5G 2 pick =  if
         rot drop
         dup i get-direct-edge-power5G -rot  ( power' freq ctl )
         leave
      else
         i 0>  if
            dup i ctl_freqbin_5G@ fbin2freq5G 2 pick >  if
               rot drop
               2dup i 1- get-indirect-edge-power5G -rot  ( power' freq ctl )
               leave
            then
         then
      then
   loop  2drop
;
: get-max-edge-power  ( freq ctl is2GHz? -- power )
   if  get-max-edge-power2G  else  get-max-edge-power5G  then
;

: get-#txchains  ( mask -- )
   0  3 0  do
      over i >> 1 and +
   loop  nip
;
create tpScaleReductionTable 0 c, 3 c, 6 c, 9 c, d# 63 c,
create ctlModesFor11a  CTL_11A , CTL_5GHT20 , CTL_11A_EXT , CTL_5GHT40  ,
create ctlModesFor11g  CTL_11B , CTL_11G ,    CTL_2GHT20  , CTL_11B_EXT , CTL_11G_EXT , CTL_2GHT40 ,
0 value 'ctlMode
0 value tscaledPower
0 value tchan
0 value tcfgctl      \ Care about the upper nibble only
0 value tfreq
0 value 'ctlIndex
d# 63 value twiceMaxEdgePower
0 value tminCtlPower
0 value tsynth-center  0 value text-center  0 value tctl-center
: ctlMode@   ( idx -- val )  'ctlMode swap na+ @  ;
: ctlIndex@  ( idx -- val )  'ctlIndex + c@  ;
: set-power-array  ( start end -- )
   1+ swap  do
      tminCtlPower targetPowerValT2 i + c@ min targetPowerValT2 i + c!
   loop
;
: set-power-per-rate-table  ( ch cfgctl powerLimit twiceMaxRegPower twiceAntRed -- )
   d# 63 to twiceMaxEdgePower
   4 pick get-chan-centers  to tsynth-center  to text-center  to tctl-center

   \ Compute TxPower reduction due to antenna gain
   \ scaledPower is the min of user input power level and regulatory allowed power level
   4 pick is-2GHz?  if  antennaGain2G@  else  antennaGain5G@  then  - 0 min +  \ maxRegAllowedPower
   ( powerLimit maxRegAllowedPower ) min   ( ch cfgctl scaledPower )
   -rot f0 and to tcfgctl  to tchan        ( scaledPower )
   
   \ Reduce scaled power by # of chains active to get per chain tx power level
   txchainmask get-#txchains  case
      2  of      6 -  endof
      3  of  d# 10 -  endof
   endcase  0  max  to tscaledPower

   tchan is-2GHz?  if
      ctlModesFor11g to 'ctlMode
      tchan is-ht40?  if  6  else  3  then
   else
      ctlModesfor11a to 'ctlMode
      tchan is-ht40?  if  4  else  2  then
   then

   \ For MIMO, need to apply regulatory caps individually across
   \ dynamically running modes: CCK, OFDM, HT20, HT40
   \
   \ The outer loop walks through each possible applicable runtime mode.
   \ The inner loop walks through each ctlIndex entry in EEPROM.
   \ The ctl value is encoded as [7:4] == test group, [3:0] == test mode.
   0  do
      i ctlMode@ dup CTL_5GHT40 = swap CTL_2GHT40 = or
      if  tsynth-center
      else  i ctlMode@ 8000 and  if
         text-center
      else
         tctl-center
      then  then  to tfreq

      \ Walk through each CTL index in eeprom
      tchan is-2GHz?  if
         eeprom >ctlIndex_2G to 'ctlIndex  d# 12
      else
         eeprom >ctlIndex_5G to 'ctlIndex  9
      then

      0  do
         i ctlIndex@ 0=  if  leave  then
         
         tcfgctl j ctlMode@ f and or  i ctlIndex@ =
         tcfgctl j ctlMode@ f and or  i ctlIndex@ f and e0 or =  or  if
            tfreq i tchan is-2GHz? get-max-edge-power  \ twiceMinEdgePower
            tcfgCtl e0 =  if
               twiceMaxEdgePower min  to twiceMaxEdgePower
            else
               to twiceMaxEdgePower
               leave
            then
         then
      loop
      tscaledPower twiceMaxEdgePower min  to tminCtlPower

      \ Apply CTL mode to correct target power set
      i ctlMode@  case
         CTL_11B  of  ALL_TARGET_LEGACY_1L_5L ALL_TARGET_LEGACY_11S  set-power-array  endof
         CTL_11A  of  ALL_TARGET_LEGACY_6_24 ALL_TARGET_LEGACY_54  set-power-array  endof
         CTL_11G  of  ALL_TARGET_LEGACY_6_24 ALL_TARGET_LEGACY_54  set-power-array  endof
         CTL_2GHT20  of  ALL_TARGET_HT20_0_8_16 ALL_TARGET_HT20_23  set-power-array  endof
         CTL_5GHT20  of  ALL_TARGET_HT20_0_8_16 ALL_TARGET_HT20_23  set-power-array  endof
         CTL_2GHT40  of  ALL_TARGET_HT40_0_8_16 ALL_TARGET_HT40_23  set-power-array  endof
         CTL_5GHT40  of  ALL_TARGET_HT40_0_8_16 ALL_TARGET_HT40_23  set-power-array  endof
      endcase
   loop
;

: mcsidx-to-tgtpwridx  ( mcs-idx base-idx -- pwridx )
   over 7 and            ( mcs-idx base-idx mod-idx )
   ?dup 0=  if  nip exit  then
   3 >  if
      over 3 >> 2 << + swap 7 and 2 - +
   else
      1+ nip
   then                  ( pwridx )
;

: get-paprd-scale-factor  ( ch -- val )
   dup is-2ghz?  if
      modalHeader2G >papdRateMaskHt20 le-l@ d# 25 >>
   else
      dup >ch-freq @
      dup d# 5700 >=  if
         drop modalHeader5G >papdRateMaskHt20 le-l@ d# 25 >>
      else
         modalHeader5G >papdRateMaskHt40 le-l@
         swap d# 5400 >=  if  d# 28  else  d# 25  then  >>
      then
   then  nip
;

: is-wwr-sku?  ( regd -- flag )
   dup and 8000 0=           ( regd flag )
   over WORLD = 	     ( regd flag flag )
   rot f0 and f0 = or and    ( flag' )
;
: get-band-ctl  ( ch -- ctl )
   regulatory 0=  if  drop SD_NO_CTL exit  then
   regulatory >reg-country @ 0= 
   regulatory >reg-cur-rd @ 3fff and  is-wwr-sku?  and  if  drop SD_NO_CTL exit  then
   dup >ch-band @ BAND_2GHZ =  if  drop regulatory >reg-pair @ >reg-2ghz-ctl @ exit  then
   dup >ch-band @ BAND_5GHZ =  if  drop regulatory >reg-pair @ >reg-5ghz-ctl @ exit  then
   drop NO_CTL
;
: get-regd-ctl  ( ch -- ctl )
   dup get-band-ctl
   over is-b?  if  CTL_11B or  nip exit  then
   swap is-g?  if  CTL_11G  else  CTL_11A  then  or
;

0 value cfgCtl
0 value twiceAntennaReduction
0 value twiceMaxRegulatoryPower
0 value powerLimit
0 value paprd-scale-factor
0 value min-pwridx
: (set-txpower)  ( ch -- )
    dup >ch-freq @ set-target-power
    baseEepHeader >featureEnable c@ 20 and  if
       dup is-2GHz?  if  modalHeader2G  else  modalHeader5G  then
       dup >papdRateMaskHt20 le-l@ 1ff.ffff and to paprd-ratemask
           >papdRateMaskHt40 le-l@ 1ff.ffff and to paprd-ratemask-ht40
       dup get-paprd-scale-factor to paprd-scale-factor
       dup is-ht40?  if  ALL_TARGET_HT40_0_8_16  else  ALL_TARGET_HT20_0_8_16  then
       to min-pwridx
       paprd-table-write-done? not  if
          targetPowerValT2 target_power_val_t2_eep /RateTable move
          d# 24 0  do
             i min-pwridx  mcsidx-to-tgtpwridx         ( pwridx )
             paprd-ratemask 1 i << and  if             ( pwridx )
                dup pow@ ?dup  if                      ( pwridx pwr )
                   over pow-eep@ over =  if            ( pwridx pwr )
                      paprd-scale-factor - swap pow!   ( )
                   else  2drop  then
                else  drop  then
             else  drop  then
          loop
       then
       targetPowerValT2 target_power_val_t2_eep /RateTable move
    then

    ( ch ) dup get-regd-ctl                  ( ch cfgctl )
    regulatory >reg-power-limit @ d# 63 min  ( ch cfgctl powerLimit )
    2 pick >ch-max-power @ 2*                ( ch cfgctl pl 2maxregpwr )
    3 pick >ch-max-antenna-gain @ 2*         ( ch cfgctl pl 2maxregpwr 2maxag )
    set-power-per-rate-table                 ( )

    baseEepHeader >featureEnable c@ 20 and  if
       /RateTable 0  do
          paprd-ratemask 1 i << and  if
             i pow@ i pow-eep@ - abs paprd-scale-factor >  if
                paprd-ratemask 1 i << invert and to paprd-ratemask
             then
          then
       loop
    then

    0 regulatory >reg-max-power !
    /RateTable 0  do
       i pow@ regulatory >reg-max-power @  max
       regulatory >reg-max-power !
    loop
;
: set-txpower  ( ch test? -- )
    over (set-txpower)
    ( test? )  if  drop exit  then

    \ This is the TX power we send back to driver core.
    \ Since power is rate dependent, use one of the indices
    \ from the AR9300_Rates enum to select an entry from
    \ targetPowerValT2[] to report. Currently returns the
    \ power for HT40 MCS 0, HT20 MCS 0, or OFDM 6 Mbps
    \ as CCK power is less interesting (?).
    dup is-ht40?  if
       ALL_TARGET_HT40_0_8_16
    else  dup is-ht20?  if 
       ALL_TARGET_HT20_0_8_16
    else
       ALL_TARGET_LEGACY_6_24
    then  then                  ( ch i )
    pow@ regulatory >reg-max-power !

    \ Write target power array to registers
    tx-power-reg!
    dup >ch-freq @ set-calibration

    dup is-2GHz?  if
       is-ht40?  if  ALL_TARGET_HT40_0_8_16  else  ALL_TARGET_HT20_0_8_16  then
    else
       is-ht40?  if  ALL_TARGET_HT40_7  else  ALL_TARGET_HT20_7  then
    then
    pow@ to paprd-target-power
;

: chansel-2GHz  ( freq -- freq' )  1.0000 * d# 15 /  ;
: chansel-5GHz  ( freq -- freq' )    8000 * d# 15 /  ;
: set-channel  ( ch -- )
   dup get-chan-centers nip nip         ( ch freq )
   dup d# 4800 <  if
      chansel-2GHz  1
   else
      chansel-5GHz 1 >>  0
   then                                 ( ch freq' synth-control )
   d# 29 << a340 reg!                   \ PHY synthesizer control
   2 dup 1608c reg@!                    \ Enable long shift
   ( freq ) 2 <<  4000.0000 or dup 16098 reg!    \ Program synthesizer
   8000.0000 or 16098 reg!              \ Toggle load synth channel bit
   to curchan
;

false value spur-in-range?
create spur-freq  d# 2420 , d# 2440 , d# 2464 , d# 2480 ,
: spur-mitigate-mrc-cck  ( ch -- )
   false to spur-in-range?
   >ch-freq @
   4 0  do
      spur-freq i na+ @ over -       \ cur_bb_spur
      dup abs d# 10 <  if
         true to spur-in-range?
         1c0 3c0 a2c4 reg@!
         d# 19 << d# 11 / f.ffff and 9 <<
         4000.00ff or 8000.0000 9fcc reg@!
         leave
      else  drop  then
   loop  drop
   spur-in-range? 0=  if
      140 3c0 a2c4 reg@!
      0 e000.1ffe 9fcc reg@!
   then
;

: spur-ofdm-clear  ( -- )
   0 f000.0000 980c reg@!
   0 9818 reg!
   0 1000.0000 982c reg@!
   0 07fe.0100 981c reg@!
   0 0000.0fff 9c0c reg@!
   0 0001.ffff a220 reg@!
   0 0000.0fff 9c10 reg@!
;

: spur-ofdm  ( freq-offset spur-subch-sd spur-delta sfreq-sd -- )
   4000.0000 dup 980c reg@!
   ( spur-delta sfreq-sd ) d# 20 << or 3fff.ffff 9818 reg@!
   ( spur-subch-sd )       d# 28 <<    1000.0000 982c reg@!
   c000.0000 dup 9818 reg@!
   8000.0000 dup 980c reg@!
   122 0000.01ff 981c reg@!
   a208 reg@ 4 and  if  400.0000 dup 981c reg@!  then

   ( freq_offset )  4 << 5 /  dup 0<  if  1-  then  7f and   ( mask-index )
 
   0002.0000 dup 981c reg@!
   3000.0000 dup 980c reg@!  
   dup 5 << c or 0000.0fff 9c0c reg@!
   dup d# 10 << a0 or 0001.ffff a220 reg@!
       5 << c or 0000.0fff 9c10 reg@!
   03fc.0000 dup 981c reg@!
;

: spur-ofdm-work  ( freq-offset ch -- )
   is-ht40?  if
      dup 0<  if
         a204 reg@  10 and  if  0  else  1  then  ( freq-offset spur-subch-sd )
	 over d# 10 +              ( freq-offset spur-subch-sd spur-freq-sd )
      else
         a204 reg@  10 and  if  1  else  0  then  ( freq-offset spur-subch-sd )
         over d# 10 -              ( freq-offset spur-subch-sd spur-freq-sd )
      then
      2 pick d# 17 <<      ( freq-offset spur-subch-sd spur-freq-sd spur-delta-phase )
   else
      0 over dup d# 18 <<  ( freq-offset spur-subch-sd spur-freq-sd spur-delta-phase )
   then
   ( spur-delta-phase )  5 / f.ffff and swap
   ( spur-freq-sd )  d# 11 /    3ff and
   spur-ofdm               ( )
;

0 value range
0 value synth-freq
: spur-mitigate-ofdm2G  ( ch -- )
   modalHeader2G >spurChans c@ 0=  if  drop exit  then

   dup >ch-freq @              ( ch freq )
   over is-ht40?  if
      d# 10  a204 reg@ 10 and  if  +  else  -  then
      d# 19
   else
      d# 10
   then  to range  to synth-freq
   spur-ofdm-clear

   5 0  do                     ( ch )
      modalHeader2G >spurChans i + c@ ?dup 0=  if  leave  then
      ( spurChans ) fbin2freq2G synth-freq -   \ freq_offset
      dup abs  range <  if  over spur-ofdm-work  else  drop  then
   loop  drop
;
: spur-mitigate-ofdm5G  ( ch -- )
   modalHeader5G >spurChans c@ 0=  if  drop exit  then

   dup >ch-freq @              ( ch freq )
   over is-ht40?  if
      d# 10  a204 reg@ 10 and  if  +  else  -  then
      d# 19
   else
      d# 10
   then  to range  to synth-freq
   spur-ofdm-clear

   5 0  do                     ( ch )
      modalHeader5G >spurChans i + c@ ?dup 0=  if  leave  then
      ( spurChans ) fbin2freq5G synth-freq -   \ freq_offset
      dup abs  range <  if  over spur-ofdm-work  else  drop  then
   loop  drop
;
: spur-mitigate-ofdm  ( ch -- )
   dup is-5GHz?  if  spur-mitigate-ofdm5G  else  spur-mitigate-ofdm2G  then
;

: spur-mitigate  ( ch -- )
   dup spur-mitigate-mrc-cck
       spur-mitigate-ofdm
;

: compute-pll-control  ( ch -- pll )
   ?dup 0=  if  1400 exit  then
   142c
   over is-half-rate?  if  4000 or  then
   swap is-quarter-rate?  if  8000 or  then
;

: set-11nmac2040  ( -- )
   conf-is-ht40?  if  1  else  0  then
   8318 reg!
;

: set-ch-regs  ( ch -- )
   a204 reg@ 3c0 or
   over is-ht40?  if
      4 or  over >ch-mode @ CH_HT40+ and  if  10 or  then
   then
   400 invert and  a204 reg!
   is-ht40?  if  1  else  0  then  8318 reg!
   50.0000 64 reg!
   f.0000  6c reg!
;

: init-bb  ( ch -- )
   1 a20c reg!             \ Activate PHY
   a254 reg@  3fff and
   swap is-b?  if  4 * d# 22 / else  d# 10 /  then
   d# 100 + us
;

: set-chain-masks  ( tx rx -- )
   dup 5 =  if  40 dup a34c reg@!  then
   dup 1 3 between over  5 = or  over 7 =  or  if
      dup a2a0 reg!  dup a2c0 reg!
   then  drop

   hw-caps HW_CAP_APM and  if  3  else  dup  then  832c reg!
   5 =  if  40 dup a34c reg@!  then
;

: override-ini  ( -- )
   0200.0020 dup 8048 reg@!
   2.0008 40 8344 reg@!
;

0 value array-#col
: array@  ( col array row -- data )  array-#col /n* * +  swap /n* + @  ;
: array-reg!  ( col array #row #col -- )
   to array-#col
   ( #row ) 0  do             ( col array )
      2dup i array@           ( col array val )
      0 2 pick i array@       ( col array val reg )
      reg!  1 us              ( col array )
   loop  2drop
;

: process-ini  ( ch -- )
   dup >ch-mode @ >r
   r@ CH_A =  r@ CH_A_HT20 = or  if  1 
   else  r@ CH_A_HT40+ =  r@ CH_A_HT40- =  or  if  2
   else  r@ CH_G =  r@ CH_G_HT20 = or  r@ CH_B =  or  if  4
   else  3  then then then       ( modesIdx )
   r> drop

   1   array-soc-preamble    soc-preamble-#row    2 array-reg!
   1   array-mac-core        mac-core-#row        2 array-reg!
   1   array-bb-core         bb-core-#row         2 array-reg!
   1   array-radio-core      radio-core-#row      2 array-reg!
   dup array-soc-postamble   soc-postamble-#row   5 array-reg!
   dup array-mac-postamble   mac-postamble-#row   5 array-reg!
   dup array-bb-postamble    bb-postamble-#row    5 array-reg!
   dup array-radio-postamble radio-postamble-#row 5 array-reg!
   1   array-rx-gain         rx-gain-#row         2 array-reg!
   dup array-tx-gain         tx-gain-#row         5 array-reg!

   over is-a-fast?  if
      dup  array-fast-clk fast-clk-#row 3 array-reg!
   then  drop

   override-ini
   dup set-ch-regs
   txchainmask rxchainmask set-chain-masks

   ( ch ) false set-txpower
;

: set-rfmode  ( ch -- )
   ?dup 0=  if  exit  then
   dup  is-b?  over is-g? or  if  4  else  0  then
   swap is-a-fast?  if  104 or  then
   a208 reg!
;

: mark-phy-inactive  ( -- )  0 a20c reg!  ; 

: log2  ( n -- log2-of-n )
   0  begin        ( n log )
      swap 1 >>    ( log n' )
   ?dup  while     ( log n' )
      swap 1+      ( n' log' )
   repeat          ( log )
;
: get-delta-slope-vals  ( coef -- man exp )
   dup log2                          ( coef exp )
   d# 38 swap -                      ( coef exp' )
   tuck d# 23 swap - 1 swap << +     ( exp man )
   d# 24 2 pick - >>                 ( exp man' )
   swap d# 16 -                      ( man exp' )
;

: set-delta-slope  ( ch -- )
   6400.0000                              ( ch coef )
   over is-half-rate?     if  1 >>  then  ( ch coef' )
   over is-quarter-rate?  if  2 >>  then  ( ch coef' )

   \ ALGO -> coef = 1e8/fcarrier*fclock/40
   swap get-chan-centers  nip nip /       ( coef' )
   dup get-delta-slope-vals               ( coef man exp )
   f and d# 13 << swap  7fff and d# 17 << or  ffff.e000  9808 reg@!

   \ For short GI, scaled coeff is 9/10 that of normal coeff
   9 * d# 10 /                            ( coef' )
   get-delta-slope-vals                   ( man exp )
   f and swap 7fff and 4 << or 7.ffff  9c14 reg@!
;

: rfbus-req?  ( -- ok? )
   1 a23c reg!          \ Enable RF bus request
   1 1 a240 wait-hw
;

: rfbus-done  ( -- )
   a254 reg@ 3fff and      ( ch rx-delay )
   curchan is-b?  if  4 * d# 22 /  else  d# 10 /  then
   d# 100 + us
   0 a23c reg!
;

: set-diversity  ( set? -- )
   if  2000  else  0  then  2000 9fc0 reg@!
;

: set-radar  ( -- )
   e400.a611 9834 reg!
   0008.ccff 9838 reg!
   0 4000 983c reg@!
;

: config-bb-watchdog  ( timeout -- )
   ?dup  if
      d# 10000 min            \ bound limit to 10 secs
      4 6 a7c8 reg@!
      \ The time unit for watchdog event is 2^15 44/88MHz cycles.
      \ For HT20 we have a time unit of 2^15/44 MHz = .74 ms per tick
      \ For HT40 we have a time unit of 2^15/88 MHz = .37 ms per tick
      d# 100 *
      curchan is-ht40?  if  d# 37  else  d#  74  then  /  fffc and
      ffff.0002 or a7c4 reg!
   else
      0 6 a7c8 reg@!
      0 3 a7c4 reg@!
   then
;

: read-bb-watchdog  ( -- )
   0 8 a7c0 reg@!           \ Reset and clear watchdog status
;

: set-tx-gain-table  ( -- )
   eeprom >baseEepHeader >txrxgain c@ 4 >>  case
      0  of  array-tx-gain-lowest to array-tx-gain
             tx-gain-lowest-#row  to tx-gain-#row
             endof
      1  of  array-tx-gain-hi to array-tx-gain
             tx-gain-hi-#row  to tx-gain-#row
             endof
      2  of  array-tx-gain-low to array-tx-gain
             tx-gain-low-#row  to tx-gain-#row
             endof
      3  of  array-tx-gain-hi to array-tx-gain
             tx-gain-hi-#row  to tx-gain-#row
             endof
   endcase
;

: set-rx-gain-table  ( -- )
   eeprom >baseEepHeader >txrxgain c@ f and  case
      0  of  array-rx-gain-common to array-rx-gain
             rx-gain-common-#row  to rx-gain-#row
             endof
      1  of  array-rx-gain-wo-xlna to array-rx-gain
             rx-gain-wo-xlna-#row  to rx-gain-#row
	     endof
   endcase
;

: init-mode-gain-tables  ( -- )
   set-tx-gain-table
   set-rx-gain-table
;

: config-pci-powersave  ( restore? -- )
   0=  if
      8.0000 dup 4014 reg@!    \ Allow forcing of PCIe core into L1 state
      WARegVal 4004 reg!
   then

   1 array-pcie-serdes pcie-serdes-#row 2 array-reg!
;

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
