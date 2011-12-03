\ See license at end of file
purpose: Driver for Realtek ALC5624 audio CODEC chip

: codec-bias-off  ( -- )
   h# 8080 h# 02 codec-set
   h# 8080 h# 04 codec-set
   h# 0000 h# 3a codec!
   h# 0000 h# 3c codec!
   h# 0000 h# 3e codec!
;
: linux-codec-on
   h# 0000 h# 26 codec!  \ Don't power down any groups
   h# 8000 h# 5e codec!  \ Disable fast vref
   h# 0c00 h# 3e codec!  \ enable HP out volume power
   h# 0002 h# 3a codec!  \ enable Main bias
   h# 2000 h# 3c codec!  \ enable Vref
   h# 6808 h# 0c codec!  \ Stereo DAC Volume
   h# 3f3f h# 14 codec!  \ ADC Record Mixer Control
   h# 4b40 h# 1c codec!  \ Output Mixer Control
   h# 0500 h# 22 codec!  \ Microphone Control
   h# 04e8 h# 40 codec!  \ General Purpose Control
;
: codec-on  ( -- )
   h# 0000 h# 26 codec!  \ Don't power down any groups
   h# 8002 h# 34 codec!  \ Slave mode, 16 bits, left justified
   b# 1000.1000.0011.1111 h# 3a codec!  \ All on except MONO depop, 0-cross
   b# 1010.0011.1111.0011 h# 3c codec!  \ All on except ClassAB, PLL, speaker mixer, MONO mixer
   b# 0011.1111.1100.1111 h# 3e codec!  \ All on except MONO_OUT and PHONE in
   h# 0140 h# 40 codec!  \ MCLK is SYSCLK, HPamp Vmid 1.25, ClassDamp Vmid 1.5
;
: codec-off  ( -- )
   h# ef00 h# 26 codec!  \ Power down everything
;
\ Mic bias 2 is for external mic
: mic-gain  ( bits11:8 -- )  h# f00 h# 22 codec-field  ;
: mic+0db   ( -- )  0 mic-gain  ;  \ Needed
: mic+20db  ( -- )  h# 500 mic-gain  ;  \ Needed
: mic+30db   ( -- )  h# a00 mic-gain  ;
: mic+40db   ( -- )  h# f00 mic-gain  ;

: mic-bias-off  ( -- )  h# 000c h# 3a codec-clr  ;
: mic-bias-on   ( -- )  h# 000c h# 3a codec-set  ;

: mic1-high-bias  ( -- )  h# 20 h# 22 codec-clr  mic-bias-on  ;  \ 0.90*AVDD, e.g. 3V with AVDD=3.3V
: mic1-low-bias   ( -- )  h# 20 h# 22 codec-set  mic-bias-on  ;  \ 0.75*AVDD, e.g. 2.5V with AVDD=3.3V
: mic2-high-bias  ( -- )  h# 10 h# 22 codec-clr  mic-bias-on  ;  \ 0.90*AVDD, e.g. 3V with AVDD=3.3V
: mic2-low-bias   ( -- )  h# 21 h# 22 codec-set  mic-bias-on  ;  \ 0.75*AVDD, e.g. 2.5V with AVDD=3.3V

\ The mic bias short circuit detection threshold can be set with reg 0x22 bits 1:0 -
\ 00:600uA  01:1200uA  1x:1800uA
\ 600uA is probably good for OLPC, since the 5.6K bias resistor limits the SC current to less than that.

\ Sets both speakers simultaneously
: speakers-source  ( value -- )  h# d800 h# 1c codec-field  ;

: speakers-off  ( -- )  0  speakers-source  ;
: hp-mixer>speakers  ( -- )  h# 4800  speakers-source  ;
: speaker-mixer>speakers  ( -- )  h# 9000  speakers-source  ;
: mono>speakers  ( -- )  h# d800  speakers-source  ;

: class-ab-speakers  ( -- )  h# 2000 h# 1c codec-clr  ;
: class-d-speakers  ( -- )  h# 2000 h# 1c codec-set  ;

: headphones-off  ( -- )  h# 300 h# 1c codec-clr  ;
: headphones-on   ( -- )  h# 300 h# 1c codec-set  ;

0 [if]  \ OLPC does not connect the MONO output
: mono-source  ( value -- )  h# c0 h# 1c codec-field  ;
: mono-off  ( -- )  0 mono-source  ;
: hp-mixer>mono  ( -- )  h# 40 mono-source  ;
: speaker-mixer>mono  ( -- )  h# 80 mono-source  ;
: mono-mixer>mono  ( -- )  h# c0 mono-source  ;
[then]

