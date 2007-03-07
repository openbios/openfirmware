purpose: Sniff the battery state from EC internal variables
\ See license at end of file

[ifndef] ec@
: ec@ wbsplit h#  381 pc! h# 382 pc! h# 383 pc@ ;
: ec! wbsplit h#  381 pc! h# 382 pc! h# 383 pc! ;
[then]
: wextend  ( w -- n )  dup h# 8000 and  if  h# ffff.0000 or  then  ;
: rr ec@ . ;
: ww ec! ;
: bat-b@ h# f900 + ec@  ;
: bat-w@ dup 1+ bat-b@ swap bat-b@ bwjoin ;
: eram-w@  h# f400 + dup 1+ ec@ swap ec@ bwjoin ;
: uvolt@ 0 bat-w@ d# 9760 d# 32 */ ;
: cur@ 2 bat-w@ wextend  d# 15625 d# 120 */ ;
\ Base unit for temperature is 1/256 degrees C
: >degrees-c 7 rshift 1+ 2/  ;  \ Round to nearest degree 
: pcb-temp 8 bat-w@ >degrees-c  ;
: bat-temp 6 bat-w@ >degrees-c  ;
: .%  ( n -- )  .d ." %" ;
: soc     h# 10 bat-b@  ;
: bat-state  h# 11 bat-b@  ;
: bat-cause@ h# 70 bat-b@  ;
string-array bat-causes
( 00) ," "
( 01) ," Bus Stuck at Zero"
( 02) ," > 32 errors"
( 03) ," (unknown)"
( 04) ," LiFe OverVoltage"
( 05) ," LiFe OverTemp"
( 06) ," Same voltage for 4 minutes during a charge"
( 07) ," Sensor error"
( 08) ," Voltage is <=5V and charging_time is >= 20 secs while the V85_DETECT bit is off"
( 09) ," Unable to get battery ID and Battery Temp is > 52 degrees C"
end-string-array

: .bat-cause  ( -- )
   bat-cause@ bat-causes count type cr
;

string-array bat-states
  ," no-battery        "
  ," charging-idle     "
  ," charging-normal   "
  ," charging-equalize "
  ," charging-learning "
  ," charging-temp-wait"
  ," charging-full     "
  ," discharge         "
  ," abnormal: "
end-string-array

: .bat-state
   bat-state dup bat-states count type
   8 =  if  .bat-cause  then
;
: .milli  ( -- )
   push-decimal
   dup abs  d# 10,000 /  <# u# u# [char] . hold u#s swap sign u#> type
   pop-base
;
: .bat  ( -- )
   ." Battery: "
   soc .%   ."   "
   uvolt@  .milli  ."  V  "
   cur@  .milli  ."  A  "
   bat-temp .d ." C    "
   .bat-state
   ."   (PCB "  pcb-temp .d ." C)"
;
: watch-battery  ( -- )
   cursor-off
   begin  (cr .bat d# 100 ms  key?  until
   key drop
   cursor-on
;
\ send questions to andrew at gold peak


\ LICENSE_BEGIN
\ Copyright (c) 2006 FirmWorks
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
