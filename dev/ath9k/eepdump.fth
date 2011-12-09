purpose: Atheros 9382 "EEPROM" dump
\ See license at end of file

headers
hex

: scdump  ( adr len -- )  bounds  ?do  i sign-c@  s.  loop  ;
: .tab  ( -- )  ."   "  ;
: .array   ( adr x y -- )  0  do  .tab 2dup cdump cr  loop  2drop  ;
: .warray  ( adr x -- )  0  do  dup i wa+ le-w@ . .tab  loop  drop  ;
: .baseEepHeader  ( adr -- )
   dup >regDmn0 le-w@              ."   regDmn0 =                " . cr
   dup >regDmn1 le-w@              ."   regDmn1 =                " . cr
   dup >txrxMask c@                ."   txrxMask =               " . cr
   dup >opFlags c@                 ."   opFlags =                " . cr
   dup >eepMisc c@                 ."   eepMisc =                " . cr
   dup >rfSilent c@                ."   rfSilent =               " . cr
   dup >blueToothOptions c@        ."   blueToothOptions =       " . cr
   dup >deviceCap c@               ."   deviceCap =              " . cr
   dup >deviceType c@              ."   deviceType =             " . cr
   dup >pwrTableOffset sign-c@     ."   pwrTableOffset =         " s. cr
   dup >params_for_tuning_caps c@  ."   params_for_tuning_caps = " . cr
   dup >featureEnable c@           ."   featureEnable =          " . cr
   dup >miscConfiguration c@       ."   miscConfiguration =      " . cr
   dup >eepromWriteEnableGpio c@   ."   eepromWriteEnableGpio =  " . cr
   dup >wlanDisableGpio c@         ."   wlanDisableGpio =        " . cr
   dup >rxBandSelectGpio c@        ."   rxBandSelectGpio =       " . cr
   dup >txrxgain c@                ."   txrxgain =               " . cr
       >swreg le-l@                ."   swreg =                  " . cr
;
: .modalHeader  ( adr -- )
   dup >antCtrlCommon le-l@        ."   antCtrlCommon =          " . cr
   dup >antCtrlCommon2 le-l@       ."   antCtrlCommon2 =         " . cr
   dup >antCtrlChain               ."   antCtrlChain =           " 3 .warray cr
   dup >xatten1DB                  ."   xatten1DB =              " 3 cdump cr
   dup >xatten1Margin              ."   xatten1Margin =          " 3 cdump cr
   dup >tempSlope sign-c@          ."   tempSlope =              " s. cr
   dup >voltSlope sign-c@          ."   voltSlope =              " s. cr
   dup >spurChans                  ."   spurChans =              " 5 cdump cr
   dup >noiseFloorThreshCh         ."   noiseFloorThreshCh =     " 3 scdump cr
   dup >ob                         ."   ob =                     " 3 cdump cr
   dup >db_stage2                  ."   db_stage2 =              " 3 cdump cr
   dup >db_stage3                  ."   db_stage3 =              " 3 cdump cr
   dup >db_stage4                  ."   db_stage4 =              " 3 cdump cr
   dup >xpaBiasLvl c@              ."   xpaBiasLvl =             " . cr
   dup >txFrameToDataStart c@      ."   txFrameToDataStart =     " . cr
   dup >txFrameToPaOn c@           ."   txFrameToPaOn =          " . cr
   dup >txClip c@                  ."   txClip =                 " . cr
   dup >antennaGain sign-c@        ."   antennaGain =            " s. cr
   dup >switchSettling c@          ."   switchSettling =         " . cr
   dup >adcDesiredSize sign-c@     ."   adcDesiredSize =         " s. cr
   dup >txEndToXpaOff c@           ."   txEndToXpaOff =          " . cr
   dup >txEndToRxOn c@             ."   txEndToRxOn =            " . cr
   dup >txFrameToXpaOn c@          ."   txFrameToXpaOn =         " . cr
   dup >thresh62 c@                ."   thresh62 =               " . cr
   dup >papdRateMaskHt20 le-l@     ."   papdRateMaskHt20 =       " . cr
       >papdRateMaskHt40 le-l@     ."   papdRateMaskHt40 =       " . cr
;
: .base_ext2  ( adr -- )
   dup >tempSlopeLow sign-c@   ."   tempSlopeLow =           " s. cr
   dup >tempSlopeHigh sign-c@  ."   tempSlopeHigh =          " s. cr
   dup >xatten1DBLow           ."   xatten1DBLow =           " 3 cdump cr
   dup >xatten1MarginLow       ."   xatten1MarginLow =       " 3 cdump cr
   dup >xatten1DBHigh          ."   xatten1DBHigh =          " 3 cdump cr
       >xatten1MarginHigh      ."   xatten1MarginHigh =      " 3 cdump cr
