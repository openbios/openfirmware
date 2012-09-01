\ See license at end of file
purpose: Display the state of the MMP2 ICU interrupt controller

: .masked  ( irq# -- )
   dup /l* h# 10c + icu@  ( irq# masked )
   1 and  if              ( irq# )
      ." IRQ" .d ." is masked off" cr
   else                   ( irq# )
      drop                ( )
   then                   ( )
;
: .selected  ( irq# -- )
   dup /l* h# 100 + icu@  ( irq# n )
   dup h# 40 and  if      ( irq# n )
      ." IRQ" swap .d     ( n )
      ." selected INT" h# 3f and .d  cr  ( )
   else                   ( irq# n )
      2drop               ( )
   then                   ( )
;
: (.pending)  ( d -- )
   ." pending INTs: "                      ( d )
   d# 64 0  do                             ( d )
      over 1 and  if  i .d  then           ( d )
      d2/                                  ( d' )
   loop                                    ( d )
   2drop                                   ( )
;
: .pending  ( irq# -- )
   dup 2* /l* h# 130 +  dup icu@  swap la1+ icu@   ( irq# d )
   2dup d0=  if                                    ( irq# d )
      3drop                                        ( )
   else                                            ( irq# d )
      ." IRQ " rot .d   (.pending)  cr             ( )
   then                                            ( )
;

: bit?  ( n bit# -- n flag )  1 swap lshift over and  0<>  ;
: .ifbit  ( n bit# msg$ -- n )
   2>r  bit?  if       ( n r: msg$ )
      2r> type  space  ( n )
   else                ( n r: msg$ )
      2r> 2drop        ( n )
   then                ( n )
;
: .enabled-ints  ( -- )
   d# 64 0  do                           ( )
      i /l* icu@  dup h# 70 and  if      ( n )
         ." INT" i .d ." -> IRQ"         ( n )
         4 " 0" .ifbit                   ( n )
         5 " 1" .ifbit                   ( n )
         6 " 2" .ifbit                   ( n )
         ."  Pri " h# f and .d  cr       ( )
      else                               ( n )
         drop                            ( )
      then                               ( )
   loop                                  ( )
;
: .int4  ( -- )
   ." INT4 - mask "  h# 168 icu@ .x
   ." status " h# 150 icu@ dup .x
   0   " USB " .ifbit
   1   " PMIC" .ifbit
   drop  cr
;
: .int5  ( -- )
   ." INT5 - mask "  h# 16c icu@ .x
   ." status " h# 154 icu@  dup .x
   0   " RTC " .ifbit
   1   " RTC_Alarm" .ifbit
   drop cr
;
: .int9  ( -- )
   ." INT9 - mask "  h# 17c icu@ .x
   ." status " h# 180 icu@  dup .x
   0   " Keypad " .ifbit
   1   " Rotary " .ifbit
   2   " Trackball" .ifbit
   drop cr
;
: .int17  ( -- )
   ." INT17 - mask " h# 170 icu@ .x
   ." status " h# 158 icu@  dup .x  ( n )
   7 2 do              ( n )
      dup 1 and  if    ( n )
	." TWSI" i .d  ( n )
      then             ( n )
      u2/              ( n' )
   loop                ( n )
   drop  cr            ( )
;
: .int35  ( -- )
   ." INT35 - mask "  h# 174 icu@ .x
   ." status " h# 15c icu@  dup  .x
   d#  0  " PJ_PerfMon" .ifbit
   d#  1 " L2_PA_ECC"   .ifbit
   d#  2 " L2_ECC"      .ifbit
   d#  3 " L2_UECC"     .ifbit
   d#  4 " DDR"         .ifbit
   d#  5 " Fabric0"     .ifbit
   d#  6 " Fabric1"     .ifbit
   d#  7 " Fabric2"     .ifbit
   d#  9 " Thermal"     .ifbit
   d# 10 " MainPMU"     .ifbit
   d# 11 " WDT2"        .ifbit
   d# 12 " CoreSight"   .ifbit
   d# 13 " PJ_Commtx"   .ifbit
   d# 14 " PJ_Commrx"   .ifbit
   drop
   cr
;
: .int51  ( -- )
   ." INT51 - mask " h# 178 icu@ .x
   ." status " h# 160 icu@  dup  .x
   0 " HSI_CAWAKE1 "  .ifbit
   1 " MIPI_HSI1"     .ifbit
   drop cr
;
: .int55  ( -- )
   ." INT55 - mask " h# 184 icu@ .x
   ." status " h# 188 icu@  dup  .x
   0 " HSI_CAWAKE0 "  .ifbit
   1 " MIPI_HSI0"     .ifbit
   drop cr
;

: .fiq  ( -- )
   h# 304 icu@  if  ." FIQ is masked off"  cr  then
   h# 300 icu@  dup  h# 40 and  if  ." FIQ selected INT: " h# 3f and .d cr  else  drop  then
   h# 310 icu@  h# 314 icu@  2dup d0=  if  ( d )
      2drop                                ( )
   else                                    ( d )
      ." FIQ " (.pending) cr               ( )
   then                                    ( )
;
  
: .icu  ( -- )
   .enabled-ints
   3 0 do  i .masked  i .selected  i .pending  loop
   \ XXX should handle DMA interrupts too
   .fiq
   .int4  .int5  .int9  .int17  .int35  .int51  .int55
;

: .irqstat  ( -- )  h# 148 h# 130 do  i icu@ .  4 +loop   ;

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
