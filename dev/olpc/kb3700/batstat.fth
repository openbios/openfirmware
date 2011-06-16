: wextend  ( w -- n )  dup h# 8000 and  if  h# ffff.0000 or  then  ;
\ Base unit for temperature is 1/256 degrees C
: >degrees-c 7 rshift 1+ 2/  ;  \ Round to nearest degree 
: uvolt@ bat-voltage@ d# 9760 d# 32 */ ;
: cur@ bat-current@ wextend  d# 15625 d# 120 */ ;
: pcb-temp ambient-temp@ >degrees-c  ;
: bat-temp bat-temp@ >degrees-c  ;
: soc     bat-soc@  ;

string-array bat-causes
( 00) ," "
( 01) ," Bus Stuck at Zero"
( 02) ," Pack info"
( 03) ," NiMH Temp"
( 04) ," NiMH Over Voltage"
( 05) ," NiMH Over Current"
( 06) ," NiMH No voltage change during use"
( 07) ," "
( 08) ," NiMH Pre-charge fail"
( 09) ," No Battery ID"
( 0a) ," LiFe Over Voltage"
( 0b) ," LiFe Over Temp"
( 0c) ," LiFe No voltage change during use"
( 0d) ," "
( 0e) ," "
( 0f) ," "
( 10) ," ACR error"
( 11) ," NIMH 0xFF count"
( 12) ," FF count"
( 13) ," Voltage Invalid"
( 14) ," Bank 0 Invalid"
( 15) ," Bank 1 Invalid"
( 16) ," Bank 2 Invalid"
end-string-array

: .bat-cause  ( -- )
   bat-cause@ bat-causes count type cr
;

: .bat-error .bat-cause ;

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
  ," trickle           "
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

: .mppt-active?
   mppt-active@ h# d and
   if ." MPPT" then
;

\needs 2.d : 2.d  ( n -- )  push-decimal <# u# u#s u#>  type  pop-base  ;
: .%  ( n -- )  2.d ." %" ;
: .bat  ( -- )
   bat-status@  ( stat )
   ." AC:"  dup h# 10 and  if  ." on  "  else  ." off "  then  ( stat )

\ PCB temp was nver really valid and was removed in Gen 1.5
\   ." PCB: "  pcb-temp 2.d ." C "

   dup h# 81 and  if
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
      dup h# 80 and  if  ." trickle  "  then
   else
      ." No battery "
   then
   drop
   .mppt-active?
;

: ?enough-power  ( )
   bat-status@                                    ( stat )
   dup  h# 10 and  0=  abort" No external power"  ( stat )
   dup  1 and  0=  abort" No battery"             ( stat )
   4 and  abort" Battery low"  
;
: watch-battery  ( -- )
   begin  (cr .bat kill-line  d# 1000 ms  key?  until
   key drop
   bat-status@ 8 and if cr .bat-error then
;

[ifndef] >sd.ddd
: >sd.ddd  ( n -- formatted )
   base @ >r  decimal
   dup abs <# u# u# u# [char] . hold u# u#s swap sign u#>
   r> base !
;
[then]

: .mppt 
   mppt-limit@            ( pwr_limit )
   vin@                   ( pwr_limit VA2 )
    ." Vin: " .d  ."  PWM: " .
;

: watch-mppt ( -- )
   begin  (cr .mppt kill-line  d# 500 ms  key?  until
   key drop
;


dev /
new-device
" battery" device-name
" olpc,xo1-battery" +compatible

0 0 reg  \ Needed so test-all will run the selftest

\ Test that the battery is inserted and not broken.
: test-battery  ( -- error? )
   bat-status@ h# 01 and  0= if
      ." Insert battery to continue.. "
      begin  d# 100 ms  bat-status@ h# 01 and  until
      cr
   then
   ." Testing battery status.. "
   bat-status@ h# 04 and  if
      ." error: battery broken" cr
      true
   else
      ." ok: " cr .bat cr
      false
   then
;

: wait-no-ac  ( -- error? )
   ." Disconnect AC power to continue.. "
   begin
      bat-status@ h# 10 and   ( ac-connected? )
   while
      d# 100 ms

      key?  if
         key  h# 1b =  if
            ." ERROR: AC still connected" cr
            true  exit
         then
      then
   repeat
   cr
   false
;

\ Test that we can run without AC power.
: test-discharging  ( -- error? )
   bat-status@ h# 10 and  0<> if
      wait-no-ac  if  true exit  then
   then
   ." Test running from battery.. "
   d# 2000 ms
   bat-status@ h# 40 and  if
      ." ok: battery discharging" cr
      false
   else
      ." ERROR: battery not discharging" cr
      true
   then
;

: wait-ac  ( -- error? )
   ." Connect AC power to continue.. "
   begin
      bat-status@ h# 10 and  0=  ( ac-disconnected? )
   while
      d# 100 ms
      
      key?  if
         key  h# 1b =  if
            ." ERROR: AC not connected" cr
            true  exit
         then
      then
   repeat
   cr
   false
;

: test-charging  ( -- error? )
   bat-status@ h# 10 and  0= if
      wait-ac  if  true exit  then
   then
   ." Test running from AC.. "
   d# 4000 ms
   bat-status@ h# 40 and  0= if
      ." ok: battery is not discharging" cr
      false
   else
      ." ERROR: battery is discharging" cr
      true
   then
;

: interactive-test  ( -- error? )
   test-battery      if  true exit  then
   " test-station" $find  if  execute  else  2drop 0  then  ( station# )
   1 <>   if                                 \ Skip this test in SMT
      test-discharging  if  true exit  then
   then
   test-charging     if  true exit  then
   false
;

: selftest  ( -- error? )
   diagnostic-mode?  if
      interactive-test
   else
      .bat false
   then
;

finish-device
device-end
