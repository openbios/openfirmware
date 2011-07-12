purpose: A complex way to do MMP2 clock frequency setting based on Marvell code

\ Our current chip_id  is 00a0.a610 and stepping is 0000.4131  (A1)

\ vcc	pclk	pdclk	baclk	xpclk	dclk	aclk	name
create operating-points
decimal
1230 ,	100 ,	100 ,	100 ,	100 ,	400 ,	100 ,	\ "Ultra Low MIPS"
1230 ,	200 ,	200 ,	200 ,	200 ,	400 ,	200 ,	\ "Low MIPS"
1280 ,	400 ,	200 ,	200 ,	200 ,	400 ,	200 ,	\ "Video M MIPS"
1300 ,	800 ,	400 ,	400 ,	400 ,	400 ,	266 ,	\ "Video H MIPS"
1350 ,	1001 ,	500 ,	500 ,	500 ,	400 ,	266 ,	\ "Super H MIPS"
0 ,
hex

0 [if]
1300 ,	800 ,	400 ,	400 ,	400 ,	400 ,	200 ,	\ "Video H MIPS" - Z0/Z1 settings
1300 ,	624 ,	312 ,	312 ,	312 ,	312 ,	156 ,	\ "624MHz"  - only for Z0 and Z1 steppings

                                               pj4-cc    sp-cc     fccr  cgr pj4-cc-oct  sp-cc-oct
                                   cur       18fd96d9  8fd8241               3077313331  1077301101
                                   old       78fd8248  8fd8248               7077301110  1077301110 17.077.301.101
                                                                             cvr52ADXBCP   52ADXBpP
ok d# 100 find-op  new-reg-values .s clear   878b86c3  88b86c3   800000 a000 20742703303 1042703303
ok d# 200 find-op  new-reg-values .s clear   87898241  8898241   800000 a000 20742301101 1042301101
ok d# 400 find-op  new-reg-values .s clear   87898240  8898240   800000 a000 20742301100 1042301100
ok d# 800 find-op  new-reg-values .s clear   87890240  8890240 20800000 8000 20742201100 1042201100
ok d# 1001 find-op  new-reg-values .s clear  87890240  8890240 40800000 c000 20742201100 1042201100
[then]

\ IDLE, EXTIDLE, APPS_IDLE, APPS_SLEEP, SYS_SLEEP all have vcc=1280

0 value 'op
: pclk   ( -- mhz )  'op 1 na+ @  ;
\ : pdclk  ( -- mhz )  'op 2 na+ @  ;  \ This is effectively unused
: baclk  ( -- mhz )  'op 3 na+ @  ;
: xpclk  ( -- mhz )  'op 4 na+ @  ;
: dclk   ( -- mhz )  'op 5 na+ @  ;
: aclk   ( -- mhz )  'op 6 na+ @  ;
: datarate  ( -- mhz )  dclk 2*  ;

