purpose: ATH9K Adaptive Noise Immunity (ANI) code
\ See license at end of file

headers
hex

\ SI: Spur immunity
\ FS: FIR Step
\ WS: OFDM / CCK Weak Signal detection
\ MRC: Maximal Ratio Combining for CCK

d# 10 constant #ofdm-lvl
create ofdm-spur-immunity 0 c, 1 c, 2 c, 3 c, 4 c, 5 c, 6 c, 7 c, 7 c, 7 c,
create ofdm-fir-step      0 c, 1 c, 2 c, 2 c, 3 c, 4 c, 5 c, 6 c, 7 c, 8 c,
create ofdm-weak-sig-det  1 c, 1 c, 1 c, 1 c, 1 c, 1 c, 1 c, 1 c, 1 c, 0 c,

: ofdm-spur-immunity@  ( lvl -- val )  ofdm-spur-immunity + c@  ;
: ofdm-fir-step@       ( lvl -- val )  ofdm-fir-step      + c@  ;
: ofdm-weak-sig-det@   ( lvl -- val )  ofdm-weak-sig-det  + c@  ;

9 constant #cck-lvl
7 constant #cck-lvl-low-rssi
create cck-fir-step       0 c, 1 c, 2 c, 3 c, 4 c, 5 c, 6 c, 7 c, 8 c,
create cck-mrc            1 c, 1 c, 1 c, 1 c, 0 c, 0 c, 0 c, 0 c, 0 c,

: cck-fir-step@  ( lvl -- val )  cck-fir-step + c@  ;
: cck-mrc@       ( lvl -- val )  cck-mrc      + c@  ;

: firstep@  ( lvl -- val )  2 - 2*  ;
: cycpwrThr1@  ( lvl -- val )  3 - 2*  ;

: clear-mib-counters  ( -- )  809c 8088  do  i reg@ drop  4 +loop  ;

: restart-ani  ( -- )
   0 curchan >ani-listenTime !
   0 curchan >ani-ofdmPhyErrCnt !
   0 curchan >ani-cckPhyErrCnt !

   \ Restart PHY error counters
   0 812c reg!               \ Clear PHY error counter 1
   0 8134 reg!               \ Clear PHY error counter 2
   0002.0000 8130 reg!       \ PHY error counter 1 mask AR_PHY_ERR_OFDM_TIMING
   0200.0000 8138 reg!       \ PHY error counter 2 mask AR_PHY_ERR_CCK_TIMING

   clear-mib-counters
;

: cache-ani-ini-regs  ( -- )
   curchan >r
   9828 reg@ 0fff.ff00 and          r@ >ani-ini-sfcorr-low !
   9824 reg@ 7ffe.001f and          r@ >ani-ini-sfcorr !
   982c reg@ 0fff.ffff and          r@ >ani-ini-sfcorr-ext !
   9e10 reg@    3.f000 and d# 12 >> r@ >ani-ini-firstep !
   9820 reg@       fc0 and     6 >> r@ >ani-ini-firstepLow !
   9810 reg@        fe and     1 >> r@ >ani-ini-cycpwrThr1 !
   9830 reg@      fe00 and     9 >> r@ >ani-ini-cycpwrThr1Ext !
   3 r@ >ani-spurImmunityLevel !
   2 r@ >ani-firstepLevel !
   0 r@ >ani-ofdmWeakSigDetectOff !
   0 r> >ani-mrcCCKOff !
;

: set-firstep-lvl  ( lvl -- )
   dup firstep@  2 firstep@ - curchan >ani-ini-firstep    @ + 0 max d# 20 min d# 12 <<
   3.f000 9e10 reg@!
   dup firstep@  2 firstep@ - curchan >ani-ini-firstepLow @ + 0 max d# 20 min     6 <<
   fc0 9820 reg@!
   curchan >ani-firstepLevel !
;
: set-ofdm-weak-signal-detect  ( on? -- )
   0fff.ff00 over  if  curchan >ani-ini-sfcorr-low @ swap  else  dup  then  9828 reg@!
   7ffe.001f over  if  curchan >ani-ini-sfcorr     @ swap  else  dup  then  9824 reg@!
   0fff.ffff over  if  curchan >ani-ini-sfcorr-ext @ swap  else  dup  then  982c reg@!
   dup  if  1  else  0  then  1  9828 reg@!
   1 xor curchan >ani-ofdmWeakSigDetectOff !
