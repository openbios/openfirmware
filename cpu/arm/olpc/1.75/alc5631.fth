\ See license at end of file
purpose: Driver for Realtek ALC5631Q audio CODEC chip

: adc-on  ( -- )  h# 0c00 h# 3a codec-set  ;
: adc-off ( -- )  h# 0c00 h# 3a codec-clr  ;
: dac-on  ( -- )  h# 0300 h# 3a codec-set  ;
: dac-off ( -- )  h# 0300 h# 3a codec-clr  ;
: adc+dac-on  ( -- )  h# 0f00 h# 3a codec-set  ;

: set-routing  ( -- )
   h# c0c0 h# 02 codec-set  \ SPKMIXLR -> SPKVOLLR, muted
   h# c0c0 h# 04 codec-set  \ OUTMIXLR -> HPOVOLLR, muted
\  h# a080 h# 06 codec!     \ AXO1/AXO2 channel volume select OUTMIXER,0DB by default
   h# b0b0 h# 14 codec!     \ Record Mixer source from Mic1/Mic2 by default
\  h# 5500 h# 22 codec!     \ Mic1/Mic2 boost 20DB by default (done in set-default-gains)
   h# dfc0 h# 1a codec!     \ DACL -> OUTMIXL - c0 is "don't change it" per datasheet 0.91
   h# dfc0 h# 1c codec!     \ DACR -> OUTMIXR - c0 is "don't change it" per datasheet 0.91
   h# d8d8 h# 28 codec!     \ DACLR -> SPKMIXLR - 808 is "don't change it" per datasheet 0.91
   h# 6c00 h# 2a codec!     \ unmute SPKVOLL -> SPOLMIX, SPKVOLR -> SPORMIX, mute L>R, R>L, and L/R>MONO
   h# 0f18 h# 4a codec!     \ (undocumented bit 11) enables HP zero-cross detection

   h# 0000 h# 2c codec!     \ SPOxMIX -> SPKRMUX, HPOVOL -> HPMUX
;

: codec-on  ( -- )
   0 0 codec!  \ Reset

   b# 1010.0000.0000.0000 h# 3c codec!  \ All on except AX and MONO
   d# 80 ms
   b# 1110.0000.0000.0000 h# 3c codec!  \ Fast VREF control

   set-routing

   h# 8001 h# 34 codec!  \ Slave mode, 16 bits, left justified, exchange L and R on playback

   \ The speaker gain ratio must be <= the ratio of SPKVDD to AVDD.
   \ In our system, SPKVDD is 5V and AVDD is 3.3V, so we need a gain ratio <= 1.51 .
   \ The value 3 gives a ratio of 1.44, and value 4 gives a ratio of 1.56 .  We use 3.
   h# 3e00 h# 40 codec!  \ Speaker Amp Ratio GAIN is 1.44x, no HPFs

   h# 0000 h# 42 codec!  \ Use MCLK, not PLL
\  b# 1110.1100.1001.0000 h# 52 codec!  \ Protection on
\  h# 4000 h# 56 codec!  \ HP depop by register control

   h# 1010 h# 38 codec!  \ Divisors; the values in this register don't seem to make much
   \ difference unless you set the divisors to very high values.
;
: elided  ( -- )
   \ The ADC and DAC will be turned on as needed by adc-on and dac-on, after
   \ the BCLK clock from the SoC is on.  If you turn on the ADC when BCLK is
   \ not clocking, the ADC often doesn't output any data.
   b# 1001.0000.1110.0000 h# 3a codec!  \ All on except ADC and DAC
   b# 1111.1100.0011.1100 h# 3b codec!  \ All on except PLL
   b# 1111.1100.0000.0000 h# 3e codec!  \ AXI and MONO IN off
;
: mic-bias-off  ( -- )  h# 000c h# 3b codec-clr  ;
: mic-bias-on   ( -- )  h# 000c h# 3b codec-set  ;

: mic1-high-bias  ( -- )  h# 80 h# 22 codec-clr  mic-bias-on  ;  \ 0.90*AVDD, e.g. 3V with AVDD=3.3V
: mic1-low-bias   ( -- )  h# 80 h# 22 codec-set  mic-bias-on  ;  \ 0.75*AVDD, e.g. 2.5V with AVDD=3.3V
: mic2-high-bias  ( -- )  h# 08 h# 22 codec-clr  mic-bias-on  ;  \ 0.90*AVDD, e.g. 3V with AVDD=3.3V
: mic2-low-bias   ( -- )  h# 08 h# 22 codec-set  mic-bias-on  ;  \ 0.75*AVDD, e.g. 2.5V with AVDD=3.3V

