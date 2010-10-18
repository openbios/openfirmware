purpose: Board-specific details of TWSI-connected devices

\ TWSI devices per channel:
\ 1 MAX8925 PMIC MAIN 78, PMIC ADC 8e, PMIC RTC d0,   MAX8649 c0
\ 2 WM8994 Audio Codec 34, WM2000 Noise Canceler 74
\ 3 m6M0 Camera ISP 3e, OV8810 Camera 6c
\ 4 HMC5843 compass 3c, CM3623 ALS/PS 20+22+b0, BMA150 accelerometer 70
\ 5 TC358762 MIPI bridge 16, TM-1210 or TM1414 touchscreen 40
\ 6 HDMI DDC EDID a0

: select-touch-panel  ( -- )  h# 40 5 set-twsi-target  ;
: touch-panel-type  ( -- n )  select-touch-panel  h# bd twsi-b@  ;
: get-tm1414-data  ( -- x y finger-mask )
   select-touch-panel                                   ( )
   h# 1a twsi-b@                                        ( low-y,low-x )
   dup h# f and  h# 18 twsi-b@   4 lshift or            ( low-y,low-x x )
   swap 4 rshift h# f and  h# 19 twsi-b@   4 lshift or  ( x y )
   h# 15 twsi-b@                                        ( x y mask )   
;
: touchpad@  ( -- x y finger-mask )  get-tm1414-data  ;

: get-tm1210-data  ( -- x y reg7-flick-magnitude reg6-gesture reg0-finger-count )
   3 twsi-b@  2 twsi-b@  bwjoin    ( x )
   5 twsi-b@  4 twsi-b@  bwjoin    ( x y )

   7 twsi-b@ 
   6 twsi-b@     
   0 twsi-b@
;

: compass@  ( -- x y z temp id )
   h# 3c 4 set-twsi-target
   0 0 twsi-b!      \ Config register A
   h# 50 1 twsi-b!  \ Config register B
   0 2 twsi-b!      \ Mode register
   4 twsi-b@  3 twsi-b@  bwjoin     ( x )
   6 twsi-b@  5 twsi-b@  bwjoin     ( x y )
   8 twsi-b@  7 twsi-b@  bwjoin     ( x y z )
   h# b twsi-b@                     ( x y z temp )
   h# a twsi-b@  9 twsi-b@  bwjoin  ( x y z temp id )
;

: select-pmic  ( -- )  h# 78 1 set-twsi-target  ;

: accel-power-on  ( -- )  \ LDO8 - vout is 36, ctl is 34
   select-pmic
   d# 3000 d# 750 -  d# 50 /   h# 36 twsi-b!     \ want 3.0V
   h# 1f h# 34 twsi-b!
;
: accel-power-off  ( -- )  \ LDO8 - vout is 36, ctl is 34
   select-pmic
   h# 1e h# 34 twsi-b!
;
: accel@  ( -- x y z temp id )
   h# 70 4 set-twsi-target

   2 twsi-b@ 6 rshift     ( x-low )
   3 twsi-b@ 2 lshift or  ( x )

   4 twsi-b@ 6 rshift     ( x y-low )
   5 twsi-b@ 2 lshift or  ( x y )

   6 twsi-b@ 6 rshift     ( x y z-low )
   7 twsi-b@ 2 lshift or  ( x y z )

   8 twsi-b@  0 twsi-b@   ( x y z temp id )
;

: init-pals  ( -- )
   h# b0 4 set-twsi-target  \ Set PS parameters address
   0 1 twsi-write     \ clear interrupt settings

   h# 22 4 set-twsi-target  \ Device init address
   h# 10 1 twsi-write \ Init device

   h# 20 4 set-twsi-target  \ Ambient Light Sensor address
   2 1 twsi-write     \ Enable ALS in most sensitive mode, 16-bit data
;
: als@  ( -- n )
   h# 22 4 set-twsi-target  \ Ambient Light Sensor LSB address
   0 1 twsi-get            ( low )
   h# 20 4 set-twsi-target  \ Ambient Light Sensor MSB address
   0 1 twsi-get  bwjoin   ( n )
;

: proximity@  ( -- byte )
   h# b0 4 set-twsi-target  \ Proximity Sensor address
   0 1 twsi-get            ( byte )
;

: lcd-backlight!  ( b.intensity -- )
   select-pmic      ( b.intensity )
   dup  if          ( b.intensity )
      h# 85 twsi-b!    ( )
      h# 84 twsi-b@  1 or  h# 84 twsi-b!   \ Turn on first LED string
   else             ( 0 )
      drop          ( )
      h# 84 twsi-b@  1 invert and  h# 84 twsi-b!   \ Turn off first LED string
   then
;

: keypad-backlight!  ( b.intensity -- )
   select-pmic         ( b.intensity )
   dup  if             ( b.intensity )
      h# 85 twsi-b!    ( )
      h# 84 twsi-b@  3 or  h# 84 twsi-b!   \ Turn on both LED strings
   else                ( )
      h# 84 twsi-b@  3 invert and  h# 84 twsi-b!   \ Turn off both LED strings
   then
;

: power-on-dsi  ( -- )
   select-pmic

   h# 16 h# 22 twsi-b!  \ 1.2 volts for LDO3
   h# 1f h# 20 twsi-b!  \ LDO3 enable

   h# 16 h# 16 twsi-b!  \ 1.2 volts for LDO17
   h# 1f h# 14 twsi-b!  \ LDO17 enable

   h# 1f h# 34 twsi-b!  \ LDO8 enable

   d# 10 ms
;

: bcd>  ( bcd -- binary )
   dup h# f and  swap 4 rshift d# 10 *  +
;
: twsi-bcd@   ( reg# -- binary )  twsi-b@ bcd>  ;
: get-rtc  ( -- )
   h# d0 1 set-twsi-target

\   3 twsi-b@   ( dow )
\   

   0 twsi-bcd@  ( sec )
   1 twsi-bcd@  ( sec min )
   2 twsi-bcd@  ( sec min hr )
   4 twsi-bcd@  ( sec min hr day )
   5 twsi-bcd@  ( sec min hr day mon )
   6 twsi-bcd@ d# 2000 + ( sec min hr day yr )
;

: core-voltage!  ( mv -- )
   h# c0 1 set-twsi-target  \ MAX8649 power management IC

   d# 750 umax  d# 1350 umin   \ Clipped voltage
   d# 750 -  d# 10 /      ( offset-in-mv/10 )
   h# 80 or               ( code )
   2 twsi-b!
;
: core-voltage@  ( -- mv )
   h# c0 1 set-twsi-target  \ MAX8649 power management IC
   2 twsi-b@     ( code )
   h# 7f and     ( offset-mv/10 )
   d# 10 *       ( offset-mv )
   d# 750 +
;
: .core-voltage  ( -- )  core-voltage@ .d  ;

: vibrate-on  ( -- )  select-pmic  h# 1f h# 3c twsi-b!  ;  \ LDO10
: vibrate-off  ( -- )  select-pmic  h# 1e h# 3c twsi-b!  ;

: power-on-sd ( -- )
   select-pmic
   h# 29 h# 42 twsi-b!
   h# 1f h# 40 twsi-b!
;
: power-off-sd  ( -- )
   select-pmic
   h# 1e h# 40 twsi-b!
;
