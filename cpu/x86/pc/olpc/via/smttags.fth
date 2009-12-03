\ SMT test

\ visible

\ Needs:
\ sharename$  ( -- adr len )  CIFS URL of share and credentials, e.g.:
\    " cifs:\\user:password@192.168.0.1\myshare"

[ifndef] $read-file
\ Read entire file into allocated memory
: $read-file  ( filename$ -- true | data$ false )
   open-dev  ?dup  0=  if  true exit  then  >r  ( r: ih )
   " size" r@ $call-method  drop   ( len r: ih )
   dup alloc-mem  swap             ( adr len r: ih )
   2dup " read" r@ $call-method    ( adr len actual r: ih )
   r> close-dev                    ( adr len actual )
   over <>  if                     ( adr len )
      free-mem  true exit
   then                            ( adr len )
   false
;
[then]

d# 20 buffer: bn-buf  \ Buffer for scanned-in board number string
0 value bn-acquired?  \ True if we have the board number

\ Get a board number from the user and validate it
: try-get-bn  ( -- )
   bn-buf 1+ d# 20 accept   ( n )
   dup bn-buf c!            ( n )
   d# 14 <>  if
      red-letters ." Wrong length, try again" black-letters cr
      exit
   then
   bn-buf 1+ " Q" comp  if
      red-letters ." Must begin with Q, try again" black-letters cr   
      exit
   then
   true to bn-acquired?
;

\ Get a board number from the user, retrying until valid
\ Usually the number is entered with a barcode scanner
: scanned-board#$  ( -- adr len )
   bn-acquired?  if  bn-buf count exit  then
   ." *****"

   begin
      blue-letters  ." Please Input Board Number ......"   black-letters
      cr cr cr

      try-get-bn
   bn-acquired? until

   bn-buf count
;

\ Construct the filename used for communicating with the server
\ We make an 8.3 name from the last 11 characters of the board number
d# 12 buffer: filename-buf
: smt-filename$  ( -- )
   scanned-board#$ drop     3 +  filename-buf 1 + 8 move
   [char] .  filename-buf 8 +  c!
   scanned-board#$ drop d# 11 +  filename-buf 9 + 3 move
   d# 12 filename-buf c!
   filename-buf count
;

0 value cifs-ih
d# 256 buffer: tempname-buf
: tempname$  ( -- adr len )  tempname-buf count  ;
: $call-cifs  ( ?? -- ?? )  cifs-ih $call-method  ;

: cifs-write  ( adr len -- )  " write" $call-cifs  ;

: cifs-connect  ( -- )
   sharename$ open-dev to cifs-ih
   cifs-ih 0= abort" Cannot open SMB share"
;
: cifs-disconnect  ( -- )
   cifs-ih  if  cifs-ih close-dev  0 to cifs-ih  then
;

: open-temp-file  ( filename$ -- )
   tempname-buf place
   
   tempname$  " $create" $call-cifs  abort" Cannot open temp file"
   cifs-ih 0= abort" Can't open temp file on manufacturing server"
;

: put-key  ( value$ key$ -- )
   cifs-write  cifs-write  " "r"n" cifs-write
;
: submit-file  ( subdir$ -- )
   " flush" $call-cifs abort" CIFS flush failed"
   " close-file" $call-cifs  abort" CIFS close-file failed"
   tempname$  2swap  " %s\\%s" sprintf  ( new-name$ )
   tempname$  2swap  " $rename" $call-cifs abort" CIFS rename failed"   
;
: get-response  ( subdir$ -- adr len )
   tempname$  2swap  " %s\\%s" sprintf  ( response-name$ )
   d# 10 0 do                           ( response-name$ )
      d# 1000 ms                        ( response-name$ )
      2dup  0 open-file  0=  if         ( response-name$ )
         2drop                          ( )
         " size" $call-cifs             ( d.size )
         abort" Size is > 4 GB"         ( size )
         dup alloc-mem  swap            ( adr len )
         2dup " read" $call-cifs        ( adr len actual )
         over <> abort" CIFS read of response file filed"
         unloop exit
      then
   loop                                 ( response-name$ )
   2drop                                ( )
   true abort" Server did not respond with 10 seconds"
