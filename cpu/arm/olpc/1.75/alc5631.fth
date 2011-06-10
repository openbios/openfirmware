\ See license at end of file
purpose: Driver for Realtek ALC5631Q audio CODEC chip

: adc-on  ( -- )  h# 0c00 h# 3a codec-set  ;
: adc-off ( -- )  h# 0c00 h# 3a codec-clr  ;
: dac-on  ( -- )  h# 0300 h# 3a codec-set  ;
: dac-off ( -- )  h# 0300 h# 3a codec-clr  ;

: codec-on  ( -- )
   0 0 codec!  \ Reset

   b# 1010.0000.0001.1101 h# 3c codec!  \ All on except AX and MONO
   d# 110 ms
   b# 1110.0000.0001.1101 h# 3c codec!  \ Fast VREF control
   d# 100 ms

   h# 8001 h# 34 codec!  \ Slave mode, 16 bits, left justified

   h# 1010 h# 38 codec!  \ Divisors; the values in this register don't seem to make much
   \ difference unless you set the divisors to very high values.

   \ The ADC and DAC will be turned on as needed by adc-on and dac-on, after
   \ the BCLK clock from the SoC is on.  If you turn on the ADC when BCLK is
   \ not clocking, the ADC often doesn't output any data.
   b# 1001.0000.1110.0000 h# 3a codec!  \ All on except ADC and DAC
   b# 1111.1100.0011.1100 h# 3b codec!  \ All on except PLL
   b# 1111.1100.0000.0000 h# 3e codec!  \ AXI and MONO IN off

\   h# 8c00 h# 40 codec!  \ Speaker Amp Auto Ratio GAIN, use HPFs
   h# 4e00 h# 40 codec!  \ Speaker Amp Ratio GAIN is 1.44x, no HPFs
   h# 0000 h# 42 codec!  \ Use MCLK, not PLL
\   b# 1110.1100.1001.0000 h# 52 codec!  \ Protection on
   h# 8000 h# 56 codec!  \ HP depop by register control
;
: codec-off  ( -- )
   0 h# 3a codec!  \ All off
   0 h# 3b codec!  \ All off
   0 h# 3c codec!  \ All off
   0 h# 3e codec!  \ All off
;
: mic-bias-off  ( -- )  h# 000c h# 3b codec-clr  ;
: mic-bias-on   ( -- )  h# 000c h# 3b codec-set  ;

: mic1-high-bias  ( -- )  h# 80 h# 22 codec-clr  mic-bias-on  ;  \ 0.90*AVDD, e.g. 3V with AVDD=3.3V
: mic1-low-bias   ( -- )  h# 80 h# 22 codec-set  mic-bias-on  ;  \ 0.75*AVDD, e.g. 2.5V with AVDD=3.3V
: mic2-high-bias  ( -- )  h# 08 h# 22 codec-clr  mic-bias-on  ;  \ 0.90*AVDD, e.g. 3V with AVDD=3.3V
: mic2-low-bias   ( -- )  h# 08 h# 22 codec-set  mic-bias-on  ;  \ 0.75*AVDD, e.g. 2.5V with AVDD=3.3V

\ The range is from -46.5 db to +12 dB
: gain>lr-12  ( db -- true | regval false )
   d# 12 min           ( db' )
   2* 3 /              ( steps )  \ Converts -46.5 .. 12 db to -31 .. 8 steps
   dup d# -31 <  if    ( steps )
      drop true
   else                ( steps )
      8 swap -         ( -steps )
      0 max            ( clipped-steps )
      dup 8 lshift or  ( regval )
      false
   then
;
\ The range is from -46.5 db to 0 dB
: gain>lr  ( db -- true | regval false )
   0 min               ( db' )
   2* 3 /              ( steps )  \ Converts -46.5 .. 12 db to -31 .. 8 steps
   dup d# -31 <  if    ( steps )
      drop true
   else                ( steps )
      0 swap -         ( -steps )
      0 max            ( clipped-steps )
      dup 8 lshift or  ( regval )
      false
   then
;

\ This sets up a simple routing from the DAC to the headphone and speaker outputs
: output-config  ( -- )
   h# df00 h# 1a codec!     \ DACL -> OUTMIXL
   h# df00 h# 1c codec!     \ DACR -> OUTMIXR
   h# 4040 h# 04 codec-set  \ OUTMIXLR -> HPOVOLLR
   h# d0d0 h# 28 codec!     \ DACLR -> SPKMIXLR
   h# 4040 h# 02 codec-set  \ SPKMIXLR -> SPKVOLLR
   h# 9000 h# 2a codec!     \ SPKVOLL -> SPOLMIX, SPKVOLR -> SPORMIX
   h# 0000 h# 2c codec!     \ SPOxMIX -> SPKRMUX, HPOVOL -> HPMUX
;

: mute-speakers  ( -- )  h# 8080 2 codec-set  ;
: set-speaker-volume    ( n -- )  \ DONE
   gain>lr-12  if  h# 8080  then   h# bfbf   2 codec-field
;
: mute-headphones  ( -- )  h# 8080 4 codec-set  ;
: set-headphone-volume  ( n -- )  \ DONE
   gain>lr  if  h# 8080  then   h# 9f9f   4 codec-field
;

false value force-speakers?
: set-volume  ( n -- )
   headphones-inserted?  ( force-speakers? 0= and )  if
      set-headphone-volume mute-speakers
   else
      set-speaker-volume mute-headphones
   then
;
d#   0 constant default-adc-gain            \   0 dB - range is -96.625 to +28.5
d#   0 constant default-dac-gain            \   0 dB - range is -96.625 to +28.5
d#  52 constant default-mic-gain            \  52 dB - range is  0 to 52 dB
d#   0 constant default-speaker-volume      \   0 dB - range is -46.5 to +12
d# -10 constant default-headphone-volume    \ -10 dB - range is -46.5 to 0

: speakers-on  ( -- )  default-speaker-volume set-speaker-volume  ;
: speakers-off  ( -- )  d# -100 set-speaker-volume   ;
: headphones-on  ( -- )  default-headphone-volume set-headphone-volume  ;
: headphones-off  ( -- )  d# -100 set-headphone-volume   ;

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

: gain>lr-3/8  ( -- lrgain boost )
   d# 28 min
   dup 0>= if          ( n )
      8 3 */           ( boost )  \ Convert to .375 dB increments
      0 swap           ( lrgain boost )
   else                        ( n )
      dup d# -96 <=  if        ( n )
         drop                  ( )
         h# ffff h# 8080       ( lrgain boost )
      else                     ( n )
         negate 8 3 */         ( steps )
         dup bwjoin            ( lrgain )
         0                     ( lrgain boost )
      then                     ( lrgain boost )
   then                        ( lrgain boost )
;
: set-dac-gain  ( n -- )
   dup d# -96 <  if  outmix-mute-dac  else  outmix-unmute-dac  then
   gain>lr-3/8  h# 0c codec!  h# 10 codec!
;
: set-adc-gain  ( n -- )
   gain>lr-3/8  h# 12 codec!  h# 16 codec!
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
   output-config
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
