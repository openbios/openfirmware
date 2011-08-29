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
: dbr!  ( n -- )  twsi-chip h# 08 + io!   ;
: cr!   ( n -- )  twsi-chip h# 10 + io!   ;
: sr!   ( n -- )  twsi-chip h# 18 + io!   ;
: sar!  ( n -- )  twsi-chip h# 20 + io!   ;
: lcr!  ( n -- )  twsi-chip h# 28 + io!   ;

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

bbu_ICR_IUE bbu_ICR_SCLE or constant iue+scle
: init-twsi-channel  ( channel# -- )
   set-twsi-channel
   7 clock-reg io!  3 clock-reg io!  \ Set then clear reset bit
   1 us
   iue+scle  bbu_ICR_UR or  cr!  \ Reset the unit
   iue+scle cr!                  \ Release the reset
   0 sar!                        \ Set host slave address
   0 cr!                         \ Disable interrupts
;
: init-twsi  ( -- )
   7 1  do  i init-twsi-channel  loop
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
   ?dup  if              ( reg-adr .. #regs slave-address  r: #data-bytes )
      slave-address      ( reg-adr .. #regs slave-address  r: #data-bytes )
      twsi-start         ( reg-adr .. #regs  r: #data-bytes )

      \ Send register addresses
      0  ?do  0 twsi-putbyte  loop       ( r: #data-bytes )

      \ If no result data requested, quit now
      r@ 0=  if                          ( r: #data-bytes )
         r> drop                         ( )
         iue+scle bbu_ICR_STOP or  cr!   ( )
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
   0=  if  exit  then                 ( adr len )
   slave-address twsi-start           ( adr len )

   1-  0  ?do  dup c@  0 twsi-putbyte  1+  loop   ( adr' )
   c@ bbu_ICR_STOP twsi-putbyte                   ( )
;

: twsi-b@  ( reg -- byte )  1 1 twsi-get  ;
: twsi-b!  ( byte reg -- )  2 twsi-out  ;

[ifdef] begin-package
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

d# 12,600,000 constant numerator
: set-bus-speed  ( hz -- )  \ Useful range is currently 25,000 .. 100,000
   child-address set-twsi-target
   numerator swap /  h# 1ff min  h# 7e max  lcr!
;
: decode-unit  ( adr len -- low high )  parse-2int  ;
: encode-unit  ( low high -- adr len )  >r <# u#s drop [char] , hold r> u#s u#>  ;
end-package
[then]
