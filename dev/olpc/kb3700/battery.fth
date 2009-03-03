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
\needs 2.d : 2.d  ( n -- )  push-decimal <# u# u#s u#>  type  pop-base  ;
: .%  ( n -- )  2.d ." %" ;
: .bat  ( -- )
   bat-status@  ( stat )
   ." AC:"  dup h# 10 and  if  ." on  "  else  ." off "  then  ( stat )
   ." PCB: "  pcb-temp 2.d ." C "

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
      ." No battery"
   then
   drop
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
;

\ A few commands for looking at what the EC is doing in
\ the battery state machine.
\ Unless you are on a serial console with stdout turned off
\ (stdout off) this will miss some state changes.
\

h# FA00 constant ec-rambase
: ec-ram@ ec-rambase + ec@ ;

: next-bstate
        begin
         f780 ec@ tuck <>
        until
;

: see-bstate
        0 begin
            next-bstate dup .
                dup 4 = if
                  cr
            then key?
        until
;

: next-e1-state
   begin 
      fae1 ec@ tuck <>
   until
;

: see-e1
        0 begin
            next-e1-state dup .
            key?
        until
;

\ Turn on the charging mosfet
: bat-enable-charge ( -- ) fc21 ec@ 40 or fc21 ec! ;

\ Turn off the charging mosfet
: bat-disable-charge ( -- ) fc21 ec@ 40 invert and fc21 ec! 03 fc24 ec! ;

\ Turn on the trickle charge with max system voltage
: bat-enable-trickle ( -- ) fc23 ec@ 1 or fc23 ec! 01 fc24 ec! ;

\ Turn off the trickle charger
: bat-disable-trickle ( -- ) fc23 ec@ 1 invert and fc23 ec! ;

\ Access the 1-wire data line via the EC GPIO ports

h# 383 constant dataport
h# 382 constant lowadr
4 constant dq-bit
0 value high
0 value low
false value 1w-initialized
0 value fileih

: disable-ec-charging
   1 h# fa07 ec!
;

: disable-ec-1w
   1 h# fa08 ec!
;

: enable-ec-charging
   0 h# fa07 ec!
;

: enable-ec-1w
   0 h# fa08 ec!
;

: 1w-init  ( -- )
   disable-interrupts
   h# fc24 ec@  dq-bit invert and  fc24 ec!
   h# fc14 ec@ dup dq-bit or to low    dq-bit invert and to high
   high fc14 ec!
   true to 1w-initialized
   1 ms
;


\ New ec revs can turn off the battery subsystem without
\ putting the ec into reset allowing the user to
\ use the XO keyboard.
: init-ec-live
   disable-ec-charging
   disable-ec-1w
   1w-init
;

: init-ec-dead
   kbc-off
   1w-init
;

\ EC code at the time these commands were added can stop
\ the battery subsystem with out putting the EC into reset.
\ so we always do a live init
: batman-init init-ec-live 500 ms bat-disable-charge bat-disable-trickle ;
: batman-init? 1w-initialized if else batman-init then ;


: batman-start batman-init? ;

: batman-stop
   enable-ec-1w
   enable-ec-charging
   enable-interrupts
   false to 1w-initialized
;

: bit?  ( us -- flag )  \ Test the data after a delay
   us  h# 34 lowadr pc!  dataport pc@  dq-bit and  0<>
;

: 1w-pulse  ( us -- )  \ Pulse the wire low for some duration
   h# 14 lowadr pc!  low dataport pc!  us  high dataport pc!
;

\ Generic 1-wire primitives

: 1w-reset  ( -- )
   d# 480 1w-pulse
   d# 67 bit?  abort" No response from battery"
   begin  1 bit?  until
;

