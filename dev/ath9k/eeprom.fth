purpose: ATH9K EEPROM and OTP manipulation
\ See license at end of file

headers
hex

\ Eeprom data structure definition
struct
   2 field >regDmn0
   2 field >regDmn1
   1 field >txrxMask
   1 field >opFlags
   1 field >eepMisc
   1 field >rfSilent
   1 field >blueToothOptions
   1 field >deviceCap
   1 field >deviceType
   1 field >pwrTableOffset         \ Signed
   2 field >params_for_tuning_caps
   1 field >featureEnable
   1 field >miscConfiguration
   1 field >eepromWriteEnableGpio
   1 field >wlanDisableGpio
   1 field >wlanLedGpio
   1 field >rxBandSelectGpio
   1 field >txrxgain
   4 field >swreg
constant /baseEepHeader

struct
   4 field >antCtrlCommon
   4 field >antCtrlCommon2
   3 /w* field >antCtrlChain
   3 field >xatten1DB
   3 field >xatten1Margin
   1 field >tempSlope           \ Signed
   1 field >voltSlope           \ Signed
   5 field >spurChans
   3 field >noiseFloorThreshCh  \ Signed
   3 field >ob
   3 field >db_stage2
   3 field >db_stage3
   3 field >db_stage4
   1 field >xpaBiasLvl
   1 field >txFrameToDataStart
   1 field >txFrameToPaOn
   1 field >txClip
   1 field >antennaGain         \ Signed
   1 field >switchSettling
   1 field >adcDesiredSize      \ Signed
   1 field >txEndToXpaOff
   1 field >txEndToRxOn
   1 field >txFrameToXpaOn
   1 field >thresh62
   4 field >papdRateMaskHt20
   4 field >papdRateMaskHt40
   d# 10 +
constant /modalHeader

struct
   1 field >ant_div_control
   d# 13 +
constant /base_ext1

struct
   1 field >tempSlopeLow          \ signed
   1 field >tempSlopeHigh         \ signed
   3 field >xatten1DBLow
   3 field >xatten1MarginLow
   3 field >xatten1DBHigh
   3 field >xatten1MarginHigh
constant /base_ext2

struct
   1 field >refPower             \ signed
   1 field >voltMeas
   1 field >tempMeas
   1 field >rxNoisefloorCal      \ signed
   1 field >rxNoisefloorPower    \ signed
   1 field >rxTempMeas
constant /cal-data-per-freq-op-loop

struct
   1 field >eepromVersion
   1 field >templateVersion
   6 field >macAddr
   d# 20 field >custData
   /baseEepHeader field >baseEepHeader
   /modalHeader field >modalHeader2G
   /base_ext1 field >base_ext1
   3 field >calFreqPier2G
   6 3 * 3 * field >calPierData2G
   2 field >calTarget_freqbin_Cck
   3 field >calTarget_freqbin_2G
   3 field >calTarget_freqbin_2GHT20
   3 field >calTarget_freqbin_2GHT40
   4 2 * field >calTargetPowerCck
   4 3 * field >calTargetPower2G
   d# 14 3 * field >calTargetPower2GHT20
   d# 14 3 * field >calTargetPower2GHT40
   d# 12 field >ctlIndex_2G
   d# 12 4 * field >ctl_freqbin_2G
   d# 12 4 * field >ctlPowerData_2G
   /modalHeader field >modalHeader5G
   /base_ext2 field >base_ext2
   8 field >calFreqPier5G
   6 8 * 3 * field >calPierData5G
   8 field >calTarget_freqbin_5G
   8 field >calTarget_freqbin_5GHT20
   8 field >calTarget_freqbin_5GHT40
   4 8 * field >calTargetPower5G
   d# 14 8 * field >calTargetPower5GHT20
   d# 14 8 * field >calTargetPower5GHT40
   9 field >ctlIndex_5G
   9 8 * field >ctl_freqbin_5G
   9 8 * field >ctlPowerData_5G
constant /eeprom
/eeprom-init /eeprom <>  if  ." eeprom data structure is inconsistent" cr  then

\ Words to facilitate signed-byte eeprom data accesses
: sign-c  ( b -- n )  d# 24 << d# 24 >>a  ;
: sign-c@  ( adr -- n )  c@ sign-c  ;

: baseEepHeader    ( -- adr )  eeprom >baseEepHeader  ;
: base_ext2        ( -- adr )  eeprom >base_ext2  ;
: pwrTableOffset@  ( -- n )    baseEepHeader >pwrTableOffset sign-c@  ;
: tempSlopeLow@    ( -- n )    base_ext2 >tempSlopeLow sign-c@  ;
: tempSlopeHigh@   ( -- n )    base_ext2 >tempSlopeHigh sign-c@  ;