;
: set-spur-immunity-lvl  ( lvl -- )
   dup cycpwrThr1@ 3 cycpwrThr1@ - curchan >ani-ini-cycpwrThr1    @ + 0 max d# 22 min 1 <<
   fe 9810 reg@!
   dup cycpwrThr1@ 3 cycpwrThr1@ - curchan >ani-ini-cycpwrThr1Ext @ + 0 max d# 22 min 9 <<
   fe00 9830 reg@!
   curchan >ani-spurImmunityLevel !
; 
: set-mrcCCKoff  ( on? -- )
   1 and dup 3 * 3  9fd0 reg@!
   1 xor curchan >ani-mrcCCKOff !
;

: set-ofdm-nil  ( lvl -- )  \ OFDM Noise Immunity Level
   dup curchan >ani-ofdmNoiseImmunityLevel !   ( lvl )
   avgbrssi curchan >ani-noiseFloor !          ( lvl )

   dup ofdm-spur-immunity@ curchan >ani-spurImmunityLevel @ over  <>  ( lvl SI )
   if  set-spur-immunity-lvl  else  drop  then                    ( lvl )

   dup ofdm-fir-step@ curchan >ani-firstepLevel @ over <>  ( lvl FS flag )
   over 3 pick cck-fir-step@ >=  and                   ( lvl FS )
   if  set-firstep-lvl  else  drop  then               ( lvl )

   opmode IFTYPE_STATION <>  opmode IFTYPE_ADHOC <>  and
   curchan >ani-noiseFloor @ curchan >ani-rssiThrHigh @ <= or  if
      curchan >ani-ofdmWeakSigDetectOff @  if
         1 set-ofdm-weak-signal-detect
      else
         dup ofdm-weak-sig-det@ curchan >ani-ofdmWeakSigDetectOff @ over  =
         if  set-ofdm-weak-signal-detect  else  drop  then
      then
   then  drop
;

: set-cck-nil  ( lvl -- )  \ CCK Noise Immunity Level
   avgbrssi curchan >ani-noiseFloor !
   opmode IFTYPE_STATION =  opmode IFTYPE_ADHOC =  or  if
      curchan >ani-noiseFloor @ curchan >ani-rssiThrLow @ <=
      if  #cck-lvl-low-rssi min  then       ( lvl' )
   then
   dup curchan >ani-cckNoiseImmunityLevel !  ( lvl )

   dup cck-fir-step@ curchan >ani-firstepLevel @ over <>  ( lvl FS flag )
   over 3 pick ofdm-fir-step@ >= and  if  set-firstep-lvl  else  drop  then

   cck-mrc@ curchan >ani-mrcCCKOff @ over =  if  set-mrcCCKoff  else  drop  then
;

: reset-ani  ( scanning? -- )
   opmode IFTYPE_STATION <>  opmode IFTYPE_ADHOC <> and or  if
      curchan >ani-ofdmNoiseImmunityLevel @ 3 <>
      curchan >ani-cckNoiseImmunityLevel  @ 2 <> or  if
         3 set-ofdm-nil
         2 set-cck-nil
      then
   else
      curchan >ani-ofdmNoiseImmunityLevel @ set-ofdm-nil
      curchan >ani-cckNoiseImmunityLevel  @ set-cck-nil
   then
   restart-ani
;

[ifdef] notyet
d# 1000 value aniperiod

\ Cycle counters for computing listen time
0 value ani-cycles
0 value ani-rx-busy
0 value ani-rx-frames
0 value ani-tx-frames

\ Cycle counters for computing busy time
0 value survey-cycles
0 value survey-rx-busy
0 value survey-rx-frames
0 value survey-tx-frames

: ofdm-err-trigger  ( -- )
   curchan >ani-ofdmNoiseImmunityLevel @ 1+ dup #ofdm-lvl <
   if  set-ofdm-nil  else  drop  then
;
: cck-err-trigger  ( -- )
   curchan >ani-cckNoiseImmunityLevel @ 1+ dup #cck-lvl <  
   if  set-cck-nil  else  drop  then
