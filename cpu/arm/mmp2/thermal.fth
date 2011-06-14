\ See license at end of file
purpose: Driver for the MMP2 thermal sensor

h# d4013200 value thermal-base
: init-thermal-sensor  ( -- )
   thermal-base l@ h# 400 and  if  exit  then
   3 h# d4015090 l!          \ Enable clocks to thermal sensor
   h# 10000 thermal-base l!  \ Enable sensing
;
   
: cpu-temperature  ( -- celcius )
   0                   ( acc )
   d# 100 0  do        ( acc )  \ Accumulate 100 samples
      thermal-base l@  ( acc reg )
      h# 3ff and       ( acc val )
      +                ( acc' )
   loop                ( acc )

   \ Now we have raw value * 100
   \ The formula (from the Linux driver) is Celcius = (raw - 529.4) / 1.96

   d# 52940 -  d# 196 /  ( celcius )
;
stand-init: Thermal sensor
   init-thermal-sensor
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
