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
\ Base unit for temperature is 1/256 degrees C
: >degrees-c 7 rshift 1+ 2/  ;  \ Round to nearest degree 
\ : uvolt@ 0 bat-w@ d# 9760 d# 32 */ ;
\ : cur@ 2 bat-w@ wextend  d# 15625 d# 120 */ ;
\ : pcb-temp 8 bat-w@ >degrees-c  ;
\ : bat-temp 6 bat-w@ >degrees-c  ;
\ : soc     h# 10 bat-b@  ;
: bat-state  h# 11 bat-b@  ;
: bat-cause@ h# 70 bat-b@  ;

: uvolt@ bat-voltage@ d# 9760 d# 32 */ ;
: cur@ bat-current@ wextend  d# 15625 d# 120 */ ;
: pcb-temp ambient-temp@ >degrees-c  ;
: bat-temp bat-temp@ >degrees-c  ;
: soc     bat-soc@  ;

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

: .bat-type  ( -- )
   bat-type@  dup 4 rshift  case   ( type )
      0  of  ." "      endof
      1  of  ." GPB "  endof
      2  of  ." BYD "  endof
      ." UnknownVendor "
   endcase                         ( type )

   h# 0f and  case                 ( )
      0  of  ." "           endof
      1  of  ." NiMH  "     endof
      2  of  ." LiFePO4  "  endof
      ." UnknownType  "
   endcase
;

: .milli  ( -- )
   push-decimal
   dup abs  d# 10,000 /  <# u# u# [char] . hold u#s swap sign u#> type
   pop-base
;
: 2.d  ( n -- )  push-decimal <# u# u#s u#>  type  pop-base  ;
: .%  ( n -- )  2.d ." %" ;
: .bat  ( -- )
   bat-status@  ( stat )
   ." AC:"  dup h# 10 and  if  ." on  "  else  ." off "  then  ( stat )
   ." PCB: "  pcb-temp 2.d ." C "

   dup 1 and  if
      ." Battery: "
      .bat-type
      soc .%   ."  "
      uvolt@  .milli  ." V "
      cur@  .milli  ." A "
      bat-temp 2.d ." C "
      dup 2 and  if  ." full "  then
      dup 4 and  if  ." low "  then
      dup 8 and  if  ." error "  then
      dup h# 20 and  if  ." charging "  then
      dup h# 40 and  if  ." discharging "  then
   else
      ." No battery"
   then
   drop
;
: watch-battery  ( -- )
   cursor-off
   begin  (cr .bat kill-line  d# 1000 ms  key?  until
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