: depop!  ( value -- )  h# 54 codec!  ;
: pwr3a!  ( value -- )  h# 3a codec!  ;
: pwr3b!  ( value -- )  h# 3b codec!  ;
: pwr3c!  ( value -- )  h# 3c codec!  ;
: pwr3e!  ( value -- )  h# 3e codec!  ;
: depop(  ( current -- )
   h# 0000 h# 5c codec!  \ Disable ZCD
   h# 0710 h# 4a codec!  \ Bit 11=0 disables HP zero-cross detection.  71 is reserved bits.
   d# 10 ms
   ( current ) h# 56 codec-i!  \ Index 56 - depop current control
;
: )depop  ( -- )
   h# 04c0 h# 5c codec!  \ Power on ZCD, enable ZCD for SPOL/R
   h# 0f10 h# 4a codec!  \ Bit 11 enables HP zero-cross detection.  71 is reserved bits
;

0 value headphones-on?
0 value speakers-on?

: mute-speakers  ( -- )  h# 8080 2 codec-set  ;
: unmute-speakers  ( -- )  h# 8080 2 codec-clr  ;

\ The range is from -46.5 db to +12 dB
: gain>lr-12  ( db -- regval on? )
   d# 12 min           ( db' )
   2* 3 /              ( steps )  \ Converts -46.5 .. 12 db to -31 .. 8 steps
   dup d# -31 <  if    ( steps )
      drop h# 2727     ( regval )
      false            ( regval on? )
   else                ( steps )
      8 swap -         ( -steps )
      0 max            ( clipped-steps )
      dup 8 lshift or  ( regval )
      true             ( regval on? )
   then
;
: set-speaker-volume    ( n -- )
   gain>lr-12  to speakers-on?  h# bfbf   2 codec-field
;

: mute-headphones  ( -- )  h# 8080 4 codec-set  ;
: unmute-headphones  ( -- )  h# 8080 4 codec-clr  ;

\ The range is from -46.5 db to 0 dB
: gain>lr  ( db -- regval on? )
   0 min               ( db' )
   2* 3 /              ( steps )  \ Converts -46.5 .. 12 db to -31 .. 8 steps
   dup d# -31 <  if    ( steps )
      drop h# 1f1f     ( regval )
      false            ( regval on? )
   else                ( steps )
      0 swap -         ( -steps )
      0 max            ( clipped-steps )
      dup 8 lshift or  ( regval )
      true             ( regval on? )
   then
;
: set-headphone-volume  ( n -- )
   gain>lr  to headphones-on?  h# 9f9f   4 codec-field
;

: codec-off  ( -- )
   mute-speakers
   mute-headphones
   0 h# 3a codec!  \ All off
   0 h# 3b codec!  \ All off
   0 h# 3c codec!  \ All off
   0 h# 3e codec!  \ All off
;

: hp-powerup-depop  ( -- )
   \ powerup depop
   h# 303e depop(        \ App note says 303f, engineer says to use 303e
      h# e01c pwr3c!     \ 1c powers on charge pump, HP Amp L/R
      h# 8080 depop!     \ Power on HP Soft Generator, (datasheet says 80 bit is "reserved-0", engineer says datasheet is wrong)
      d# 100 ms
      h# e01e pwr3c!     \ Now put HP output in normal, not depop, mode
   )depop

   \ unmute depop 
   h# 302f depop(        \ This is the only case where 10 ms delay is actually needed
      h# c003 depop!     \ Power on HP Soft Generator, HP Softgen Trigger, ena HPOL/R depop
      unmute-headphones
      d# 160 ms
   )depop
;
: hp-powerdown-depop  ( -- )
   \ mute depop 
   h# 302f depop(
      h# c003 depop!    \ Power on HP Soft Generator, HP Softgen Trigger, ena HPOL/R depop
      mute-headphones
      d# 150 ms
   )depop
 
   \ powerdown depop
   h# 303f depop(
      h# c030 depop!     \ ..30 enables HPOL/R startup, disables HPOL/R depop
      d# 75 ms
      h# 8030 depop!     \ !4000 powers down HP softgen trigger
      h# e01c pwr3c!     \ !2 puts HP output in depop mode
      h# 80b0 depop!
      d# 80 ms
      h# 8000 depop!     \ !30 disables  HPOL/R startup
      h# e000 pwr3c!     \ !1c powers off charge pump, HP Amp L/R
   )depop
;