;
: .tabx  ( -- )  ."      "  ;
: .calPierData  ( adr #piers #chains -- )
   ."   chain#  pier#  refPwr voltM  tempM  rxNFC  rxNFP  rxTempM" cr
   0  do                          ( adr #piers )
      dup 0  do                   ( adr #piers )
         .tabx j .  .tabx  i .  .tabx
         2dup j * i + /cal-data-per-freq-op-loop * +     ( adr #piers adr )
         dup >refPower sign-c@           s. .tabx
         dup >voltMeas c@                . .tabx
         dup >tempMeas c@                . .tabx
         dup >rxNoisefloorCal sign-c@    s. .tabx
         dup >rxNoisefloorPower sign-c@  s. .tabx
             >rxTempMeas c@              . cr
      loop
   loop  2drop
;

: .eeprom  ( -- )
   eeprom >r
   r@ >eepromVersion c@         ." EEPROM version =           " . cr
   r@ >templateVersion c@       ." Template version =         " . cr
   r@ >macAddr                  ." MAC address =              " 6 cdump cr
   r@ >custData                 ." Customer data =            " d# 20 cdump cr
   r@ >baseEepHeader            ." Base EEPROM Header:" cr  .baseEepHeader cr

   r@ >modalHeader2G            ." 2GHz Modal Header:" cr  .modalHeader cr
   r@ >base_ext1                ." base_ext1 =                " d# 14 cdump cr
   r@ >calFreqPier2G            ." calFreqPier2G =            " 3 cdump cr
   r@ >calPierData2G            ." calPierData2G:" cr  3 3 .calPierData
   r@ >calTarget_freqbin_Cck    ." calTarget_freqbin_Cck =    " 2 cdump cr
   r@ >calTarget_freqbin_2G     ." calTarget_freqbin_2G =     " 3 cdump cr
   r@ >calTarget_freqbin_2GHT20 ." calTarget_freqbin_2GHT20 = " 3 cdump cr
   r@ >calTarget_freqbin_2GHT40 ." calTarget_freqbin_2GHT40 = " 3 cdump cr
   r@ >calTargetPowerCck        ." calTargetPowerCck.tPow2x:"    cr      4 2 .array
   r@ >calTargetPower2G         ." calTargetPower2G.tPow2x:"     cr      4 3 .array
   r@ >calTargetPower2GHT20     ." calTargetPower2GHT20.tPow2x:" cr  d# 14 3 .array
   r@ >calTargetPower2GHT40     ." calTargetPower2GHT40.tPow2x:" cr  d# 14 3 .array
   r@ >ctlIndex_2G              ." ctlIndex_2G =              " d# 12 cdump cr
   r@ >ctl_freqbin_2G           ." ctl_freqbin_2G:"  cr  d# 12 4 .array
   r@ >ctlPowerData_2G          ." ctlPowerData_2G:" cr  d# 12 4 .array

   r@ >modalHeader5G            ." 5GHz Modal Header:" cr  .modalHeader cr
   r@ >base_ext2                ." base_ext2:" cr  .base_ext2
   r@ >calFreqPier5G            ." calFreqPier5G =            " 8 cdump cr
   r@ >calPierData5G            ." calPierData5G:" cr  8 3 .calPierData
   r@ >calTarget_freqbin_5G     ." calTarget_freqbin_5G =     " 8 cdump cr
   r@ >calTarget_freqbin_5GHT20 ." calTarget_freqbin_5GHT20 = " 8 cdump cr
   r@ >calTarget_freqbin_5GHT40 ." calTarget_freqbin_5GHT40 = " 8 cdump cr
   r@ >calTargetPower5GHT20     ." calTargetPower5GHT20.tPow2x:" cr  d# 14 8 .array
   r@ >calTargetPower5GHT40     ." calTargetPower5GHT40.tPow2x:" cr  d# 14 8 .array
   r@ >ctlIndex_5G              ." ctlIndex_5G =              " 9 cdump cr
   r@ >ctl_freqbin_5G           ." ctl_freqbin_5G:"  cr  9 8 .array
   r@ >ctlPowerData_5G          ." ctlPowerData_5G:" cr  9 8 .array

   r>  drop
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
