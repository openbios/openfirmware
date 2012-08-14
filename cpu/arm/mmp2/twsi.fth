purpose: Driver for Two Wire Serial Interface on Marvell Armada 610

\ 0 0  " d4011000"  " /" begin-package

[ifdef] unaligned-mmap
h# 050000 unaligned-mmap  constant clock-unit-pa
[then]

0 value twsi-chip
0 value clock-reg
0 value slave-address

: dbr@  ( -- n )  twsi-chip h# 08 + io@   ;
: cr@   ( -- n )  twsi-chip h# 10 + io@   ;
: sr@   ( -- n )  twsi-chip h# 18 + io@   ;
: sar@  ( -- n )  twsi-chip h# 20 + io@   ;
: lcr@  ( -- n )  twsi-chip h# 28 + io@   ;
: wcr@  ( -- n )  twsi-chip h# 30 + io@   ;
: dbr!  ( n -- )  twsi-chip h# 08 + io!   ;
: cr!   ( n -- )  twsi-chip h# 10 + io!   ;
: sr!   ( n -- )  twsi-chip h# 18 + io!   ;
: sar!  ( n -- )  twsi-chip h# 20 + io!   ;
: lcr!  ( n -- )  twsi-chip h# 28 + io!   ;
: wcr!  ( -- n )  twsi-chip h# 30 + io!   ;

create channel-bases
h# 011000 ,  h# 031000 ,  h# 032000 ,  h# 033000 ,  h# 033800 ,  h# 034000 ,

[ifdef] unaligned-mmap
6 0  do
   channel-bases i la+ io@  unaligned-mmap  channel-bases i la+ io!
loop
[then]

create clock-offsets
h# 04 c,  h# 08 c,  h# 0c c,  h# 10 c,  h# 7c c,  h# 80 c,

: set-twsi-channel  ( channel -- )
   1-
   channel-bases over na+ @  to twsi-chip  ( channel )
   clock-offsets + c@  clock-unit-pa +  to clock-reg  ( )
;
: set-twsi-target  ( slave channel -- )  \ Channel numbers range from 1 to 6
   set-twsi-channel
   to slave-address
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

d#   26 constant ftwsi-mhz  \ 
d# 1400 constant tlow-nsec  \ The I2C spec calls for Tlow >= 1300 ns
ftwsi-mhz tlow-nsec d# 1000 */ constant tlow-ticks