;
: ani-lower-immunity  ( -- )
   curchan >ani-ofdmNoiseImmunityLevel @ dup 0>  if
      curchan >ani-ofdmsTurn @ curchan >ani-cckNoiseImmunityLevel @ 0=  or  if
         1- set-ofdm-nil
         exit
      then
   then  drop

   curchan >ani-cckNoiseImmunityLevel @ dup 0>  if  1- set-cck-nil  else  drop  then
;
: update-cycle-cnts  ( -- )
   2 40 reg!                \ freeze
   80f8 reg@ dup ani-cycles       + to ani-cycles
                 survey-cycles    + to survey-cycles
   80f4 reg@ dup ani-rx-busy      + to ani-rx-busy
                 survey-rx-busy   + to survey-rx-busy
   80f0 reg@ dup ani-rx-frames    + to ani-rx-frames
                 survey-rx-frames + to survey-rx-frames
   80ec reg@ dup ani-tx-frames    + to ani-tx-frames
                 survey-tx-frames + to survey-tx-frames
   80fc 80ec  do  0 i reg!  4 +loop
   0 40 reg!                \ unfreeze
;
: listen-time  ( -- time )
   ani-cycles ani-rx-frames - ani-tx-frames - clockrate d# 1000 * /
   0 to ani-cycles 0 to ani-rx-busy 0 to ani-rx-frames 0 to ani-tx-frames
;
: ani-read-cnts  ( -- ok? )
   update-cycle-cnts
   listen-time  dup 0<=  if  drop restart-ani false exit  then
   curchan >ani-listenTime tuck @ + swap !
   clear-mib-counters

   812c reg@ curchan >ani-ofdmPhyErrCnt !
   8134 reg@ curchan >ani-cckPhyErrCnt !
   true
;
: monitor-ani  ( -- )
   ani-read-cnts 0=  if  exit  then
   curchan >ani-ofdmPhyErrCnt @ d# 1000 * curchan >ani-listenTime @ /  \ ofdmPhyErrRate
   curchan >ani-cckPhyErrCnt  @ d# 1000 * curchan >ani-listenTime @ /  \ cckPhyErrRate

   curchan >ani-listenTime @ aniperiod 5 * >  if
      2dup d# 300 <= swap d# 400 <= and  if
         ani-lower-immunity
         curchan >ani-ofdmsTurn dup @ -1 xor swap !
      then
      restart-ani
   else
   curchan >ani-listenTime @ aniperiod >  if
      2dup d# 600 <= curchan >ani-ofdmsTurn @ or swap d# 1000 >  and  if
         ofdm-err-trigger
         restart-ani
         false curchan >ani-ofdmsTurn !
      else
      dup d# 600 >  if
         cck-err-trigger
         restart-ani
         true curchan >ani-ofdmsTurn !
      then then
   then  then  2drop
;
: proc-mib-event  ( -- )
   0 8124 reg!               \ Filtered OFDM counter
   0 8128 reg!               \ Filtered CCK counter
   8258 reg@ 2 and  if  1 8248 reg!  then
   clear-mib-counters
   812c reg@ c0.0000 and  8134 reg@ c0.0000 and  or  if
      restart-ani
   then
;
[then]

: enable-mib-counters  ( -- )
   clear-mib-counters
   0 8124 reg!               \ Filtered OFDM counter
   0 8128 reg!               \ Filtered CCK counter
   0 40 reg!                 \ MIB control
   0002.0000 8130 reg!       \ PHY error counter 1 mask AR_PHY_ERR_OFDM_TIMING
   0200.0000 8138 reg!       \ PHY error counter 2 mask AR_PHY_ERR_CCK_TIMING
;

: disable-mib-counters  ( -- )
   2 40 reg!
   clear-mib-counters
   4 40 reg!
   0 8124 reg!               \ Filtered OFDM counter
   0 8128 reg!               \ Filtered CCK counter
;

: init-ani  ( -- )
   #channels 0  do
      i 'channel >r
      3 r@ >ani-spurImmunityLevel !
      2 r@ >ani-firstepLevel !
      0 r@ >ani-mrcCCKOff !
      true r@ >ani-ofdmsTurn !
      d# 40 r@ >ani-rssiThrHigh !
      7 r@ >ani-rssiThrLow !
      false r@ >ani-ofdmWeakSigDetectOff !
      2 r> >ani-cckNoiseImmunityLevel !
   loop

   restart-ani
   enable-mib-counters
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