: ~=  ( n1 n2 -- flag )  -  -2 2 between  ;
: find-op  ( mhz -- )
   operating-points  begin  dup @  while  ( mhz adr )
      2dup na1+ @ ~=  if                   ( mhz adr )
         to 'op  drop  exit               ( -- )
      then                                ( mhz adr )
      7 na+                               ( mhz adr' )
   repeat                                 ( mhz adr )
   true abort" Can't find operating point"
;

0 value old-dclk
0 value new-fccr
0 value pll-pj4-frequency
0 value pll-ad-frequency
0 value new-cgr

: set-field  ( val bits bit# -- val' )  lshift or  ;
: >bit  ( bit# -- )  1 swap lshift  ;
: set-bit  ( val bit# -- val' )  >bit or  ;

create frequencies  d# 400 ,  d# 800 ,  0 ,  d# 26 ,
: fccr>frequency  ( source-id -- mhz )  frequencies swap na+ @  ;
: 'pll2-frequency  ( -- adr )  frequencies  2 na+   ;

create cgr-masks  d# 13 >bit ,  d# 15 >bit ,  d# 14 >bit ,  0  ,
: fccr>cgr-mask  ( source-id -- mhz )  cgr-masks swap na+ @  ;

: frequency>fccr  ( mhz -- fccr-bits )
   dup d# 26 =  if  drop 3 exit  then          \ Special case for VCXO frequency
   d# 800 over mod  3 <  if            ( mhz )  \ Close to a divisor of 800 ?
      d# 400 <=  if  0  else  1  then  ( fccr-bits )
   else                                ( mhz )
      'pll2-frequency @  if            ( mhz )
         drop                          ( )
      else                             ( mhz )
         'pll2-frequency !             ( )
      then                             ( )
      2                                ( fccr-bits )
   then                                ( fccr-bits )
;

: mhz>source-frequency  ( mhz fccr-bit# -- source-frequency )
   >r frequency>fccr                             ( fccr-bits r: fccr-bit# )
   dup r> lshift      new-fccr or  to new-fccr   ( fccr-bits )
   dup fccr>cgr-mask  new-cgr  or  to new-cgr    ( fccr-bits )
   fccr>frequency                                ( source-frequency )
;
: choose-pclk-source  ( -- )
   pclk d# 29 mhz>source-frequency  to pll-pj4-frequency   ( )
\   clip-pj4-clocks
;

: choose-dclk-source  ( -- )
   datarate d# 23 mhz>source-frequency  to pll-ad-frequency  ( )
\   clip-ad-clocks
;

\ The clock sources have been selected, so pll-pj4-frequency and pll-ad-frequency are valid
\ Calculate the various divisors and insert them into the appropriate fields for the
\ two clock control registers.
: compute-new-cc-regs  ( -- pj4-cc sp-cc )
   0                                                                      ( cc-reg )
   pclk   if  pll-pj4-frequency  pclk / 1-  0 set-field  then             ( cc-reg' )
   xpclk  if  pll-pj4-frequency xpclk / 1-  9 set-field  then             ( cc-reg' )
   pll-pj4-frequency baclk / 1-  baclk  if  6  else  3  then  set-field   ( cc-reg' )  \ Either BA_CLK (6) or CS_CLK (3)

   datarate  if   pll-ad-frequency datarate / 1- d# 12 set-field  then    ( cc-reg' )
   aclk   if  pll-ad-frequency aclk / 1- d# 15 set-field  then            ( cc-reg' )

\ The lines following this block force both async bits to be set, so this conditional setting is irrelevant
\  pdclk datarate <>  if  d# 19 set-bit  then   \ Async2 if pdclock2 != DDRClk
\  baclk aclk     <>  if  d# 23 set-bit  then   \ Async5 if baclk2 != aclk

   d# 19 set-bit  ( cc-reg' )   \ PMUA_CC_MOH_ASYNC2
   d# 23 set-bit  ( cc-reg' )   \ PMUA_CC_MOH_ASYNC5

   \ Write a subset of the fields to the SP's clock control register before finishing the value for the PJ4's CC reg
   dup  d# 27 >bit  or  swap   ( sp-cc-reg pj4-cc-reg )  \ PMUA_CC_SEA_SEA_ALLOW_SPD_CHG bit + others in PMUA_CC_SP

   pclk 0<>  baclk 0<>  or  ( pdclk 0<> or ) xpclk 0<> or  if  d# 24 set-bit  then  ( cc-reg' )  \ PMUA_CC_MOH_MOH_FREQ_CHG_REQ
   datarate  if  d# 25 set-bit  then  ( sp-cc-reg pj4-cc-reg' )  \ PMUA_CC_MOH_DDR_FREQ_CHG_REQ
   aclk      if  d# 26 set-bit  then  ( sp-cc-reg pj4-cc-reg' )  \ PMUA_CC_MOH_BUS_FREQ_CHG_REQ
[ifdef] notdef
   dup  h# 0700.0000 and  if  d# 27 set-bit  then   ( sp-cc-reg pj4-cc-reg' )
[then]
   d# 31 set-bit  ( sp-cc-reg pj4-cc-reg' )  \ PMUA_CC_MOH_MOH_RD_ST_CLEAR
   swap           ( pj4-cc-reg sp-cc-reg )
;

\ Assumes that 'op already points to an operating point table
: new-reg-values  ( -- pj4-cc sp-cc fccr cgr )
   0 to new-fccr  0 to new-cgr  'pll2-frequency off
   choose-pclk-source
   choose-dclk-source

\ I think this write is deferred until the DDR clock setting step
\ writel(fccr, info->pmum_base + FCCR_OFF);

   compute-new-cc-regs   ( pj4-cc sp-cc )
   new-fccr new-cgr      ( pj4-cc sp-cc fccr cgr )
;

\ Beginning of section that accesses the hardware

: +pmua  ( -- adr )  h# d428.2800 +  ;
: +pmum  ( -- adr )  h# d405.0000 +  ;

: pmum-pll2cr  ( -- adr )  h# 34 +pmum  ; 
: pmum-pll2-ctrl1  ( -- adr )  h# 414 +pmum  ; 
: get-pll2-frequency  ( -- mhz )
   pmum-pll2cr l@     ( regval )          \ PMUM_PLL2CR
   dup d# 19 5 bits   ( regval refdiv )
   swap d# 10 9 bits  ( refdiv fbdiv )
   2+  d# 26 *        ( refdiv numerator )
   swap 2+  /         ( mhz )
;
: reg-set  ( mask -- )   >r r@ l@  or  r> l!  ;
: reg-clr  ( mask -- )   >r r@ l@  swap invert and  r> l!  ;

4 constant refdiv  \ 4 is the only reference divisor value that is mentioned in the documentation

: setup-pll2  ( freq -- )
   refdiv 2+ *  d# 26  rounded-/             ( fbdiv )
   1 d# 29 lshift  pmum-pll2-ctrl1  reg-clr  ( fbdiv )  \ make sure pll2 is in reset

   
   pmum-pll2cr l@           ( fbdiv val )
   h# 100 invert and        ( fbdiv val' )  \ PMUM_PLL2CR_PLL2_SW_EN off
   dup pmum-pll2cr l!       ( fbdiv val )

   h# 0007.fc00 invert and  refdiv d# 19 lshift or   ( fbdiv val' )
   h# 00f8.0000 invert and  swap   d# 10 lshift or   ( val' )

   h# 200 or                ( val' )  \ PMUM_PLL2CR_CTRL
   dup pmum-pll2cr l!       ( val )

   h# 100 or                ( val )
   pmum-pll2cr l!           ( )       \ PMUM_PLL2CR_PLL2_SW_EN on

   1 d# 29 lshift  pmum-pll2-ctrl1  reg-set  ( )  \ pll2 out of reset

   d# 20 ms  \ C code uses 2M spins
;

: ?change-pll2-frequency  ( -- )
   'pll2-frequency @  ?dup  if       ( mhz )
      dup get-pll2-frequency <>  if  ( mhz )
         setup-pll2                  ( )
      else                           ( mhz )
         drop                        ( )
      then                           ( )
   then                              ( )
;

[ifdef] later
: set-sram-table  ( table-adr table# -- )
   4 lshift  h# 8000.0000 or   ( table-adr common-bits )
   #sram-table 0  do           ( table-adr common-bits )
      over i 8 * +             ( table-adr common-bits table-entry-adr )
      dup  l@ h# c20 dmcu!     ( table-adr common-bits table-entry-adr )
      la1+ l@ h# c30 dmcu!     ( table-adr common-bits )
      over i or  h# c00 dmcu!  ( common-bits table-adr )
   loop                        ( table-adr common-bits )
   2drop                       ( )
;
: x-do-fcs  ( cc-reg fccr dclk -- )
   dup old-dclk =  if      ( cc-reg fccr dclk )
      \ There is no need to do DDR recal if dclk is unchanged
      drop                 ( cc-reg fccr )
      0                    ( cc-reg fccr pmua_mc_par_ctrl-val )
   else                    ( cc-reg fccr dclk )
      dup to old-dclk      ( cc-reg fccr dclk )
      choose-ddr-table 0 set-sram-table  ( cc-reg fccr )
      4                    ( cc-reg fccr pmua_mc_par_ctrl-val )
   then  to pmua_mc_par_ctrl-val  ( cc-reg fccr )


\   STUFF
;
[then]
: do-fcs  ( cc-reg fccr dclk -- )
   drop  ." FCCR " .x   ."   CCR " .x cr
;

: current-dclk  ( -- mhz )
   8 +pmum l@  d# 23 rshift 7 and   fccr>frequency  ( source-mhz )
   4 +pmua l@ d# 12 rshift 7 and  1+ /
;

: PMUcore2_hw_fc_seq  ( -- )
   current-dclk to old-dclk
\    get-pll2-frequency to old-pll2-frequency
\    pll2-old-frequency pclk min to new-pll2-frequency

   d# 31 >bit  4 +pmua  reg-clr  \ PMUA_CC_MOH_MOH_RD_ST_CLEAR - clears PJ_RD_STATUS to allow frequency changing

   d# 21 >bit  h# 88 +pmua  reg-set \ Omit this on Z stepping - this is an undocumented bit in an undocumented debug register

   1 >bit  h# 98 +pmua reg-set     \ PMUA_MOH_IMR_MOH_FC_INTR_MASK bit in PMUA_PJ_IMR register

   begin           
      4 +pmua l@  d# 24 >bit  and  \ PMUA_DM_CC_MOH_SEA_RD_STATUS bit in DM_CC_MOH register
   0= until

   new-reg-values          ( pj4-cc sp-cc fccr cgr )

   ?change-pll2-frequency  ( pj4-cc sp-cc fccr cgr )

   h# 1024 +pmum l!        ( pj4-cc sp-cc fccr )
   swap  0 +pmua l!        ( pj4-cc-reg fccr )
   dclk  do-fcs            ( )

[ifdef] notdef
   2 >bit  h# b4 +pmua  reg-clr  \ MC_FC_SLP_EN bit in PMUA_MC_SLP_REQ_PJ register
[then]

   d# 31 >bit  4 +pmua  reg-clr  \ PMUA_CC_MOH_MOH_RD_ST_CLEAR (the documentation is unclear - is this bit write 1 to clr?)
;

0 [if]
0 value new-pll2-frequency
0 value old-pll2-frequency
: clip-pj4-clocks  ( -- )
   pll-pj4-frequency pclk  min to pclk    ( )
\   pll-pj4-frequency pdclk min to pdclk   ( )
   pll-pj4-frequency baclk min to baclk   ( )
   pll-pj4-frequency xpclk min to xpclk   ( )
;
: clip-ad-clocks  ( -- )
   pll-ad-frequency aclk     min  to aclk      ( )
   pll-ad-frequency datarate min  to datarate  ( )
;

: old-choose-pclk-source  ( -- )
   pclk case
      d# 100  of  d# 400  d# 13 >bit  0  endof
      d# 200  of  d# 400  d# 13 >bit  0  endof
      d# 400  of  d# 400  d# 13 >bit  0  endof
      d# 800  of  d# 800  d# 15 >bit  1  endof
      ( default )
         old-pll2-frequency new-pll2-frequency <>  if
            new-pll2-frequency setup-pll2
         then
         >r  new-pll2-frequency  d# 14 >bit  2  r>
   endcase                           ( pll-pj4-frequency acgr-bits fccr-bits  )

   d# 29 lshift  to new-fccr         ( pll-pj4-frequency acgr-bits )
   new-cgr or to new-cgr             ( pll-pj4-frequency )
   to pll-pj4-frequency                   ( )
\  clip-pj4-clocks
;
: old-choose-dclk-source  ( -- )
   datarate case
      d# 100  of  d# 400  d# 13 >bit  0  endof
      d# 200  of  d# 400  d# 13 >bit  0  endof
      d# 400  of  d# 400  d# 13 >bit  0  endof
      d# 800  of  d# 800  d# 15 >bit  1  endof
      ( default ) >r  pll-pj4-frequency  d# 14 >bit  2  r>
   endcase                                      ( pll-ad-frequency acgr-bits fccr-bits  )

   new-fccr  over d# 23 set-field  to new-fccr  ( pll-ad-frequency acgr-bits )
   new-cgr  or to new-cgr                       ( pll-ad-frequency )
   to pll-ad-frequency                          ( )
\  clip-ad-clocks
;
[then]