: open-common  ( -- )
   h# 8080 h# 3a codec-set  \ Power on I2S, DAC ref (which is also used for ADC according to the engineer)
;
: close-common  ( -- )
   h# 8080 h# 3a codec-clr  \ Power off I2S, DAC ref
\  h# 0000 pwr3b!  \ Power off PLL
;
: open-out-specific  ( -- )
   h# 0060 h# 3a codec-set                              \ Power on DAC to mixer
   speakers-on?    if  h# 1000 h# 3a codec-set  then    \ Power on ClassD amp
   speakers-on?    if  h# c000 h# 3e codec-set  then    \ Power on SPKL/RVOL
   headphones-on?  if  h# 0c00 h# 3e codec-set  then    \ Power on HPOVOLL/R
\  h# 0300 h# 3a codec-set                              \ Power on DACL/R - defer until dac-on is called by start-audio-out or out-in
   h# c000 pwr3b!                                       \ Power on OUTMIXL/R
   speakers-on?    if  h# 3000 h# 3b codec-set  then    \ Power on SPKMIXL/R

   speakers-on?    if  unmute-speakers   then
   headphones-on?  if  hp-powerup-depop  then
;

: open-out  ( -- )
   open-common
   open-out-specific
;
 
: close-out-specific  ( -- )
   speakers-on?    if  mute-speakers       then
   headphones-on?  if  hp-powerdown-depop  then
 
   h# f000 h# 3b codec-clr  \ Power off OUTMIXL/R, SPKMIXL/R
   h# 0300 h# 3a codec-clr  \ Power off DACs
   h# cc00 h# 3e codec-clr  \ Power off SPKL/RVOL, HPOVOLL/R
   h# 1060 h# 3a codec-clr  \ Power off ClassD amp, DAC to mixer
;
: close-out  ( -- )
   close-out-specific
   close-common
;
 
: adc-source   ( value -- )  h# c000 h# 4a codec-field  ;
: adc-stereo           ( -- )        0 adc-source  ;  \ L->L, R->R
: adc-mono-left        ( -- )  h# 4000 adc-source  ;  \ L->L+R
: adc-mono-right       ( -- )  h# 8000 adc-source  ;  \ R->L+R
: adc-stereo-reversed  ( -- )  h# c000 adc-source  ;  \ L->R, R->L (channels swapped)

: open-in-specific  ( -- )
   h# 000c h# 3b codec-set  \ Power on MIC1/2 bias
   adc-stereo
   h# 0c00 h# 3b codec-set  \ Power on RECMIXLR
   h# 0030 h# 3b codec-set  \ Power on MIC1/2 boost gain
\  h# 0c00 h# 3a codec-set  \ Power on ADCL/R - defer until adc-on is called by audio-in or out-in
;
: open-in  ( -- )
\  h# 46f0 h# 44 codec!  \ pll: 256000 -> 2048000  ??? why is this different from playback? - 8khz record?
   open-common
   open-in-specific
;
 
: close-in-specific  ( -- )
   h# 0c00 h# 3a codec-clr  \ Power off ADCL/R
   h# 0030 h# 3b codec-clr  \ Power off MIC1/2 boost gain
   h# 0c0c h# 3b codec-clr  \ Power off RECMIXLR, MIC1/2 bias
;
: close-in  ( -- )
   close-in-specific
   close-common
;

: open-out-in  ( -- )
   open-common
   open-out-specific
   open-in-specific
;

: close-out-in  ( -- )
   close-in-specific
   close-out-specific
   close-common
;

false value force-speakers?
: set-volume  ( n -- )
   mute-speakers mute-headphones  \ Start with both muted, will be unmuted later
   headphones-inserted?  ( force-speakers? 0= and )  if
      d# 30 - set-headphone-volume
      true false
   else
      set-speaker-volume
      false true
   then
   to speakers-on?  to headphones-on?
;
d#   0 constant default-adc-gain            \   0 dB - range is -96.625 to +28.5
d#   0 constant default-dac-gain            \   0 dB - range is -96.625 to +28.5
d#  52 constant default-mic-gain            \  52 dB - range is  0 to 52 dB
d#   0 constant default-speaker-volume      \   0 dB - range is -46.5 to +12
d# -10 constant default-headphone-volume    \ -10 dB - range is -46.5 to 0

: speakers-on  ( -- )  default-speaker-volume set-speaker-volume  ;
: speakers-off  ( -- )  d# -100 set-speaker-volume  ;
: headphones-on  ( -- )  default-headphone-volume set-headphone-volume  ;
: headphones-off  ( -- )  d# -100 set-headphone-volume  ;