bbu_ICR_IUE bbu_ICR_SCLE or value cr-set   \ bits to maintain as set
: init-twsi-channel  ( channel# -- )
   set-twsi-channel
   7 clock-reg io!  3 clock-reg io!  \ Set then clear reset bit
   1 us
   cr-set  bbu_ICR_UR or  cr!    \ Reset the unit
   cr-set cr!                    \ Release the reset
   0 sar!                        \ Set host slave address
   0 cr!                         \ Disable interrupts
   \ The COUNT field of TWSI_WCR establishes a minimum value for the SCL low time.
   \ The minimum Tlow is the clock period * (12 + 2*COUNT)
   wcr@ h# 1f invert and  tlow-ticks d# 12 - 2/  or  wcr!  \ Setup and hold times
;
: init-twsi  ( -- )
   7 1  do  i init-twsi-channel  loop
;

: twsi-run  ( extra-flags -- )
   cr-set or  bbu_ICR_TB or  cr!      ( )

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
      cr-set  bbu_ICR_MA or  cr!      ( )
      true abort" TWSI bus error"
   then                               ( )
;

: twsi-get  ( register-address .. #reg-bytes #data-bytes -- data-byte ... )
   >r                    ( reg-adr .. #regs  r: #data-bytes )
   ?dup  if              ( reg-adr .. #regs slave-address  r: #data-bytes )
      slave-address      ( reg-adr .. #regs slave-address  r: #data-bytes )
      twsi-start         ( reg-adr .. #regs  r: #data-bytes )

      \ Send register addresses
      0  ?do  0 twsi-putbyte  loop       ( r: #data-bytes )

      \ If no result data requested, quit now
      r@ 0=  if                          ( r: #data-bytes )
         r> drop                         ( )
         cr-set  bbu_ICR_STOP or  cr!    ( )
         exit
      then                               ( r: #data-bytes )
   then                                  ( r: #data-bytes )

   r>  ?dup  if                          ( #data-bytes )
      \ Send the read address with a (or another) start bit
      slave-address 1 or  bbu_ICR_START twsi-putbyte     ( #data-bytes )   
      sr@ sr!    \ clear ITE and IRF status bits         ( #data-bytes )
      \ Bug on line 367 of bbu_TWSI.s - writes SR without first reading it

      1-  0  ?do  0 twsi-getbyte   loop  ( bytes )

      \ Set the stop bit on the final byte
      bbu_ICR_STOP  bbu_ICR_ACKNAK or twsi-getbyte   ( bytes )
   then
;

: twsi-out  ( byte .. #bytes -- )
   slave-address twsi-start           ( byte .. #bytes )

   1-  0  ?do  0 twsi-putbyte  loop   ( byte )
   bbu_ICR_STOP twsi-putbyte          ( )
;
: twsi-write  ( adr len -- )
   dup 0=  if  2drop exit  then       ( adr len )
   slave-address twsi-start           ( adr len )

   1-  0  ?do  dup c@  0 twsi-putbyte  1+  loop   ( adr' )
   c@ bbu_ICR_STOP twsi-putbyte                   ( )
;
: twsi-read  ( adr len -- )
   dup 0=  if  2drop exit  then       ( adr len )
   slave-address 1 or twsi-start      ( adr len )

   1-  0  ?do  0 twsi-getbyte  over c!  1+  loop   ( adr' )
   bbu_ICR_STOP bbu_ICR_ACKNAK or twsi-getbyte swap c!  ( )
;

: twsi-b@  ( reg -- byte )  1 1 twsi-get  ;
: twsi-b!  ( byte reg -- )  2 twsi-out  ;

[ifdef] begin-package
: make-twsi-node  ( baseadr clock# irq# muxed-irq? fast? unit# -- )
   root-device
   new-device
      " linux,unit#" integer-property
      " i2c" name
      " mrvl,mmp-twsi" +compatible                    ( baseadr clock# irq# muxed-irq? fast? )
      if  0 0  " mrvl,i2c-fast-mode" property  then   ( baseadr clock# irq# muxed-irq? )
      if
          " /interrupt-controller/interrupt-controller@158" encode-phandle " interrupt-parent" property
      then                                            ( baseadr clock# irq# )
      " interrupts" integer-property                  ( baseadr clock# )
      " /apbc" encode-phandle rot encode-int encode+ " clocks" property

      h# 1000 reg                                     ( )
      1 " #address-cells" integer-property
      1 " #size-cells" integer-property
      " : open true ; : close ;" evaluate
      " : encode-unit  ( phys.. -- str )  push-hex (u.) pop-base  ;" evaluate
      " : decode-unit  ( str -- phys.. )  push-hex  $number  if  0  then  pop-base  ;" evaluate
   finish-device
   device-end
;      

\     baseadr   clk irq mux? fast? unit#
  h# d4011000     1   7 false true     2 make-twsi-node  \ TWSI1
\ h# d4031000     2   0 true  true     N make-twsi-node  \ TWSI2
\ h# d4032000     3   1 true  true     N make-twsi-node  \ TWSI3
  h# d4033000     4   2 true  true     0 make-twsi-node  \ TWSI4
\ h# d4038000 d# 30   3 true  true     N make-twsi-node  \ TWSI5
  h# d4034000 d# 31   4 true  true     1 make-twsi-node  \ TWSI6


0 0  " 34" " /i2c@d4011000" begin-package  \ TWSI1
   " audio-codec" name
   " realtek,alc5631" +compatible
   " realtek,rt5631" +compatible
   my-address my-space 1 reg
end-package

[ifdef] soon-olpc-cl2  \ this breaks cl4-a1 boards, which ofw calls cl2.
0 0  " 30" " /i2c@d4033000" begin-package  \ TWSI4
   " touchscreen" name
   " raydium_ts" +compatible
   my-address my-space 1 reg
end-package
[else]
0 0  " 50" " /i2c@d4033000" begin-package  \ TWSI4
   " touchscreen" name
   " zforce" +compatible
   my-address my-space 1 reg
   touch-rst-gpio# 1  " reset-gpio" gpio-property
   touch-tck-gpio# 1  " test-gpio"  gpio-property
   touch-hd-gpio#  1  " hd-gpio"    gpio-property
   touch-int-gpio# 1  " dr-gpio"    gpio-property
end-package
[then]

0 0  " 19" " /i2c@d4034000" begin-package  \ TWSI6
   " accelerometer" name
   " lis3lv02d" +compatible
   my-address my-space 1 reg
end-package

0 0  " "  " /" begin-package
" twsi" name

0 0 instance 2value child-address
: open  ( -- okay? )  true  ;
: close  ( -- )  ;
: set-address  ( target channel -- )  to child-address  ;
2 " #address-cells" integer-property
0 " #size-cells" integer-property
: get  ( #bytes -- bytes ... )
   child-address set-twsi-target
   0 swap twsi-get
;
: smbus-out-in  ( out ... #outs #ins -- in ... )
   child-address set-twsi-target
   twsi-get
;
: smbus-b@  ( -- )
   child-address set-twsi-target
   twsi-b@
;
: smbus-b!  ( -- )
   child-address set-twsi-target
   twsi-b!
;
: smbus-out  ( byte .. #bytes -- )
   child-address set-twsi-target
   twsi-out
;


: set-bus-standard  cr-set  h# 18000 invert and              to cr-set  ;
: set-bus-fast      cr-set  h# 18000 invert and  h# 8000 or  to cr-set  ;

: set-bus-speed  ( hz -- )  \ Useful range is 25K .. 400K - 100K and 400K are typical
   child-address set-twsi-target                         ( hz )
   ftwsi-mhz d# 1,000,000  2 pick */                     ( hz ticks )
   swap  d# 100,000 <=  if                               ( ticks )
      \ In slow mode, Thi = Tclk * (8+slv), Tlow = Tclk * (1+slv)
      9 -  2/ 1+                                         ( slv )
      lcr@ h# 1ff invert and  or  lcr!                   ( )
      set-bus-standard                                   ( )
   else                                                  ( ticks )
      \ (The information below is poorly documented and was determined empirically)
      \ In fast mode, Thi = Tclk * (10+flv), Tlo = Tclk * max(1+flv, tlow_ticks))
      dup d# 11 - 2/ 1+  tlow-ticks  max                 ( ticks ticks-low )
      -  d# 10 -                                         ( flv )
      9 lshift  lcr@ h# 3.fe00 invert and  or  lcr!      ( )
      set-bus-fast                                       ( )
   then                                                  ( )
;
: decode-unit  ( adr len -- low high )  parse-2int  ;
: encode-unit  ( low high -- adr len )  >r <# u#s drop [char] , hold r> u#s u#>  ;
end-package
[then]
