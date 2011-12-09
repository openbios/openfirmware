purpose: ATH9K Calibration
\ See license at end of file

headers
hex

struct
   5 /n* field >nfCalBuffer
   /n field >currIndex
   /n field >privNF
   /n field >invalidNFcount
constant /nfCalHist

struct
   /n field >cd-ch
   /n field >cd-chFlags
   /n field >calValid
   /n field >iCoff
   /n field >Coff
   /n field >paprd-done?
   /n field >nfcal-pending?
   /n field >nfcal-interference?
   3 /n* field >small-signal-gain
   d# 24 3 * /n* field >pa-table
   /nfCalHist 6 * field >nfCalHist
constant /caldata

/caldata buffer: caldata
: init-buf  ( -- )  caldata /caldata erase  ;

\ iq-calState definitions
0 constant CAL_INACTIVE
1 constant CAL_WAITING
2 constant CAL_RUNNING
3 constant CAL_DONE
CAL_INACTIVE value iq-calState

struct
   /n field >nf-nominal
   /n field >nf-max
   /n field >nf-min
constant /nf-limit

3 /n* buffer: measI
3 /n* buffer: measQ
3 /n* buffer: measIQ
create nf-2g  d# -110 , d#  -95 , d# -125 ,
create nf-5g  d# -115 , d# -100 , d# -125 ,

: sort  ( buf size -- )
   dup 0  do                 ( buf size )
      dup 1  do              ( buf size )
         over i na+ @ 2 pick i 1- na+ @ 2dup >  if  ( buf size buf[i] buf[i-1] )
            3 pick i na+ !  2 pick i 1- na+ !       ( buf size )
         else                                       ( buf size buf[i] buf[i-1] )
            2drop                                   ( buf size )
         then
      loop
   loop  2drop
;

5 /n* buffer: tmpbuf
: get-nf-hist-mid  ( nfCalBuf -- nfval )
   tmpbuf 5 /n* move
   tmpbuf 5 sort
   tmpbuf 2 na+ @
;