: headphones-inserted?  ( -- flag )  h# 54 codec@ 2 and 0<>  ;

\ The range is from -34.5 db to +12 dB
: gain>lr  ( db -- true | regval false )
   2* 3 /              ( steps )  \ Converts -34.5 .. 12 db to -23 .. 8 steps
   dup d# -23 <  if    ( steps )
      drop true
   else                ( steps )
      8 swap -         ( -steps )
      0 max            ( clipped-steps )
      dup 8 lshift or  ( regval )
      false
   then
;
\ The range is from -46.5 db to 0 dB
: >output-volume  ( db -- regval mask )
   d# 12 +     \ Bias to the range used by gain>lr
   gain>lr  if  h# 8080  then   h# 9f9f       
;
: set-speaker-volume    ( n -- )  >output-volume  2 codec-field  ;
: set-headphone-volume  ( n -- )  >output-volume  4 codec-field  ;
\ : set-mono-volume       ( n -- )  >output-volume  6 codec-field  ;
: set-volume  ( n -- )
   dup set-speaker-volume  set-headphone-volume
;
d#  0 constant default-adc-gain            \  0 dB - range is -16.5 to +30
d#  0 constant default-dac-gain            \  0 dB - range is -34.5 to +12
d# 44 constant default-mic-gain            \ 44 dB - range is -34.5 to 
d#  0 constant default-speaker-volume      \  0 dB - range is -46.5 to 0
d#  0 constant default-headphone-volume    \  0 dB - range is -46.5 to 0

: select-headphones  ( -- )  h# 300 h# 1c codec!  ;
: select-speakers-ab  ( -- )  h# 4800 h# 1c codec!  ;  \ ClassAB, headphone mixer
: select-speakers  ( -- )  h# 6800 h# 1c codec!  ;  \ ClassD, headphone mixer

: set-line-in-gain  ( n -- )
   gain>lr  if  h# e000  then  h# ff1f  h# 0a codec-field
;
: set-dac-gain  ( n -- )
   gain>lr  if  h# e000  then  h# ff1f  h# 0c codec-field
;
false value external-mic?
: mic-routing  ( -- n )
   \ Mute selected MIC inputs to the ADC as follows:
   \ For external, we send MIC1 to left and MIC2 to right
   \ For internal, we send MIC1 to both left and right
   external-mic?  if   h# 2040  else  h# 2020  then
;
: set-mic-boost  ( db -- db' )
   dup d# 26 >  if  mic+40db d# 40 -  exit  then
   dup d# 16 >  if  mic+30db d# 30 -  exit  then
   dup d# 06 >  if  mic+20db d# 20 -  exit  then
   mic+0db
;
: set-mic-gain  ( db -- )
   set-mic-boost              ( db' )   
   gain>lr  if                ( )  \ Mute
      \ Turn everything off
      mic-bias-off            ( )
      0  h# 6060  h# e0e0     ( gain adc-mute mic-output-mute )
   else                       ( gain )
      mic-bias-on             ( gain )
      \ Mic routing to ADC depends on internal or external mic
      mic-routing             ( gain adc-mute )
      \ To avoid feedback, we do not feedthrough the mic
      h# e0e0                 ( gain adc-mute mic-output-mute )
   then                       ( gain adc-mute mic-output-mute )
   h# e0e0 h# 10 codec-field  ( gain adc-mute )
   h# 6060 h# 14 codec-field  ( gain )
   h# 1f1f h# 0e codec-field
;
: set-adc-gain  ( db -- )  \ Range is -16.5 dB to +30 dB
   d# 18 -       ( db' )
   gain>lr  if  0  then   ( gain )
   h# f9f h# 12 codec-field
   h# 60 h# 12 codec-set  \ Enable ADC zero-cross detectors
;
: set-default-gains  ( -- )
   headphones-inserted?  if  select-headphones  else  select-speakers  then
   default-speaker-volume set-speaker-volume
   default-headphone-volume set-headphone-volume
   default-dac-gain set-dac-gain
   default-mic-gain set-mic-gain
   default-adc-gain set-adc-gain
;

: set-codec-sample-rate  ( rate -- )
   case
      d#  8000 of  h# 2222 h# 5272  endof
      d# 16000 of  h# 2020 h# 2272  endof
      d# 32000 of  h# 2121 h# 2172  endof
      d# 48000 of  h# 0000 h# 3072  endof
      ( default )  true abort" Unsupported audio sample rate"
   endcase   ( reg62val2 reg60val )
   h# 60 codec!  h# 62 codec!
;

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
