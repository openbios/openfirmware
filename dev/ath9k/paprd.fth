purpose: ATH9K PAPRD code
\ See license at end of file

headers
hex

: get-streams  ( chainmask -- #1bits )
   ( val ) 0  3 0  do  over i >> 1 and +  loop  nip
;

: enable-paprd  ( flag -- )
   dup  if
      true to paprd-table-write-done?
      curchan false set-txpower
   then
   dup 1 98f0 reg@!
   tx-chainmask 2 and  if  dup 1 a8f0 reg@!  then
   tx-chainmask 4 and  if  dup 1 b9f0 reg@!  then
   drop
;

[ifdef] notyet
0 value paprd-training-power
d# 32 /n* buffer: paprd-gain-table-entry
d# 32 buffer: paprd-gain-table-index

: get-training-power-2G  ( -- power )
   eeprom >modalHeader2G >papdRateMaskHt20 le-l@ d# 25 >> 7 and
   paprd-target-power over - abs dup ( power delta delta )
   a3d0 reg@  3f and                 ( power delta delta scale )
   >  if  2drop -1  exit  then       ( power delta )
   dup 4 <  if  + 4 -  then          ( power' )
;

: get-training-power-5G  ( -- power )
   curchan >ch-freq @ d# 5700 >=  if
      eeprom >modalHeader5G >papdRateMaskHt20 le-l@ d# 25 >>
   else
   curchan >ch-freq @ d# 5400 >=  if
      eeprom >modalHeader5G >papdRateMaskHt40 le-l@ d# 28 >>
   else
      eeprom >modalHeader5G >papdRateMaskHt40 le-l@ d# 25 >>
   then  then  7 and                ( scale )

   curchan is-ht40?  if  a3dc  else  a3d4  then  reg@ 8 >> 3f and over +
                                    ( scale power )
   paprd-target-power over - abs    ( scale power delta )
   rot >  if  drop -1 exit  then    ( power )
   tx-chainmask get-streams 2* +    ( power' )
;

create ctrl0  98f0 , a8f0 , b8f0 ,
create ctrl1  98f4 , a8f4 , b8f4 ,
: setup-paprd-single-table  ( -- )
   curchan is-2GHz?  if  get-training-power-2G  else  get-training-power-5G  then
   dup 0<  if
      " ERROR: PAPRD target power out of training range" vtype
      drop exit
   then
   to paprd-training-power

   paprd-ratemask 1ff.ffff 98e4 reg@!
   paprd-ratemask 1ff.ffff 98e8 reg@!
   paprd-ratemask-ht40 1ff.ffff 98ec reg@!

   max-txchains 0  do
      1800.0002 f800.0002 ctrl0 i na+ @ reg@!
      02d2.0006 0fff.fe07 ctrl1 i na+ @ reg@!
   loop

   false enable-paprd
   0003.0c39 0003.ff7f a690 reg@!
   d# 147 a694 reg!
   244e.1eb1 2fff.ffff a698 reg@!
   0064.0190 03ff.ffff a69c reg@!
   d# 261376 3.ffff 9900 reg@!
   d# 248079 3.ffff 9904 reg@!
   d# 233759 3.ffff 9908 reg@!
   d# 330464 3.ffff 990c reg@!
   d# 208194 3.ffff 9910 reg@!
   d# 196949 3.ffff 9914 reg@!
   d# 185706 3.ffff 9918 reg@!
   d# 175487 3.ffff 991c reg@!
;

: get-paprd-gain-table  ( -- )
   d# 32 0  do
      a500 i la+ reg@
      dup paprd-gain-table-entry i na+ !
      d# 24 >> paprd-gain-table-index i + c!
   loop
;

0 value desired-scale
0 value alpha-therm
0 value alpha-volt
0 value therm-cal-val
0 value volt-cal-val
0 value therm-val
0 value volt-val
: get-desired-gain  ( target-power chain -- desired-gain )
   0 1 a6a0 reg@!
   a42a reg@ 3e00.0000 and d# 25 >> to desired-scale
   a440 reg@ 001f.00ff and dup d# 16 >> to alpha-volt
                               ff and   to alpha-therm
   a43c reg@ 0000.ffff and dup 8 >>     to volt-cal-val
                               ff and   to therm-cal-val
   a454 reg@ 0000.ffff and dup 8 >>     to volt-val
                               ff and   to therm-val
   ( chain ) 1000 * a420 + reg@  ff.0000 and d# 16 >>
   dup d# 128 >  if  d# 256 -  then  -  ( desired-gain )
   alpha-therm therm-val therm-cal-val - * d# 128 + 8 >>a -
   alpha-volt  volt-val  volt-cal-val  - * d#  64 + 7 >>a -
   desired-scale +                      ( desired-gain' )
;

: force-tx-gain  ( gain-idx -- )
   paprd-gain-table-entry swap na+ @       ( gain-entry )
   00ff.ffff and 1 << 01ff.ffff a458 reg@! ( )
   0 3f a3f8 reg@!
;

: setup-paprd-gain-table  ( chain -- )
   paprd-training-power swap get-desired-gain
   0 swap  d# 32 0  do             ( idx desired-gain )
      paprd-gain-table-index i + c@ over >=  if  nip i swap leave  then
   loop  drop                      ( idx )
   force-tx-gain
   0 1 a6a0 reg@!
;

: init-paprd-table  ( -- )
   setup-paprd-single-table
   get-paprd-gain-table
;

: populate-paprd-single-table  ( chain caldata -- )
   dup >pa-table 2 pick d# 24 * na+   ( chain caldata patable[chain] )
   2 pick 1000 * 9920 +               ( chain caldata patable[chain] reg )
   d# 24 0  do
      over i na+ @ over i na+ reg!
   loop  2drop                        ( chain caldata )

   >small-signal-gain over na+ @      ( chain small-signal-gain[chain] )
   swap 1000 * 98f8 +                 ( small-signal-gain[chain] reg )
   3ff swap reg@!                     ( )
   paprd-training-power 3 << 1f8 98f4 reg@!
   tx-chainmask 2 and  if  paprd-training-power 3 << 1f8 a8f4 reg@!  then
   tx-chainmask 4 and  if  paprd-training-power 3 << 1f8 b8f4 reg@!  then
;

: paprd-done?  ( -- done? )  a6a0 reg@ 1 and  ;

\ Arguments from create-paprd-curve
d# 48 2* /n* buffer: data-buf
0 value data-l
0 value data-u

\ Local variables
d# 24 constant #bin
#bin /n* constant /binbuf
/binbuf buffer: theta
/binbuf buffer: y
/binbuf buffer: yest
/binbuf buffer: xest
/binbuf buffer: xtilde
/binbuf buffer: b1tmp
/binbuf buffer: b2tmp
/binbuf buffer: PAin
0 value max-idx
0 value accum-cnt
0 value G-fxp
0 value cM
0 value cI
0 value cL
0 value sum-y2
0 value sum-y4
0 value xtilde-abs
0 value Qx
0 value Qb1
0 value Qb2
0 value beta
0 value alpha
0 value beta-raw
0 value alpha-raw
0 value scale-b
0 value Qscale-b
0 value Qbeta
0 value Qalpha
0 value order1-5x
0 value order2-3x
0 value order1-5x-rem
0 value order2-3x-rem

\ Local routines
: data-l@  ( i -- n )  data-l swap na+ @  ;
: data-u@  ( i -- n )  data-u swap na+ @  ;
: xtilde@  ( i -- n )  xtilde swap na+ @  ;
: xtilde!  ( n i -- )  xtilde swap na+ !  ;
: xest@    ( i -- n )  xest swap na+ @  ;
: xest!    ( n i -- )  xest swap na+ !  ;
: theta@   ( i -- n )  theta swap na+ @  ;
: theta!   ( n i -- )  theta swap na+ !  ;
: y@       ( i -- n )  y swap na+ @  ;
: y!       ( n i -- )  y swap na+ !  ;
: yest@    ( i -- n )  yest swap na+ @  ;
: yest!    ( n i -- )  yest swap na+ !  ;
: b1tmp@   ( i -- n )  b1tmp swap na+ @  ;
: b1tmp!   ( n i -- )  b1tmp swap na+ !  ;
: b2tmp@   ( i -- n )  b2tmp swap na+ @  ;
: b2tmp!   ( n i -- )  b2tmp swap na+ !  ;
: PAin@    ( i -- n )  PAin swap na+ @  ;
: PAin!    ( n i -- )  PAin swap na+ !  ;
: scale@   ( n -- scale )  log2 d# 10 - 0 max  ;
: up>>  ( n scale -- n' )  1 over << 1- rot + swap >>  ;
: up>>a  ( n scale -- n' )  1 over << 1- rot + swap >>a  ;
: up/   ( n r -- r' )  tuck 1- + swap /  ;

: (create-paprd-curve)  ( pa-table gain -- error? )
   y     /binbuf erase   yest   /binbuf erase    theta /binbuf erase  
   xest  /binbuf erase   xtilde /binbuf erase
   0 to max-idx
   #bin 1- 0  do
      i data-l@ ffff and dup to accum-cnt  d# 16 >  if       \ Enough samples
         \ sum of tx amplitude
         i data-l@ d# 16 >> i data-u@ 7ff and  wljoin 5 <<
         accum-cnt up/ 5 up>>  i 1+ xest!
         \ sum of rx amplitude to lower bin edge
         i data-u@ d# 11 >> 1f and  i d# 23 + data-l@ ffff and 5 <<  or 5 <<
         accum-cnt up/ 5 up>> max-idx 5 << + d# 16 +  i 1+ y!
         \ sum of angles
         i d# 23 + data-l@ d# 16 >> i d# 23 + data-u@ 7ff and wljoin
         dup 400.0000 >=  if  800.0000 -  then  5 <<
         accum-cnt up/  i 1+ theta!
         max-idx 1+ to max-idx
      then
   loop

   \ Find average theta of first 5 bin and all of those to same value.
   \ Curve is linear at that range.
   0  6 0  do  i theta@ +  loop  5 /      ( pa-table gain theta-avg )
   6 0  do  dup i theta!  loop            ( pa-table gain theta-avg )
   max-idx 1+ 0  do  i theta@ over - i theta!  loop  drop

   6 xest@ 3 xest@ =  if  2drop true exit  then  \ Low signal gain

   6 y@ 3 y@ - 8 <<  6 xest@ 3 xest@ - up/
   ?dup 0=  if  2drop true exit  then     \ Prevent divide by 0
   dup to G-fxp

   0 xest@ 3 xest@ - * d# 256 up/ 3 y@ +  ( pa-table gain y-intercept )
   max-idx 1+ 0  do  i y@ over - i yest!  loop  drop
   4 0  do
      i 5 << dup i yest!
      ( yest[i] ) 8 <<  G-fxp up/  i xest!
   loop

   max-idx yest@ ?dup 0=  if  2drop true exit  then

   max-idx xest@ over 8 <<  G-fxp up/ -  swap up/  case
      0  of  d# 10  endof
      1  of      9  endof
      ( otherwise )  8 swap
   endcase  to cM
   max-idx 1 >> 7 min to cI
   max-idx cI - 1+ to cL

   0 to sum-y2  0 to sum-y4  0 to xtilde-abs
   false cL 0  do               ( pa-table gain false )
      i cI + yest@ ?dup 0=  if  drop true leave  then
                  ( pa-table gain false yest[i+cI] )
      i cI + xest@ over 8 << - G-fxp up/ cM << over up/
                                         cM << over up/
                                         cM << over up/
      dup i xtilde!             ( pa-table gain false yest[i+cI] xtilde[i] )
      abs  dup xtilde-abs >  if  to xtilde-abs  else  drop  then
      dup * d# 64 up/           ( pa-table gain false yest[i+cI]**2 )
      dup sum-y2 + to sum-y2    ( pa-table gain false yest[i+cI]**2 )
      dup i b2tmp!              ( pa-table gain false yest[i+cI]**2 )
      dup cL * i b1tmp!         ( pa-table gain false yest[i+cI]**2 )
      dup * sum-y4 + to sum-y4  ( pa-table gain false )
   loop
   if  2drop true exit  then

   0 0  cL 0  do                ( pa-table gain max-b1-abs max-b2-abs )
      i b1tmp@ sum-y2 - dup i b1tmp!
      abs rot max swap          ( pa-table gain max-b1-abs' max-b2-abs )
      sum-y4 i b2tmp@ sum-y2 * - dup i b2tmp!
      abs max                   ( pa-table gain max-b1-abs max-b2-abs' )
   loop

   ( max-b2-abs ) scale@ to Qb2
   ( max-b1-abs ) scale@ to Qb1
   xtilde-abs scale@ to Qx
   0 to beta-raw   0 to alpha-raw
   cL 0  do
      i xtilde@ Qx  >>a dup i xtilde!   ( pa-table gain xtilde[i] )
      i b1tmp@  Qb1 >>a dup i b1tmp!    ( pa-table gain xtilde[i] b1tmp[i] )
      over * beta-raw + to beta-raw     ( pa-table gain xtilde[i] )
      i b2tmp@  Qb2 >>a dup i b2tmp!    ( pa-table gain xtilde[i] b2tmp[i] )
      * alpha-raw + to alpha-raw        ( pa-table gain )
   loop

   sum-y4 3 >>a cL *  sum-y2 dup 3 >>a * 3 << -    ( pa-table gain scale-b )
   dup abs scale@ dup to Qscale-b >>a              ( pa-table gain scale-b' )
   ?dup 0=  if  2drop true exit  then  to scale-b  ( pa-table gain )

   beta-raw  dup abs scale@ dup to Qbeta   >>a dup to beta-raw
   d# 10 << scale-b / to beta
   alpha-raw dup abs scale@ dup to Qalpha  >>a dup to alpha-raw
   d# 10 << scale-b / to alpha

   cM 3 * Qx - d# 10 + Qscale-b + dup
   Qb1 - Qbeta  - 5 /mod  to order1-5x  to order1-5x-rem
   Qb2 - Qalpha - 3 /mod  to order2-3x  to order2-3x-rem

   #bin 0  do
      i 5 <<                             ( pa-table gain i*32 )
      beta over * order1-5x 6 + >>       ( pa-table gain i*32 y5 )
      4 0  do  over * order1-5x >>  loop ( pa-table gain i*32 y5' )
      order1-5x-rem >>                   ( pa-table gain i*32 y5' )
      swap alpha                         ( pa-table gain y5 i*32 y3 )
      3 0  do  over * order2-3x >>  loop ( pa-table gain y5 i*32 y3' )
      order2-3x-rem >>                   ( pa-table gain y5 i*32 y3' )
      swap 8 << G-fxp / + + i PAin!      ( pa-table gain )
      i 2 >=  if
         i PAin@ i 1- PAin@ <  if
            i 1- PAin@ dup i 2 - PAin@ - +  i PAin!
         then
      then
      i PAin@ d# 1400 min  i PAin!
   loop

   0 to beta-raw  0 to alpha-raw
   cL 0  do
      i cI + yest@                       ( pa-table gain yest[i+cI] )
      i cI + theta@ cM << over up/       ( pa-table gain yest[i+cI] theta~ )
                    cM << over up/       ( pa-table gain yest[i+cI] theta~' )
                    cM << swap up/       ( pa-table gain theta~' )
      dup i b1tmp@ * beta-raw + to beta-raw
          i b2tmp@ * alpha-raw + to alpha-raw
   loop

   beta-raw  dup abs scale@ dup to Qbeta  >>a to beta-raw
   alpha-raw dup abs scale@ dup to Qalpha >>a to alpha-raw

   alpha-raw d# 10 << scale-b / to alpha
   beta-raw  d# 10 << scale-b / to beta
   cM 3 * Qx - d# 10 + Qscale-b + 5 + dup
   Qb1 - Qbeta  - 5 /mod  to order1-5x  to order1-5x-rem
   Qb2 - Qalpha - 3 /mod  to order2-3x  to order2-3x-rem

   #bin 0  do
      i 4 <>  if
         i 4 <  if
            0                            ( pa-table gain pa-angle )
         else
            i 5 <<
            beta 0>=  if
               beta over * order1-5x 6 + >>
            else
               beta over * order1-5x 6 + up>>a
            then
            4 0  do  over * order1-5x >>a  loop
            order1-5x-rem >>a            ( pa-table gain i*32 y5 )

            swap alpha 0>=  if
               alpha over * order2-3x >>
            else
               alpha over * order2-3x up>>a
            then
            over * order2-3x >>a  swap * order2-3x >>a  order2-3x-rem >>a
                                         ( pa-table gain y5 y3 )
            + d# -150 max  d# 150 min    ( pa-table gain pa-angle )
         then
         dup 7ff and i PAin@ 7ff and d# 11 << or 3 pick i na+ ! \ pa-table[i] !
         i 5 =  if
            1+ 1 >> 7ff and  i 1- PAin@ 7ff and d# 11 << or  2 pick i 1- na+ ! \ pa-table[i-1] !
         else
            drop
         then
      then
   loop

   G-fxp swap !  drop  false             ( false )
;

: create-paprd-curve  ( caldata chain -- error? )
   2dup  d# 24 /n* * swap >pa-table + dup d# 24 /n* erase
                                   ( caldata chain 'pa-table[chain] )
   data-buf to data-l
   data-buf d# 48 /n* + to data-u
   0 8 a370 reg@!
   d# 48 0  do  9b00 i na+ reg@  data-l i na+ !  loop
   8 8 a370 reg@!
   d# 48 0  do  9b00 i na+ reg@  data-u i na+ !  loop

   rot >small-signal-gain rot +    ( 'pa-table[chain] 'small-signal-gain[chain] )
   (create-paprd-curve)  if  true exit  then
   0 1 a6a0 reg@!
   false
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
