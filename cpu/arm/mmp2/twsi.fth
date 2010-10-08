purpose: Driver for Two Wire Serial Interface on Marvell Armada 610

\ 0 0  " d4011000"  " /" begin-package

0 value chip
0 value clock-reg
0 value slave-address

: dbr@  ( -- n )  chip h# 08 + l@   ;
: cr@   ( -- n )  chip h# 10 + l@   ;
: sr@   ( -- n )  chip h# 18 + l@   ;
: sar@  ( -- n )  chip h# 20 + l@   ;
: lcr@  ( -- n )  chip h# 28 + l@   ;
: dbr!  ( n -- )  chip h# 08 + l!   ;
: cr!   ( n -- )  chip h# 10 + l!   ;
: sr!   ( n -- )  chip h# 18 + l!   ;
: sar!  ( n -- )  chip h# 20 + l!   ;
: lcr!  ( n -- )  chip h# 28 + l!   ;

create channel-bases
h# D4011000 ,  h# D4031000 ,  h# D4032000 ,  h# D4033000 ,  h# D4033800 ,  h# D4034000 ,

create clock-offsets
h# 04 c,  h# 08 c,  h# 0c c,  h# 10 c,  h# 7c c,  h# 80 c,

create slave-addresses  \ per channel
h# 78 c,  \ 1 MAX8925 PMIC MAIN 78, PMIC ADC 8e, PMIC RTC d0,   MAX8649 c0
h# 34 c,  \ 2 WM8994 Audio Codec 34, WM2000 Noise Canceler 74
h# 3e c,  \ 3 m6M0 Camera ISP 3e, OV8810 Camera 6c
h# 3c c,  \ 4 HMC5843 compass 3c, CM3623 ALS/PS 20+22+b0, BMA150 accelerometer 70
h# 16 c,  \ 5 TC358762 MIPI bridge 16, TM-1210 or TM1414 touchscreen 40
h# a0 c,  \ 6 HDMI DDC EDID a0

: set-slave  ( n -- )  to slave-address  ;
: set-address  ( n -- )  \ Channel numbers range from 1 to 6
   1-
   channel-bases over na+ @  to chip  ( n )
   dup clock-offsets + c@  clock-unit-pa +  to clock-reg  ( n )
   slave-addresses + c@  set-slave
;

\       Bit defines

h# 4000 constant bbu_ICR_UR                \ Unit Reset bit
h# 0040 constant bbu_ICR_IUE               \ ICR TWSI Unit enable bit
h# 0020 constant bbu_ICR_SCLE              \ ICR TWSI SCL Enable bit
h# 0010 constant bbu_ICR_MA                \ ICR Master Abort bit
h# 0008 constant bbu_ICR_TB                \ ICR Transfer Byte bit
h# 0004 constant bbu_ICR_ACKNAK            \ ICR ACK bit
h# 0002 constant bbu_ICR_STOP              \ ICR STOP bit
h# 0001 constant bbu_ICR_START             \ ICR START bit
h# 0040 constant bbu_ISR_ITE               \ ISR Transmit empty bit
h# 0400 constant bbu_ISR_BED               \ Bus Error Detect bit

h# 1000 constant BBU_TWSI_TimeOut          \ TWSI bus timeout loop counter value