: adc-mute-all  ( -- )   h# f0f0 h# 14 codec!  ;
: adc-mute-mic  ( -- )   h# 4040 h# 14 codec-set  ;
: adc-unmute-mic  ( -- )   h# 4040 h# 14 codec-clr  ;
\ : adc-unmute-outmix  ( -- )   h# 8080 h# 14 codec-clr  ;

\ The useful one is outmix-unmute-dac
: outmix-mute-all  ( -- )   h# ff00 dup h# 1a codec!  h# 1c codec!  ;
: outmix-mute-mic  ( -- )   h# 1000 dup h# 1a codec-set  h# 1c codec-set  ;
: outmix-unmute-mic  ( -- )   h# 1000 dup h# 1a codec-clr  h# 1c codec-clr  ;
: outmix-mute-dac  ( -- )   h# 2000 dup h# 1a codec-set  h# 1c codec-set  ;
: outmix-unmute-dac  ( -- )   h# 2000 dup h# 1a codec-clr  h# 1c codec-clr  ;
: outmix-mute-recmix  ( -- )   h# 8000 dup h# 1a codec-set  h# 1c codec-set  ;
: outmix-unmute-recmix  ( -- )   h# 8000 dup h# 1a codec-clr  h# 1c codec-clr  ;

: attenuation-3/8  ( db -- lrgain boost )
   dup d# -96 <=  if   ( db )
      drop             ( )
      h# ffff h# 8080  ( lrgain boost-muted )
   else                ( db )
      negate 8 3 */    ( steps )
      dup bwjoin       ( lrgain )
      0                ( lrgain boost )
   then                ( lrgain boost )
;
: gain>lr-3/8  ( db -- lrgain boost )
   d# 28 min           ( db )
   dup 0>= if          ( db )
      8 3 */           ( boost )  \ Convert to .375 dB increments
      0 swap           ( lrgain boost )
   else                ( db )
      attenuation-3/8  ( lrgain boost )
   then                ( lrgain boost )
;
: set-dac-gain  ( db -- )
   dup d# -96 <  if  outmix-mute-dac  else  outmix-unmute-dac  then
   gain>lr-3/8  h# 0c codec!  h# 10 codec!
;
: gain>lr-3/2+3/8  ( db -- lrgain boost )
   d# 28 min           ( db )
   dup 0>= if          ( db )
      2 3 */           ( boost )  \ Convert to 1.5 dB increments
      0 swap           ( lrgain boost )
   else                ( db )
      attenuation-3/8  ( lrgain boost )
   then                ( lrgain boost )
;
: set-adc-gain  ( db -- )
   gain>lr-3/2+3/8  h# 12 codec!  h# 16 codec!
;
: mic1-balanced  ( -- )   h# 8000 h# 8000 h# 0e codec-field  ;
: mic1-single-ended  ( -- )     0 h# 8000 h# 0e codec-field  ;
: mic2-balanced  ( -- )   h# 0080 h# 0080 h# 0e codec-field  ;
: mic2-single-ended  ( -- )     0 h# 0080 h# 0e codec-field  ;

false value external-mic?
: mic-routing  ( -- n )
   mic1-single-ended mic2-single-ended
   mic1-low-bias mic2-low-bias    \ Works better than high bias
   adc-unmute-mic
;
: db>mic-boost  ( db -- code )
   dup d# 52 >=  if  drop h# 8800 exit  then
   dup d# 50 >=  if  drop h# 7700 exit  then
   dup d# 44 >=  if  drop h# 6600 exit  then
   dup d# 40 >=  if  drop h# 5500 exit  then
   dup d# 35 >=  if  drop h# 4400 exit  then
   dup d# 30 >=  if  drop h# 3300 exit  then
   dup d# 24 >=  if  drop h# 2200 exit  then
   dup d# 20 >=  if  drop h# 1100 exit  then
   drop h# 0000
;
: set-mic-gain  ( db -- )
   db>mic-boost h# ff00 h# 22 codec-field
   mic-routing
;
: mic+0db  ( -- )  0 set-mic-gain  ;
: mic+20db  ( -- )  d# 20 set-mic-gain  ;
: set-default-gains  ( -- )
   headphones-inserted?  ( force-speakers? 0= and  ) if
      headphones-on
      speakers-off
   else
      speakers-on
      headphones-off
   then
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
   \ XXX need to do something with register 38
   2drop
\   h# 60 codec!  h# 62 codec!
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