\ ModalHeader based data:
: tempSlope@  ( adr -- n )  >tempSlope sign-c@  ;
: voltSlope@  ( adr -- n )  >voltSlope sign-c@  ;
: noiseFloorThreshCh@  ( adr -- n )  >noiseFloorThreshCh sign-c@  ;
: antennaGain@  ( adr -- n )  >antennaGain sign-c@  ;
: adcDesiredSize@  ( adr -- n )  >adcDesiredSize sign-c@  ;

: modalHeader2G  ( -- adr )  eeprom >modalHeader2G  ;
: tempSlope2G@  ( adr -- n )  modalHeader2G tempSlope@  ;
: voltSlope2G@  ( adr -- n )  modalHeader2G voltSlope@  ;
: noiseFloorThreshCh2G@  ( adr -- n )  modalHeader2G noiseFloorThreshCh@  ;
: antennaGain2G@  ( adr -- n )  modalHeader2G antennaGain@  ;
: adcDesiredSize2G@  ( adr -- n )  modalHeader2G adcDesiredSize@  ;

: modalHeader5G  ( -- adr )  eeprom >modalHeader5G  ;
: tempSlope5G@  ( adr -- n )  modalHeader5G tempSlope@  ;
: voltSlope5G@  ( adr -- n )  modalHeader5G voltSlope@  ;
: noiseFloorThreshCh5G@  ( adr -- n )  modalHeader5G noiseFloorThreshCh@  ;
: antennaGain5G@  ( adr -- n )  modalHeader5G antennaGain@  ;
: adcDesiredSize5G@  ( adr -- n )  modalHeader5G adcDesiredSize@  ;

\ calPierData based data accesses:
: calPierData2G  ( pier chain -- adr )
   3 * + /cal-data-per-freq-op-loop *  eeprom >calPierData2G +
;
: refPower2G@           ( pier chain -- n )  calPierData2G >refPower sign-c@  ;
: voltMeas2G@           ( pier chain -- n )  calPierData2G >voltMeas c@  ;
: tempMeas2G@           ( pier chain -- n )  calPierData2G >tempMeas c@  ;
: rxTempMeas2G@         ( pier chain -- n )  calPierData2G >rxtempMeas c@  ;
: rxNoisefloorCal2G@    ( pier chain -- n )  calPierData2G >rxNoisefloorCal sign-c@  ;
: rxNoisefloorPower2G@  ( pier chain -- n )  calPierData2G >rxNoisefloorPower sign-c@  ;

: calPierData5G  ( pier chain -- adr )
   8 * + /cal-data-per-freq-op-loop *  eeprom >calPierData5G +
;
: refPower5G@           ( pier chain -- n )  calPierData5G >refPower sign-c@  ;
: voltMeas5G@           ( pier chain -- n )  calPierData5G >voltMeas c@  ;
: tempMeas5G@           ( pier chain -- n )  calPierData5G >tempMeas c@  ;
: rxtempMeas5G@         ( pier chain -- n )  calPierData5G >rxtempMeas c@  ;
: rxNoisefloorCal5G@    ( pier chain -- n )  calPierData5G >rxNoisefloorCal sign-c@  ;
: rxNoisefloorPower5G@  ( pier chain -- n )  calPierData5G >rxNoisefloorPower sign-c@  ;

\ calTargetPower based data accesses
: calTargetPowerCck@     ( idx pier -- n )  4 * +  eeprom >calTargetPowerCck + c@  ;
: calTargetPower2G@      ( idx pier -- n )  4 * +  eeprom >calTargetPower2G + c@  ;
: calTargetPower2GHT20@  ( idx pier -- n )  d# 14 * +  eeprom >calTargetPower2GHT20 + c@  ;
: calTargetPower2GHT40@  ( idx pier -- n )  d# 14 * +  eeprom >calTargetPower2GHT40 + c@  ;

: calTargetPower5G@      ( idx pier -- n )  4 * +  eeprom >calTargetPower5G + c@  ;
: calTargetPower5GHT20@  ( idx pier -- n )  d# 14 * +  eeprom >calTargetPower5GHT40 + c@  ;
: calTargetPower5GHT40@  ( idx pier -- n )  d# 14 * +  eeprom >calTargetPower5GHT40 + c@  ;

\ ctl based data accesses
: ctl_freqbin_2G@   ( ctl edge -- n )  d# 12 * +  eeprom >ctl_freqbin_2G + c@  ;
: ctlPowerData_2G@  ( ctl edge -- n )  d# 12 * +  eeprom >ctlPowerData_2G + c@  ;

: ctl_freqbin_5G@   ( ctl edge -- n )  9 * +  eeprom >ctl_freqbin_5G + c@  ;
: ctlPowerData_5G@  ( ctl edge -- n )  9 * +  eeprom >ctlPowerData_5G + c@  ;

\ Words to modify the eeprom data structure based on OTP/EEPROM content
0 value epptr
0 value edptr
0 value edend
: epptr+  ( n -- )  epptr + to epptr  ;
: edptr+  ( n -- )  2 + edptr + to edptr  ;
: (process-edata)  ( adr len -- )
   over + to edend to edptr
   eeprom to epptr
   begin  edptr edend <  while
      edptr c@ epptr+
      edptr 1+ c@ edptr 2 + epptr 2 pick move
      dup epptr+  edptr+
   repeat