: get-nf-limits  ( ch -- 'limit )
   ?dup 0=  if  nf-2g exit  then
   is-2GHz?  if  nf-2g  else  nf-5g  then
;

: get-nf-default  ( ch -- default )
   get-nf-limits >nf-nominal @
;

6 /n* buffer: nfarray
0 value nh
0 value nmax
0 value nlimit
0 value ncmask
0 value high-nf-mid
: 'nh  ( idx -- adr )  /nfCalHist * nh +  ;
: update-nfcal-hist  ( caldata -- )
   dup >nfCalHist to nh                      ( calData )
   curchan get-nf-limits >nf-max @ to nmax   ( calData )
   rxchainmask dup 3 << or to ncmask         ( calData )
   false to high-nf-mid                      ( calData )

   6 0  do
      ncmask 1 i << and
      conf-is-ht40?  i 3 >=  and not  and  if
         nfarray i na+ @             ( calData nfarray[i] )
         i 'nh >nfCalBuffer i 'nh >currIndex @ na+ !
         i 'nh >currIndex @ 1+  dup 5 >=  if  drop 0  then
         i 'nh >currIndex !
         i 'nh >invalidNFcount @ dup 0>  if
            1- i 'nh >invalidNFCount !
            nfarray i na+ @ 
         else
            drop  i 'nh >nfCalBuffer get-nf-hist-mid
         then  dup i 'nh >privNF !
         nmax >  if
            true to high-nf-mid
            dup >nfcal-interference? @ 0=  if
               nmax i 'nh >privNF !
            then
         then
      then
   loop
   high-nf-mid swap >nfcal-interference? !
;

: get-nf-thresh  ( band -- nf-thresh )  drop 0  ;

: setup-calibration  ( -- )
   a000 f000 980c reg@!
   0 a2c8 reg!
   1.0000 dup 980c reg@!      \ kick off cal
;

: reset-calibration  ( -- )
   setup-calibration
   CAL_RUNNING to iq-calState
   measI  3 /n* erase
   measQ  3 /n* erase
   measIQ 3 /n* erase
;

: reset-calvalid?  ( -- notdone? )
   iq-calState CAL_DONE  <>  if  true exit  then
   CAL_WAITING to iq-calState
   false
;

: start-nfcal  ( update? -- )
   true caldata >nfcal-pending? !
   if  8002  else  2.8002  then  2.8002 a2c4 reg@!
;

0 value dnf
create nf-regs 9e1c , ae1c , be1c , 9830 , a830 , b830 , 

: load-nf  ( ch -- )
   rxchainmask dup 3 << or to ncmask
   get-nf-default to dnf
   caldata >nfCalHist to nh

   6 0  do
      ncmask 1 i << and
      conf-is-ht40?  i 3 >=  and not  and  if
         nh  if  i 'nh >privNF @  else  dnf  then  1 <<  1ff and
         1ff nf-regs i na+ @ reg@!         
      then
   loop

   8000 2.0002 a2c4 reg@!
   0 2 a2c4 wait-hw 0=  if  " Timeout waiting for NF to load" vtype exit  then

   \ Restore maxCCAPower
   6 0  do
      ncmask 1 i << and
      conf-is-ht40?  i 3 >=  and not  and  if
         19c 1ff nf-regs i na+ @ reg@!         
      then
   loop
;

: sanitize-nf  ( 'nf -- )
   curchan is-2GHz?  if  nf-2g  else  nf-5g  then  to nlimit
   6 0  do
      dup i na+ @ d# -60 >  if
         nlimit >nf-max @ over i na+ !
      else
      dup i na+ @ nlimit >nf-min @ <  if
         nlimit >nf-nominal @ over i na+ !
      then  then
   loop  drop
;

: sign-extend32  ( val index -- val' )  d# 31 swap - tuck << swap >>a  ;
: do-get-nf  ( nfarray -- )
   3 0  do
      1 i << rxchainmask and  if
         nf-regs i na+ @ reg@ 1ff0.0000 and d# 20 >>  8 sign-extend32  over i na+ !
         curchan is-ht40?  if
            nf-regs i 3 + na+ @ reg@ 1ff.0000 and d# 16 >>  8 sign-extend32  over i 3 + na+ !
         then
      then
   loop  drop
;

: get-nf  ( ch -- ok? )
   nfarray 6 /n* erase
   CH_CW_INT not over >ch-flags @ and over >ch-flags !
   a2c4 reg@ 2 and  if  " NF did not complete" vtype drop false exit  then
   nfarray do-get-nf
   nfarray sanitize-nf
   nfarray @ 0 >  if
      " Noise floor detection failed" vtype
      CH_CW_INT over >ch-flags @ or over >ch-flags !
   then

   false caldata >nfcal-pending? !
   caldata update-nfcal-hist
   caldata >nfcalHist >privNF @ swap >ch-noisefloor !
   true
;

: init-nfcal-hist  ( ch -- )
   dup >ch-freq @ caldata >cd-ch !
   dup >ch-flags @ CH_CW_INT invert and caldata >cd-chFlags !
   caldata >nfCalHist to nh
   get-nf-default                  ( default-nf )

   6 0  do
      0 i 'nh >currIndex !
      dup i 'nh >privNF !
      3 i 'nh >invalidNFcount !
      i 'nh >nfCalBuffer 5 /n* 2 pick " lfill" evaluate
   loop  drop
;

[ifdef] notyet
: get-ch-noise  ( ch -- noisefloor )
   curchan ?dup 0=  if  get-nf-default exit  then
   >ch-noiseFloor @ ?dup  if  nip  else  get-nf-default  then
;

: bstuck-nfcal  ( -- )
   caldata >nfcal-pending? @  if
      a2c4 reg@ 2 and 0=  if  curchan get-nf drop  then
   else
      true start-nfcal
   then
   true caldata >nfcal-interference? !
;

: #rxchains   ( -- #chains )  0  6 0  do  rxchainmask i >> 1 and +  loop  ;

: collect-iqcal  ( -- )
   3 0  do
      98c0 i 1000 * + reg@ measI  i na+ !
      98c4 i 1000 * + reg@ measQ  i na+ !
      98c8 i 1000 * + reg@ measIQ i na+ !
   loop
;

0 value iqCorrNeg
: calibrate-iq  ( #chains -- )
   0  do
      false to iqCorrNeg
      measI i na+ @  measQ i na+ @  measIQ i na+ @
      dup 8000.0000 u>  if  not 1+  true to iqCorrNeg  then
                      ( powerMeasI powerMeasQ iqCorrMeas' )
      -rot over 1 >> over 1 >> + 8 >>  ( iqCorrMeas powerMeasI powerMeasQ iCoffDenom )
      swap 6 >>                        ( iqCorrMeas powerMeasI iCoffDenom qCoffDenom )
      2dup or  if                      \ Avoid divide by zero
         rot swap / d# 64 -            ( iqCorrMeas iCoffDenom qCoff )
         d# 63 min  d# -63 max  7f and ( iqCorrMeas iCoffDenom qCoff' )
         -rot / d# 63 min  d# -63 max  ( qCoff iCoff )
         iqCorrNeg 0=  if  negate  then  7f and  ( qCoff iCoff' )
         7 << or 3fff 98dc i 1000 * + reg@!
      then
   loop                      
   4000 dup 98dc reg@!
;

: (calibrate)  ( -- done? )
   iq-calState CAL_RUNNING =  if
      980c reg@ 1.0000 and 0=  if
         collect-iqcal
         #rxchains calibrate-iq
         CAL_DONE to iq-calState
      then
   then
   iq-calState CAL_DONE = 
;

: calibrate  ( ch longcal? -- done? )
   (calibrate) -rot      ( done? ch longcal? )

   if
      get-nf  drop
      curchan load-nf
      false start-nfcal
   else
      drop
   then                  ( done? )
;
[then]

3 /n* constant /coeff-meas                \ 3 passes per measurement
/coeff-meas 8 * constant /coeff-chain     \ 8 measurements per chain

/coeff-chain 6 * buffer: mag-coeff  \ [AR9300_MAX_CHAINS][MAX_MEASUREMENT][MPASS]
/coeff-chain 6 * buffer: phs-coeff  \ [AR9300_MAX_CHAINS][MAX_MEASUREMENT][MPASS]
2 /n* buffer: iq-coeff
6 /n* buffer: iq-res

: 'mag-coeff  ( m chain -- adr )  /coeff-chain * swap /coeff-meas * + mag-coeff +  ;
: 'phs-coeff  ( m chain -- adr )  /coeff-chain * swap /coeff-meas * + phs-coeff +  ;
: coeff@      ( i adr -- n )      swap na+ @  ;
: coeff!      ( n i adr -- )      swap na+ !  ;
: mag-coeff@  ( i m chain -- n )  'mag-coeff coeff@  ;
: mag-coeff!  ( n i m chain -- )  'mag-coeff coeff!  ;
: phs-coeff@  ( i m chain -- n )  'phs-coeff coeff@  ;
: phs-coeff!  ( n i m chain -- )  'phs-coeff coeff!  ;

\ Local variables for the iq calibration
0 value sin-2phi-1  0 value sin-2phi-2
0 value cos-2phi-1  0 value cos-2phi-2
0 value mag-a0-d0   0 value mag-a1-d0
0 value phs-a0-d0   0 value phs-a1-d0
0 value if1
0 value if2
0 value if3
0 value mag-tx
0 value mag-rx
0 value phs-tx
0 value phs-rx

\ Solve 4x4 linear equation used in loopback iq cal.
: solve-iq-cal  ( -- solved? )
   cos-2phi-1 cos-2phi-2 - to if1
   sin-2phi-1 sin-2phi-2 - to if3
   if1 if1 * if3 if3 * + d# 15 >>a ?dup  0=  if  false exit  then  \ Divide by zero
   to if2
   mag-a0-d0 mag-a1-d0 - if1 *  phs-a0-d0 phs-a1-d0 - if3 * + if2 / to mag-tx
   mag-a1-d0 mag-a0-d0 - if3 *  phs-a0-d0 phs-a1-d0 - if1 * + if2 / to phs-tx

   mag-a0-d0 cos-2phi-1 mag-tx * sin-2phi-1 phs-tx * + d# 15 >>a - to mag-rx
   phs-a0-d0 sin-2phi-1 mag-tx * cos-2phi-1 phs-tx * - d# 15 >>a + to phs-rx
   true
;

: find-mag  ( i q -- mag )
   abs swap abs                   ( abs[i] abs [q] )
   2dup max -rot min              ( max-abs min-abs )
   over 5 >> swap dup 3 >> swap 2 >> + + -
;

\ Local variables
0 value i2-m-q2-a0-d0  0 value i2-p-q2-a0-d0  0 value iq-corr-a0-d0
0 value i2-m-q2-a0-d1  0 value i2-p-q2-a0-d1  0 value iq-corr-a0-d1
0 value i2-m-q2-a1-d0  0 value i2-p-q2-a1-d0  0 value iq-corr-a1-d0
0 value i2-m-q2-a1-d1  0 value i2-p-q2-a1-d1  0 value iq-corr-a1-d1
0 value mag-a0-d1      0 value mag-a1-d1
0 value phs-a0-d1      0 value phs-a1-d1
0 value mag-corr-tx    0 value phs-corr-tx
0 value mag-corr-rx    0 value phs-corr-rx
0 value mag1           0 value mag2

: ?sign-800  ( n -- )  dup 800 >  if  d# 20 << d# 20 >>a  then  ;
: calc-iq-corr  ( -- ok? )
   iq-res @          fff and  ?sign-800  to i2-m-q2-a0-d0
   iq-res @ d# 12 >> fff and  ?sign-800  to i2-p-q2-a0-d0
   iq-res @ d# 24 >>          ?sign-800  to iq-corr-a0-d0

   iq-res na1+  @     4 >> fff and  ?sign-800  to i2-m-q2-a0-d1
   iq-res 2 na+ @          fff and  ?sign-800  to i2-p-q2-a0-d1
   iq-res 2 na+ @ d# 12 >> fff and  ?sign-800  to iq-corr-a0-d1

   iq-res 2 na+ @ d# 24 >>          ?sign-800  to i2-m-q2-a1-d0
   iq-res 3 na+ @     4 >> fff and  ?sign-800  to i2-p-q2-a1-d0
   iq-res 4 na+ @          fff and  ?sign-800  to iq-corr-a1-d0

   iq-res 4 na+ @ d# 12 >> fff and  ?sign-800  to i2-m-q2-a1-d1
   iq-res 4 na+ @ d# 24 >>          ?sign-800  to i2-p-q2-a1-d1
   iq-res 5 na+ @     4 >> fff and  ?sign-800  to iq-corr-a1-d1

   i2-p-q2-a0-d0 0= i2-p-q2-a0-d1 0= or i2-p-q2-a1-d0 0= or i2-p-q2-a1-d1 0= or
   if  false exit  then        \ Divide by zero

   i2-m-q2-a0-d0 d# 15 << i2-p-q2-a0-d0 / to mag-a0-d0
   iq-corr-a0-d0 d# 15 << i2-p-q2-a0-d0 / to phs-a0-d0

   i2-m-q2-a0-d1 d# 15 << i2-p-q2-a0-d1 / to mag-a0-d1
   iq-corr-a0-d1 d# 15 << i2-p-q2-a0-d1 / to phs-a0-d1

   i2-m-q2-a1-d0 d# 15 << i2-p-q2-a1-d0 / to mag-a1-d0
   iq-corr-a1-d0 d# 15 << i2-p-q2-a1-d0 / to phs-a1-d0

   i2-m-q2-a1-d1 d# 15 << i2-p-q2-a1-d1 / to mag-a1-d1
   iq-corr-a1-d1 d# 15 << i2-p-q2-a1-d1 / to phs-a1-d1

   \ W/o analog phase shift
   mag-a0-d0 mag-a0-d1 - 8 << 5 >>a to sin-2phi-1
   phs-a0-d1 phs-a0-d0 - 8 << 5 >>a to cos-2phi-1
   mag-a1-d0 mag-a1-d1 - 8 << 5 >>a to sin-2phi-2
   phs-a1-d1 phs-a1-d0 - 8 << 5 >>a to cos-2phi-2

   \ Force sin2 + cos2 = 1
   \ Find magnitude by approximation
   cos-2phi-1 sin-2phi-1 find-mag to mag1
   cos-2phi-2 sin-2phi-2 find-mag to mag2
   mag1 0= mag2 0= or  if  false exit  then  \ Divide by zero

   \ Normalize sin and cos by mag
   sin-2phi-1 d# 15 << mag1 / to sin-2phi-1
   cos-2phi-1 d# 15 << mag1 / to cos-2phi-1
   sin-2phi-2 d# 15 << mag2 / to sin-2phi-2
   cos-2phi-2 d# 15 << mag2 / to cos-2phi-2

   \ Calculate IQ mismatch
   solve-iq-cal 0=  if  false exit  then  \ Failure

   mag-tx 8000 =  if  false exit  then    \ Divide by zero

   \ Calculate and quantize tx IQ correction factor
   mag-tx d# 15 <<  8000 mag-tx - / to mag-corr-tx
   phs-tx negate to phs-corr-tx

   mag-corr-tx 7 << d# 15 >>a  d# -63 max  d# 63 min  7 <<
   phs-corr-tx 8 << d# 15 >>a  d# -63 max  d# 63 min  +     iq-coeff !

   mag-rx negate 8000 =  if  false exit  then   \ Divide by zero

   \ Calculate and quantize rx IQ correction factor
   mag-rx negate d# 15 <<  8000 mag-rx + / to mag-corr-rx
   phs-rx negate to phs-corr-rx

   mag-corr-rx 7 << d# 15 >>a  d# -63 max  d# 63 min  7 <<
   phs-corr-rx 8 << d# 15 >>a  d# -63 max  d# 63 min  +     iq-coeff na1+ !
   true
;

: compute-avg  ( coeff[] -- false | avg true )
   >r
   0 r@ coeff@  1 r@ coeff@ - abs  ( diff0 )  ( R: coeff[] )
   1 r@ coeff@  2 r@ coeff@ - abs  ( diff0 diff1 )  ( R: coeff[] )
   2 r@ coeff@  0 r@ coeff@ - abs  ( diff0 diff1 diff2 )  ( R: coeff[] )

   3dup + + d# 33 >  if  r> 4drop false  exit  then
                                   ( diff0 diff1 diff2 )  ( R: coeff[] )
   rot dup 3 pick <= swap 2 pick <=  and  if
      2drop 0 r@ coeff@  1 r@ coeff@ + 1 >>a
   else  <=  if
      1 r@ coeff@  2 r@ coeff@ + 1 >>a
   else
      2 r@ coeff@  0 r@ coeff@ + 1 >>a
   then  then
   true  r> drop
;

\ Local variables
8 6 * /n* buffer: tx-cc-regs  \ [MAX_MEASUREMENT][AR9300_MAX_CHAINS]
: txcc@  ( c m -- n )  6 * /n* tx-cc-regs + swap na+ @  ;
: txcc!  ( n c m -- )  6 * /n* tx-cc-regs + swap na+ !  ;

: load-tx-iq-cal-avg-2passes  ( #chains -- )
   \ Setup array of register addresses
   4 0  do
      a650 i na+ dup  0 i 2* txcc!  0 i 2* 1+ txcc!
      b650 i na+ dup  1 i 2* txcc!  1 i 2* 1+ txcc!
      c650 i na+ dup  2 i 2* txcc!  2 i 2* 1+ txcc!
   loop

   \ Load the average of 2 passes
   ( #chains ) false swap  0  do               \ Chain loop
      a68c reg@ 3e and 1 >> 8 min  0  do       \ Measurement loop
         i j 'mag-coeff compute-avg 0=  if   drop true leave  then  7f and ( mag )
         i j 'phs-coeff compute-avg 0=  if  2drop true leave  then  7f and ( mag phase )
         7 << or
         i 1 and  if  d# 14 << fff.c000  else  3fff  then
         j i txcc@ reg@!
      loop
      dup  if  leave  then
   loop
   ( failed? )  if  0 0  else  2000.0000 8000.0000  then
   8000.0000 98b0 reg@!
   2000.0000 98dc reg@!
;

: cal-tx-iq  ( -- )
   false 3 0  do                           \ Pass loop
      80.0000 01fc.0000 a648 reg@!
      1 1 a640 reg@!
      0 1 a640 wait-hw  0=  if
         " TX IQ cal not complete" vtype
         drop true leave
      then

      a68c reg@ 3e and 1 >> 8 min i        ( flag #meas pass# )
      tx-chainmask get-streams  0  do      \ Chain loop
         over 0  do                        \ Measurement loop
            a68c j 1000 * + reg@ 1 and  if  rot drop true -rot leave  then
            9b00 j 1000 * +                ( flag #meas pass# reg-base )
            3 0  do
               j 3 * i + 4 * over +        \ reg
               0 8 a370 reg@!
               dup reg@  iq-res i 2* na+ !
               8 8 a370 reg@!
               reg@ ffff and  iq-res i 2* 1+ na+ !
            loop  drop                     ( flag #meas pass# )
            calc-iq-corr 0=  if  rot drop true -rot leave  then
            iq-coeff @ 7f and dup d# 63 >  if  d# 128 -  then
            over i j mag-coeff!
            iq-coeff @ 7 >> 7f and  dup d# 63 >  if  d# 128 -  then
            over i j phs-coeff!
         loop                              ( flag #meas pass# )
      loop  2drop  dup  if  leave  then
      dup  if  leave  then
   loop
   0=  if  tx-chainmask get-streams load-tx-iq-cal-avg-2passes  then
;

: init-cal  ( -- )
   40d8 reg@ 2.0000 and  if  3 3  else  7 7  then  set-chain-masks
   cal-tx-iq                  \ Do tx IQ calibration
   0 a20c reg!
   5 us
   1 a20c reg!
   1 1 a2c4 reg@!             \ Calibrate the AGC
   0 1 a2c4 wait-hw drop
   txchainmask rxchainmask set-chain-masks    \ Restore chain masks
   true start-nfcal
   reset-calibration
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