bbu_ICR_IUE bbu_ICR_SCLE or constant iue+scle
: init-twsi-channel  ( channel# -- )
   set-address
   7 clock-reg l!  3 clock-reg l!  \ Set then clear reset bit
   1 us
   iue+scle  bbu_ICR_UR or  cr!  \ Reset the unit
   iue+scle cr!                  \ Release the reset
   0 sar!                        \ Set host slave address
   0 cr!                         \ Disable interrupts
;

: twsi-run  ( extra-flags -- )
   iue+scle or  bbu_ICR_TB or  cr!    ( )

   h# 1000  0  do
      cr@ bbu_ICR_TB and 0=  if   unloop exit  then
   loop
   true abort" TWSI timeout"
;
: twsi-putbyte  ( byte extra-flags -- )
   swap dbr!      ( extra-flags )
   twsi-run
;
: twsi-getbyte  ( extra-flags -- byte )
   twsi-run  ( )
   dbr@      ( byte )
   sr@ sr!   ( byte )
;

: twsi-start  ( slave-address -- )
   bbu_ICR_START  twsi-putbyte        ( )
   sr@  bbu_ISR_BED and  if           ( )
      bbu_ISR_BED sr!                 ( )
      iue+scle bbu_ICR_MA or  cr!     ( )
      true abort" TWSI bus error"
   then                               ( )
;

: twsi-get  ( register-address .. #reg-bytes #data-bytes -- data-byte ... )
   >r                    ( reg-adr .. #regs  r: #data-bytes )
   \ Handle the case where the device does not require that a write register address be sent
   slave-address         ( reg-adr .. #regs slave-address  r: #data-bytes )
   over 0=  if           ( reg-adr .. #regs slave-address  r: #data-bytes )
      r@  if             ( reg-adr .. #regs slave-address  r: #data-bytes )
         1 or            ( reg-adr .. #regs slave-address' r: #data-bytes )
      then               ( reg-adr .. #regs slave-address' r: #data-bytes )
   then                  ( reg-adr .. #regs slave-address' r: #data-bytes )

   twsi-start            ( reg-adr .. #regs  r: #data-bytes )

   \ Abort the transaction if both #reg-bytes and #data-bytes are 0
   dup r@ or  0=  if                  ( #regs  r: #data-bytes )
      iue+scle bbu_ICR_MA or  cr!     ( #regs  r: #data-bytes )  \ Master abort
      r> 2drop exit                   ( -- )
   then                               ( reg-adr .. #regs  r: #data-bytes )

   \ Send register addresses, if any
   0  ?do  0 twsi-putbyte  loop       ( r: #data-bytes )

   \ If no result data requested, quit now
   r>  dup 0=  if                     ( #data-bytes )
      drop                            ( )
      iue+scle bbu_ICR_STOP or  cr!   ( )
      exit
   then                               ( #data-bytes )

   \ Otherwise send the read address with another start bit
   slave-address 1 or  bbu_ICR_START twsi-putbyte     ( #data-bytes )   
   sr@ sr!    \ clear ITE and IRF status bits         ( #data-bytes )
   \ Bug on line 367 of bbu_TWSI.s - writes SR without first reading it

   1-  0  ?do  0 twsi-getbyte   loop  ( bytes )

   \ Set the stop bit on the final byte
   bbu_ICR_STOP  bbu_ICR_ACKNAK or twsi-getbyte   ( bytes )
;

: twsi-write  ( byte .. #bytes -- )
   slave-address twsi-start           ( byte .. #bytes )

   1-  0  ?do  0 twsi-putbyte  loop   ( byte )
   bbu_ICR_STOP twsi-putbyte          ( )
;

: twsi-b@  ( reg -- byte )  1 1 twsi-get  ;
: twsi-b!  ( byte reg -- )  2 twsi-write  ;

: select-touch-panel  ( -- )
   5 set-address
   h# 40 set-slave
;
: touch-panel-type  ( -- n )
   select-touch-panel
   h# bd twsi-b@
;
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

: select-compass  ( -- )
   4 set-address
   h# 3c set-slave
;

: compass@  ( -- x y z temp id )
   select-compass
   0 0 twsi-b!      \ Config register A
   h# 50 1 twsi-b!  \ Config register B
   0 2 twsi-b!      \ Mode register
   4 twsi-b@  3 twsi-b@  bwjoin     ( x )
   6 twsi-b@  5 twsi-b@  bwjoin     ( x y )
   8 twsi-b@  7 twsi-b@  bwjoin     ( x y z )
   h# b twsi-b@                     ( x y z temp )
   h# a twsi-b@  9 twsi-b@  bwjoin  ( x y z temp id )
;

: select-pmic  ( -- )  1 set-address   h# 78 set-slave  ;

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
   4 set-address
   h# 70 set-slave

   2 twsi-b@ 6 rshift     ( x-low )
   3 twsi-b@ 2 lshift or  ( x )

   4 twsi-b@ 6 rshift     ( x y-low )
   5 twsi-b@ 2 lshift or  ( x y )

   6 twsi-b@ 6 rshift     ( x y z-low )
   7 twsi-b@ 2 lshift or  ( x y z )

   8 twsi-b@  0 twsi-b@   ( x y z temp id )
;

: init-pals  ( -- )
   4 set-address

   h# b0 set-slave  \ Set PS parameters address
   0 1 twsi-write          \ clear interrupt settings

   h# 22 set-slave  \ Device init address
   h# 10 1 twsi-write      \ Init device

   h# 20 set-slave  \ Ambient Light Sensor address
   2 1 twsi-write          \ Enable ALS in most sensitive mode, 16-bit data
;
: als@  ( -- n )
   4 set-address
   h# 22 set-slave  \ Ambient Light Sensor LSB address
   0 1 twsi-get            ( low )
   h# 20 set-slave  \ Ambient Light Sensor MSB address
   0 1 twsi-get  bwjoin   ( n )
;

: proximity@  ( -- byte )
   4 set-address
   h# b0 set-slave  \ Proximity Sensor address
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

: init-twsi  ( -- )
   7 1  do  i init-twsi-channel  loop
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
   1 set-address
   h# d0 set-slave

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
   1 set-address  h# c0 set-slave  \ MAX8649 power management IC

   d# 750 umax  d# 1350 umin   \ Clipped voltage
   d# 750 -  d# 10 /      ( offset-in-mv/10 )
   h# 80 or               ( code )
   2 twsi-b!
;
: core-voltage@  ( -- mv )
   1 set-address  h# c0 set-slave  \ MAX8649 power management IC
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
