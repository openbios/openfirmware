\ Post-runin boot script $Revision$

visible

\ Location of the files containing KA tag data
: ka-dir$  ( -- adr len )  " http:\\10.1.0.1\ka\"  ;

: mfg-ntp-server  ( -- name$ )
   " NT" find-tag  if  ?-null  else  " 10.1.0.1"  then
;
' mfg-ntp-server to ntp-servers

\ The Linux-based runin selftests put this file at int:\runin\olpc.fth
\ after they have finished.  On the next reboot, OFW thus boots this
\ script instead of int:\boot\olpc.fth .  This script either displays
\ the failure log (if int:\runin\fail.log is present) or modifies the
\ manufacturing data tags to cause the next boot to enter final test.

d# 20 buffer: sn-buf
: sn$  ( -- adr len )  sn-buf count  ;

: try-scan-sn  ( -- gotit? )
   sn-buf 1+ d# 20 accept   ( n )
   d# 12 <>  if
      " Wrong length, try again" .problem
      false exit
   then
   sn-buf 1+ " TSHC" comp  if
      " Must begin with TSHC, try again" .problem
      false exit
   then
   sn-buf 2+  sn-buf 1+  d# 11 move  \ Elide the T
   d# 11 sn-buf c!
   true
;

: scan-sn  ( -- )
   ." *****"

   begin
      " Please Input Serial Number ......" .instructions
      try-scan-sn
   until
;

: board#$  ( -- adr len )
   " B#" find-tag  0= abort" Missing B# tag !!!"
   -null
;

: get-info  ( -- )
   scan-sn
;

0 0 2value response$

: final-filename$  ( -- adr len )  sn$ " %s.txt" sprintf  ;

\ Send the board number as the request and return the response data
: final-tag-exchange  ( -- )
   final-filename$ open-temp-file
   sn$              " SN:"  put-key+value
   " Request" submit-file
   " Response" get-response  to response$ 
;

: show-result-screen  ( -- )
   pass?  if
      clear-screen
      ." PASS" cr cr
      green-screen
   else
      ." FAIL" cr cr
      red-screen
   then
;

: put-ka-tag  ( value$ key$ -- )
   2over  8 min  ka-dir$ " %s%s" sprintf  ( value$ key$ filename$ )
   $read-file  if                     ( value$ key$ )
      ." ERROR: No KA tag file for " 2swap type cr  ( key$ )
      2drop                           ( )
   else                               ( value$ key$ file-data$ )
      2swap ($add-tag)                ( value$ )
      2drop                           ( )
   then
;

false value write-protect?

: special-tag?  ( value$ key$ -- true | value$ key$ false )
   2dup " KA" $=  if                       ( value$ key$ )
      put-ka-tag                           ( )
      true  exit                           ( -- true )
   then                                    ( value$ key$ )
   2dup " WP" nocase-$=  if                ( value$ key$ )
      2drop " 0" $=  0= to write-protect?  ( )
      true exit                            ( -- true )
   then                                    ( value$ key$ )
   2dup " ak" nocase-$=  if                ( value$ key$ )
      2drop " 0" $=  0=  if                ( )
         " "  " ak"  ($add-tag)            ( )
      then                                 ( )
      true exit                            ( -- true )
   then                                    ( value$ key$ )
   false                                   ( value$ key$ false )
;
: put-tag  ( value$ key$ -- )
   special-tag?  if  exit  then
   put-ascii-tag
;
: show-tag  ( value$ -- )
   $tag-printable?  if  ?-null type  else  wrapped-cdump  then
;
: do-tag-error  ( -- )
   \ Don't know what to do here
   begin halt again
