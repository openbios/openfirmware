purpose: Support package driver for Two Wire Serial Interface on Marvell Armada 610

support-package: twsi

0 instance value twsi-chip
0 instance value slave-address

: dbr@  ( -- n )  twsi-chip h# 08 + rl@   ;
: cr@   ( -- n )  twsi-chip h# 10 + rl@   ;
: sr@   ( -- n )  twsi-chip h# 18 + rl@   ;
: sar@  ( -- n )  twsi-chip h# 20 + rl@   ;
: lcr@  ( -- n )  twsi-chip h# 28 + rl@   ;
: wcr@  ( -- n )  twsi-chip h# 30 + rl@   ;
: dbr!  ( n -- )  twsi-chip h# 08 + rl!   ;
: cr!   ( n -- )  twsi-chip h# 10 + rl!   ;
: sr!   ( n -- )  twsi-chip h# 18 + rl!   ;
: sar!  ( n -- )  twsi-chip h# 20 + rl!   ;
: lcr!  ( n -- )  twsi-chip h# 28 + rl!   ;
: wcr!  ( -- n )  twsi-chip h# 30 + rl!   ;

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
: twsi-on  ( -- )
   cr-set  bbu_ICR_UR or  cr!    \ Reset the unit
   cr-set cr!                    \ Release the reset
   0 sar!                        \ Set host slave address
   0 cr!                         \ Disable interrupts
   \ The COUNT field of TWSI_WCR establishes a minimum value for the SCL low time.
   \ The minimum Tlow is the clock period * (12 + 2*COUNT)
   wcr@ h# 1f invert and  tlow-ticks d# 12 - 2/  or  wcr!  \ Setup and hold times
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

external

: write-bytes  ( adr len -- )
   dup 0=  if  2drop exit  then       ( adr len )
   slave-address twsi-start           ( adr len )

   1-  0  ?do  dup c@  0 twsi-putbyte  1+  loop   ( adr' )
   c@ bbu_ICR_STOP twsi-putbyte                   ( )
;

: read-bytes  ( adr len -- )
   dup 0=  if  2drop exit  then       ( adr len )
   slave-address 1 or twsi-start      ( adr len )

   1-  0  ?do  0 twsi-getbyte  over c!  1+  loop   ( adr' )
   bbu_ICR_STOP bbu_ICR_ACKNAK or twsi-getbyte swap c!  ( )
;

: set-address  ( slave chip -- )  \ Channel numbers range from 1 to 6
   to twsi-chip
   2* to slave-address
   twsi-on
;

: bytes-out-in  ( register-address .. #reg-bytes #data-bytes -- data-byte ... )
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

: bytes-out  ( byte .. #bytes -- )
   slave-address twsi-start           ( byte .. #bytes )

   1-  0  ?do  0 twsi-putbyte  loop   ( byte )
   bbu_ICR_STOP twsi-putbyte          ( )
;

: reg-b@  ( reg -- byte )  1 1 bytes-out-in  ;
: reg-b!  ( byte reg -- )  2 bytes-out  ;

: set-bus-standard  cr-set  h# 18000 invert and              to cr-set  ;
: set-bus-fast      cr-set  h# 18000 invert and  h# 8000 or  to cr-set  ;

: set-bus-speed  ( hz -- )  \ Useful range is 25K .. 400K - 100K and 400K are typical
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

: open  ( -- okay? )  true  ;
: close  ( -- )  ;

end-support-package

\ LICENSE_BEGIN
\ Copyright (c) 2012 FirmWorks
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