;

: wait-hw  ( val mask reg -- ok? )
   d# 1.0000 0  do
      3dup reg@ and =  ?leave
      d# 10 us
   loop
   reg@ and =
;

: fbin2freq  ( freq is2GHz? -- freq' )
   over  ff =  if  drop exit  then
   if  d# 2300 +  else  5 * d# 4800 +  then
;
: fbin2freq2G  ( freq -- freq' )  true  fbin2freq  ;
: fbin2freq5G  ( freq -- freq' )  false fbin2freq  ;

: interpolate  ( x xa xb ya yb -- y )
   over >r
   \ y = (yb - ya) * (x - xa) / (xb - xa) + ya
   swap - 2* >r over - -rot - r> * swap /
   2 /mod r> + +
;

: eeprom@  ( idx -- data )   \ On 32-bit boundary, read 32 bits
   fffc and 2000 + reg@ drop
   0 5.0000 4084 wait-hw drop    \ Wait till data is valid
   4084 reg@  ffff and
;
: eeprom-b@  ( idx -- b )  dup eeprom@ swap 3 and 8 * >> ff and  ;

\ One time programmable memory read
: otp@  ( idx -- data )      \ On 32-bit boundary, read 32 bits
   fffc and 1.4000 + reg@ drop
   4 7 1.5f18 wait-hw drop       \ Wait till data is valid
   1.5f1c reg@
;
: otp-b@  ( idx -- b )  dup otp@ swap 3 and 8 * >> ff and  ;

: hdr>len  ( header -- len )  lbflip dup 4 >> 7f0 and swap d# 20 >> f and or  ;
: .hdr  ( header -- )
   dup                                     ." Header    = " u. cr
   lbflip
   dup 5 >> 7 and                          ." Code      = " u. cr
   dup 1f and over d# 10 >> 20 and or      ." Reference = " u. cr
   dup 4 >> 7f0 and over d# 20 >> f and or ." Length    = " u. cr
   dup d# 16 >> f and                      ." Major     = " u. cr
       d# 24 >> ff and                     ." Minor     = " u. cr
;

\ To decipher the content of EEPROM or OTP
\ 0. format: 4-byte hdr, data, 2-byte chksum (read backwards)
\ 1. see if 3fc eeprom@ is a valid hdr (not 0's and ff's)
\ 2. if not, see if 1fc eeprom@ is a valid hdr else goto step 6
\ 3. if not, see if 3fc otp@ is a valid hdr else goto step 6
\ 4. if not, see if 1fc otp@ is a valid hdr else goto step 7
\ 5. if not, bad else goto step 7
\ 6. use eeprom@, goto step 8
\ 7. use otp@, goto step 8
\ 8. from current idx down upto 100 times
\       decipher hdr
\       if len>=1024, idx--
\       else verify checksum (sum of all data bytes)
\            if checksum bad, idx-=len+4+2
\ 9. save good content in eeprom

\ OTP data block format, entries of:
\    data-offset  data-len   data
\ They correspond to C struct ar9300_eeprom.
\ The AR9382 in Alex correspond to ar9300_h116.
\ So far, the interesting one is the first entry, which is the mac address.

false value edata-found?
defer read-op
defer read-bop
0 value ehdr
0 value eptr
0 value elen
d# 1024 buffer: edata

: check-hdr  ( -- ok? )  eptr read-op dup  0<>  swap -1 <> and  ;
: (read-edata)  ( len -- ok? )
   0 swap                                      ( chksum len )
   dup to elen 0  do                           ( chksum )
      eptr i - read-bop dup edata i + c! +     ( chksum' )
   loop  ffff and                              ( chksum' )
   eptr elen - dup read-bop swap 1- read-bop   ( chksum cs.lo cs.hi )
   bwjoin  = dup to edata-found?
;
: read-edata  ( -- )
   d# 100 0  do
      eptr read-op dup to ehdr hdr>len         ( elen )
      eptr 4 - to eptr
      dup d# 1024 >=  if  drop  else  (read-edata) ?leave  then
   loop
;
: process-edata  ( -- )
    edata elen (process-edata)
    edata 2 + mac-adr /mac-adr move
;

: (init-edata)  ( -- )  \ ath9k_hw_eeprom_init
   false to edata-found?
   3ff to eptr  ['] eeprom-b@ to read-bop  ['] eeprom@ to read-op
   check-hdr  if  read-edata  exit  then
   1ff to eptr
   check-hdr  if  read-edata  exit  then
   3ff to eptr  ['] otp-b@ to read-bop  ['] otp@ to read-op
   check-hdr  if  read-edata  exit  then
   1ff to eptr
   check-hdr  if  read-edata  then
;
: init-edata  ( -- )
   (init-edata)
   edata-found?  if
      process-edata
   else
      ." WARNING: did not found data in OTP" cr
   then
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