;
: handle-tag  ( value$ key$ -- )
   2dup find-tag  if  ( value$ key$ old-value$ )       \ Tag already exists, check it
      2over " KA" $=  0=  if  ?-null  then   ( value$ key$ old-value$' )
      2>r 2over 2r@ $=  if                   ( value$ key$ r: old-value$' )
         2drop 2drop 2r> 2drop               ( )
      else                                   ( value$ key$ r: old-value$' )
         2drop 2drop 2r> 2drop               ( )
         \ type ." tag changed!" cr            ( value$ r: old-value$' )
         \ ."   Old: " r> show-tag cr          ( value$ )
         \ ."   New: " show-tag cr             ( )
         \ do-tag-error
      then
   else                                      ( value$ key$ )   \ New tag, add it
      put-tag
   then
;

: parse-tags  ( adr len -- )
   begin  dup  while              ( adr len )
      linefeed left-parse-string  ( rem$ line$ )
      ?remove-cr                  ( rem$ line$ )
      [char] : left-parse-string  ( rem$ value$ key$ )
      dup 2 =  if                 ( rem$ value$ key$ )
         handle-tag               ( rem$ )
      else                        ( rem$ value$ key$ )
         4drop                    ( rem$ )
      then                        ( rem$ )
   repeat                         ( adr len )
   2drop                          ( )
;
: format-date  ( s m h d m y -- adr len )
   push-decimal
   >r >r >r >r >r >r
   <#
   [char] Z hold
   r> u# u# drop
   r> u# u# drop
   r> u# u# drop
   [char] T hold
   r> u# u# drop
   r> u# u# drop
   r> u# u# u# u#
   u#>
   pop-base
;
: make-md-tag  ( -- )
   time&date  ( s m h d m y )  format-date  " MD" put-ascii-tag
;
: inject-tags  ( -- )
   get-mfg-data

   " TS" ($delete-tag)
   " MS" ($delete-tag)
   " BD" ($delete-tag)
   " MD" ($delete-tag)
   make-md-tag
   " FINAL"  " TS" ($add-tag)

   response$ parse-tags

   \ per request from wei-heng
   " TS" ($delete-tag)
   " SHIP"  " TS" put-ascii-tag

   flash-write-enable
   (put-mfg-data)
   \ Change "ww" to "wp" if we want security to be enabled
   write-protect?  if  " wp"  h# efffe  write-spi-flash  then
   no-kbc-reboot
   kbc-on
;

d# 4 constant rtc-threshold
0 value ntp-seconds
0 value rtc-seconds
: .clocks  ( -- )
   ." RTC: " rtc-seconds unix-seconds> .date space .time ."  UTC" cr
   ." NTP: " ntp-seconds unix-seconds> .date space .time ."  UTC" cr
;
: verify-rtc-date  ( -- )
\ XXX check RTC power lost bit
   ." Getting time from NTP server .. "
   begin  ntp-timestamp  while  ." Retry "  repeat  ( d.timestamp )

   ntp>time&date >unix-seconds  to ntp-seconds
   time&date     >unix-seconds  to rtc-seconds
   ntp-seconds rtc-seconds -       ( lost-seconds )
   dup rtc-threshold >  if         ( lost-seconds )
      page show-fail               ( lost-seconds )
      ." Clock lost " .d ." seconds since SMT"  cr  ( )
      .clocks
      stall
   then                            ( lost-seconds )

   abs dup rtc-threshold >  if     ( gained-seconds )
      page show-fail               ( gained-seconds )
      ." Clock gained " .d ." seconds since SMT"  cr  ( )
      .clocks
      stall
   then
   ." NTP and RTC clocks agree." cr
;

: put-key:value  ( value$ key$ -- )  " %s:%s" sprintf put-key-line  ;

: upload-tag  ( data$ tag$ -- )
   2dup " wp" $=  if                       ( data$ tag$ )
      4drop  " 1" " WP" put-key:value      ( )
      exit
   then
   2dup " ww" $=  if                       ( data$ tag$ )
      4drop  " 0" " WP" put-key:value      ( )
      exit
   then
   2dup " ak" $=  if                       ( data$ tag$ )
      4drop  " 1" " ak" put-key:value      ( )
      exit
   then
   2dup " KA" $=  if                       ( data$ tag$ )
      4drop                                ( )
      exit
   then
   2dup " SG" $=  if                       ( data$ tag$ )
      4drop                                ( )
      exit
   then                                    ( data$ tag$ )

   2swap ?-null 2swap                      ( data$' tag$ )
   put-key:value                           ( )
;

: upload-tags  ( -- )
   mfg-data-top                 ( adr )
   begin  another-tag?  while   ( adr' data$ tname-adr )
      2 upload-tag              ( adr )
   repeat                       ( adr )
   drop
;

\ Upload the result data 
: final-result  ( -- )
   final-filename$  open-temp-file
   upload-tags
   pass?  if  " PASS"  else  " FAIL"  then  " RESULT="  put-key+value
   " Handshake" submit-file
;

: wait-connections  ( -- )
   silent-probe-usb
   wait-scanner
   ?usb-keyboard
   wait-lan
\   wait-usb-key
;             

: my-cifs-connect  ( adr -- )
   open-dev to cifs-ih
   cifs-ih 0= abort" Cannot open SMB share"
;

: finish-final-test  ( -- )
   wait-connections

   get-info

\   verify-rtc-date

   ." Getting final tags .. "
   cifs-connect final-tag-exchange cifs-disconnect
   ." Done" cr

   \ save a copy of the factory server string, before we destroy MS tag
   factory-server$ dup alloc-mem $save

   inject-tags

   my-cifs-connect final-result cifs-disconnect
   " int:\runin\olpc.fth" $delete-all

   \ Ultimately this should just be delete of runin\olpc.fth
   \ " int:\runin\olpc.fth" " int:\runin\runin.sav" $rename
;

\ Make the "wait for SD insertion" step highly visible 
dev ext
warning @  warning off
: wait&clear  ( -- error? )  wait-card? page  ;
patch wait&clear wait-card? selftest
: selftest  ( -- )  page show-pass  selftest  ;
warning !
dend

: fail-backup-file$  ( -- name$ )
   time&date format-date " int:\runin\fail-%s.log" sprintf
;
: fail-log-file$  ( -- name$ )  " int:\runin\fail.log"   ;

\ The operator can type this to reset the state to run
\ the Linux-based runin tests again.
: rerunin  ( -- )
   " int:\runin\olpc.fth" $delete-all
   fail-log-file$ fail-backup-file$ $rename
;

: after-runin  ( -- )
   fail-log-file$ $read-file  0=  if  ( adr len )
      page
      show-fail
      ." Type a key to see the failure log"
      key drop  cr cr
      list
      ." Type R to restart runin, any other key to power off "
      key dup emit cr  upc [char] R =  if
         ." Resetting state to restart runin." cr
         ." The old failure log is in " fail-backup-file$ type cr
         rerunin
      else
         power-off
      then
   else
      autorun-mfg-tests
      pass?  if  finish-final-test  then
      show-result-screen
   then

   ." Type a key to power off"
   key cr
   power-off
;

\ Override the display self test
dev /display

warning @ warning off
: selftest  ( -- error? )
   depth d# 16 <  if  false exit  then

   .vertical-bars16     wait
    hgradient           

   confirm-selftest?
;
warning !
 
device-end

after-runin
