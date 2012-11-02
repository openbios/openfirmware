\ See license at end of file
purpose: Setup keyboard wakeups and display the state of the wakeup machinery

\ XXX we might need to set GPIOs 71 and 160 (ps2 clocks), and perhaps the dat lines too,
\ for non-sleep-mode control - or maybe for sleep mode control as inputs.
\ We also may need to enable falling edge detects.
: disable-int40  ( -- )
   d# 40 disable-interrupt
   1  h# 29.00cc  io-set   \ Unmask the inter-processor communications interrupt
;

\ How to wakeup from SP:
: setup-key-wakeup  ( -- )
   rotate-gpio# 8 bounds do  h# b0 i af!  loop  \ Wake SoC on game keys
[ifdef] soc-kbd-clk-gpio#
   h# 220 soc-kbd-clk-gpio# af!  \ Wake SoC on KBD CLK falling edge
   h# 221 soc-tpd-clk-gpio# af!  \ Wake SoC on TPD CLK falling edge
[then]
   h# 4  h# 4c +mpmu  io-set  \ Pin edge (GPIO per datasheet) wakes SoC
   ['] disable-int40 d# 40 interrupt-handler!
   d# 40 enable-interrupt  \ SP to PJ4 communications interrupt
   1  h# 29.00cc  io-clr   \ Unmask the inter-processor communications interrupt
;

\ We need to do this in the SP interrupt handler
: clear-wakeup  ( gpio# -- )
   dup af@                 ( gpio# value )
   2dup h# 40 or swap af!  ( gpio# value )
   swap af!
;

: gpio-wakeup?  ( gpio# -- flag )
   h# 019800 over 5 rshift la+ io@ ( gpio# mask )
   swap h# 1f and                  ( mask bit# )
   1 swap lshift  and  0<>         ( flag )
;

\ !!! The problem right now is that I have woken from keyboard, but the interrupt is still asserted
\ So perhaps the interrupt handler didn't fire
: rotate-wakeup? ( -- flag )  d#  15 gpio-wakeup?   ;
: kbd-wakeup?    ( -- flag )  soc-kbd-clk-gpio# gpio-wakeup?   ;
: tpd-wakeup?    ( -- flag )  soc-tpd-clk-gpio# gpio-wakeup?   ;

string-array wakeup-bit-names
   ," WU0 "
   ," WU1 "
   ," WU2 "
   ," WU3 "
   ," WU4 "
   ," WU5 "
   ," WU6 "
   ," WU7 "
   ," TIMER_1_1 "
   ," TIMER_1_2 "
   ," TIMER_1_3 "
   ," MSP_INS "
   ," AUDIO "
   ," WDT1 "
   ," TIMER_2_1 "
   ," TIMER_2_2 "
   ," TIMER_2_3 "
   ," RTC_ALARM "
   ," WDT2 "
   ," ROTARY "
   ," TRACKBALL "
   ," KEYPRESS "
   ," SDH3_CARD "
   ," SDH1_CARD "
   ," FULL_IDLE "
   ," ASYNC_INT "
   ," SSP1_SRDY "
   ," CAWAKE "
   ," resv28 "
   ," SSP3_SRDY "
   ," ALL_WU "
   ," resv31 "
end-string-array

string-array wakeup-mask-names
   ," WU0 "
   ," WU1 "
   ," WU2 "
   ," WU3 "
   ," WU4 "
   ," WU5 "
   ," WU6 "
   ," WU7 "
   ," TIMER_1_1 "
   ," TIMER_1_2 "
   ," TIMER_1_3 "
   ," "
   ," "
   ," "
   ," TIMER_2_1 "
   ," TIMER_2_2 "
   ," TIMER_2_3 "
   ," RTC_ALARM "
   ," WDT2 "
   ," ROTARY "
   ," TRACKBALL "
   ," KEYPRESS "
   ," SDH3_CARD "
   ," SDH1_CARD "
   ," FULL_IDLE "
   ," ASYNC_INT "
   ," WDT1 "
   ," SSP3_SRDY "
   ," SSP1_SRDY "
   ," CAWAKE "
   ," MSP_INS "
   ," resv31 "
end-string-array

: .active-wakeups  ( -- )
   ." Wakeups: "
   h# 1048 mpmu@    ( n )
   d# 31 0  do      ( n )
      dup 1 and  if  i wakeup-bit-names count type  then  ( n )
      u2/           ( n' )
   loop             ( n )
   drop cr          ( )
;
: .wakeup-mask  ( -- )
   ." Enabled wakeups: "
   h# 4c mpmu@  h# 104c or   ( n )
   d# 31 0  do               ( n )
      dup 1 and  if  i wakeup-mask-names count type  then  ( n )
      u2/                    ( n' )
   loop                      ( n )
   drop cr                   ( )
;
: .edges  ( -- )
   ." Wakeup edges: "           ( )
   d# 6 0  do                   ( )
      h# 19800 i la+ io@        ( n )
      d# 32  0  do              ( n )
         dup 1 and  if          ( n )
	    j d# 32 *  i +  .d  ( n )
         then                   ( n )
         u2/                    ( n' )
      loop                      ( n )
      drop                      ( )
   loop                         ( )
   cr                           ( )
;
: .edge-enables  ( -- )
   ." Enabled edges: "
   d# 160  0  do
      i af@ dup  h# 70 and  h# 40 <>   if  ( n )
         dup h# 10 and  if  ." R"  then    ( n )
         dup h# 20 and  if  ." F"  then    ( n )
         dup h# 40 and  if  ." C"  then    ( n )
	 i .d                              ( n )
      then                                 ( n )
      drop                                 ( )
   loop
;
: .wakeup  ( -- )   .active-wakeups  .wakeup-mask  .edges .edge-enables  ;

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
