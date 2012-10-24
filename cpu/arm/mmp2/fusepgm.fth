\ Script to change the speed code in 1 GHz production MMP2 chips to
\ match the old speed code value that was used for 1 GHz engineering
\ sample MMP2 chips.

0 value fuse-block#
: fuse-ena!  ( n -- )  h# 68 pmua!  ;
: fuse-ena@  ( -- n )  h# 68 pmua@  ;

: ena-fuse-module  ( -- )
   \ Do not touch the enable register if it is already enabled.
   \ That register also controls the interface between the SP and
   \ PJ4 processors, which is used for keyboard communication.
   \ The enabling process resets the device, causing system lockups
   \ if the keyboard interface is active.
   fuse-ena@  h# 1b =  if  exit  then   

   h# 08 fuse-ena!
   h# 09 fuse-ena!
   h# 19 fuse-ena!
   h# 1b fuse-ena!
;

: fuse-ctl!  ( n -- )
   fuse-block# d# 18 lshift or  h# 292804 io!
   d# 100 ms
;

: otp-setup  ( -- )
   ena-fuse-module
   h# 0002.0000 fuse-ctl!   \ HiV
   h# 0042.0000 fuse-ctl!   \ Reset + HiV
   h# 0002.0000 fuse-ctl!   \ HiV
;
: otp-teardown  ( -- )
   h# 0200.4000 fuse-ctl!   \ ClkDiv                      + SOFT
   h# 0240.4000 fuse-ctl!   \ ClkDiv + SetRst             + SOFT
   h# 0200.4000 fuse-ctl!   \ ClkDiv                      + SOFT
;

: pgm-fuses2  ( v7 v6 v5 v4 v3 v2 v1 v0 block# -- )
   to fuse-block#                            ( v7 v6 v5 v4 v3 v2 v1 v0 )
   otp-setup                                 ( v7 v6 v5 v4 v3 v2 v1 v0 )
   h# 292838 h# 20 bounds  do  i io!  4 +loop  ( )

   h# 0203.4000 fuse-ctl!   \ ClkDiv +         HiV + Burn + SOFT
   begin  h# 292984 io@ h# 100 and  until  \ Wait for complete
   h# 0202.4000 fuse-ctl!   \ ClkDiv +         HiV +      + SOFT
   h# 0200.4000 fuse-ctl!   \ ClkDiv +                    + SOFT
   h# 0240.4000 fuse-ctl!   \ ClkDiv + SetRst             + SOFT
   h# 0200.4000 fuse-ctl!   \ ClkDiv +                    + SOFT

   otp-teardown
;

2 value es-speed-1g  \ This is the engineering sample speed code for 1 GHz parts
: fix-speed  ( -- )
   ena-fuse-module

   \ Reprogram only if the divider values are the ones that we
   \ observe in the first batch of production parts - indicating
   \ that the SoC is not an engineering sample
   h# 290c fuse@  h# 90001410 =  if

      \ Reprogram only if the SW version field is 0 - a virgin part
      \ that we have not yet reprogrammed
      h# 2898 fuse@ 0=  if

         \ If the speed code indicates a 988 MHz part, change the
         \ speed code to the old engineering sample code for 1001 MHz
         \ and reboot to switch to the higher speed
         rated-speed 0=  if
            es-speed-1g d# 14 lshift 0 0 1  0 0 0 0   3 pgm-fuses2
            bye
         then

         \ If the speed code has already been reprogrammed to the
         \ engineering sample 1001 MHz value, but the SW version field
         \ is 0, set the SW version field to 1.  This fixes an initial
         \ batch of 200 chips whose speed code was reprogrammed
         \ using a different procedure.
         rated-speed 2 =  if
            0 0 0 1  0 0 0 0   3 pgm-fuses2
         then
      then
   then
;