;

\ Upload the result data 
: smt-result  ( pass? -- adr len )
   smt-filename$  open-temp-file
   if  " PASS"  else  " FAIL"  then  " RESULT="  put-key
   " FVT" " PROCESS=" put-key
   " "  " STATION=" put-key
   " "  " OPID=" put-key
   " "  " GUID=" put-key
   scanned-board#$ " MB_NUM=" put-key
   " Result" submit-file
;

\ Send the board number as the request and return the response data
: smt-request$  ( -- adr len )
   smt-filename$ open-temp-file
   scanned-board#$  " MB_NUM="  put-key
   " Request" submit-file
   " Response" get-response
;

: clear-mfg-buf  ( -- )
   mfg-data-buf  /flash-block  h# ff fill
;

: put-ascii-tag  ( value$ key$ -- )
   2swap  dup  if  add-null  then  2swap  ( value$' key$ )
   ($add-tag)                             ( )
;

\ Decode the server's response and insert appropriate mfg data tags
: parse-smt-response  ( adr len -- error? )
   drop  " Timeout" comp 0=  if  true exit  then

   flash-write-enable

   clear-mfg-buf                          ( )
   " "      " ww"  put-ascii-tag          ( )
   " EN"    " SS"  put-ascii-tag          ( )
   scanned-board#$  " B#"  put-ascii-tag  ( )
   (put-mfg-data)                         ( )

   \ check-tags

   no-kbc-reboot
   flash-write-disable

   false
;

\ Perform the exchange with the manufacturing server
: smt-tag-exchange  ( -- error? )
   smt-request$ $read-file  dup  if  exit  then   ( adr len )
   2>r  2r@ parse-smt-response                    ( r: adr len )
   2r> free-mem   
;

0 0  " 0"  " /" begin-package
" gpios" device-name
: open  ( -- okay? )  true  ;
: close  ( -- )  ;
: gpio-lo ( mask -- )  h# 4c acpi-l@  swap invert and  h# 4c acpi-l!  ;
: gpio-hi  ( mask -- )  h# 4c acpi-l@  swap or  h# 4c acpi-l!  ;
: wlan-led-on  ( -- )  h# 200000 gpio-lo  ;
: wlan-led-off ( -- )  h# 200000 gpio-hi  ;
: hdd-led-on  ( -- )  h# 400000 gpio-lo  ;
: hdd-led-off ( -- )  h# 400000 gpio-hi  ;
: selftest  ( -- )
   ." Flashing LEDs" cr
      
   confirm-selftest?
;

end-package

: led-item ( -- )  " /leds"  mfg-test-dev  ;


\ XXX need a better icon
icon: led.icon    rom:timer.565

: smt-test-menu  ( -- )
   mfgtest-menu
   " LEDs"
   ['] led-item    led.icon   3 4 install-icon
;
\ d# 15 to #mfgtests
\ ' smt-test-menu to root-menu

: smt-tests  ( -- pass? )
   5 #mfgtests +  5 do
      i set-current-sq
      refresh
      d# 200 0 do
         d# 10 ms  key? if  unloop unloop exit  then
      loop
      doit
      pass? 0= if  unloop false exit  then
   loop
   all-tests-passed
   true
;

: do-smt-test  ( -- )
   smt-tag-exchange
   smt-tests  smt-result
;

\ patch do-smt-test play-item mfgtest-menu
\ patch smt-tests play-item mfgtest-menu

true value once?
: doit-once  ( -- )
   do-key
   once?  if
      false to once?
\      doit
      smt-tests
   then
;
patch doit-once do-key menu-interact

' true to (diagnostic-mode?)
patch false diagnostic-mode? memory-test-suite

\ menu