: 1w-write-byte  ( byte -- )
   8 0  do                     ( byte )
      dup  1 and  if           ( byte )
         1 1w-pulse  d# 60 us  ( byte )
      else                     ( byte )
         d# 60 1w-pulse        ( byte )
      then                     ( byte )
      2/                       ( byte' )
   loop                        ( byte )
   drop                        ( )
;

: 1w-read-byte  ( -- )
   0   8 0  do
      1 1w-pulse
      \ Shift bits in from the left, little endian
      d# 10 bit?  h# 100 and  or  2/  d# 50 us
   loop
;

: 1w-skip-address  ( -- )  h# cc 1w-write-byte  ;

: 1w-cmd   ( arg cmd -- )  1w-reset  1w-skip-address  1w-write-byte  1w-write-byte  ;

\ Basic commands for the DS2756 chip

: 1w-read   ( adr len start -- )
   h# 69 1w-cmd                            ( adr len )
   bounds  ?do  1w-read-byte i c!  loop    ( )
   1w-reset
;

: 1w-write   ( adr len start -- )
   h# 6c 1w-cmd                            ( adr len )
   bounds  ?do  i c@ 1w-write-byte  loop   ( )
   1w-reset
;

: 1w-write-start ( start -- )
   h# 6c 1w-cmd
;

: 1w-copy    ( start -- )  h# 48 1w-cmd  d# 10 ms  ;

: 1w-recall  ( start -- )  h# b8 1w-cmd  ;

\ : 1w-lock    ( start -- )  h# 6a 1w-cmd  ;

: 1w-sync  ( -- )  0  h# d2 1w-cmd  ;

\ Some higher-level commands for accessing battery data

\ buffer for reading bank data
h# 20 constant /ds-bank     \ Bytes per bank in the battery sensor chip
h# 60 constant /ds-eeprom   \ Bytes in the eeprom
h# 01 constant ni-mh
h# 02 constant li-fe
h# 00 constant ds-regs
h# 10 constant ds-acr
h# 20 constant ds-bank0
h# 25 constant ds-bat-misc-flag
h# 2d constant ds-last-dis-soc
h# 2e constant ds-last-dis-acr-msb
h# 2f constant ds-last-dis-acr-lsb
h# 40 constant ds-bank1
h# 60 constant ds-bank2
h# 68 constant ds-remain-acr-msb
h# 69 constant ds-remain-acr-lsb
h# 5f constant ds-batid

h# 01 constant ds-bat-low-volt
h# 20 constant ds-bat-full

h# 20 buffer: ds-bank-buf

: ds-bank$  ( -- adr len )  ds-bank-buf /ds-bank  ;

: bat-id  ( -- id )  ds-bank-buf 1 ds-batid 1w-read  ds-bank-buf c@ h# 0f and  ;

: read-bank  ( offset -- )  ds-bank$ rot 1w-read  ;

: bat-read-eeprom ( -- ) ds-bank-buf /ds-eeprom ds-bank0 1w-read ;

: bat-ds-regs@ ( -- )  ds-regs  read-bank  ;
: bat-bank0@   ( -- )  ds-bank0 read-bank  ;
: bat-bank1@   ( -- )  ds-bank1 read-bank  ;
: bat-bank2@   ( -- )  ds-bank2 read-bank  ;

: bat-dump-bank  ( -- )  ds-bank$ dump  ;

: bat-dump-banks ( -- )
   batman-init? 
   cr ." Regs"
   bat-ds-regs@ bat-dump-bank
   cr cr ." Bank 0"
   bat-bank0@ bat-dump-bank
   cr cr ." Bank 1"
   bat-bank1@ bat-dump-bank
   cr cr ." Bank 2"
   bat-bank2@ bat-dump-bank
;

: bat-dump-regs ( -- ) batman-init? bat-ds-regs@ bat-dump-bank ;

: s16>s32 ( signed16bit -- 32bit_sign-extended )
   d# 16 << d# 16 >>a
;

: bat-save  ( -- )
   " disk:\battery.dmp"
   2dup ['] $delete  catch  if  2drop  then  ( name$ )
   $create-file to fileih

   1w-init
   h# 80 0  do
      ds-bank$ i 1w-read
      ds-bank$ " write" fileih $call-method
   /ds-bank +loop

   fileih close-dev
;

\ bg-* words access the gauge directly via 1w rather than
\ read the value from the ec cache
: bg-acr@     ( -- acr )
   batman-init?
   ds-bank-buf 2 ds-acr 1w-read                  ( )
   ds-bank-buf c@ 8 <<                          ( msb )
   ds-bank-buf 1 + c@ or s16>s32                ( acr )
;

: bg-acr! ( acr -- )
   batman-init?
   wbsplit
   ds-acr 1w-write-start
   1w-write-byte
   1w-write-byte
   1w-reset
;

: bg-last-dis-soc@ ( -- last-dis-soc )
   batman-init?
   ds-bank-buf 1 ds-last-dis-soc 1w-read
   ds-bank-buf c@ 
;

: bg-last-dis-soc! ( soc -- )
   batman-init?
   ds-bank0 1w-recall
   ds-last-dis-soc 1w-write-start
   1w-write-byte
   ds-last-dis-soc 1w-copy
   1w-reset
;

: bg-last-dis-acr@ ( -- last-dis-acr )
   batman-init?
   ds-bank-buf 2 ds-last-dis-acr-msb 1w-read ( )
   ds-bank-buf c@ 8 <<                          ( last-dis-acr-msb )
   ds-bank-buf 1 + c@ or s16>s32                ( last-dis-acr )
;

: bg-last-dis-acr! ( last-dis-acr --)
   batman-init?
   wbsplit
   ds-bank0 1w-recall
   ds-last-dis-acr-msb 1w-write-start
   1w-write-byte
   1w-write-byte
   ds-last-dis-acr-msb 1w-copy
   1w-reset
;

: bg-misc@ ( -- misc-flag )
   batman-init?
   ds-bank-buf 1 ds-bat-misc-flag 1w-read
   ds-bank-buf c@
;

: bg-set-full-flag ( -- )
   bg-misc@
   ds-bat-full or
   ds-bank0 1w-recall
   ds-bat-misc-flag 1w-write-start
   1w-write-byte
   ds-bat-misc-flag  1w-copy
   1w-reset
;

: bg-clear-full-flag ( -- )
   bg-misc@
   ds-bat-full not and
   ds-bank0 1w-recall
   ds-bat-misc-flag 1w-write-start
   1w-write-byte
   ds-bat-misc-flag  1w-copy
   1w-reset
;

: .bg-eeprom
   base @ >r
   decimal
   ."          acr: " bg-acr@ . cr
   ." Last dis soc: " bg-last-dis-soc@ . cr
   ." Last dis acr: " bg-last-dis-acr@ . cr
   hex
   ."   Misc flags: " bg-misc@ dup . ."  : "
   dup ds-bat-full and if ." fully charged " then
   dup ds-bat-low-volt and if ." low voltage " then
   drop
   cr
   r> base !
;

: >sd.ddd  ( n -- formatted )
   base @ >r  decimal
   dup abs <# u# u# u# [char] . hold u#s rot sign u#>
   r> base !
;

: >sd.dd  ( n -- formatted )
   base @ >r  decimal
   dup abs <# u# u# [char] . hold u#s rot sign u#>
   r> base !
;

: bg-acr>mAh ( raw-value -- acr_in_mAh )
   abs
   d# 625 ( mV ) * d# 15 ( mOhm ) /
   over 0<  if  negate  then
;

: bg-V>V ( raw-value - Volts )
   abs
   d# 488 ( mV ) * 2* d# 100 / 5 >>
   over 0<  if  negate  then
;

: bg-I>mA ( raw-value -- I_in_mA )
   abs 3 >>
   d# 15625 ( nV ) * d# 15 ( mOhm ) / d# 10 /
   over 0< if  negate  then
;

: bg-temp>degc ( raw-value -- temp_in_degc )
   abs
   d# 125 * d# 10 / 5 >>
   over 0<  if  negate  then
;

h# 90 buffer: logstr
: >sd
   <# "  " hold$ u#s u#>
;

: >sdx
   <# "  " hold$ u#s " 0x" hold$ u#>
;

: bat-lfp-dataf@
      base @ >r 
      0 logstr c!

      decimal
      now drop <# " :" hold$ u#s u#> logstr $cat  <# "  " hold$ u#s u#> logstr $cat   \ Running time
      h# 10 bat-b@        \ SOC
      >sd logstr $cat

      hex
      h# e0 ec-ram@       \ C state
      >sdx logstr $cat
      h# e1 ec-ram@       \ w1 state index
      >sdx logstr $cat  
      h# F780 ec@         \ w1 state
      >sdx logstr $cat
      h# 40 ec-ram@       \ pwr_flag
      >sdx logstr $cat
      h# a4 ec-ram@       \ bat_status
      >sdx logstr $cat
      h# a5 ec-ram@       \ chg status
      >sdx logstr $cat
      h# a6 ec-ram@       \ bat misc
      >sdx logstr $cat
      h# a7 ec-ram@       \ bat misc2
      >sdx logstr $cat
      h# 70 bat-b@        \ AbnormalCauseCode
      >sdx logstr $cat

      decimal
      h# 54 bat-b@ 8 << h# 55 bat-b@ or s16>s32    \ ACR
      bg-acr>mAh >sd.dd logstr $cat "  " logstr $cat
      h# 00 bat-b@ 8 << h# 01 bat-b@ or s16>s32    \ V
      bg-V>V >sd.ddd logstr $cat "  " logstr $cat
      h# 02 bat-b@ 8 << h# 03 bat-b@ or s16>s32    \ I
      bg-I>mA >sd.dd logstr $cat "  " logstr $cat
      h# 06 bat-b@ 8 << h# 07 bat-b@ or            \ Temp
      bg-temp>degc >sd.dd logstr $cat "  " logstr $cat
\      h# 17 bat-b@ 8 << h# 18 bat-b@ or            \ NiMh Chargetime
\      >sd logstr $cat

      \ Chemistry specific stuff below here
      h# 11 bat-b@        \ bat_state
      >sd logstr $cat

      hex
      h# FBD1 ec@          \ ProcessBatteryCharge
      >sdx logstr $cat
      h# FBD0 ec@          \ ChargeFlowControl
      >sdx logstr $cat

      r> base !
;

: bat-debug
   begin
      bat-lfp-dataf@
      logstr count type
      cr
      200 ms key?
   until key drop 
;

: bat-debug-log
   " disk:\batdbug.log" $new-file
   begin
      bat-lfp-dataf@
      logstr count ftype
      logstr count type
      fcr
      cr
      200 ms key?
   until key drop 
   ofd @ fclose
;

dev /
new-device
" battery" device-name
0 0 reg  \ Needed so test-all will run the selftest
: selftest  ( -- error? )
   .bat
   false
;
finish-device
device-end

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
